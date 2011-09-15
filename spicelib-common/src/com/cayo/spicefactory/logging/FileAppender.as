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

package com.cayo.spicefactory.logging
{
	import com.cayo.util.DateUtil2;
	
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.getTimer;
	
	import org.spicefactory.lib.flash.logging.FlashLogger;
	import org.spicefactory.lib.flash.logging.LogEvent;
	import org.spicefactory.lib.flash.logging.LogLevel;
	import org.spicefactory.lib.flash.logging.impl.AbstractAppender;
	
	public class FileAppender extends AbstractAppender
	{
		private var _file:File;
		private var _needsLineFeed:Boolean;
		
		public var useShortNames:Boolean = true;
		public var includeTime:Boolean = true;
		
		public function FileAppender()
		{
			super();
			var dateStr:String = DateUtil2.toFileDTF(new Date(),true);
			_file = getLogFolder();
			_file = _file.resolvePath( "canmore_" + dateStr + "_log.txt" );
		}
		
		/**
		 * @private
		 */
		protected override function handleLogEvent (event:org.spicefactory.lib.flash.logging.LogEvent) : void 
		{
			if (isBelowThreshold(event.level)) return;
			var loggerName:String = FlashLogger(event.target).name;
			var logMessage:String;
			if ((event.level.toValue() <= LogLevel.INFO.toValue())) 
			{
				var levelString:String = (event.level == LogLevel.DEBUG) ? "DEBUG: " : "INFO:  ";
				loggerName = loggerName.replace("::", ".");
				if (useShortNames) 
				{
					var index:int = loggerName.lastIndexOf(".");
					if (index != -1) loggerName = loggerName.substring(index + 1);
				} 
				
				logMessage = includeTime ? ("[" + DateUtil2.formatMilliseconds( getTimer() ) + "] ") : "";
				logMessage += levelString + loggerName + " - " + event.message;
				_needsLineFeed = true;
			} 
			else 
			{
				var lf:String = (_needsLineFeed) ? "\n" : "";
				logMessage = lf + "  *** " + event.level + " *** " + loggerName + " ***\n" 
					+ event.message + "\n";
				_needsLineFeed = false;
			}
			
			write(logMessage);
		}	
		
		private function write(msg:String):void
		{		
			var fs:FileStream = new FileStream();
			fs.open( _file, FileMode.APPEND);
			fs.writeUTFBytes(msg + File.lineEnding);
			fs.close();
		}	
		
		public static function getLogFolder() : File
		{
			return File.desktopDirectory;
		}
		
	}
}