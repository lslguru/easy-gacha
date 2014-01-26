define( [
] , function(
) {
    'use strict';

    // Basic algorithm taken from
    // https://stackoverflow.com/questions/15478954/sort-array-elements-string-with-numbers-natural-sort

    var exports = {};

    var stringCompare = exports.stringCompare = function( a , b ) {
        if( a > b ) return 1;
        if( a < b ) return -1;
        return 0;
    };

    exports.naturalCompare = function( a , b ) {
        var partsRegexp = /(\d+|\D+)/g;
        var x = [], y = [];

        a.replace( partsRegexp , function( $0 , $1 ) { x.push( $1 || 0 ); } );
        b.replace( partsRegexp , function( $0 , $1 ) { y.push( $1 || 0 ); } );

        while( x.length && y.length ) {
            var xx = x.shift();
            var yy = y.shift();
            var nn = ( xx - yy ) || stringCompare( xx , yy );
            if( nn ) return nn;
        }

        if( x.length ) return -1;
        if( y.length ) return +1;

        return 0;
    };

    return exports;

} );
