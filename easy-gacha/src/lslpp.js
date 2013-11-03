#!/usr/bin/env node

var data = require( 'fs' ).readFileSync( process.argv[ 2 ] );
var linesToParse = String(data).split( /\n/ );
var match;

var included = [];
var defines = {};
var organized = {
    globalvariables: []
    , globalfunctions: []
    , default: []
    , states: []
};
var lineMode = 'default';
var s;
var startSectionRegexp = /^#start\s(.*)$/;
var endSectionRegexp = /^#end\s(.*)$/;
var matchedSection;

while( linesToParse.length ) {
    (function( line ) {
        // Strip white-space through comments
        line = line.replace( /\s*\/\/.*/ , '' );

        // Strip leading and trailing whitespace
        line = line.replace( /^\s+/ , '' );
        line = line.replace( /\s+$/ , '' );

        // Section directives
        if( matchedSection = line.match( startSectionRegexp ) ) {
            lineMode = matchedSection[ 1 ];
            return;
        }
        if( matchedSection = line.match( endSectionRegexp ) ) {
            if( lineMode !== matchedSection[ 1 ] ) {
                throw 'Current mode is ' + lineMode + ' but found: ' + line;
            }

            lineMode = 'default';
            return;
        }

        // Include directives
        if( /^#include /.test( line ) ) {
            match = line.match( /^#include (.*)/ );
            if( -1 === included.indexOf( match[1] ) ) {
                data = require( 'fs' ).readFileSync( match[1] );
                linesToParse = String(data).split( /\n/ ).concat( linesToParse );
                included.push( match[1] );
            }
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
    process.stderr.write( 'Printing section: ' + s + '\n' );

    organized[ s ].forEach( function( line ) {
        // Replace with defines
        do {
            var oldLine = line;
            for( s in defines ) {
                line = line.replace( new RegExp( '\\b' + s + '\\b' ) , defines[ s ] );
            }
        } while( oldLine != line );

        // If there's anything left
        if( line ) {
            process.stdout.write( line + '\n' );
        }
    } );
}
