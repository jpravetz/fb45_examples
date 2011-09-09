/*************************************************************************
 * CAYO CONFIDENTIAL
 * Copyright 2009 Cayo Systems, Inc. All Rights Reserved.
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
	import com.cayo.util.AppVariables;
	import com.cayo.util.DateUtil2;
	
	import flash.filesystem.File;
	
	import org.spicefactory.lib.flash.logging.FlashLogFactory;
	import org.spicefactory.lib.flash.logging.LogLevel;
	import org.spicefactory.lib.flash.logging.impl.DefaultLogFactory;
	import org.spicefactory.lib.flash.logging.impl.TraceAppender;
	import org.spicefactory.lib.logging.LogContext;
	
	public class Logging
	{
		public static const NONE:String = 'none';
		public static const TRACE:String = 'trace';
		public static const FILE:String = 'file';
		public static const SOS:String = 'sos';
		
		public function Logging()
		{
		}
		
		private static var _factory:FlashLogFactory;
		
		private static var _bTrace:Boolean;
		private static var _bFile:Boolean;
		private static var _bSOS:Boolean;
		
		/**
		 * Initialize logging for the application. 
		 * This needs to be done before everything else, else log messages won't be recorded.
		 * Classes that wish to log messages should call:
		 *	private static const log:Logger = LogContext.getLogger(MyClass);
		 *	log.info("Number {0}, {1}", 1, 2 );
		 * Every call to this method will append a logger of the specified <code>type</code>,
		 * without regard to the loggers of other type that are already present. You can thus add a logger
		 * for each type and end up with three separate loggers outputting at once.
		 * NOTE: I'd like to move this to the Context file, but do not know the syntax to do so.
		 * @param bSpiceOn If true then will allow all spicefactory log messages through, else will filter some.
		 */
		
		public static function addLogAppender( type:String=TRACE, bSpiceOn:Boolean=false ) : void
		{
			trace( 'Logger begin initialization' );
			if( type == NONE )
				return ;
			
			if( _factory == null )
			{
				_factory = new DefaultLogFactory();
				// factory.setRootLogLevel( LogLevel.WARN );
				// This suppresses log messages for these packages
				if( bSpiceOn )
				{
					_factory.addLogLevel( "org.spicefactory.lib.reflect.cache", LogLevel.WARN );
					_factory.addLogLevel( "org.spicefactory.parsley.core.view.impl", LogLevel.WARN );
				}
				LogContext.factory = _factory;
			}
			
			if( type == SOS && !_bSOS ) 
			{
				var appender:SOS3Appender = new SOS3Appender();
				appender.setInitCallback( onSOSResult, onSOSFault );
				appender.init();
				
				function onSOSResult() : void
				{
					// appender.useShortNames = true;
					_factory.addAppender( appender );
					_bSOS = true;
					complete( type );
				}
				
				function onSOSFault() : void
				{
					_factory.addAppender( new TraceAppender );
					_bTrace = true;
					complete( TRACE );
				}
			} 
			else if( type == TRACE && !_bTrace )
			{
				_factory.addAppender( new TraceAppender );
				_bTrace = true;
				complete( TRACE );
			}
			else if( type == FILE && !_bFile )
			{
				_factory.addAppender( new FileAppender );
				_bFile = true;
				complete( type );
			}
			
			function complete(opt:String) : void
			{
				LogContext.getLogger(Logging).info( 'Add Log Appender of type {0}; {1}', opt, DateUtil2.formatDT( new Date, true, true, true ) );
				LogContext.getLogger(Logging).info( getAppString() );
			}
		}
		
		/*
		private static function initFileOrTrace( option:String ) : void
		{
		var logTarget:LineFormattedTarget;
		
		if( option == FILE ) 
		{
		var dateStr:String = DateUtil2.toFileDTF(new Date(),true);
		var file:File = getLogFolder();
		file = file.resolvePath( "canmore_" + dateStr + "_log.txt" );
		logTarget = new FileTarget(file);
		}
		else if( option == TRACE )
		{
		logTarget = new TraceTarget();
		} 
		
		// logTarget.filters = [ "com.adobe.cairngorm.persistence.*", "org.spicefactory.*" ];
		
		logTarget.level = LogEventLevel.ALL;
		
		// logTarget.includeDate = true;
		logTarget.includeTime = true;
		logTarget.includeCategory = true;
		logTarget.includeLevel = true;
		
		Log.addTarget( logTarget );
		}
		*/
		
		public static function getLogFolder() : File
		{
			return File.desktopDirectory;
		}
		
		
		//		public static function logApplicationInformation():void {
		//			
		//			var log:Logger = LogContext.getLogger(Logging);
		//			log.info("AppID = " + NativeApplication.nativeApplication.applicationID);			
		//			log.info("AppVersion = " + appXml.ns::version[0];;			
		//			log.info("runtimeVersion = " + NativeApplication.nativeApplication.runtimeVersion);			
		//			log.info("runtimePatchLevel = " + NativeApplication.nativeApplication.runtimePatchLevel);			
		//		}
		private static function getAppString() : String
		{
			var appVars:AppVariables = new AppVariables;
			return appVars.toAppString();
		}
		
	}
}