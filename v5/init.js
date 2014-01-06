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
    }

    , shim: {
        'bootstrap': {
            deps: [
                'jquery'
            ]
        }
    }

} , [

    'backbone'
    , 'marionette'
    , 'lib/router'
    , 'models/info'
    , 'css!vendor/bootstrap/css/bootstrap'
    , 'css!vendor/bootstrap/css/bootstrap-theme'
    , 'css!vendor/tablesorter/themes/blue/style'
    , 'css!styles/page'

] , function(

    Backbone
    , Marionette
    , AppRouter
    , Info

) {
    'use strict';

    var app = new Marionette.Application();

    app.addInitializer( function( options ) {
        this.info = new Info();
    } );

    app.addInitializer( function( options ) {
        this.router = new AppRouter( options );
        Backbone.history.start( { } );
    } );

    app.addRegions( {
        'body': 'body'
    } );

    app.start( {
        app: app
    } );

} );
