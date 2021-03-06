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
	
	/**
	 * Video player. Uses the ActionScript' NetConnection and the NetStream objects
	 * for the video playback.
	 * 
	 * @see http://livedocs.adobe.com/flash/9.0/ActionScriptLangRefV3/flash/net/NetConnection.html
	 * @see http://livedocs.adobe.com/flash/9.0/ActionScriptLangRefV3/flash/net/NetStream.html
	 */
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
		
		/**
		 * Public constructor. Creates a video player that fits its container.
		 *
		 * @param width Container width
		 * @param param2 Container height
		 *
		 */
		public function VideoPlayer(width:int, height:int):void
		{
			this.log("START");
			this.vidInfoObj = new Object();
			this.eventListeners = new Array();
			
			// open a remote connection to stream the video
			this.connection = new NetConnection();
			this.connection.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			this.connection.connect(null);
	
			// init the video object and attach it to the stream
			video = new Video(width, height);
			video.attachNetStream(videoStream);
			
			// add the video the sprite
			addChild(video);
		}
		
		// -------- Playback control
		
		/**
		 * Loads a video file.
		 *
		 * @param url File url
		 * @param startAt Start playing the video at this time (in seconds). Optional parameter with 0 (beginning of file) as default value.
		 * @param stopAt Stop playing the video after this time (in seconds). Optional parameter with -1 (end of file) as default value. 
		 *
		 */
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
		
		/**
		 * Plays a video. If there is no video file loaded the error event is triggered.
		 */
		public function play():void
		{
			this.onStateChange(Consts.ON_STATE_CHANGE_PLAYING);
			videoStream.resume();
			this.status = Consts.STATUS_PLAYING;
		}
		
		/**
		 * Stops the video playback. Subsequent calls to 'play' will play the video from the beginning.
		 */
		public function stop():void
		{
			this.status = Consts.STATUS_STOPPED;
			this.onStateChange(Consts.ON_STATE_CHANGE_STOPPED);
			videoStream.pause();
			this.status = Consts.STATUS_SEEKING;
			videoStream.seek(this.startTime);
		}
		
		/**
		 * Pauses the video playback.
		 */
		public function pause():void
		{
			videoStream.pause();
			this.onStateChange(Consts.ON_STATE_CHANGE_PAUSED);
			this.status = Consts.STATUS_PAUSED;
		}
		
		/**
		 * Stops the audio playback. Subsequent calls to 'play' will play the audio from the beginning.
		 */
		public function seek(seekTo:Number):void
		{
			videoStream.seek(seekTo);
		}
		
		// -------- Playback time
		
		/**
		 * Returns the current playback time.
		 */
		public function getCurrentTime():Number
		{
			return this.videoStream.time;
		}
		
		/**
		 * Returns the configured video start time.
		 */
		public function getStartTime():Number
		{
			return this.startTime;
		}
		
		/**
		 * Returns the configured video end time.
		 */
		public function getEndTime():Number
		{
			return this.endTime;
		}
		
		/**
		 * Returns the player status.
		 */
		public function getStatus():String
		{
			return this.status;
		}
		
		// -------- Event Handling 
		
		/**
		 * Triggered by the video streaming object. Handles the video streaming.
		 * 
		 * @param event The event details. 
		 */
		private function netStatusHandler(event:NetStatusEvent):void 
		{
			this.log("Code: " + event.info.code + " / Status: " + this.status);
			switch (event.info.code) 
			{
				// occurs after a seek operation. the video playback is resumed.
				case "NetStream.Seek.Notify":
					if(this.status == Consts.STATUS_LOADING)
					{
						this.status = Consts.STATUS_SEEKING;
						this.videoStream.resume();
					}
					break;
				// occurs when the video playback starts or 
				// when a video is loaded. in the latter, the player is paused.
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
				// occurs when the video playback stops
				case "NetStream.Play.Stop":
					this.status = Consts.STATUS_STOPPED;
					if(int(this.videoStream.time) == int(this.endTime))
					{
						this.onStateChange(Consts.ON_STATE_CHANGE_ENDED);
					}
					break;
				// occurs when the connection to the video stream is successful. 
				case "NetConnection.Connect.Success":
					connectStream();
					break;
				// occurs when the connection to the video stream fails.
				case "NetStream.Play.Failed":
					this.onError(Consts.ON_ERROR_FAILED_TO_LOAD);
					break;
				case "NetStream.Play.StreamNotFound":
				case "NetStream.FileStructureInvalid":
				case "NetStream.Play.NoSupportedTrackFound":
					this.onError(Consts.ON_ERROR_FILE_NOT_SUPPORTED);
					break;
				// occurs when the player is ready to play a video
				case "NetStream.Buffer.Flush":
				case "NetStream.Buffer.Full":
					if(this.status == Consts.STATUS_SEEKING || this.status == Consts.STATUS_LOADING)
					{
						if(this.getCurrentTime() >= this.startTime)
						{
							// ready to play
							this.videoStream.pause();
							this.status = Consts.STATUS_READY_TO_PLAY;
							this.onLoading(Consts.ON_LOADING_MEDIA_LOADED);
							this.video.visible = true;
						}
						else
						{
							// HACK: seeking not always work. silently play the video
							// till the position configured as the start time is reached.
							this.seekEventTimer = new Timer(1);
							this.seekEventTimer.addEventListener(TimerEvent.TIMER, onSeekEventTimer);
							this.seekEventTimer.start();
						}
					}
					break;
			}
		}
		
		private var seekEventTimer:Timer;
		
		/**
		 * Triggered by the event that gives support to video seeking (HACK)
		 * Used to silently play the video till the position configured as the start time is reached.
		 * 
		 * @param event The event details. 
		 */
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
		
		/**
		 * Connects the player to a video stream
		 * 
		 */
		private function connectStream():void 
		{
			//this.log("netstream created");
			videoStream = new NetStream(connection);
			videoStream.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			videoStream.client = this;
			videoStream.bufferTime = bufferTime;
		}
	
		/**
		 * Loads the video metadata
		 * 
		 * @param info Metadata 
		 */
		public function onMetaData(info:Object):void {
			var vidInfoObj:Object = info;
			
			this.video.width = vidInfoObj.width;
			this.video.height = vidInfoObj.height;
			
			// http://stackoverflow.com/questions/4366093/how-to-get-current-frame-of-currently-playing-video-file
			
			this.endTime = videoStream.bufferTime = vidInfoObj.duration;
			
			this.onLoading(Consts.ON_LOADING_METADATA_LOADED);
		}
		
		public function onPlayStatus(infoObject:Object):void 
		{ 
			//trace("onPlayStatus"); 
		} 
		
		// -------- Event Dispatchers
		
		/**
		 * Dispatched when an error occurs. 
		 * 
		 * @param event The event details. 
		 */
		public function onError(eventId:int):void
		{
			this.dispatchEvent(new PlayerEvent(PlayerEvent.ON_ERROR, eventId));  
		}

		/**
		 * Dispatched when the player state changes
		 * 
		 * @param eventId Event id
		 * @param eventValue Event value 
		 */
		public function onStateChange(eventId:int, eventValue:Number = 0):void
		{
			this.dispatchEvent(new PlayerEvent(PlayerEvent.ON_STATE_CHANGE, eventId, eventValue));  
		}
		
		/**
		 * Dispatched when an loading event occurs.
		 * 
		 * @param eventId Event id
		 */
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