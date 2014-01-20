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
    , 'models/info'
    , 'css!styles/page'
    , 'css!vendor/font-awesome-4.0.3/css/font-awesome'
    , 'jquery'
    , 'lib/is-sl-viewer'

] , function(

    Backbone
    , Marionette
    , AppRouter
    , Info
    , pageStyles
    , fontawesome // pre-loaded for entire project
    , $
    , isSlViewer

) {
    'use strict';

    document.body.innerHTML = 'Please use a different web browser. I suggest Chrome or FireFox.';

    var app = new Marionette.Application();

    app.addInitializer( function( options ) {
        this.info = new Info();
    } );

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

} );
