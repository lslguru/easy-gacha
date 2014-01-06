define( [
] , function(
) {
    'use strict';

    var Vector = function( str ) {
        if( str ) {
            return Vector.parse( str );
        }

        this.x = 0;
        this.y = 0;
        this.z = 0;
    };

    Vector.parse = function( str ) {
        var parts = /^<\s*([-0-9.]*)\s*,\s*([-0-9.]*)\s*,\s*([-0-9.]*)\s*>$/.exec( str );
        var vec = new Vector();

        if( !parts ) {
            return vec;
        }

        vec.x = Number(parts[1]);
        vec.y = Number(parts[2]);
        vec.z = Number(parts[3]);

        return vec;
    };

    Vector.toString = function() {
        return '<' + this.x + ',' + this.y + ',' + this.z + '>';
    };

    return Vector;
} );
