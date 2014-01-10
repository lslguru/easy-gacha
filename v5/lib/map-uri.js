define( [ ] , function( ) {
    'use strict';

    var exports = function( regionName , x , y , z ) {
        return (
            'secondlife:///app/worldmap/'
            + encodeURIComponent( regionName )
            + '/'
            + Math.round( x )
            + '/'
            + Math.round( y )
            + '/'
            + Math.round( z )
        );
    };

    return exports;

} );
