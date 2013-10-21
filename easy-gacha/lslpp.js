#!/usr/bin/env node

var data = require( 'fs' ).readFileSync( process.argv[ 2 ] );
var linesToParse = String(data).split( /\n/ );
var match;

var defines = {};
var organized = {
    globalvariables: []
    , globalfunctions: []
    , other: []
    , states: []
};
var lineMode = 'other';
var s;

while( linesToParse.length ) {
    (function( line ) {
        // Strip white-space through comments
        line = line.replace( /\s\+\/\/.*/ , '' );

        // Strip leading and trailing whitespace
        line = line.replace( /^\s+/ , '' );
        line = line.replace( /\s+$/ , '' );

        // Section directives
        for( s in organized ) {
            if( (new RegExp( '^#start' + s )).test( line ) ) {
                lineMode = s;
                return;
            }
        }
        if( (new RegExp( '^#end' + lineMode )).test( line ) ) {
            lineMode = 'other';
            return;
        }

        // Include directives
        if( /^#include /.test( line ) ) {
            match = line.match( /^#include (.*)/ );
            data = require( 'fs' ).readFileSync( match[1] );
            linesToParse = String(data).split( /\n/ ).concat( linesToParse );
            return;
        }

        // Define directives
        if( /^#define /.test( line ) ) {
            match = line.match( /^#define ([^ ]+) (.*)/ );
            defines[ match[1] ] = match[2];
            return;
        }

        // Push into appropriate area
        organized[ lineMode ].push( line );
    })( linesToParse.shift() );
}

for( s in organized ) {
    organized[ s ].forEach( function( line ) {
        // Replace with defines
        do {
            var oldLine = line;
            for( s in defines ) {
                line = line.replace( s , defines[ s ] );
            }
        } while( oldLine != line );

        // If there's anything left
        if( line ) {
            console.log( line );
        }
    } );
}
