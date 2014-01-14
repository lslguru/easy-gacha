// This file is loaded bare from the SL script page. This reduces the amount of
// text needed in the script dramatically, but makes it harder to do simple
// things like the text that normally is your static index.html file...
(function() {
    // Prevent error message from showing up
    window.easyGachaLoaded = true;

    // Switch to HTML5 because SL refuses to serve up content-type text/html
    document.replaceChild( document.implementation.createDocumentType( 'html' , '' , '' ) , document.doctype );
    document.documentElement.removeAttribute( 'xmlns' );

    // Get base path
    var scripts = document.getElementsByTagName( 'script' );
    var path = scripts[ scripts.length - 1 ].src.split( '?' )[ 0 ]; // remove any query string
    var mydir = path.split( '/' ).slice( 0 , -1 ).join( '/' ) + '/'; // remove last filename part of path

    // Get dev flag
    var dev = Boolean(String(document.location.search).match(/[?&]dev=1(&|$)/));

    // Create some header elements (done here so we don't have to bake all this
    // into the script)
    var el;

    // Twitter Bootstrap Asset
    el = document.createElement( 'meta' );
    el.setAttribute( 'name' , 'viewport' );
    el.setAttribute( 'content' , 'width=device-width, initial-scale=1.0' );
    document.head.appendChild( el );

    // Let them know we're doing stuff
    window.onload = function() {
        var el = document.createElement( 'p' );
        el.innerHTML = 'Please wait, loading...';
        document.body.appendChild( el );
    };

    // Use requirejs to load init.js
    el = document.createElement( 'script' );
    el.setAttribute( 'type' , 'text/javascript' );
    el.setAttribute( 'data-main' , mydir + 'init' + ( dev ? '' : '.min' ) + '.js' );
    el.setAttribute( 'src' , mydir + 'vendor/require.js' );
    document.head.appendChild( el );
})();
