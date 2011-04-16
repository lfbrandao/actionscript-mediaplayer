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
	
	import players.AudioPlayer;
	import players.IPlayer;
	import players.VideoPlayer;
	
	public class MediaPlayer extends Sprite
	{
		private var videoPlayer:VideoPlayer;
		private var audioPlayer:AudioPlayer;
		private var currentFileURL:String;
		
		private var currentPlayer:IPlayer;
		
		private var status:String;
		
		private static const STATUS_CAN_PLAY:String = "canPlay";
		private static const STATUS_PAUSED:String = "pause";
		private static const STATUS_STOPPED:String = "stopped";
		
		private var eventsListeners:Dictionary;
		
		private var timeChangeTimer:Timer;
		private var playerId:String;
		
		// onload - id
		public function MediaPlayer()
		{
			this.eventsListeners = new Dictionary();
			
			// notify listeners that the player is loaded
			this.loaderInfo.addEventListener(Event.COMPLETE, onPlayerLoaded);
			
			this.currentFileURL = "";
		
			// create and configure the audio player
			this.audioPlayer = new AudioPlayer();
			this.audioPlayer.addEventListener(PlayerEvent.ON_LOADING, onPlayerEvent);
			this.audioPlayer.addEventListener(PlayerEvent.ON_ERROR, onPlayerEvent);
			this.audioPlayer.addEventListener(PlayerEvent.ON_STATE_CHANGE, onPlayerEvent);
			
			this.currentPlayer = this.videoPlayer;
			
			// setup the entry point for javascript calls
			ExternalInterface.addCallback("sendToFlash", playerControl);
			ExternalInterface.addCallback("getVolume", getVolume);
			
			ExternalInterface.addCallback("addEventListener", addListener);
			ExternalInterface.addCallback("removeEventListener", removeListener);
			
			// set the player id
			var paramObj:Object = LoaderInfo(this.root.loaderInfo).parameters;
			this.playerId = paramObj.vidId;
			this.log("playerId " + this.playerId);
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.RESIZE, resizeHandler);
			
			this.timeChangeTimer = new Timer(500);
			this.timeChangeTimer.addEventListener(TimerEvent.TIMER, onTimeChange);
			
			// add players to the sprite
			this.log("Mediaplayer width 1 " + this.stage.stageWidth);
			this.log("Mediaplayer height 1 " + this.stage.stageHeight);
			
			// create and configure the video player
			this.videoPlayer = new VideoPlayer(stage.stageWidth, stage.stageHeight);
			this.videoPlayer.addEventListener(PlayerEvent.ON_LOADING, onPlayerEvent);
			this.videoPlayer.addEventListener(PlayerEvent.ON_ERROR, onPlayerEvent);
			this.videoPlayer.addEventListener(PlayerEvent.ON_STATE_CHANGE, onPlayerEvent);
			this.addChild(this.videoPlayer);
			this.addChild(this.audioPlayer);
			
			this.log("Mediaplayer width 2 " + this.stage.stageWidth);
			this.log("Mediaplayer height 2 " + this.stage.stageHeight);
		}
		
		private function resizeHandler(event:Event):void 
		{
			trace("stageWidth: "+stage.stageWidth);
			trace("stageHeight: "+stage.stageHeight);
			//this.x = stage.stageWidth/2;
			//this.y = stage.stageHeight/2;
			
			/*
			this.videoPlayer.width = stage.stageWidth;
			this.videoPlayer.height = stage.stageHeight;
			*/
			
			var stageAspectRatio:Number = stage.stageWidth / stage.stageHeight;
			var videoAspectRatio:Number = this.videoPlayer.width / this.videoPlayer.height; 
			
			var widthRatio:Number = stage.stageWidth / this.videoPlayer.width;
			var heightRatio:Number = stage.stageHeight / this.videoPlayer.height;
			
			this.log("widthRatio:" + widthRatio);
			this.log("heightRatio:" + heightRatio);
			
			this.log("Stage aspect ratio:" + stageAspectRatio);
			this.log("Video aspect ratio:" + videoAspectRatio);
			
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
			}
			
			this.log("RESIZE - Stage Size " + stage.stageWidth + "x" + stage.stageHeight);
			this.log("RESIZE - Stage Size 2" + stage.width + "x" + stage.height);
			this.log("RESIZE - Videoplayer Size " + stage.stageWidth + "x" + stage.stageHeight);
		}
		
		private function addListener(eventName:String, listenerName:String):void
		{
			this.log("addListener " + eventName);
			// TO-DO - try/ catch, check if listener name is correct, avoid cast
			if(this.eventsListeners[eventName] == null)
			{
				this.log("addListener new");
				this.eventsListeners[eventName] = new Array();
			}
			(this.eventsListeners[eventName] as Array).push(listenerName);
		}
		
		private function removeListener(eventName:String, listenerName:String):void
		{
			if(this.eventsListeners[eventName] != null)
			{
				var listeners:Array = this.eventsListeners[eventName] as Array;
				var listenerIndex:int = listeners.indexOf(listenerName); 
				
				if(listenerIndex > -1)
				{
					this.eventsListeners[eventName] = listeners.splice(listenerIndex,1);
				}
			}	
		}
		
		private function playerControl(action:String, value:String) : Number
		{
			this.log("Player control - value : " + value);
			if(action == "play")
			{
				this.play();
				this.timeChangeTimer.start();
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
			
			return -1;
		}
		
		private var lastTime:Number;
		
		public function onTimeChange(event:TimerEvent):void
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
			this.onPlayerEvent(new PlayerEvent(PlayerEvent.ON_LOADING, 1));
			this.resizeHandler(event);
		}
		
		private function onPlayerEvent(event:PlayerEvent):void
		{
			this.dispatchEventToJavascript(event.type, event.eventId, event.eventValue);
		}
		
		// -------- Playback control
		
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
			
			this.currentPlayer.load(url, startAt, 5);
		}
		
		private function stop():void
		{
			this.currentPlayer.stop();
		}
		
		private function pause():void
		{
			this.currentPlayer.pause();
		}
		
		private function play():void
		{
			this.currentPlayer.play();
		}
		
		// -------- Volume control
		
		public function getVolume():Number
		{
			// TO-DO - avoid cast + error handling 
			return SoundMixer.soundTransform.volume;
		}
		
		public function setVolume(value:Number):void
		{
			/*this.videoPlayer.soundTransform = new SoundTransform(value);
			this.log("in " + SoundMixer.areSoundsInaccessible());*/
			this.log("volume " + value);
			SoundMixer.soundTransform = new SoundTransform(value);
		}
		
		// -------- Media type (audio/video)
		
		private function getFileType(url:String)
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
		
		private function dispatchEventToJavascript(eventName:String, eventId:int, eventValue:Number = 0.00) : void  
		{  
			// TO-DO if not available?
			if(ExternalInterface.available)  
			{
				if(this.eventsListeners[eventName] != null)
				{
					var listeners:Array = this.eventsListeners[eventName] as Array;
					
					for(var i:int = 0; i < listeners.length; i++)
					{
						if(eventName == Consts.ON_STATE_CHANGE)
						{
							ExternalInterface.call(listeners[i], playerId, eventId, eventValue);
						}
						else
						{
							ExternalInterface.call(listeners[i], playerId, eventId);
						}
					}
				}
			}  
		}
		
		
		// -------- Volume control
		
		private var verbose:Boolean = true;
		
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