define( [
] , function(
) {
    'use strict';

    var Rotation = function( str ) {
        if( str ) {
            return Rotation.parse( str );
        }

        this.x = 0;
        this.y = 0;
        this.z = 0;
        this.s = 1;
    };

    Rotation.regexp = /^<\s*([-0-9.]*)\s*,\s*([-0-9.]*)\s*,\s*([-0-9.]*)\s*,\s*([-0-9.]*)\s*>$/;

    Rotation.isRotation = function( str ) {
        return Boolean( Rotation.regexp.exec( str ) );
    };

    Rotation.parse = function( str ) {
        var parts = Rotation.regexp.exec( str );
        var rot = new Rotation();

        if( !parts ) {
            return rot;
        }

        rot.x = Number(parts[1]);
        rot.y = Number(parts[2]);
        rot.z = Number(parts[3]);
        rot.s = Number(parts[4]);

        return rot;
    };

    Rotation.prototype.toString = function() {
        return '<' + this.x + ',' + this.y + ',' + this.z + ',' + this.s + '>';
    };

    return Rotation;
} );
