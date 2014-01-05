define( function() {
    // Dependencies
    var $ = require( 'jquery' );
    var Bootstrap = require( 'bootstrap' );

    // Prevent error message from showing up
    window.easyGachaLoaded = true;

    // Switch to HTML5 because SL refuses to serve up content-type text/html
    document.replaceChild( document.implementation.createDocumentType( 'html' , '' , '' ) , document.doctype );
    document.documentElement.removeAttribute( 'xmlns' );

    // Add bootstrap dependencies
    $('head').append( '<title>Easy Gacha</title>' );
    $('head').append( '<meta name="viewport" content="width=device-width, initial-scale=1.0" />' );
    $('head').append( '<link href="' + require.toUrl( './bootstrap/css/bootstrap.min.css' ) + '" rel="stylesheet" />' );
} );
