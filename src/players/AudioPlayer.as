package players
{
	import configuration.Consts;
	
	import events.PlayerEvent;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.net.URLRequest;
	
	public class AudioPlayer extends Sprite implements IPlayer
	{
		private var audioFile:Sound;
		private var soundChannel:SoundChannel; 
		private var status:String = "";
		private static const ON_LOADING_MEDIA_LOADED:int = 3;
		private var startTime:Number = 0.00;
		private var playingAt:Number = 0.00;
		
		public function AudioPlayer()
		{
			audioFile = new Sound();
			audioFile.addEventListener(Event.COMPLETE, onComplete);
		}
		
		private function onComplete(event:Event):void 
		{
			this.onLoading(Consts.ON_LOADING_MEDIA_LOADED);
		}
		
		public function load(url:String, startAt:Number = 0.00, stopAt:Number = -1.00):void
		{
			this.startTime = startAt;
			this.audioFile.load(new URLRequest(url));
		}
		
		public function play():void
		{
			if(this.playingAt > this.startTime)
			{
				soundChannel = this.audioFile.play(playingAt);
			}
			else
			{
				soundChannel = this.audioFile.play(startTime);
			}
			this.onStateChange(Consts.ON_STATE_CHANGE_PLAYING);
		}
		
		public function pause():void
		{
			this.playingAt = soundChannel.position;
			this.soundChannel.stop();
			this.onStateChange(Consts.ON_STATE_CHANGE_PAUSED);
		}
		
		public function stop():void
		{
			this.playingAt = 0.00;
			soundChannel.stop();
			this.onStateChange(Consts.ON_STATE_CHANGE_STOPPED);
		}
		
		
		public function getCurrentTime():Number
		{
			return (this.soundChannel.position / 10);
		}
		
		public function getStartTime():Number
		{
			return (this.startTime / 10);
		}
		
		public function getEndTime():Number
		{
			return (this.audioFile.length / 10);
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
		
	}
}