/*************************************************************************
 * CAYO CONFIDENTIAL
 * Copyright 2010 Cayo Systems, Inc. All Rights Reserved.
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
	public class StringUtil
	{
		/**
		 * Builds the message from the specified message and parameters.
		 * The message may contain numered placeholders like '{0}' which will be replaced by the
		 * specified parameters. For parameters of type Error the whole stacktrace will be included.
		 * 
		 * @param message the message, possibly containing parameter placeholders
		 * @param params the parameters to fill the placeholders with
		 * @return the fully resolved log message 
		 */
		public static function buildMessage (message:String, params:Array) : String {
			if (params == null) return message;
			for (var i:int = 0; i < params.length; i++) {
				var param:* = params[i];
				if (param is Error) {
					var e:Error = param as Error;
					param = "\n" + e.getStackTrace();
				}
				message = message.replace(new RegExp("\\{"+ i +"\\}", "g"), param);
			}
			return message;
		}

	}
}