window.easyGachaLoaded = true;
require( function() {
    // Switch to HTML5 because SL refuses to serve up content-type text/html
    document.replaceChild( document.implementation.createDocumentType( 'html' , '' , '' ) , document.doctype );
    document.documentElement.removeAttribute( 'xmlns' );

    alert( 'Test' );
} );
