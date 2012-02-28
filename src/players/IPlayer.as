package players
{
	/**
	 * Contract for media players
	 * 
	 */
	public interface IPlayer
	{
		// load video
		function load(url:String, startAt:Number = 0.00, stopAt:Number = -1.00):void;
		
		// playback control
		function play():void;
		function pause():void;
		function stop():void;
		function seek(seekTo:Number):void;
		
		// events
		function onError(eventId:int):void;
		function onStateChange(eventId:int, eventValue:Number = 0):void;
		function onLoading(eventId:int):void;
		
		function getCurrentTime():Number;
		function getStartTime():Number;
		function getEndTime():Number;
		
		function getStatus():String;
	}
}