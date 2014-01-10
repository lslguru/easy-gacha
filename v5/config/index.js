define( [

    'underscore'
    , 'marionette'
    , 'hbs!config/templates/index'
    , 'backbone'
    , 'bootstrap'
    , 'config/loader'
    , 'config/header'
    , 'config/tabs'

] , function(

    _
    , Marionette
    , template
    , Backbone
    , bootstrap
    , LoaderView
    , HeaderView
    , TabsView

) {
    'use strict';

    var exports = Marionette.Layout.extend( {
        template: template

        , regions: {
            'loader': '#loader'
            , 'header': '#header'
            , 'tabs': '#tabs'
        }

        , onRender: function() {
            var data = new Backbone.Model();

            this.loader.show( new LoaderView( _.extend( {} , this.options , {
                model: data
            } ) ) );

            data.on( 'change:percentage' , function( data , percentage , options ) {
                if( 100 === percentage ) {
                    this.loader.close();

                    this.header.show( new HeaderView( _.extend( {} , this.options , {
                        model: data.get( 'info' )
                    } ) ) );

                    this.tabs.show( new TabsView( _.extend( {} , this.options , {
                        model: data
                    } ) ) );
                }
            } , this );

            function updatePageTitle() {
                if( data.get( 'info' ) && data.get( 'info' ).get( 'objectName' ) ) {
                    document.title = 'Easy Gacha Config - ' + data.get( 'info' ).get( 'objectName' );
                } else {
                    document.title = 'Easy Gacha Configuration';
                }
            }

            function setupListener() {
                data.get( 'info' ).on( 'change:objectName' , updatePageTitle , this );
            }

            data.on( 'change:info' , function() {
                if( data.previous( 'info' ) ) {
                    data.previous( 'info' ).off( null , null , this );
                }

                setupListener();
                updatePageTitle();
            } , this );

            setupListener();
            updatePageTitle();
        }
    } );

    return exports;

} );
