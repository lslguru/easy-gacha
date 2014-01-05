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

] , function(

    Backbone

) {
    'use strict';

    var adminKey = window.localStorage.getItem( window.location.origin + window.location.pathname );
    if( adminKey ) {
        console.log( 'loaded adminKey' , adminKey );
        window.easyGachaAdminKey = adminKey;
    }

    var AppRouter = Backbone.Router.extend( {
        routes: {
            'admin/:adminKey': 'adminEntryPoint'
            , 'dashboard': 'dashboard'
            , 'config': 'config'
            , '*path': 'dashboard'
        }

        , adminEntryPoint: function( adminKey ) {
            window.localStorage.setItem( window.location.origin + window.location.pathname , adminKey );
            window.easyGachaAdminKey = adminKey;
            console.log( 'saved adminKey' , adminKey );
            this.navigate( 'config' , { trigger: true , replace: true } );
        }

        , dashboard: function() {
            this.navigate( 'dashboard' , { replace: true } );
        }

        , config: function() {
            this.navigate( 'config' , { replace: true } );
        }
    } );

    var appRouter = new AppRouter( { } );
    Backbone.history.start( { } );

} );
