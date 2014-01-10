define( [

    'marionette'
    , 'hbs!templates/loader'
    , 'css!styles/loader'
    , 'bootstrap'
    , 'models/info'
    , 'models/items'

] , function(

    Marionette
    , template
    , styles
    , bootstrap
    , Info
    , Items

) {
    'use strict';

    // Things to load:
    // 15% Info
    // 85% Items

    var exports = Marionette.ItemView.extend( {
        template: template

        , modelEvents: {
            'change:percentage': 'updateProgress'
        }

        , ui: {
            'progressBar': '.progress-bar'
            , 'srValue': '.sr-only .value'
        }

        , updateProgress: function() {
            var percentage = this.model.get( 'percentage' );
            this.ui.progressBar.attr( 'aria-valuenow' , percentage );
            this.ui.progressBar.css( 'width' , percentage + '%' );
            this.ui.srValue.text( percentage );
        }

        , onShowCalled: function() {
            var model = this.model;

            model.set( 'percentage' , 0 );

            function getInfo( next ) {
                var info = new Info();
                model.set( 'info' , info );

                info.fetch( {
                    success: function() {
                        model.set( 'percentage' , model.get( 'percentage' ) + 15 );

                        next();
                    }
                } );
            }

            function getAllItems( next ) {
                var items = model.get( 'items' ) || new Items();
                model.set( 'items' , items );

                items.fetch( {
                    success: next
                } );
                items.on( 'add' , function( modelAdded , collectionAddedTo , addOptions ) {
                    var itemCount = model.get( 'info' ).get( 'itemCount' ) + 1;
                    model.set( 'percentage' , ( model.get( 'percentage' ) + ( 85 / itemCount ) ) );
                } , this );
            }

            getInfo( function() {
                getAllItems( function() {
                    model.set( 'percentage' , 100 );
                } );
            } );
        }
    } );

    return exports;

} );

