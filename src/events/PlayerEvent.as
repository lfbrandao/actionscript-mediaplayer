package events
{
	import flash.events.*;

	public class PlayerEvent extends Event
	{
		public static const ON_ERROR:String = "onError";
		public static const ON_LOADING:String = "onLoading";
		public static const ON_STATE_CHANGE:String = "onStateChange";
		public static const ON_PLAYER_LOADED:String = "onPlayerLoaded";
		
		public var eventId:int;
		public var eventValue:Number;
		
		public function PlayerEvent(type:String, id:int = 0, value:Number = 0.00,
									bubbles:Boolean = false, 
									cancelable:Boolean = false 
									)
		{
			super(type, bubbles, cancelable);
			this.eventId = id;
			this.eventValue = value;
		}
		
		public override function clone():Event
		{
			return new PlayerEvent(type, eventId, eventValue, bubbles, cancelable);
		}
		
		public override function toString():String 
		{
			return formatToString("PlayerEvent", "type", "id", "value", "bubbles", "cancelable", "eventPhase");
		}
	}
}