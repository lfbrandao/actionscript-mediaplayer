package players 
{
	import configuration.Consts;
	
	import events.PlayerEvent;
	
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.NetStreamPlayOptions;
	import flash.utils.Timer;
	
	public class VideoPlayer extends Sprite implements IPlayer
	{
		private var connection:NetConnection;	// video stream connection 
		private var videoStream:NetStream;		// video streaming object
		private var video:Video;				// video object
		
		private var vidInfoObj:Object;			// array for loading metadata
		private var eventListeners:Array;		// event listeners list
		
		private var timer:Timer;
		
		private var videoURL:String;			// current video's URL
		private var startTime:Number;			// current video's start time
		private var endTime:Number;				// current video's end time
		
		private var status:String = "";			// player status
		
		// hack to stop the video when endTime is reached 
		private var stopVideoTimer:Timer;
		private var stopVideoAt:Number;
		
		// -------- Constructors
		
		public function VideoPlayer(width:int, height:int):void
		{
			this.vidInfoObj = new Object();
			this.eventListeners = new Array();
			
			// open a remote connection to stream the video
			this.connection = new NetConnection();
			this.connection.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			this.connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			this.connection.connect(null);
	
			// init the video object and attach it to the stream
			video = new Video(width, height);
			video.attachNetStream(videoStream);
			
			// add the video the sprite
			addChild(video);
			
			// hack
			this.timer = new Timer(1); //Set a timer for 1 ms.
			timer.addEventListener(TimerEvent.TIMER, onTimer);
			
			this.stopVideoTimer = new Timer(1);
			this.stopVideoTimer.addEventListener(TimerEvent.TIMER, onStopVideoTimer);
		}
		
		// -------- Playback control
		
		public function load(url:String, startAt:Number = 0.00, stopAt:Number = -1.00):void
		{
			this.log("LOAD");
			this.videoStream.close();
			this.video.clear();
			this.status = Consts.STATUS_LOADING;
				
			//timer.start();
			this.videoURL = url;
			this.log(videoURL);
			
			this.startTime = startAt;
			
			if(stopAt > -1)
			{
				this.stopVideoAt = startAt + stopAt;
			}
			
			// calling play seems to be the only way to load the video
			this.videoStream.play(videoURL);
		}
		
		public function play():void
		{
			this.log("PLAY " + this.startTime + " " + this.status);
			this.onStateChange(Consts.ON_STATE_CHANGE_PLAYING);
			if(((this.startTime != 0) && (this.status == Consts.STATUS_LOADING)) || this.status == Consts.STATUS_STOPPED)
			{
			    videoStream.seek(this.startTime);
			}
			videoStream.resume();
			
			this.stopVideoTimer.start();
		}
		
		public function stop():void
		{
			this.status = Consts.STATUS_STOPPED;
			this.onStateChange(Consts.ON_STATE_CHANGE_STOPPED);
			videoStream.pause();
		}
		
		public function pause():void
		{
			this.status = Consts.STATUS_PAUSED;
			this.onStateChange(Consts.ON_STATE_CHANGE_PAUSED);
			
			videoStream.pause();
		}
				
		// -------- Playback time
		
		public function getCurrentTime():Number
		{
			return this.videoStream.time;
		}
		
		public function getStartTime():Number
		{
			return this.startTime;
		}
		
		public function getEndTime():Number
		{
			return this.endTime;
		}
		
		// -------- Error Handling Events 
		
		private function netStatusHandler(event:NetStatusEvent):void 
		{
			this.log(event.info.code);
			switch (event.info.code) 
			{
				case "NetStream.Play.Stop":
					this.log("Stop: " + this.videoStream.time + " " +  this.endTime);
					this.status = Consts.STATUS_STOPPED;
					if(int(this.videoStream.time) == int(this.endTime))
					{
						this.onStateChange(Consts.ON_STATE_CHANGE_ENDED);
					}
					break;
				case "NetStream.Pause.Notify":
					this.status = Consts.STATUS_PAUSED;
					break;
				case "NetConnection.Connect.Success":
					connectStream();
					break;
				case "NetStream.Buffer.Full":
					if(this.status == Consts.STATUS_LOADING)
					{	
						this.videoStream.pause();
						//this.videoStream.seek(this.startTime);
						this.status = Consts.STATUS_READY_TO_PLAY;
						this.onLoading(Consts.ON_LOADING_MEDIA_LOADED);
					}
				case "NetStream.Buffer.Flush":
					if(this.status == Consts.STATUS_LOADING)
					{	
						this.videoStream.pause();
						this.status = Consts.STATUS_READY_TO_PLAY;
						this.onLoading(Consts.ON_LOADING_MEDIA_LOADED);
					}
					break;
				case "NetStream.Play.Failed":
					this.onError(Consts.ON_ERROR_FAILED_TO_LOAD);
					break;
				case "NetStream.Play.StreamNotFound":
				case "NetStream.FileStructureInvalid":
				case "NetStream.Play.NoSupportedTrackFound":
					this.onError(Consts.ON_ERROR_FILE_NOT_SUPPORTED);
					break;
			}
		}
		
		private function securityErrorHandler(event:SecurityErrorEvent):void 
		{
			this.log("securityErrorHandler: " + event);
		}
		
		private function connectStream():void 
		{
			//this.log("netstream created");
			videoStream = new NetStream(connection);
			videoStream.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			videoStream.client = this;
		}
	
		// -------- Timer events
		private function onTimer(evt:TimerEvent):void
		{
			var percent:Number = Math.round(videoStream.bytesLoaded/videoStream.bytesTotal * 100 );
			if(percent == 100)
			{
				this.timer.stop();
			}
		}
		
		private function onStopVideoTimer(evt:TimerEvent):void
		{
			// this.log("onStopVideoTimer " + this.stopVideoAt + " - " + this.videoStream.time); 
			if(this.endTime > -1)
			{	
				if(this.videoStream.time >= this.stopVideoAt)
				{
					this.stop();
					this.stopVideoTimer.stop();
				}
			}
		}
		
		public function onMetaData(info:Object):void {
			var vidInfoObj:Object = info;
			/*
			for (var prop:String in vidInfoObj)
			{
				
				if(prop == "seekpoints")
				{
					trace(prop);
					var spoints:Object = prop;
					for (var sp:String in spoints)
					{
						trace(sp);
					}
				}
			}*/
			
			this.endTime = videoStream.bufferTime = vidInfoObj.duration;
			this.onLoading(Consts.ON_LOADING_METADATA_LOADED);
		}
		
		// -------- Event Dispatchers
		
		public function onError(eventId:int):void
		{
			this.dispatchEvent(new PlayerEvent(PlayerEvent.ON_ERROR, eventId));  
		}
		
		public function onStateChange(eventId:int, eventValue:Number = 0):void
		{
			//this.log("OnStateChange " + eventValue);
			this.dispatchEvent(new PlayerEvent(PlayerEvent.ON_STATE_CHANGE, eventId, eventValue));  
		}
		
		public function onLoading(eventId:int):void 
		{  
			this.dispatchEvent(new PlayerEvent(PlayerEvent.ON_LOADING, eventId));
		}
		
		// -------- Helper methods
		
		private var verbose:Boolean = false;
		
		private function log(message:String):void
		{
			var currentTime:Date = new Date();
			
			trace("VideoPlayer " + currentTime.getHours() + ":" + currentTime.getMinutes() + ":" + currentTime.getSeconds() + " " + message);
		}
	}
}