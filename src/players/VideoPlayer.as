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
		
		private var videoURL:String;			// current video's URL
		private var startTime:Number;			// current video's start time
		private var endTime:Number;				// current video's end time
		
		private var status:String = "";			// player status
		
		// hack to stop the video when endTime is reached 
		private const bufferTime:Number = 3;
		
		// -------- Constructors
		
		public function VideoPlayer(width:int, height:int):void
		{
			this.log("START");
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
		}
		
		// -------- Playback control
		
		public function load(url:String, startAt:Number = 0.00, stopAt:Number = -1.00):void
		{
			this.videoStream.close();
			this.video.clear();
			this.status = Consts.STATUS_LOADING;
				
			//timer.start();
			this.videoURL = url;
			this.log(videoURL);
			
			this.startTime = startAt;
			
			this.videoStream.play(videoURL);
			this.video.visible = false;
		}
		
		public function play():void
		{
			this.onStateChange(Consts.ON_STATE_CHANGE_PLAYING);
			videoStream.resume();
			this.status = Consts.STATUS_PLAYING;
		}
		
		public function stop():void
		{
			this.status = Consts.STATUS_STOPPED;
			this.onStateChange(Consts.ON_STATE_CHANGE_STOPPED);
			videoStream.pause();
			this.status = Consts.STATUS_SEEKING;
			videoStream.seek(this.startTime);
		}
		
		public function pause():void
		{
			videoStream.pause();
			this.onStateChange(Consts.ON_STATE_CHANGE_PAUSED);
			this.status = Consts.STATUS_PAUSED;
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
		
		public function getStatus():String
		{
			return this.status;
		}
		
		// -------- Error Handling Events 
		
		private function netStatusHandler(event:NetStatusEvent):void 
		{
			this.log("Code: " + event.info.code + " / Status: " + this.status);
			switch (event.info.code) 
			{
				case "NetStream.Seek.Notify":
					if(this.status == Consts.STATUS_LOADING)
					{
						this.status = Consts.STATUS_SEEKING;
						this.videoStream.resume();
					}
					break;
				case "NetStream.Play.Start":
					if(this.status == Consts.STATUS_LOADING)
					{	
						if(this.startTime > 0)
						{
							this.videoStream.pause();
							this.videoStream.seek(this.startTime);
						}
					}
					
					break;
				case "NetStream.Play.Stop":
					this.status = Consts.STATUS_STOPPED;
					if(int(this.videoStream.time) == int(this.endTime))
					{
						this.onStateChange(Consts.ON_STATE_CHANGE_ENDED);
					}
					break;
				case "NetStream.Pause.Notify":
					break;
				case "NetConnection.Connect.Success":
					connectStream();
					break;
				case "NetStream.Play.Failed":
					this.onError(Consts.ON_ERROR_FAILED_TO_LOAD);
					break;
				case "NetStream.Play.StreamNotFound":
				case "NetStream.FileStructureInvalid":
				case "NetStream.Play.NoSupportedTrackFound":
					this.onError(Consts.ON_ERROR_FILE_NOT_SUPPORTED);
					break;
				case "NetStream.Buffer.Flush":
				case "NetStream.Buffer.Full":
					if(this.status == Consts.STATUS_SEEKING || this.status == Consts.STATUS_LOADING)
					{
						/*
						this.videoStream.pause();
						this.status = Consts.STATUS_READY_TO_PLAY;
						this.onLoading(Consts.ON_LOADING_MEDIA_LOADED);
						*/
						this.changeVideoStatusToPlay();
					}
					break;
			}
		}
		
		private var seekEventTimer:Timer;
		
		private function changeVideoStatusToPlay()
		{
			this.log("changeVideoStatusToPlay " + this.getCurrentTime() + " " + this.startTime);
			if(this.getCurrentTime() >= this.startTime)
			{
				this.videoStream.pause();
				this.status = Consts.STATUS_READY_TO_PLAY;
				this.onLoading(Consts.ON_LOADING_MEDIA_LOADED);
				this.video.visible = true;
			}
			else
			{
				this.seekEventTimer = new Timer(1);
				this.seekEventTimer.addEventListener(TimerEvent.TIMER, onSeekEventTimer);
				this.seekEventTimer.start();
			}
		}
		
		private function onSeekEventTimer(event:Event):void
		{
			if(this.getCurrentTime() >= this.startTime)
			{
				this.seekEventTimer.stop();
				this.videoStream.pause();
				this.status = Consts.STATUS_READY_TO_PLAY;
				this.onLoading(Consts.ON_LOADING_MEDIA_LOADED);
				this.video.visible = true;
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
			videoStream.bufferTime = bufferTime;
		}
	
		public function onMetaData(info:Object):void {
			var vidInfoObj:Object = info;
			
			this.video.width = vidInfoObj.width;
			this.video.height = vidInfoObj.height;
			
			// http://stackoverflow.com/questions/4366093/how-to-get-current-frame-of-currently-playing-video-file
			var metaInfo = info;
			var tmpstr:String = '';
			for(var s:String in info){
				var tstr:String = s + ' = ' + info[s] + '\n';
				tmpstr += tstr.indexOf('object') == -1 ? tstr : '';
				for(var a:String in info[s]){
					var ttstr:String = s + ':' + a + ' = ' + info[s][a] + '\n';
					tmpstr += ttstr.indexOf('object') == -1 ? ttstr : '';
					for(var c:String in info[s][a]){
						var tttstr:String = s + ':' + a + ':' + c + ' = ' + info[s][a][c] + '\n';
						tmpstr += tttstr.indexOf('object') == -1 ? tttstr : '';                     
					}
				}
			}
			this.log(tmpstr);     
			
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
		
		private var verbose:Boolean = true;
		
		private function log(message:String):void
		{
			var currentTime:Date = new Date();
			if(verbose)
			{
				trace("VideoPlayer " + currentTime.getHours() + ":" + currentTime.getMinutes() + ":" + currentTime.getSeconds() + " " + message);
			}
		}
	}
}