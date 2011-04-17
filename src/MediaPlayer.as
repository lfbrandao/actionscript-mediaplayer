package
{
	import configuration.Consts;
	
	import events.PlayerEvent;
	
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Point;
	import flash.media.SoundMixer;
	import flash.media.SoundTransform;
	import flash.utils.*;
	
	import flashx.textLayout.formats.BackgroundColor;
	
	import players.AudioPlayer;
	import players.IPlayer;
	import players.VideoPlayer;
	
	public class MediaPlayer extends Sprite
	{
		private static const STATUS_CAN_PLAY:String = "canPlay";
		private static const STATUS_PAUSED:String = "pause";
		private static const STATUS_STOPPED:String = "stopped";
		
		private var videoPlayer:VideoPlayer; 	// video player
		private var audioPlayer:AudioPlayer; 	// audio player
		
		private var currentFileURL:String; 		// url of the current media
		private var currentPlayer:IPlayer; 		// reference to player in use
		private var status:String; 				// player status
		private var playerId:String; 			// player id
		
		private var timeChangeTimer:Timer;		// media playback progress timer
		private var lastTime:Number;			// 
		
		private var verbose:Boolean = false;		// enable / disable logging
		
		// -------- Constructor
		
		public function MediaPlayer()
		{
			this.currentFileURL = "";
		
			// create and configure the audio player
			this.audioPlayer = new AudioPlayer();
			this.audioPlayer.addEventListener(PlayerEvent.ON_LOADING, onPlayerEvent);
			this.audioPlayer.addEventListener(PlayerEvent.ON_ERROR, onPlayerEvent);
			this.audioPlayer.addEventListener(PlayerEvent.ON_STATE_CHANGE, onPlayerEvent);
			
			// setup the entry point for javascript calls
			ExternalInterface.addCallback("sendToFlash", playerControl);
			ExternalInterface.addCallback("getVolume", getVolume);
			
			// set the player id
			var paramObj:Object = LoaderInfo(this.root.loaderInfo).parameters;
			this.playerId = paramObj.vidId;
			this.log("playerId " + this.playerId);
			
			// setup the stage scale mode to trigger the resize event and configure the event
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.RESIZE, onStageResize);
			
			// timer for video playback progress
			this.timeChangeTimer = new Timer(500);
			this.timeChangeTimer.addEventListener(TimerEvent.TIMER, onTimeChange);
			
			// create and configure the video player
			this.videoPlayer = new VideoPlayer(stage.stageWidth, stage.stageHeight);
			this.videoPlayer.addEventListener(PlayerEvent.ON_LOADING, onPlayerEvent);
			this.videoPlayer.addEventListener(PlayerEvent.ON_ERROR, onPlayerEvent);
			this.videoPlayer.addEventListener(PlayerEvent.ON_STATE_CHANGE, onPlayerEvent);
			
			// the video player is the default player
			this.currentPlayer = this.videoPlayer;
			
			// add both players to the container
			this.addChild(this.videoPlayer);
			this.addChild(this.audioPlayer);
			
			// notify listeners that the player is loaded
			this.loaderInfo.addEventListener(Event.COMPLETE, onPlayerLoaded);
		}
		
		
		// -------- Playback control
		
		/**
		 * Player playback control function. Plays, pauses, (...) the player.
		 *
		 * @param action Action (play, pause, etc) to perform.
		 * @param value Action configuration values.
		 *
		 */
		public function playerControl(action:String, value:String) : Number
		{
			if(action == "play")
			{
				this.play();
			}
			else if(action == "stop")
			{
				this.stop();
				this.timeChangeTimer.stop();
			}
			else if(action == "pause")
			{
				this.pause();
				this.timeChangeTimer.stop();
			}
			else if(action == "load")
			{
				// TO-DO - check params
				var params:Array = value.split(",");
				
				this.load(params[0], params[1], params[2]);
			}
			else if(action == "setVolume")
			{
				this.setVolume(Number(value));
			}
			else if(action == "getCurrentTime")
			{
				this.log("time " + this.currentPlayer.getCurrentTime());
				return this.currentPlayer.getCurrentTime();
			}
			else if(action == "getStartTime")
			{
				this.log("time " + this.currentPlayer.getCurrentTime());
				return this.currentPlayer.getStartTime();
			}
			else if(action == "getEndTime")
			{
				this.log("time " + this.currentPlayer.getCurrentTime());
				return this.currentPlayer.getEndTime();
			}
			else if(action == "resize")
			{
				this.log("RESIZE");
				var params:Array = value.split(",");
				this.resizePlayer(params[0], params[1]);
			}
			
			return -1;
		}
		
		/**
		 * Loads a video or audio file.
		 *
		 * @param url File url
		 * @param startAt Start playing the video / audio at this time (in seconds). Optional parameter with 0 (beginning of file) as default value.
		 * @param stopAt Stop playing the video / audio after this time (in seconds). Optional parameter with -1 (end of file) as default value. 
		 *
		 */
		private function load(url:String, startAt:Number = 0.00, stopAt:Number = -1.00):void
		{
			var fileType:String = this.getFileType(url);
			
			switch(fileType)
			{
				case "mp3":
					this.currentPlayer = audioPlayer;
					break;
				default:
					this.currentPlayer = videoPlayer;
					break;
			}
			if(stopAt == 0)
			{
				stopAt = -1;
			}
			
			this.currentPlayer.load(url, startAt, stopAt);
			//this.resizePlayer(stage.stageWidth, stage.stageHeight);
		}
		
		/**
		 * Stops the video or audio playback. Subsequent calls to play will play the video from the beginning.
		 */
		private function stop():void
		{
			this.currentPlayer.stop();
		}
		
		/**
		 * Pauses the video or audio playback.
		 */
		private function pause():void
		{
			this.currentPlayer.pause();
		}
		
		/**
		 * Plays the latest video or audio loaded. If there is no file loaded the error event is triggered.
		 */
		private function play():void
		{
			/*if(this.currentFileURL == "")
			{
				this.onPlayerEvent(new PlayerEvent(PlayerEvent.ON_ERROR, Consts.ON_ERROR_NO_FILE_LOADED));
			}
			else
			{
			
			}
			*/
			this.currentPlayer.play();
			this.timeChangeTimer.start();
		}
		
		
		// -------- Internal events
		
		/**
		 * Stage resize event listener. Adjusts the video player size to fit in
		 * the stage.
		 *
		 * @event Stage resize event.
		 */
		private function onStageResize(event:Event):void 
		{
			this.resizePlayer(stage.stageWidth, stage.stageHeight);
			/*
			var stageAspectRatio:Number = stage.stageWidth / stage.stageHeight;
			var videoAspectRatio:Number = this.videoPlayer.width / this.videoPlayer.height; 
			
			var widthRatio:Number = stage.stageWidth / this.videoPlayer.width;
			var heightRatio:Number = stage.stageHeight / this.videoPlayer.height;
			
			if(widthRatio != 1 || heightRatio != 1)
			{
				if(heightRatio > widthRatio)
				{
				 	this.videoPlayer.width = stage.stageWidth;
					if (stageAspectRatio > videoAspectRatio)
					{
				 		this.videoPlayer.height = stage.stageWidth * videoAspectRatio;
					}
					else
					{
						this.videoPlayer.height = stage.stageWidth / videoAspectRatio;
					}
				}
				else
				{
					if (stageAspectRatio > videoAspectRatio)
					{
						this.videoPlayer.width = stage.stageHeight * videoAspectRatio;
					}
					else
					{
						this.videoPlayer.width = stage.stageHeight / videoAspectRatio;
					}
					this.videoPlayer.height = stage.stageHeight;
				}
				
				this.videoPlayer.x = Math.abs(this.videoPlayer.width - stage.stageWidth) / 2;
				this.videoPlayer.y = Math.abs(this.videoPlayer.height - stage.stageHeight) / 2;
			}*/
		}
		
		private function resizePlayer(canvasWidth:Number, canvasHeight:Number):void 
		{
			this.log("Resize player start");
			this.log("Stage size " + stage.width + " - " + stage.height);
			this.log("Stage size2 " + stage.stageWidth + " - " + stage.stageHeight);
			this.log("Video player size " + videoPlayer.width + " - " + videoPlayer.height);
			
			this.log("Updating video size...");
			
			var stageAspectRatio:Number = canvasWidth / canvasHeight;
			var videoAspectRatio:Number = this.videoPlayer.width / this.videoPlayer.height; 
			
			var widthRatio:Number = canvasWidth / this.videoPlayer.width;
			var heightRatio:Number = canvasHeight / this.videoPlayer.height;
			
			this.log("Width / height ratio " + widthRatio + " - " + heightRatio);
			
			if(widthRatio != 1 || heightRatio != 1)
			{
				if(heightRatio > widthRatio)
				{
					this.videoPlayer.width = canvasWidth;
					if (stageAspectRatio >= videoAspectRatio)
					{
						this.videoPlayer.height = canvasWidth * videoAspectRatio;
					}
					else
					{
						this.videoPlayer.height = canvasWidth / videoAspectRatio;
					}
				}
				else
				{
					if (stageAspectRatio >= videoAspectRatio)
					{
						this.videoPlayer.width = canvasHeight * videoAspectRatio;
					}
					else
					{
						this.videoPlayer.width = canvasHeight / videoAspectRatio;
					}
					this.videoPlayer.height = canvasHeight;
				}
				
				this.videoPlayer.x = 1 + (Math.abs(this.videoPlayer.width - canvasWidth) / 2);
				this.videoPlayer.y = 1 + (Math.abs(this.videoPlayer.height - canvasHeight) / 2);
			}
			
			this.log("Stage size " + stage.width + " - " + stage.height);
			this.log("Stage size2 " + stage.stageWidth + " - " + stage.stageHeight);
			this.log("Video player size " + videoPlayer.width + " - " + videoPlayer.height);
			
			this.log("Resize player ended");
		}
		
		
		// -------- Event Dispatchers
		
		private function onTimeChange(event:TimerEvent):void
		{
			if(lastTime > 0 && lastTime == this.currentPlayer.getCurrentTime())
			{
				this.timeChangeTimer.stop();
				return;
			}
			
			this.lastTime = this.currentPlayer.getCurrentTime();
			this.onPlayerEvent(new PlayerEvent(PlayerEvent.ON_STATE_CHANGE, Consts.ON_STATE_CHANGE_TIME, this.currentPlayer.getCurrentTime()));
		}
		
		private function onPlayerLoaded(event:Event):void
		{
			//this.onPlayerEvent(new PlayerEvent(PlayerEvent.ON_LOADING, 1));
			this.log("Player Loaded");
			// this.onStageResize(event);
			this.callJavascriptFunction("onPlayerLoaded", this.playerId);
		}
		
		private function onPlayerEvent(event:PlayerEvent):void
		{
			if(event.type == PlayerEvent.ON_LOADING && event.eventId == Consts.ON_LOADING_METADATA_LOADED)
			{
				this.resizePlayer(stage.stageWidth, stage.stageHeight);	
			}
			
			this.dispatchEventToJavascript(event.type, event.eventId, event.eventValue);
		}
		
		
		// -------- Volume control
		
		public function getVolume():Number
		{
			return SoundMixer.soundTransform.volume;
		}
		
		public function setVolume(value:Number):void
		{
			SoundMixer.soundTransform = new SoundTransform(value);
		}
		
		
		// -------- Call Javascript Functions
		
		private function callJavascriptFunction(functionName:String, functionValue:String) : void
		{
			if(ExternalInterface.available)  
			{
				ExternalInterface.call(functionName, functionValue);
			}
		}
		
		private function dispatchEventToJavascript(eventName:String, eventId:int, eventValue:Number = 0.00) : void  
		{  
			// TO-DO if not available?
			if(ExternalInterface.available)  
			{
				if(eventName == Consts.ON_STATE_CHANGE)
				{
					ExternalInterface.call(eventName, playerId, eventId, eventValue);
				}
				else
				{
					ExternalInterface.call(eventName, playerId, eventId);
				}
			}  
		}
		
		
		// -------- Helpers
		
		private function getFileType(url:String):String
		{
			var fileExtensionSeparatorIndex:Number = url.lastIndexOf('.');
			var fileExtension:String = url.substr(fileExtensionSeparatorIndex + 1, url.length).toLowerCase();
			
			if(fileExtension == "mp3")
			{
				return "mp3";
			}
			else
			{
				return "video";
			}
		}
		
		private function log(message:String):void
		{
			if(verbose)
			{
				var currentTime:Date = new Date();
				trace("MediaPlayer " + currentTime.getHours() + ":" + currentTime.getMinutes() + ":" + currentTime.getSeconds() + " " + message);
			}
		}
	}
}