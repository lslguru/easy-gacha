define( [

    'underscore'
    , 'marionette'
    , 'hbs!dashboard/templates/index'
    , './loader'
    , './header'
    , './items'
    , 'backbone'
    , 'bootstrap'

] , function(

    _
    , Marionette
    , template
    , LoaderView
    , HeaderView
    , ItemsView
    , Backbone
    , bootstrap

) {
    'use strict';

    var exports = Marionette.Layout.extend( {
        template: template

        , regions: {
            'loader': '#loader'
            , 'header': '#header'
            , 'items': '#items'
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

                    this.items.show( new ItemsView( _.extend( {} , this.options , {
                        collection: data.get( 'items' )
                    } ) ) );
                }
            } , this );

            function updatePageTitle() {
                if( data.get( 'info' ) && data.get( 'info' ).get( 'objectName' ) ) {
                    document.title = data.get( 'info' ).get( 'objectName' ) + ' - Easy Gacha Dashboard';
                } else {
                    document.title = 'Easy Gacha Dashboard';
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
