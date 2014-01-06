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

    Vector.regexp = /^<\s*([-0-9.]*)\s*,\s*([-0-9.]*)\s*,\s*([-0-9.]*)\s*>$/;

    Vector.isVector = function( str ) {
        return Boolean( Vector.regexp.exec( str ) );
    };

    Vector.parse = function( str ) {
        var parts = Vector.regexp.exec( str );
        var vec = new Vector();

        if( !parts ) {
            return vec;
        }

        vec.x = Number(parts[1]);
        vec.y = Number(parts[2]);
        vec.z = Number(parts[3]);

        return vec;
    };

    Vector.prototype.toString = function() {
        return '<' + this.x + ',' + this.y + ',' + this.z + '>';
    };

    return Vector;
} );
