#!/usr/bin/env node

// lsl script word frequency analyzer

var data = require( 'fs' ).readFileSync( process.argv[ 2 ] );
var linesToParse = String( data ).split( /\n/ );

var chunks = {};
while( linesToParse.length ) {
    (function( line ){
        var lineChunks = line.match( /([0-9\.A-Za-z_']+|[^\s0-9A-Za-z_']+)/g );
        if( lineChunks ) {
            lineChunks.forEach( function( chunk ) {
                chunks[ chunk ] = ( chunks[ chunk ] || 0 ) + 1;
            } );
        }
    })( linesToParse.shift() );
}

var sortable = [];
for( var chunk in chunks ) {
    sortable.push( { name: chunk , count: chunks[ chunk ] } );
}
sortable.sort( function( a , b ) {
    // Descending sort
    if( a.count > b.count ) return -1;
    if( a.count < b.count ) return 1;
    return 0;
} );
sortable.forEach( function( chunk ) {
    console.log( chunk.count + '\t' + chunk.name );
} );
