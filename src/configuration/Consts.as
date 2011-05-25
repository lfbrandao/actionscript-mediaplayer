package configuration
{
	public final class Consts
	{
		public static const MP3_FILE_EXTENSIONS:Array = new Array("mp3");
		
		public static const STATUS_READY_TO_PLAY:String = "readyToPlay";
		public static const STATUS_PAUSED:String = "paused";
		public static const STATUS_STOPPED:String = "stopped";
		public static const STATUS_LOADING:String = "loading";
		public static const STATUS_SEEKING:String = "seeking";
		public static const STATUS_PLAYING:String = "playing";
		
		// event id
		public static const ON_LOADING_PLAYER_LOADED:int = 1;
		public static const ON_LOADING_METADATA_LOADED:int = 2;
		public static const ON_LOADING_MEDIA_LOADED:int = 3;
		
		public static const ON_STATE_CHANGE_PLAYING:int = 1;
		public static const ON_STATE_CHANGE_PAUSED:int = 2;
		public static const ON_STATE_CHANGE_STOPPED:int = 3;
		public static const ON_STATE_CHANGE_ENDED:int = 4;
		public static const ON_STATE_CHANGE_TIME:int = 5;
		
		public static const ON_ERROR_FAILED_TO_LOAD:int = 1;
		public static const ON_ERROR_FILE_NOT_SUPPORTED:int = 2;
		public static const ON_ERROR_NO_FILE_LOADED:int = 3;
		
		// event type
		public static const ON_LOADING:String = "onLoading";
		public static const ON_STATE_CHANGE:String = "onStateChange";
		public static const ON_ERROR:String = "onError";
	}
}