define( [

    'marionette'
    , 'hbs!dashboard/templates/loader'
    , 'css!dashboard/styles/loader'
    , 'css!vendor/absolute-center'
    , 'bootstrap'
    , 'models/info'
    , 'models/username'
    , 'models/displayname'
    , 'models/items'
    , 'backbone'

] , function(

    Marionette
    , template
    , styles
    , absoluteCenterStyles
    , bootstrap
    , Info
    , UserName
    , DisplayName
    , Items
    , Backbone

) {
    'use strict';

    // Things to load:
    // 5% Info
    // 5% Owner UserName
    // 5% Owner DisplayName
    // 85% Items

    var exports = Marionette.ItemView.extend( {
        template: template

        , modelEvents: {
            'change': 'render'
        }

        , onShowCalled: function() {
            var model = this.model;

            model.set( 'percentage' , 0 );

            function getInfo( next ) {
                var info = new Info();
                model.set( 'info' , info );

                info.fetch( {
                    success: function() {
                        model.set( 'percentage' , model.get( 'percentage' ) + 5 );

                        next();
                    }
                } );
            }

            function getUserName( next ) {
                var ownerUserName = new UserName( {
                    lookup: model.get( 'info' ).get( 'ownerKey' )
                } );
                model.set( 'ownerUserName' , ownerUserName );

                ownerUserName.fetch( {
                    success: function() {
                        model.set( 'percentage' , model.get( 'percentage' ) + 5 );
                        model.get( 'info' ).set( 'ownerUserName' , ownerUserName.get( 'result' ) );

                        next();
                    }
                } );
            }

            function getDisplayName( next ) {
                var ownerDisplayName = new DisplayName( {
                    lookup: model.get( 'info' ).get( 'ownerKey' )
                } );
                model.set( 'ownerDisplayName' , ownerDisplayName );

                ownerDisplayName.fetch( {
                    success: function() {
                        model.set( 'percentage' , model.get( 'percentage' ) + 5 );
                        model.get( 'info' ).set( 'ownerDisplayName' , ownerDisplayName.get( 'result' ) );

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
                items.bind( 'add' , function( modelAdded , collectionAddedTo , addOptions ) {
                    model.set( 'percentage' , model.get( 'percentage' ) + ( 85 / model.get( 'info' ).get( 'itemCount' ) ) );
                } , this );
            }

            getInfo( function() {
                getUserName( function() { 
                    getDisplayName( function() { 
                        getAllItems( function() { 
                            model.set( 'percentage' , 100 );
                        } );
                    } );
                } );
            } );
        }
    } );

    return exports;

} );

