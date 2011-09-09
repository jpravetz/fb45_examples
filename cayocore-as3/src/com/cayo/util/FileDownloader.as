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
	 * Dispatched the download is complete and the file has been written, but 
	 * not when the file has been closed. Watch the close event instead.
	 * 
	 * @eventType flash.events.Event.COMPLETE
	 */
	[Event(name="complete", type="flash.events.Event")]
	
	/**
	 * Dispatched the download is complete and the file has been written and closed.
	 * This is the event to watch for to know when we can grap the resultant file.
	 * 
	 * @eventType flash.events.Event.CLOSE
	 */
	[Event(name="close", type="flash.events.Event")]
	
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
	 * 
	 * TODO: Rename this file to FileDownloader and get rid of old FileDownloader, as this version is better
	 */
	public class FileDownloader extends EventDispatcher
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
		public function FileDownloader( remotePath:String = "" , localFile:File = null ) 
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
					
					_urlStream.addEventListener( ProgressEvent.PROGRESS, streamProgressHandler );
					_urlStream.addEventListener( Event.COMPLETE, streamCompleteHandler );
					_urlStream.addEventListener( IOErrorEvent.IO_ERROR, streamIOErrorHandler );
					_urlStream.addEventListener( SecurityErrorEvent.SECURITY_ERROR, streamSecurityErrorHandler );
					
					_fileStream.addEventListener(IOErrorEvent.IO_ERROR, fileIOErrorHandler );
					_fileStream.addEventListener( Event.CLOSE, fileCloseHandler );
					_fileStream.openAsync( localFile, FileMode.WRITE );
					
					_urlStream.load( requester );
					
				} 
				catch( e:Error ) 
				{
					stop();
					var event:ErrorEvent = new ErrorEvent( ErrorEvent.ERROR );
					event.text = e.message;
					dispatchEvent( event );
				}
				catch( ioError:IOError ) 
				{
					stop();
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
		 * Stop the download. Caller will still need to wait for CLOSE event for FileStream to be signaled as closed.
		 */
		public function stop():void 
		{
			closeUrlStream();
			if( _fileStream )
				_fileStream.close();		// Will result in dispatch of Event.CLOSE		
		}
		
		/**
		 * Cleanup this object. Cleanup is async pending a FileSystem close event.
		 */
		public function cleanupAsync() : void
		{
			stop();
		}
		
		private function closeUrlStream() : void
		{
			if( _urlStream != null )
			{
				_urlStream.close();
				_urlStream.removeEventListener( ProgressEvent.PROGRESS, streamProgressHandler );
				_urlStream.removeEventListener( Event.COMPLETE, streamCompleteHandler );
				_urlStream.removeEventListener( IOErrorEvent.IO_ERROR, streamIOErrorHandler );
				_urlStream.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, streamSecurityErrorHandler );
				_urlStream = null;
			}
		}
		
		private function stopTimer() : void 
		{
			if( _timer )
			{
				_timer.stop();
				_timer.removeEventListener( TimerEvent.TIMER_COMPLETE, timeoutHandler );
				_timer = null;
			}
		}
		
		private function streamIOErrorHandler( evt:IOErrorEvent ) : void
		{
			stop();
			var event:ErrorEvent = new ErrorEvent( ErrorEvent.ERROR );
			event.text = evt.text;
			dispatchEvent( event );
		}
		
		private function streamSecurityErrorHandler( evt:SecurityErrorEvent ) : void
		{
			stop();
			var event:ErrorEvent = new ErrorEvent( ErrorEvent.ERROR );
			event.text = evt.text;
			dispatchEvent( event );
		}
		
		private function streamCompleteHandler( event:Event ):void 
		{
			var bytes:ByteArray = new ByteArray();
			_urlStream.readBytes( bytes, 0, _urlStream.bytesAvailable );
			_fileStream.writeBytes( bytes, 0, bytes.length );
			_fileStream.close();
			
			stop();
			
			// We dispatch this, but the file is not available until the CLOSE event is dispatched
			dispatchEvent( new Event(Event.COMPLETE) );
		}
		
		private function streamProgressHandler( event:ProgressEvent ):void 
		{
			if( _urlStream.bytesAvailable > 50 * 1024 )
			{
				var bytes:ByteArray = new ByteArray();
				_urlStream.readBytes( bytes, 0, _urlStream.bytesAvailable );
				_fileStream.writeBytes( bytes, 0, bytes.length );
			}
			
			// Dispatch for progress bars, etc.
			dispatchEvent( event );
		}
		
		private function fileCloseHandler( evt:Event ) : void 
		{
			stopTimer();
			if( _fileStream )
			{
				_fileStream.removeEventListener(IOErrorEvent.IO_ERROR, fileIOErrorHandler );
				_fileStream.removeEventListener( Event.CLOSE, fileCloseHandler );
				_fileStream = null;
			}
			dispatchEvent( new Event( Event.CLOSE ) );
		}
		
		private function fileIOErrorHandler( evt:IOErrorEvent ) : void 
		{
			stop();
			var event:ErrorEvent = new ErrorEvent( ErrorEvent.ERROR );
			event.text = evt.text;
			dispatchEvent( event );
		}
		
		private function timeoutHandler( event:TimerEvent ):void 
		{
			stopTimer();
			stop();
			dispatchEvent( event );
		}
		
		
	}
}
