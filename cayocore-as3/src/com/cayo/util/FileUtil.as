/*************************************************************************
 * CAYO CONFIDENTIAL
 * Copyright 2011 Cayo Systems, Inc. All Rights Reserved.
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
	import flash.errors.EOFError;
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	
	public class FileUtil
	{
		private static const BUFFER_SIZE:int = 512;
		
		/**
		 * Writes zeros to the file, then deletes it.
		 */
		public static function eraseFile( f:File, logError:Function=null ) : Boolean 
		{
			if( f && f.nativePath && f.exists )
			{
				var ba:ByteArray = new ByteArray;
				for( var bdx:int=0; bdx<BUFFER_SIZE; ++bdx )
					ba.writeByte( 0 );
				var size:Number = f.size;
				var fs:FileStream = new FileStream;
				try {
					fs.open( f, FileMode.WRITE );
					for( var fdx:int=0; fdx<size; fdx += BUFFER_SIZE )
						fs.writeBytes( ba );
					var remainingBytes:int = size - fs.position;
					for( var odx:int=0; odx<remainingBytes; ++odx )
						fs.writeByte(0);
					fs.close();
				} catch(e:IOError) {
					if( logError != null ) 
						logError( "Erase IOError overwriting file '" + f.nativePath + "': " + e.message );
					return false;
				} catch(e:SecurityError) {
					if( logError != null ) 
						logError( "Erase SecurityError overwriting file '" + f.nativePath + "': " + e.message );
					return false;
				}
				try {
					f.deleteFile();
				} catch(e:Error) {
					if( logError != null ) 
						logError( "IOError while deleting srcFile '" + f.nativePath + "': " + e.message );
					return false;
				}
			}
			return true;
		}
		
		/**
		 * Wrapper around File.moveToAsync that generates callbacks rather then throws events.
		 */
		public static function moveToAsync( srcFile:File, destFile:File, onCompleteCallback:Function=null, onFailCallback:Function=null, log:Function=null ) : void
		{
			var f:File = srcFile.clone();
			try {
				f.addEventListener( Event.COMPLETE, onComplete );
				f.addEventListener( IOErrorEvent.IO_ERROR, onIOError );
				f.moveToAsync( destFile , true );
			} 
			catch( e:IOError ) 
			{
				if( log != null ) log( "IOError while copying srcFile '" + srcFile.nativePath + "' to '" + destFile.nativePath + "': " + e.message );
				if( onFailCallback != null )
					onFailCallback();
			}
			
			function onComplete( event:Event ) : void
			{
				if( onCompleteCallback != null )
					onCompleteCallback();
			}
			
			function onIOError( event:IOErrorEvent ) : void
			{
				if( log != null ) log( "IOError while copying srcFile '" + srcFile.nativePath + "' to '" + destFile.nativePath + "': " + event.toString() );
				
				if( onFailCallback != null )
					onFailCallback();
			}		
		}
		
		/**
		 * Moves a file by first copying it, then erasing and deleting the orignal.
		 * Note: This routine has fallen into disrepair. Please verify before using.
		 * 
		 * @param srcFile The File to be moved
		 * @param destFile The destination File
		 * @param onCompleteCallback Called when async process completes successfully. This callback takes no parameters.
		 * @param onFailCallback Called when async process fails. This callback takes no parameters.
		 * @param log Output a debug log message
		 */
		public static function moveAsync( srcFile:File, destFile:File, onCompleteCallback:Function=null, onFailCallback:Function=null, log:Function=null ) : void 
		{
			try {
				srcFile.addEventListener( Event.COMPLETE, onComplete );
				srcFile.addEventListener( IOErrorEvent.IO_ERROR, onIOError );
				srcFile.copyToAsync( destFile , true );
			} 
			catch( e:IOError ) 
			{
				if( log != null ) log( "IOError while copying srcFile '" + srcFile.nativePath + "' to '" + destFile.nativePath + "': " + e.message );
				if( onFailCallback != null )
					onFailCallback();
			}
			
			function onComplete( event:Event ) : void
			{
				if( !destFile.exists )
				{
					if( log != null ) 
						log( "SrcFile copy failed. DestFile does not exist: '" + destFile.nativePath + "'" );
					if( onFailCallback != null )
						onFailCallback();
				}
				else
				{
					eraseFile( srcFile, log );
					
					if( onCompleteCallback != null )
						onCompleteCallback();
				}
			}
			
			function onIOError( event:IOErrorEvent ) : void
			{
				if( log != null ) log( "IOError while copying srcFile '" + srcFile.nativePath + "' to '" + destFile.nativePath + "': " + event.toString() );
				
				// Is this really safe if we are deleting the src upon failure?
				eraseFile( srcFile, log );
				
				if( onFailCallback != null )
					onFailCallback();
			}		
		}
		
		/**
		 * Check the bytes of the file to see if it is a PDF.
		 * Will return false if there is an error opening the PDF file.
		 * @param f The file to test
		 * @param log A callback function to log error messages.
		 * @return Returns true if the file could be opened and looks to be a PDF file, false if the 
		 * file does not look like a PDF file or if the file could not be opened.
		 */
		public static function isPdf( f:File, log:Function=null ) : Boolean
		{
			var result:Boolean = false;
			if( f && f.nativePath && f.exists )
			{
				try {
					var fs:FileStream = new FileStream;
					fs.open( f, FileMode.READ );
					var ba:ByteArray = new ByteArray;
					fs.readBytes( ba, 0, 4 );
//					if( log != null ) log( "First 4 bytes of file: " + ba.toString() );		// Get rid of this after things work
					if( ba.toString().toUpperCase() == '%PDF' )
						result = true;
				} catch( e0:IOError ) {
					if( log != null ) log( "FileStream IOError error " + e0.message );
					result = false;
				} catch( e1:SecurityError ) {
					if( log != null ) log( "FileStream Security error " + e1.message );
					result = false;
				} catch( e2:EOFError ) {
					if( log != null ) log( "FileStream EOFError error " + e2.message );
					result = false;
				}
			}
			return result;
		}
		
	}
}