package 
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.Stage;
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
	import flash.utils.Timer;
	
	public class VideoPlayer extends Sprite 
	{
		private var videoURL:String;
		private var connection:NetConnection; 
		private var videoStream:NetStream;
		private var video:Video;				// video object
		private var timer:Timer;
		private var vidInfoObj:Object = new Object();
		private var eventListeners:Array = new Array();
		
		private var status:String = "";
		private static const STATUS_READY_TO_PLAY:String = "NetStream.Buffer.Full";
		private static const STATUS_PAUSED:String = "";
		private static const STATUS_STOPPED:String = "";
		
		private static const ON_LOADING_PLAYER_LOADED:int = 1;
		private static const ON_LOADING_METADATA_LOADED:int = 2;
		private static const ON_LOADING_MEDIA_LOADED:int = 3;
		
		private static const ON_STATE_CHANGE_PLAY_BEGUN:int = 1;
		private static const ON_STATE_CHANGE_PAUSED:int = 2;
		private static const ON_STATE_CHANGE_STOPPED:int = 3;
		private static const ON_STATE_CHANGE_ENDED:int = 4;
		
		public static const ON_LOADING:String = "onLoading";
		public static const ON_STATE_CHANGE:String = "onStateChange";
		
		
		
		public function VideoPlayer():void
		{
			this.connection = new NetConnection();
			this.connection.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			this.connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			this.connection.connect(null);
			
			video = new Video();
			video.attachNetStream(videoStream);
			addChild(video);
			
			this.addEventListener(Event.ENTER_FRAME, loading);
			
			// hack
			this.timer = new Timer(1); //Set a timer for 1 ms.
			timer.addEventListener(TimerEvent.TIMER, onTimer);
		}
		
		public function load(url:String):void
		{
			//timer.start();
			this.videoURL = url;
			this.log(videoURL);
			videoStream.play(videoURL);
		}
		
		public function play():void
		{
			this.log("play. status: " + this.status);
			if(this.status == STATUS_READY_TO_PLAY)
			{
				videoStream.resume();
			}
		}
		
		public function stop():void
		{
			videoStream.close();
			video.clear();
		}
		
		public function pause():void
		{
			videoStream.pause();
		}
		
		// -------- Error Handling Events 
		private function netStatusHandler(event:NetStatusEvent):void 
		{
			this.log(event.info.code);
			switch (event.info.code) 
			{
				case "NetConnection.Connect.Success":
					connectStream();
					break;
				case "NetStream.Play.StreamNotFound":
					//this.log("Stream not found: " + videoURL);
					break;
				case "NetStream.Play.Start":
					//this.log("NetStream.Play.Start");
					this.onStateChange(ON_STATE_CHANGE_PLAY_BEGUN);
					break;
				case "NetStream.Buffer.Full":
					this.pause();
					this.status = STATUS_READY_TO_PLAY;
					//this.log("NetStream.Buffer.Full");
					this.onLoading(ON_LOADING_MEDIA_LOADED);

				case "NetStream.FileStructureInvalid":
					//this.log("The MP4's file structure is invalid.");
					break;
				case "NetStream.NoSupportedTrackFound":
					//this.log("The MP4 doesn't contain any supported tracks");
					break;
			}
		}
		
		private function securityErrorHandler(event:SecurityErrorEvent):void 
		{
			this.log("securityErrorHandler: " + event);
		}
		
		private function connectStream():void 
		{
			this.log("netstream created");
			videoStream = new NetStream(connection);
			videoStream.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			videoStream.client = this;
		}
		
		
		private function loading(e:Event):void
		{
			var total:Number = this.stage.loaderInfo.bytesTotal;
			var loaded:Number = this.stage.loaderInfo.bytesLoaded;
			
			this.log(Math.floor((loaded/total)*100)+ "%");
			
			if (total == loaded)
			{
				this.removeEventListener(Event.ENTER_FRAME, loading);
			}
		}
		
		private function onTimer(evt:TimerEvent):void
		{
			var percent:Number = Math.round(videoStream.bytesLoaded/videoStream.bytesTotal * 100 );
			if(percent == 100)
			{
				this.timer.stop();
			}
		}
		
		public function onMetaData(info:Object):void {
			var vidInfoObj:Object = info;
			videoStream.bufferTime = vidInfoObj.duration;
			
			this.log("metadata: duration=" + info.duration + " width=" + info.width + " height=" + info.height + " framerate=" + info.framerate);
			this.onLoading(2);
		}
		
		
		// -------- Events
		private function onError(eventValue:int):void
		{
			this.dispatchEvent(new PlayerEvent(PlayerEvent.ON_ERROR, eventValue));  
		}
		
		private function onStateChange(eventValue:int):void
		{
			this.dispatchEvent(new PlayerEvent(PlayerEvent.ON_STATE_CHANGE, eventValue));  
		}
		
		private function onLoading(eventValue:int):void 
		{  
			
			this.dispatchEvent(new PlayerEvent(PlayerEvent.ON_LOADING, eventValue));
		}
		
		// -------- Helper methods
		
		private var verbose:Boolean = true;
		
		private function log(message:String):void
		{
			var currentTime:Date = new Date();
			
			trace(currentTime.getHours() + ":" + currentTime.getMinutes() + ":" + currentTime.getSeconds() + " " + message);
		}
		
	}
}