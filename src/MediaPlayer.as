package
{
	import events.PlayerEvent;
	
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
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
		
		public function MediaPlayer()
		{
			this.eventsListeners = new Dictionary();
			
			// notify listeners that the player is loaded
			this.loaderInfo.addEventListener(Event.COMPLETE, onPlayerLoaded);
			
			this.currentFileURL = "";
		
			// create and configure the video player
			this.videoPlayer = new VideoPlayer(stage.width, stage.height);
			this.videoPlayer.addEventListener(PlayerEvent.ON_LOADING, onPlayerEvent);
			this.videoPlayer.addEventListener(PlayerEvent.ON_ERROR, onPlayerEvent);
			this.videoPlayer.addEventListener(PlayerEvent.ON_STATE_CHANGE, onPlayerEvent);
			
			// create and configure the audio player
			this.audioPlayer = new AudioPlayer();
			
			this.currentPlayer = this.videoPlayer;
			
			// add players to the sprite
			this.addChild(this.videoPlayer);
			this.addChild(this.audioPlayer);
			
			// setup entry point for javascript calls
			ExternalInterface.addCallback("sendToFlash", playerControl);
			ExternalInterface.addCallback("getVolume", getVolume);
			
			ExternalInterface.addCallback("addEventListener", addListener);
			ExternalInterface.addCallback("removeEventListener", removeListener);
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
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
			this.log("fromJS " + action + " : " + value);
			if(action == "play")
			{
				this.play();
			}
			else if(action == "stop")
			{
				this.stop();
			}
			else if(action == "pause")
			{
				this.pause();
			}
			else if(action == "load")
			{
				// TO-DO - check params
				var params:Array = value.split(",");
				this.load(params[0], params[1]);
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
		
		private function onPlayerLoaded(event:Event):void
		{
			this.onPlayerEvent(new PlayerEvent(PlayerEvent.ON_LOADING, 1));
		}
		
		private function onPlayerEvent(event:PlayerEvent):void
		{
			this.dispatchEventToJavascript(event.type, event.value);
		}
		
		// -------- Playback control
		
		private function load(url:String, startAt:int = 0):void
		{
			this.stop();
			
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
			
			this.currentPlayer.load(url, startAt);
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
		
		private function dispatchEventToJavascript(eventName:String, eventValue:int) : void  
		{  
			this.log("EVENT " + eventName);
			// TO-DO if not available?
			if(ExternalInterface.available)  
			{
				if(this.eventsListeners[eventName] != null)
				{
					var listeners:Array = this.eventsListeners[eventName] as Array;
					
					for(var i:int = 0; i < listeners.length; i++)
					{
						this.log("listener: " + eventName + " : " + eventValue);	
						ExternalInterface.call(listeners[i], eventValue);
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
				trace(currentTime.getHours() + ":" + currentTime.getMinutes() + ":" + currentTime.getSeconds() + " " + message);
			}
		}
	}
}