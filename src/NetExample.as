package {
	import flash.display.Sprite;
	import flash.display.MovieClip;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.events.Event;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.text.TextField;
	import flash.net.navigateToURL;
	import flash.net.URLRequest;
	
	public class NetExample extends MovieClip
	{
		
		private var videoURL:String="http://www.mediacollege.com/video-gallery/testclips/20051210-w50s.flv";
		private var connection:NetConnection;
		private static var stream:NetStream;
		private var timer:Timer=new Timer(1); //Set a timer for 1 ms.
		private static var vidInfoObj:Object = new Object();
		
		public function NetExample() {
			connection = new NetConnection();
			connection.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			connection.connect(null);
			timer.addEventListener(TimerEvent.TIMER, onTimer);
		}
		
		private function netStatusHandler(event:NetStatusEvent):void {
			switch (event.info.code) {
				case "NetConnection.Connect.Success" :
					connectStream();
					break;
				case "NetStream.Play.StreamNotFound" :
					trace("Stream not found: " + videoURL);
					break;
			}
		}
		
		private function securityErrorHandler(event:SecurityErrorEvent):void {
			trace("securityErrorHandler: " + event);
		}
		
		private function connectStream():void {
			timer.start();
			stream=new NetStream(connection);
			stream.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			stream.client = new CustomClient();
			
			var video:Video = new Video();
			video.attachNetStream(stream);
			stream.play(videoURL);
			
			addChild(video);
		}
		
		private function onTimer(evt:TimerEvent):void {
			//Check to see if the video is completely buffered! if yes, remove the timer. If no, show progress!
			if (Math.ceil((stream.bufferLength / stream.bufferTime) * 100) < 100)
			{
				trace("Buffer Len : " + stream.bufferLength + " Buff Time : " + stream.bufferTime + "\n" + "Percent Loaded : " + Math.ceil((stream.bufferLength / stream.bufferTime) * 100) + "%");
			}
			else
			{
				timer.stop();
				timer.removeEventListener(TimerEvent.TIMER, onTimer);
			}
			
		}
		
		public static function setVideoParams(info:Object):void {
			vidInfoObj=info;
			stream.bufferTime=vidInfoObj.duration;
		}
		
	}
}

class CustomClient {
	public function onMetaData(info:Object):void {
		//NetConnectionExample.setVideoParams(info);
		trace("metadata: duration=" + info.duration + " width=" + info.width + " height=" + info.height + " framerate=" + info.framerate);
	}
	public function onCuePoint(info:Object):void {
		trace("cuepoint: time=" + info.time + " name=" + info.name + " type=" + info.type);
	}
}

