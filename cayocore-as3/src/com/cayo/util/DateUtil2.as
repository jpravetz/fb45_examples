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

package com.cayo.util
{
	
	public class DateUtil2
	{
		
		public function DateUtil2()
		{
			super();
		}												  
		
		/**
		 * Returns a date string formatted according to W3CDTF (YYYY-MM-DDTHH:MM:SS.sss-08:00).
		 * Also referred to as xmlschema.
		 *
		 * @param d
		 * @param includeMilliseconds Determines whether to include the milliseconds value (if any) in the formatted string.
		 * @param format If 0 then output is in form . Otherwise YYYYMMDD_HHMMSS.sss
		 *
		 * @returns
		 *
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 9.0
		 * @tiptext
		 *
		 * @see http://www.w3.org/TR/NOTE-datetime
		 */		     
		public static function toW3CDTF(d:Date,includeMilliseconds:Boolean=false,local:Boolean=false):String
		{
			return formatDT( d, true, includeMilliseconds, local, 0 );
		}
		
		public static function toFileDTF( d:Date, includeTime:Boolean=false, includeMilliseconds:Boolean=false, local:Boolean=true ) : String
		{
			return formatDT( d, includeTime, includeMilliseconds, local, 1 );
		}
		
		
		public static function formatDT(d:Date,includeTime:Boolean,includeMilliseconds:Boolean=false,local:Boolean=false,format:int=0):String
		{
			if( d == null )
				return null;
			var date:Number = local ? d.getDate() : d.getUTCDate();
			var month:Number = local ? d.getMonth() : d.getUTCMonth();
			var hours:Number = local ? d.getHours() : d.getUTCHours();
			var minutes:Number = local ? d.getMinutes() : d.getUTCMinutes();
			var seconds:Number = local ? d.getSeconds() : d.getUTCSeconds();
			var milliseconds:Number = local ? d.getMilliseconds() : d.getUTCMilliseconds();
			var sb:String = new String();
			
			var tzo:Number = d.getTimezoneOffset();
			var tzd:String = (tzo < 0 ) ? "+" : "-";
			var tzh:int = Math.abs(tzo) / 60;
			var tzm:int = Math.abs(tzo) % 60;
			if (tzh < 10)
				tzd += "0";
			tzd += tzh;
			tzd += ":";
			if (tzm < 10)
				tzd += "0";
			tzd += tzm;
			
			sb += d.getUTCFullYear();
			sb += (format==0) ? "-" : "";
			
			//thanks to "dom" who sent in a fix for the line below
			if (month + 1 < 10)
			{
				sb += "0";
			}
			sb += month + 1;
			sb += (format==0) ? "-" : "";
			if (date < 10)
			{
				sb += "0";
			}
			sb += date;
			if( includeTime )
			{
				sb += (format==0) ? "T" : "_";
				if (hours < 10)
				{
					sb += "0";
				}
				sb += hours;
				sb += (format==0) ? ":" : "";
				if (minutes < 10)
				{
					sb += "0";
				}
				sb += minutes;
				sb += (format==0) ? ":" : "";
				if (seconds < 10)
				{
					sb += "0";
				}
				sb += seconds;
				if (includeMilliseconds && milliseconds > 0)
				{
					sb += ".";
					if( milliseconds < 100 )
						sb += "0";
					if( milliseconds < 10 )
						sb += "0";
					sb += milliseconds;
				}
				if( format==0 ) {
					sb += local ? tzd : "-00:00";
				}
			}
			return sb;
		}
		
		public static function formatMilliseconds( ms:int, format:int=0 ) : String
		{
			var milliseconds:int = ms % 1000;
			var seconds:int = int( ms / 1000 ) % 60;
			var minutes:int = int( seconds / 60 );
			
			var sb:String = "";
			if (minutes < 10)
				sb += "0";
			sb += minutes;
			sb += (format==0) ? ":" : "";
			if (seconds < 10)
				sb += "0";
			sb += seconds;
			if( milliseconds == 0 )
				sb += ".000";
			else
			{
				sb += ".";
				if( milliseconds < 100 )
					sb += "0";
				if( milliseconds < 10 )
					sb += "0";
				sb += milliseconds;
			}
			return sb;
		}
		
		/**
		 * Parses dates that conform to the OFX Date-time Format into Date objects.
		 *
		 * The string format is '19961005132200.124[-5:EST]' where elements to the right
		 * are optional. 
		 * 
		 * TODO: This method has not been unit tested or even debugged for times with milliseconds
		 * or timezone offsets.
		 *
		 * @param str
		 *
		 * @returns
		 */		     
		public static function parseOFXDTF(str:String):Date
		{
			var finalDate:Date;
			try
			{
				if( str.length < 8 ) {
					throw new Error("Date string '" + str + "' does not conform to OFX datetime format.");
				}
				
				var year:Number = Number(str.substring(0,4));
				var month:Number = Number(str.substring(4,6));
				var date:Number = Number(str.substring(6,8));
				var hour:Number = 0;
				var minutes:Number = 0;
				var seconds:Number = 0;
				if( str.length >= 10 ) {
					hour = Number(str.substring(8,10));
					if( str.length >= 12 ) {
						minutes = Number(str.substring(10,12));
						if( str.length >= 14 ) {
							seconds = Number(str.substring(12,14));
						}
					}
				}
				
				var milliseconds:Number = 0;
				
				var multiplier:Number = 1;
				var offsetHours:Number = 0;
				var offsetMinutes:Number = 0;
				
				if( str.length > 16 ) 
				{
					var timeStr:String = str.substring(14);
					
					var regExp:RegExp = /\.(\d+)/;
					var msMatch:Array = regExp.exec( timeStr );
					//					var msMatch:Array = timeStr.match(  );
					if( msMatch != null && msMatch.length >= 2 ) 
					{
						milliseconds = Number(msMatch[1]);
					}
					
					var offsetMatch:Array = timeStr.match( /\[([-+])([\d\.]+)/ );
					
					if( offsetMatch.length >= 3 ) 
					{
						multiplier = offsetMatch[1] == '-' ? -1 : +1;
						var offsetStr:String = offsetMatch[2];
						if( offsetStr.indexOf('.') != -1 ) 
						{
							offsetHours = Number(offsetStr.substring(0, offsetStr.indexOf(".")));
							offsetMinutes = Number(offsetStr.substring(offsetStr.indexOf(".")+1, offsetStr.length));
						}
						else 
						{
							offsetHours = Number(offsetStr);
						}
						
					}
					
				} 
				
				var utc:Number = Date.UTC(year, month-1, date, hour, minutes, seconds, milliseconds);
				var offset:Number = (((offsetHours * 3600000) + (offsetMinutes * 60000)) * multiplier);
				finalDate = new Date(utc - offset);
				
				if (finalDate.toString() == "Invalid Date")
				{
					throw new Error("Date does not conform to OFX datetime format.");
				}
			}
			catch (e:Error)
			{
				var eStr:String = "Unable to parse the string [" +str+ "] into a date. ";
				eStr += "The internal error was: " + e.toString();
				throw new Error(eStr);
			}
			return finalDate;
		}
		
		
		
	}
}