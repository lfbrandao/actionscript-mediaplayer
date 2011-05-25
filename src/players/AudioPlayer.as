package players
{
	import configuration.Consts;
	
	import events.PlayerEvent;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.net.URLRequest;
	
	/**
	 * Audio player. Uses the ActionScript' SoundChannel and the Sound objects
	 * for the audio playback and streaming.
	 * 
	 * @see http://livedocs.adobe.com/flash/9.0/ActionScriptLangRefV3/flash/media/SoundChannel.html
	 * @see http://livedocs.adobe.com/flash/9.0/ActionScriptLangRefV3/flash/media/Sound.html
	 */
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
		
		/**
		 * Dispatched when an audio file is completely loaded.
		 * 
		 * @param event Event details
		 */
		private function onComplete(event:Event):void 
		{
			this.onLoading(Consts.ON_LOADING_MEDIA_LOADED);
		}
		
		/**
		 * Loads a video file.
		 *
		 * @param url File url
		 * @param startAt Start playing the audio at this time (in seconds). Optional parameter with 0 (beginning of file) as default value.
		 * @param stopAt Stop playing the audio after this time (in seconds). Optional parameter with -1 (end of file) as default value. 
		 *
		 */
		public function load(url:String, startAt:Number = 0.00, stopAt:Number = -1.00):void
		{
			this.startTime = startAt * 1000;
			this.audioFile = new Sound();
			this.audioFile.addEventListener(Event.COMPLETE, onComplete);
			this.audioFile.load(new URLRequest(url));
		}
		
		/**
		 * Plays an audio file. If there is no audio file loaded the error event is triggered.
		 */
		public function play():void
		{
			if(this.status != Consts.STATUS_PLAYING)
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
				this.status = Consts.STATUS_PLAYING;
			}
		}
		
		/**
		 * Pauses the video playback.
		 */
		public function pause():void
		{
			this.playingAt = soundChannel.position;
			this.soundChannel.stop();
			this.onStateChange(Consts.ON_STATE_CHANGE_PAUSED);
			this.status = Consts.STATUS_PAUSED;
		}
		
		/**
		 * Stops the audio playback. Subsequent calls to 'play' will play the audio from the beginning.
		 */
		public function stop():void
		{
			this.playingAt = 0.00;
			soundChannel.stop();
			this.onStateChange(Consts.ON_STATE_CHANGE_STOPPED);
			this.status = Consts.STATUS_STOPPED;
		}
		
		/**
		 * Returns the current playback time.
		 */
		public function getCurrentTime():Number
		{
			// http://kb2.adobe.com/cps/155/tn_15542.html
			try
			{
				return int(Math.round(this.soundChannel.position / 10)) / 100;
			}
			catch(Exception)
			{
				return 0;
			}
			return 0;
		}
		
		/**
		 * Returns the configured audio start time.
		 */
		public function getStartTime():Number
		{
			return (this.startTime / 10);
		}
		
		/**
		 * Returns the configured audio end time.
		 */
		public function getEndTime():Number
		{
			return int(Math.round(this.audioFile.length / 10)) / 100;
		}
		
		/**
		 * Returns the player status.
		 */
		public function getStatus():String
		{
			return this.status;
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
			//this.log("OnStateChange " + eventValue);
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
	}
}