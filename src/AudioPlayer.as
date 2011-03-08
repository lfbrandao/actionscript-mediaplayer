package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.net.URLRequest;
	import flash.net.URLStream;
	import flash.utils.ByteArray;
	
	public class AudioPlayer extends Sprite
	{
		private var audioFile:Sound;
		private var soundChannel:SoundChannel; 
		private var urlStream:URLStream;
		
		public var bArr:ByteArray;
		
		public function AudioPlayer()
		{
			audioFile = new Sound();
		}
		
		public function load(url:String)
		{
			var urlReq:URLRequest = new URLRequest(url);
			this.audioFile.load(urlReq);
			soundChannel = audioFile.play();
		}
		
		private function loaded(event:Event):void {
			soundChannel = audioFile.play();
		}
		
		private function sampleDataHandler(event:SampleDataEvent):void {
			event.data.writeBytes(bArr, 0, 40960);
		}
	}
}