/*************************************************************************
 * CAYO CONFIDENTIAL
 * Copyright 2010-2011 Cayo Systems, Inc. All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains the property
 * of Cayo Systems, Inc. and its suppliers, if any.  The intellectual
 * and technical concepts contained herein are proprietary to 
 * Cayo Systems, Inc. and its suppliers and may be covered by U.S. and
 * Foreign Patents, patents in process, and are protected by trade secret
 * or copyright law. Dissemination of this information or reproduction of
 * this material is strictly forbidden unless prior written permission
 * is obtained from Cayo Systems, Inc..
 **************************************************************************/

package com.cayo.util
{
	import flash.errors.IOError;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.OutputProgressEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLRequest;
	import flash.net.URLStream;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	/**
	 * Dispatched when there is download progress to report.
	 * 
	 * @eventType flash.events.ProgressEvent.PROGRESS
	 */
	[Event(name="progress", type="flash.events.ProgressEvent")]
	
	/**
	 * Dispatched the download is complete and the file has been written.
	 * 
	 * @eventType flash.events.Event.COMPLETE
	 */
	[Event(name="complete", type="flash.events.Event")]
	
	/**
	 * Dispatched if the download times out.
	 * 
	 * @eventType flash.events.TimerEvent.TIMER_COMPLETE
	 */
	[Event(name="timerComplete", type="flash.events.TimerEvent")]
	
	/**
	 * Dispatched if an exception is caught, setting the text property to the message
	 * of the error.
	 * 
	 * @eventType flash.events.ErrorEvent.ERROR
	 */
	[Event(name="error", type="flash.events.ErrorEvent")]
	
	
	
	/**
	 * Class to download files from the internet.
	 */
	public class OldFileDownloader extends EventDispatcher
	{
		
		// Function called every time data arrives
		//              called with an argument of how much has been downloaded
		public var remotePath:String = "";
		public var localFile:File = null;
		/**
		 * Timeout (ms). Set to 0 for no timeout.
		 */
		public var timeout:int = 30 * 1000;
		
		private var _urlStream:URLStream;
		private var _fileStream:FileStream;
		private var _timer:Timer;
		private var _downloadComplete:Boolean = false;
		private var _currentPosition:uint = 0;
		
		/**
		 * Initialize the downloader.
		 * @param remotePath The URL of the file to download
		 * @param localFile Where to store the file
		 */
		public function OldFileDownloader( remotePath:String = "" , localFile:File = null ) 
		{
			this.remotePath = remotePath;
			this.localFile = localFile;
		}
		
		/**
		 * Download the file.
		 */
		public function load() :void 
		{
			if( !_urlStream || !_urlStream.connected ) 
			{
				try 
				{
					_urlStream = new URLStream();
					_fileStream = new FileStream();
					
					var requester:URLRequest = new URLRequest( remotePath );
					_currentPosition = 0;
					_downloadComplete = false;
					
					// Function to call oncomplete, once the download finishes and
					//      all data has been written to disc                               
					_fileStream.addEventListener( OutputProgressEvent.OUTPUT_PROGRESS, fileProgressHandler );
					_fileStream.openAsync( localFile, FileMode.WRITE );
					_urlStream.addEventListener( ProgressEvent.PROGRESS, streamProgressHandler );
					_urlStream.addEventListener( Event.COMPLETE, streamCompleteHandler );
					_urlStream.addEventListener( IOErrorEvent.IO_ERROR, onIOError );
					_urlStream.addEventListener( SecurityErrorEvent.SECURITY_ERROR, onSecurityError );
					_urlStream.load( requester );
					
				} 
				catch( e:Error ) 
				{
					destroyStreams();
					var event:ErrorEvent = new ErrorEvent( ErrorEvent.ERROR );
					event.text = e.message;
					dispatchEvent( event );
				}
				catch( ioError:IOError ) 
				{
					destroyStreams();
					var event2:ErrorEvent = new ErrorEvent( ErrorEvent.ERROR );
					event2.text = ioError.message;
					dispatchEvent( event2 );
				}
				
				if( timeout > 0 ) 
				{
					_timer = new Timer( timeout, 1 );
					_timer.addEventListener(TimerEvent.TIMER_COMPLETE,timeoutHandler, false, 0, true);
					_timer.start();
				}
				
			} else {
				// Do something unspeakable
			}
		}
		
		/**
		 * Stop the download.
		 */
		public function stop():void 
		{
			if( _timer )
			{
				_timer.stop();
				_timer.removeEventListener( TimerEvent.TIMER_COMPLETE, timeoutHandler );
				_timer = null;
			}
			destroyStreams();
		}
		
		public function cleanup() : void
		{
			stop();
		}
		
		private function destroyStreams() : void
		{
			closeUrlStream();
			closeFileStream();
		}
		
		private function closeUrlStream() : void
		{
			if( _urlStream != null )
			{
				_urlStream.close();
				_urlStream.removeEventListener( ProgressEvent.PROGRESS, streamProgressHandler );
				_urlStream.removeEventListener( Event.COMPLETE, streamCompleteHandler );
				_urlStream.removeEventListener( IOErrorEvent.IO_ERROR, onIOError );
				_urlStream.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, onSecurityError );
				_urlStream = null;
			}
		}
		
		private function closeFileStream() : void
		{
			if( _fileStream != null )
			{
				_fileStream.close();
				_fileStream.removeEventListener( OutputProgressEvent.OUTPUT_PROGRESS, fileProgressHandler );
				_fileStream = null;
			}
		}
		
		private function onIOError( evt:IOErrorEvent ) : void
		{
			destroyStreams();
			var event:ErrorEvent = new ErrorEvent( ErrorEvent.ERROR );
			event.text = evt.text;
			dispatchEvent( event );
		}
		
		private function onSecurityError( evt:SecurityErrorEvent ) : void
		{
			destroyStreams();
			var event:ErrorEvent = new ErrorEvent( ErrorEvent.ERROR );
			event.text = evt.text;
			dispatchEvent( event );
		}
		
		private function streamCompleteHandler( event:Event ):void 
		{
			_downloadComplete = true;
			if( _timer )
				_timer.stop();
		}
		
		private function streamProgressHandler( event:ProgressEvent ):void 
		{
			var bytes:ByteArray = new ByteArray();
			var thisStart:uint = _currentPosition;
			_currentPosition += _urlStream.bytesAvailable;
			// ^^  Makes sure that asyncronicity does not break anything
			
			_urlStream.readBytes( bytes, thisStart );
			_fileStream.writeBytes( bytes, thisStart );
			
			dispatchEvent( event );
		}
		
		private function fileProgressHandler( event:OutputProgressEvent ):void 
		{
			if( event.bytesPending == 0 && _downloadComplete )
			{
				stop();
				dispatchEvent( new Event(Event.COMPLETE) );
			}
		}
		
		private function timeoutHandler( event:TimerEvent ):void 
		{
			stop();
			dispatchEvent( event );
		}
		

	}
}
