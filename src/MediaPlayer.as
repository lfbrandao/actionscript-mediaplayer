package
{
	import events.PlayerEvent;
	
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.external.ExternalInterface;
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
		
		
		public function MediaPlayer()
		{
			this.loaderInfo.addEventListener(Event.COMPLETE, objectLoaded);
			
			
			this.currentFileURL = "";
			// create and configure the video player
			stage.align = StageAlign.TOP_RIGHT;
			stage.scaleMode = StageScaleMode.EXACT_FIT;
			
			
			this.videoPlayer = new VideoPlayer(stage.width, stage.height);
			this.videoPlayer.addEventListener(PlayerEvent.ON_LOADING, onLoading);
			this.videoPlayer.addEventListener(PlayerEvent.ON_STATE_CHANGE, onStateChange);
			
			// create and configure the audio player
			this.audioPlayer = new AudioPlayer();
			
			this.currentPlayer = this.videoPlayer;
			
			// add players to the sprite
			this.addChild(this.videoPlayer);
			this.addChild(this.audioPlayer);
			
			
			
			this.log("players created");
			
			// setup entry point for javascript calls
			ExternalInterface.addCallback("sendToFlash", fromJS);
		}
		
		private function objectLoaded(event:Event):void
		{
			
			this.log("initial stage width: " + stage.width + "height: " + stage.height);
			this.log("initial loaderInfo width: " + loaderInfo.width + "height: " + loaderInfo.height);
		}
		
		private function onLoading(event:PlayerEvent):void 
		{
			this.log("onLoading stage width: " + stage.width + "height: " + stage.height);
			this.log("onLoading: " + event.value);
			this.fireEvent("onLoading", event.value);
		}
		
		private function onStateChange(event:PlayerEvent):void 
		{
			this.log("onStateChange: " + event.value);
			this.fireEvent("onStateChange", event.value);
		}
		
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
		
		private function fromJS(action:String, value:String) : void
		{
			this.log("fromJS " + action);
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
				this.load(value,0);
				
			}
		}
		
		private function fireEvent(eventName:String, eventValue:int) : void  
		{  
			if(ExternalInterface.available)  
			{  
				ExternalInterface.call(eventName, eventValue);  
			}  
		}
		
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