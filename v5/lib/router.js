define( [

    'underscore'
    , 'marionette'
    , 'lib/admin-key'
    , 'dashboard/index'
    , 'config/index'
    , 'registry/index'
    , 'lib/google-analytics'

] , function(

    _
    , Marionette
    , adminKeyStore
    , DashboardView
    , ConfigView
    , RegistryView
    , ga

) {
    'use strict';

    return Marionette.AppRouter.extend( {
        routes: {
            'admin/:adminKey': 'adminEntryPoint'
            , 'dashboard': 'dashboard'
            , 'config': 'config'
            , 'config/:tab': 'configTab'
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
            ga( 'set' , 'page' , '/dashboard' );
            ga( 'send' , 'pageview' );
        }

        , config: function() {
            this.navigate( 'config' , { replace: true } );
            var view = new ConfigView( this.options );
            this.options.app.body.show( view );
        }

        , configTab: function( tabName ) {
            this.navigate( 'config/' + tabName , { replace: true } );
            var view = new ConfigView( _.defaults( {
                defaultTab: tabName
            } , this.options ) );
            this.options.app.body.show( view );
        }

        , registry: function() {
            this.navigate( 'registry' , { replace: true } );
            var view = new RegistryView( this.options );
            this.options.app.body.show( view );
            ga( 'set' , 'page' , '/registry' );
            ga( 'send' , 'pageview' );
        }
    } );

} );
