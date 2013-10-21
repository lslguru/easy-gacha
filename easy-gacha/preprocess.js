#!/usr/bin/env node

var data = '';

process.stdin.resume();
process.stdin.setEncoding('utf8');

process.stdin.on( 'data' , function( chunk ) {
    data += chunk;
} );

process.stdin.on( 'end' , function() {
    var lines = String(data).split( /\n/ );
    var defines = [];

    lines.forEach( function( line ) {
        if( /^#define /.test( line ) ) {
            var match = line.match( /^#define ([^ ]+) (.*)/ );
            defines.push( { match: match[1] , replace: match[2] } );
        } else {
            defines.forEach( function( replacement ) {
                line = line.replace( replacement.match , replacement.replace );
            } );

            // Strip comments
            line = line.replace( /\/\/.*/ , '' );

            // If there's anything left to show
            if( line ) {
                console.log( line );
            }
        }
    } );
} );
