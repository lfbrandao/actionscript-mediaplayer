package
{
	import flash.events.*;

	public class PlayerEvent extends Event
	{
		public static const ON_ERROR:String = "onError";
		public static const ON_LOADING:String = "onLoading";
		public static const ON_STATE_CHANGE:String = "onStateChange";
		
		public var value:int;
		
		public function PlayerEvent(type:String, value:int = 0, 
									bubbles:Boolean = false, 
									cancelable:Boolean = false 
									)
		{
			super(type, bubbles, cancelable);
			this.value = value;
		}
		
		public override function clone():Event
		{
			return new PlayerEvent(type, value, bubbles, cancelable);
		}
		
		public override function toString():String 
		{
			return formatToString("PlayerEvent", "type", "bubbles", "cancelable", "eventPhase", "value");
		}
	}
}