// RequireJS Base64 AMD Plugin (supports minification)
// Author: Jason Schmidt
// Released under the MIT license

// The purpose of this plugin is to dynamically (or via bundle) load a file as
// a base64 encoded string which may later be decoded or embedded in a
// data-uri. It's basically a clone of the text plugin with a Base64 wrapper
(function () {
	'use strict';

	////////////////////////////////////////////////////////////////////////////////

	/**
	 * BinFileReader.js
	 * You can find more about this function at
	 * http://nagoon97.com/reading-binary-files-using-ajax/
	 *
	 * Copyright (c) 2008 Andy G.P. Na <nagoon97@naver.com>
	 * The source code is freely distributable under the terms of an MIT-style license.
	 */
	function BinFileReader(fileURL){
		var _exception = {};
		_exception.FileLoadFailed = 1;
		_exception.EOFReached = 2;

		var filePointer = 0;
		var fileSize = -1;
		var fileContents;

		this.getFileSize = function(){
			return fileSize;
		};

		this.getFilePointer = function(){
			return filePointer;
		};

		this.movePointerTo = function(iTo){
			if( iTo < 0 ) {
				filePointer = 0;
			}
			else if(iTo > this.getFileSize()) {
				throwException(_exception.EOFReached);
			}
			else {
				filePointer = iTo;
			}

			return filePointer;
		};

		this.movePointer = function(iDirection){
			this.movePointerTo(filePointer + iDirection);

			return filePointer;
		};

		this.readNumber = function(iNumBytes, iFrom){
			iNumBytes = iNumBytes || 1;
			iFrom = iFrom || filePointer;

			this.movePointerTo(iFrom + iNumBytes);

			var result = 0;
			for(var i=iFrom + iNumBytes; i>iFrom; i--){
				result = result * 256 + this.readByteAt(i-1);
			}

			return result;
		};

		this.readString = function(iNumChars, iFrom){
			iNumChars = iNumChars || 1;
			iFrom = iFrom || filePointer;

			this.movePointerTo(iFrom);

			var result = '';
			var tmpTo = iFrom + iNumChars;
			for(var i=iFrom; i<tmpTo; i++){
				result += String.fromCharCode(this.readNumber(1));
			}

			return result;
		};

		this.readUnicodeString = function(iNumChars, iFrom){
			iNumChars = iNumChars || 1;
			iFrom = iFrom || filePointer;

			this.movePointerTo(iFrom);

			var result = '';
			var tmpTo = iFrom + iNumChars*2;
			for(var i=iFrom; i<tmpTo; i+=2){
				result += String.fromCharCode(this.readNumber(2));
			}

			return result;
		};

		function throwException(errorCode){
			switch(errorCode){
				case _exception.FileLoadFailed:
					throw new Error('Error: Filed to load "'+fileURL+'"');
				case _exception.EOFReached:
					throw new Error('Error: EOF reached');
			}
		}

		function BinFileReaderImpl_IE(fileURL){
			var vbArr = binFileReaderImpl_IE_VBAjaxLoader(fileURL);
			fileContents = vbArr.toArray();

			fileSize = fileContents.length-1;

			if(fileSize < 0) {
				throwException(_exception.FileLoadFailed);
			}

			this.readByteAt = function(i){
				return fileContents[i];
			};
		}

		function BinFileReaderImpl(fileURL){
			var req = new XMLHttpRequest();

			req.open('GET', fileURL, false);

			//XHR binary charset opt by Marcus Granado 2006 [http://mgran.blogspot.com]
			req.overrideMimeType('text/plain; charset=x-user-defined');
			req.send(null);

			if (req.status != 200) {
				throwException(_exception.FileLoadFailed);
			}

			fileContents = req.responseText;

			fileSize = fileContents.length;

			this.readByteAt = function(i){
				return fileContents.charCodeAt(i) & 0xff;
			};
		}
		if(/msie/i.test(navigator.userAgent) && !/opera/i.test(navigator.userAgent)) {
			BinFileReaderImpl_IE.apply(this, [fileURL]);
		}
		else {
			BinFileReaderImpl.apply(this, [fileURL]);
		}
	}

	// Modified from original to only write to document if we're in IE
	if( 'undefined' !== typeof window && window.navigator && /msie/i.test( navigator.userAgent ) && !/opera/i.test( navigator.userAgent ) ) {
		document.write(
			'<script type="text/vbscript">\n'
			+ 'Function binFileReaderImpl_IE_VBAjaxLoader(fileName)\n'
			+ '    Dim xhr\n'
			+ '    Set xhr = CreateObject("Microsoft.XMLHTTP")\n'
			+ '\n'
			+ '    xhr.Open "GET", fileName, False\n'
			+ '\n'
			+ '    xhr.setRequestHeader "Accept-Charset", "x-user-defined"\n'
			+ '    xhr.send\n'
			+ '\n'
			+ '    Dim byteArray()\n'
			+ '\n'
			+ '    if xhr.Status = 200 Then\n'
			+ '        Dim byteString\n'
			+ '        Dim i\n'
			+ '\n'
			+ '        byteString=xhr.responseBody\n'
			+ '\n'
			+ '        ReDim byteArray(LenB(byteString))\n'
			+ '\n'
			+ '        For i = 1 To LenB(byteString)\n'
			+ '            byteArray(i-1) = AscB(MidB(byteString, i, 1))\n'
			+ '        Next\n'
			+ '    End If\n'
			+ '\n'
			+ '    BinFileReaderImpl_IE_VBAjaxLoader=byteArray\n'
			+ 'End Function\n'
			+ '</script>'
		);
	}

	////////////////////////////////////////////////////////////////////////////////

	var Base64 = {

		keyStr: 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/='

		, encode: function( input , keyStr ) {
			var output = [],
				chr1, chr2, chr3,
				enc1, enc2, enc3, enc4,
				i = 0;

			input = String( input );
			keyStr = keyStr || this.keyStr;

			while ( i < input.length ) {
				chr1 = input.charCodeAt( i++ );
				chr2 = input.charCodeAt( i++ );
				chr3 = input.charCodeAt( i++ );

				// Strange edge-case where 0xff becomes 0xfffd in JS
				chr1 = ( 0xfffd === chr1 ? 0xff : chr1 );
				chr2 = ( 0xfffd === chr2 ? 0xff : chr2 );
				chr3 = ( 0xfffd === chr3 ? 0xff : chr3 );

				enc1 = ( chr1 >> 2 );
				enc2 = ( ( ( chr1 & 3 ) << 4 ) | ( chr2 >> 4 ) );
				enc3 = ( ( ( chr2 & 15 ) << 2 ) | ( chr3 >> 6 ) );
				enc4 = ( chr3 & 63 );

				if ( isNaN( chr2 ) ) {
					enc3 = enc4 = 64;
				} else if ( isNaN( chr3 ) ) {
					enc4 = 64;
				}

				output.push( keyStr.charAt( enc1 ) );
				output.push( keyStr.charAt( enc2 ) );
				output.push( keyStr.charAt( enc3 ) );
				output.push( keyStr.charAt( enc4 ) );
			}

			return output.join( '' );
		}

		, decode: function( input , keyStr ) {
			var output = [];
			var chr1, chr2, chr3;
			var enc1, enc2, enc3, enc4;
			var i = 0;

			input = String(input);
			keyStr = keyStr || this.keyStr;

			while ( i < input.length ) {
				enc1 = keyStr.indexOf( input.charAt( i++ ) );
				enc2 = ( ( i < input.length ) ? keyStr.indexOf( input.charAt( i++ ) ) : 64 );
				enc3 = ( ( i < input.length ) ? keyStr.indexOf( input.charAt( i++ ) ) : 64 );
				enc4 = ( ( i < input.length ) ? keyStr.indexOf( input.charAt( i++ ) ) : 64 );

				chr1 = ( ( enc1 << 2 ) | ( enc2 >> 4 ) );
				chr2 = ( ( ( enc2 & 15 ) << 4) | ( enc3 >> 2 ) );
				chr3 = ( ( ( enc3 & 3 ) << 6) | enc4 );

				output.push( String.fromCharCode( chr1 ) );

				if ( enc3 != 64 ) {
					output.push( String.fromCharCode( chr2 ) );
				}
				if ( enc4 != 64 ) {
					output.push( String.fromCharCode( chr3 ) );
				}
			}

			return output.join( '' );
		}

	};

	////////////////////////////////////////////////////////////////////////////////

	// Global cache object
	var buildMap = {};

	// Here is the beginning of the AMD module
	define( {

		_buildMap: buildMap
		, _Base64: Base64
		, _BinFileReader: BinFileReader

		, load: function( name , req , load , config ) {

			var base64;
			var contents;
			var file;
			var fileSize;
			var fs;
			var url;

			url = req.toUrl( name );
			contents = '';
			base64 = '';

			if ( 'undefined' !== typeof window && window.navigator && window.document ) {
				file = new BinFileReader( url );
				fileSize = file.getFileSize();
				contents = file.readString( fileSize );
				base64 = Base64.encode( contents );
			} else if ( 'undefined' !== typeof process ) {
				// Node does the hard work for us :-D
				fs = require.nodeRequire('fs');
				base64 = fs.readFileSync( url , 'base64' );
			}

			buildMap[ name ] = base64;
			load( base64 );

		} // end load()

		, write: function( pluginName , moduleName , write , config ) {

			var content;

			if( moduleName in buildMap ) {

				content = buildMap[ moduleName ];

				write.asModule(
					pluginName
						+ '!'
						+ moduleName
					, 'define(function(){return \''
						+ content
						+ '\';});\n'
				);

			} // end if( moduleName in buildMap )

		} // end write()

	} ); // end define( { ... } )

}()); // end file closure
