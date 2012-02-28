Lightweight Flash object with a Javascript API. Used to play audio and video files on Firefox at Zeega (http://www.zeega.org) and Sensate (http://sensatejournal.com/).

Features
--------

- video formats supported: mp4, m4v
- audio formats supported: mp3
- start and end time are configurable

Known issues
------------

- seeking on MP4 files is dependent on the number of key frames included in the file

Components
------------

- MediaPlayer 
	- Extends Sprite
	- Main class. Instantiates and controls both the video and the audio players. Exposes an API in Javascript.

- VideoPlayer extends Sprite, implements IPlayer
	- Extends Sprite, Implements IPlayer
	- Video player. 

- AudioPlayer extends Sprite, implements IPlayer
	- MP3 player. 

Events codes
------------

- onLoading
	- 1 : Player Loaded
	- 2 : Metadata Loaded
	- 3 : Video (Audio) CanPlay (at cue-in)
	
- onStateChange
	- 1 : Play begun
	- 2 : Paused
	- 3 : Stopped
	- 5 : on Time Change (every 500ms)
	- 4 : Video ended
	
- onError
	- 1 : Failed To Load Resource (user aborted, network interrupted, decoding error)
	- 2 : File Type Not Supported

Subscribing / unsubscribing to events from Javascript
-----------------------------------------------------

- Subscribe: flashobject.addEventListener(event_name, subscriber_method_name);
- Unsubscribe: flashobject.removeListener(event_name, subscriber_method_name);)

- onLoading
	- Subscriber method signature: function subscriber_method_name(eventid, eventvalue)
- onStateChange
- onError	
	- Subscriber method signature: function subscriber_method_name(eventid)
	
Methods
-------

- load(params) - params: url + "," + start_time + "," + end_time  
- play()
- stop()
- pause()
- pause(float)

- getVolume()
- getCurrentTime()
- getStartTime()
- getEndTime()

Example
-------
- The player can be tested using the file `bin-debug/test.html`. Usage: `fill the url field -> press load -> press play`.
