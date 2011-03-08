package
{
	import flash.display.Sprite;
	import flash.external.ExternalInterface;
	
	public class MediaPlayer extends Sprite
	{
		private var videoPlayer:VideoPlayer;
		private var audioPlayer:AudioPlayer;
		
		public function MediaPlayer()
		{
			// create and configure the video player
			this.videoPlayer = new VideoPlayer();
			this.videoPlayer.addEventListener(PlayerEvent.ON_LOADING, onLoading);
			this.videoPlayer.addEventListener(PlayerEvent.ON_STATE_CHANGE, onStateChange);
			
			// create and configure the audio player
			this.audioPlayer = new AudioPlayer();
			
			// add players to the sprite
			this.addChild(this.videoPlayer);
			this.addChild(this.audioPlayer);
			
			this.log("players created");
			
			// setup entry point for javascript calls
			ExternalInterface.addCallback("sendToFlash", fromJS);
		}
		
		private function onLoading(event:PlayerEvent):void 
		{
			this.log("onLoading: " + event.value);
			this.fireEvent("onLoading", event.value);
		}
		
		private function onStateChange(event:PlayerEvent):void 
		{
			this.log("onStateChange: " + event.value);
			this.fireEvent("onStateChange", event.value);
		}
		
		
		private function fromJS(action:String, value:String) : void
		{
			this.log("fromJS " + action);
			if(action == "play")
			{
				this.videoPlayer.play();
			}
			else if(action == "stop")
			{
				this.videoPlayer.stop();
			}
			else if(action == "pause")
			{
				this.videoPlayer.pause();
			}
			else if(action == "load")
			{
				this.audioPlayer.load(value);
				// this.videoPlayer.load(value);
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