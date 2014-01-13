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
            if( 100 !== this.gacha.get( 'progressPercentage' ) ) {
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
            var gacha = this.gacha;

            if( ! this.header.currentView || ! this.tabs.currentView ) {
                this.loader.close();

                if( ! gacha.get( 'info' ).get( 'isAdmin' ) ) {
                    this.options.app.router.navigate( 'dashboard' , { trigger: true , replace: true } );
                    return;
                }

                this.header.show( new HeaderView( _.extend( {} , this.options , {
                    model: gacha.get( 'info' )
                } ) ) );

                this.tabs.show( new TabsView( this.options ) );
            }
        }

        , updatePageTitle: function() {
            var gacha = this.gacha;

            if( gacha.get( 'info' ) && gacha.get( 'info' ).get( 'objectName' ) ) {
                document.title = 'Easy Gacha Config - ' + gacha.get( 'info' ).get( 'objectName' );
            } else {
                document.title = 'Easy Gacha Configuration';
            }
        }

        , setupPageTitleHandlers: function() {
            var gacha = this.gacha;

            function setupListener() {
                gacha.get( 'info' ).on( 'change:objectName' , this.updatePageTitle , this );
            }

            gacha.on( 'change:info' , function() {
                if( gacha.previous( 'info' ) ) {
                    gacha.previous( 'info' ).off( null , null , this );
                }

                setupListener();
                this.updatePageTitle();
            } , this );

            this.updatePageTitle();
        }

        , onRender: function() {
            var gacha = window.gacha = new Gacha();

            this.options.lookupAgentDialog = this.lookupAgentDialog;

            this.gacha = gacha;
            this.options.model = gacha;
            this.options.gacha = gacha;
            window.gacha = gacha;

            gacha.on( 'change:progressPercentage' , this.loaderView , this );

            this.setupPageTitleHandlers();

            gacha.fetch( {
                loadAdmin: true
            } );
        }

        , lookupAgentDialog: function( options ) {
            this.lookupAgent.show( new LookupAgentView( _.extend( {} , this.options , options ) ) );
        }
    } );

    return exports;

} );
