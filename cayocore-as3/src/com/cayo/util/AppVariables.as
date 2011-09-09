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
	import flash.desktop.NativeApplication;
	import flash.html.HTMLLoader;
	import flash.html.HTMLPDFCapability;
	import flash.net.URLVariables;
	import flash.system.Capabilities;
	import flash.utils.describeType;
	
	/**
	 * Class returns the Application runtime information that we care about.
	 */
	public class AppVariables
	{
		public var appId:String;
		public var appVersion:String;
		public var playerType:String;
		public var runtimeVersion:String;
		public var os:String;
		public var cpuArch:String;
		public var pdfCapability:String;
		
		public function AppVariables()
		{
			var appXml:XML = NativeApplication.nativeApplication.applicationDescriptor;
			var ns:Namespace = appXml.namespace();
			this.appId = appXml.ns::id[0];
			this.appVersion = appXml.ns::version[0];
			this.playerType = Capabilities.playerType;
			this.runtimeVersion = NativeApplication.nativeApplication.runtimeVersion;
			this.os = Capabilities.os;
			this.cpuArch = Capabilities.cpuArchitecture;
			if( HTMLLoader.pdfCapability == HTMLPDFCapability.STATUS_OK )
				this.pdfCapability = 'ok';
			else if( HTMLLoader.pdfCapability == HTMLPDFCapability.ERROR_CANNOT_LOAD_READER )
				this.pdfCapability = 'error_load';
			else if( HTMLLoader.pdfCapability == HTMLPDFCapability.ERROR_INSTALLED_READER_NOT_FOUND )
				this.pdfCapability = 'error_install';
			else if( HTMLLoader.pdfCapability == HTMLPDFCapability.ERROR_INSTALLED_READER_TOO_OLD )
				this.pdfCapability = 'error_old';
			else if( HTMLLoader.pdfCapability == HTMLPDFCapability.ERROR_PREFERRED_READER_TOO_OLD )
				this.pdfCapability = 'error_preferred_old';
			else
				this.pdfCapability = 'error';
		}
		
		public function toAppString( delimiter:String=", ", separator:String="=" ) : String
		{
			var result:String = 'appId' + separator + this.appId;
			result += delimiter + 'appVersion' + separator + this.appVersion;
			result += delimiter + 'playerType' + separator + this.playerType;
			result += delimiter + 'runtimeVersion' + separator + this.runtimeVersion;
			result += delimiter + 'os' + separator + this.os;
			result += delimiter + 'cpuArch' + separator + this.cpuArch;
			result += delimiter + 'pdfCapability' + separator + this.pdfCapability;
			return result;
		}
		
	}
}