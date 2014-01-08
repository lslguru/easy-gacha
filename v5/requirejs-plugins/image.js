// RequireJS Alternative Image AMD Plugin (supports minification)
// Author: Jason Schmidt
// Released under the MIT license

(function () {
	'use strict';

    define( [ 'base64' ] , function( base64 ) {
        return {

            load: function( name , req , load , config ) {
                if( config.isBuild ) {
                    return base64.load( name , req , load , config );
                }

                var img = new Image();

                var cleanup = function() {
                    try {
                        delete img.onerror;
                        delete img.onload;
                    } catch( e ) {
                        // IE7 sucks
                        img.onerror = noop;
                        img.onload = noop;
                    }
                };

                img.onerror = function( err ) {
                    load.error( err );
                    cleanup();
                };

                img.onload = function( evt ) {
                    load( img );
                    cleanup();
                };

                img.src = req.toUrl( name );
            } // end load()

            , write: function( pluginName , moduleName , write , config ) {
                if( moduleName in base64._buildMap ) {
                    var content = base64._buildMap[ moduleName ];

					var mime = 'image';
					if( /\.gif$/.test( moduleName ) ) mime = 'image/gif';
					if( /\.jpe?g$/.test( moduleName ) ) mime = 'image/jpeg';
					if( /\.png$/.test( moduleName ) ) mime = 'image/png';
					if( /\.svg$/.test( moduleName ) ) mime = 'image/svg+xml';

                    write.asModule(
                        pluginName + '!' + moduleName
                        , 'define(function(){var i=new Image();i.src=\'data:' + mime + ';base64,' + content + '\';return i;});\n'
                    );
                }
            } // end write()

        }; // end return
    } ); // end define( function ...)

})(); // end file closure
