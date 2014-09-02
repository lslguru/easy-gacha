require.onError = function( err ) {
    document.body.innerHTML = (
        '<p>Something went wrong. Please refresh the page and try again</p>\n<pre>' + err + '</pre>'
    );
};

require( {

    paths: {
        'bootstrap': 'vendor/bootstrap/js/bootstrap'
        , 'underscore': 'vendor/underscore'
        , 'jquery': 'vendor/jquery'
        , 'backbone': 'vendor/backbone'
        , 'text': 'vendor/text'
        , 'css': 'vendor/require-css/css'
        , 'css-builder': 'vendor/require-css/css-builder'
        , 'normalize': 'vendor/require-css/normalize'
        , 'base64': 'requirejs-plugins/base64'
        , 'image': 'requirejs-plugins/image'
        , 'backbone.wreqr': 'vendor/backbone.wreqr'
        , 'backbone.babysitter': 'vendor/backbone.babysitter'
        , 'marionette': 'vendor/marionette'
        , 'hbs': 'vendor/require-handlebars-plugin/hbs'
        , 'moment': 'vendor/moment/moment'
        , 'tablesorter': 'vendor/tablesorter/jquery.tablesorter'
    }

    , shim: {
        'bootstrap': {
            deps: [
                'jquery'
                , 'css!vendor/bootstrap/css/bootstrap'
                , 'css!vendor/bootstrap/css/bootstrap-theme'
            ]
        }
        , 'tablesorter': {
            deps: [
                'css!vendor/tablesorter/themes/blue/style'
            ]
        }
    }

} , [

    'backbone'
    , 'marionette'
    , 'lib/router'
    , 'css!styles/page'
    , 'css!vendor/font-awesome-4.0.3/css/font-awesome'
    , 'jquery'
    , 'lib/is-sl-viewer'
    , 'lib/google-analytics'

] , function(

    Backbone
    , Marionette
    , AppRouter
    , pageStyles
    , fontawesome // pre-loaded for entire project
    , $
    , isSlViewer
    , ga

) {
    'use strict';

    document.body.innerHTML = 'Please use a different web browser. I suggest Chrome or FireFox.';

    ga( 'create' , 'UA-29886355-4' , 'auto' , { allowLinker: true } );
    ga( 'require' , 'linker' );
    ga( 'require' , 'displayfeatures' );
    ga( 'set' , 'anonymizeIp' , false );

    if( window && window.performance && window.performance.timing && window.performance.timing.domComplete ) {
        var time = Date.now() - window.performance.timing.domComplete;
        ga( 'send' , 'timing' , 'app' , 'initialize' , time );
    }

    var app = new Marionette.Application();

    app.addInitializer( function( options ) {
        this.router = new AppRouter( options );
        Backbone.history.start( { } );
    } );

    app.addInitializer( function( options ) {
        if( isSlViewer() ) {
            $( document.body ).addClass( 'sl-viewer' );
        }
    } );

    app.addRegions( {
        'body': 'body'
    } );

    app.start( {
        app: app
    } );

} , function( err ) {

    document.body.innerHTML = '<p>ERROR LOADING PAGE: Please reload and try again</p>\n<pre>' + err + '</pre>';

    if( window.ga ) {
        window.ga( 'send' , 'exception' , {
            exDescription: err
            , exFatal: true
        } );
    }

} );
