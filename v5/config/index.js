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

        , loading: false

        , initialize: function() {
            this.constructor.__super__.initialize.apply( this , arguments );

            _.bindAll( this
                , 'lookupAgentDialog'
            );

            this.options.lookupAgentDialog = this.lookupAgentDialog;
            this.options.model = this.options.gacha = window.gacha = new Gacha();
        }

        , onRender: function() {
            var gacha = this.options.gacha;

            this.loaderView = new LoaderView( _.extend( {} , this.options , {
                model: gacha
            } ) );

            gacha.on( 'change:progressPercentage' , function() {
                if( !this.loading && 100 !== gacha.get( 'progressPercentage' ) ) {
                    this.header.close();
                    this.tabs.close();

                    this.loader.show( new LoaderView( this.options ) );

                    this.loading = true;
                }

                if( this.loading && 100 === gacha.get( 'progressPercentage' ) ) {
                    this.loader.close();

                    if( !gacha.get( 'info' ).get( 'isAdmin' ) ) {
                        this.options.app.router.navigate( 'dashboard' , { trigger: true , replace: true } );
                        return;
                    }

                    this.header.show( new HeaderView( _.extend( {} , this.options , {
                        model: gacha.get( 'info' )
                    } ) ) );

                    this.tabs.show( new TabsView( this.options ) );

                    this.loading = false;
                }
            } , this );

            function updatePageTitle() {
                if( gacha.get( 'info' ) && gacha.get( 'info' ).get( 'objectName' ) ) {
                    document.title = 'Easy Gacha Config - ' + gacha.get( 'info' ).get( 'objectName' );
                } else {
                    document.title = 'Easy Gacha Configuration';
                }
            }

            function setupListener() {
                gacha.get( 'info' ).on( 'change:objectName' , updatePageTitle , this );
            }

            gacha.on( 'change:info' , function() {
                if( gacha.previous( 'info' ) ) {
                    gacha.previous( 'info' ).off( null , null , this );
                }

                setupListener();
                updatePageTitle();
            } , this );

            setupListener();
            updatePageTitle();
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
