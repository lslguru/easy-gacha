define( [

    'marionette'
    , 'hbs!templates/loader'
    , 'css!styles/loader'
    , 'bootstrap'
    , 'models/info'
    , 'models/config'
    , 'models/items'
    , 'models/payouts'
    , 'models/invs'

] , function(

    Marionette
    , template
    , styles
    , bootstrap
    , Info
    , Config
    , Items
    , Payouts
    , Invs

) {
    'use strict';

    // Things to load:
    // 10% Info
    // 10% Config
    // 20% Payouts
    // 30% Items
    // 30% Items

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
                        model.set( 'percentage' , model.get( 'percentage' ) + 10 );

                        next();
                    }
                } );
            }

            function getConfig( next ) {
                var config = new Config();
                model.set( 'config' , config );

                config.fetch( {
                    success: function() {
                        model.set( 'percentage' , model.get( 'percentage' ) + 10 );

                        next();
                    }
                } );
            }

            function getAllPayouts( next ) {
                var payouts = model.get( 'payouts' ) || new Payouts();
                model.set( 'payouts' , payouts );

                payouts.fetch( {
                    success: next
                } );
                payouts.bind( 'add' , function( modelAdded , collectionAddedTo , addOptions ) {
                    var payoutCount = model.get( 'info' ).get( 'payoutCount' ) + 1;
                    model.set( 'percentage' , ( model.get( 'percentage' ) + ( 20 / payoutCount ) ) );
                } , this );
            }

            function getAllItems( next ) {
                var items = model.get( 'items' ) || new Items();
                model.set( 'items' , items );

                items.fetch( {
                    success: next
                } );
                items.bind( 'add' , function( modelAdded , collectionAddedTo , addOptions ) {
                    var itemCount = model.get( 'info' ).get( 'itemCount' ) + 1;
                    model.set( 'percentage' , ( model.get( 'percentage' ) + ( 30 / itemCount ) ) );
                } , this );
            }

            function getAllInv( next ) {
                var invs = model.get( 'invs' ) || new Invs();
                model.set( 'invs' , invs );

                invs.fetch( {
                    success: next
                } );
                invs.bind( 'add' , function( modelAdded , collectionAddedTo , addOptions ) {
                    var invCount = model.get( 'info' ).get( 'inventoryCount' ) + 1;
                    model.set( 'percentage' , ( model.get( 'percentage' ) + ( 30 / invCount ) ) );
                } , this );
            }

            getInfo( function() {
                getConfig( function() {
                    getAllPayouts( function() {
                        getAllItems( function() {
                            getAllInv( function() {
                                model.set( 'percentage' , 100 );
                            } );
                        } );
                    } );
                } );
            } );
        }
    } );

    return exports;

} );

