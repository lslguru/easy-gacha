define( [

    'underscore'
    , 'marionette'
    , 'lib/admin-key'
    , 'dashboard/index'
    , 'config/index'
    , 'registry/index'

] , function(

    _
    , Marionette
    , adminKeyStore
    , DashboardView
    , ConfigView
    , RegistryView

) {
    'use strict';

    return Marionette.AppRouter.extend( {
        routes: {
            'admin/:adminKey': 'adminEntryPoint'
            , 'dashboard': 'dashboard'
            , 'config': 'config'
            , 'registry': 'registry'
            , '*path': 'dashboard'
        }

        , adminEntryPoint: function( adminKey ) {
            adminKeyStore.save( adminKey );
            this.navigate( 'config' , { trigger: true , replace: true } );
        }

        , dashboard: function() {
            this.navigate( 'dashboard' , { replace: true } );
            var view = new DashboardView( this.options );
            this.options.app.body.show( view );
        }

        , config: function() {
            this.navigate( 'config' , { replace: true } );
            var view = new ConfigView( this.options );
            this.options.app.body.show( view );
        }

        , registry: function() {
            this.navigate( 'registry' , { replace: true } );
            var view = new RegistryView( this.options );
            this.options.app.body.show( view );
        }
    } );

} );
