define( [

    'underscore'
    , 'marionette'
    , 'hbs!config/templates/index'
    , 'models/gacha'
    , 'bootstrap'
    , 'lib/loader-view'
    , 'config/header'
    , 'config/tabs'
    , 'lib/lookup-agent'

] , function(

    _
    , Marionette
    , template
    , Gacha
    , bootstrap
    , LoaderView
    , HeaderView
    , TabsView
    , LookupAgentView

) {
    'use strict';

    var exports = Marionette.Layout.extend( {
        template: template

        , regions: {
            'loader': '#loader'
            , 'header': '#header'
            , 'tabs': '#tabs'
            , 'lookupAgent': '#lookup-agent-container'
        }

        , initialize: function() {
            this.constructor.__super__.initialize.apply( this , arguments );

            _.bindAll( this
                , 'lookupAgentDialog'
            );
        }

        , loaderView: function() {
            if( 100 !== this.model.get( 'progressPercentage' ) ) {
                if( undefined === this.loader.currentView ) {
                    this.header.close();
                    this.tabs.close();
                    this.lookupAgent.close();
                    this.loader.show( new LoaderView( this.options ) );
                }
            } else {
                this.mainView();
            }
        }

        , mainView: function() {
            if( ! this.header.currentView || ! this.tabs.currentView ) {
                this.loader.close();

                if( ! this.model.get( 'isAdmin' ) ) {
                    this.options.app.router.navigate( 'dashboard' , { trigger: true , replace: true } );
                    return;
                }

                this.header.show( new HeaderView( this.options ) );
                this.tabs.show( new TabsView( this.options ) );
            }
        }

        , updatePageTitle: function() {
            if( this.model.get( 'objectName' ) ) {
                document.title = 'Easy Gacha Config - ' + this.model.get( 'objectName' );
            } else {
                document.title = 'Easy Gacha Configuration';
            }
        }

        , onRender: function() {
            this.options.lookupAgentDialog = this.lookupAgentDialog;

            this.model = new Gacha();
            this.options.model = this.model;
            this.options.gacha = this.model;
            window.gacha = this.model;

            this.model.on( 'change:progressPercentage' , this.loaderView , this );
            this.model.on( 'change:objectName' , this.updatePageTitle , this );

            this.updatePageTitle();

            this.model.fetch( {
                loadAdmin: true
            } );
        }

        , lookupAgentDialog: function( options ) {
            this.lookupAgent.show( new LookupAgentView( _.extend( {} , this.options , options ) ) );
        }
    } );

    return exports;

} );
