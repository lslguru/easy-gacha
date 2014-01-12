define( [

    'underscore'
    , 'models/base-sl-collection'
    , 'models/item'
    , 'lib/constants'

] , function(

    _
    , BaseCollection
    , Item
    , CONSTANTS

) {
    'use strict';

    var exports = BaseCollection.extend( {
        model: Item
        , comparator: 'name'

        , initialize: function() {
            BaseCollection.prototype.initialize.apply( this , arguments );

            this.bind( 'reset' , function() {
                this.totalRarity = 0;
                this.totalBought = 0;
                this.totalLimit = 0;
            } , this );

            this.bind( 'add' , function( model ) {
                this.totalRarity += model.get( 'rarity' );
                this.totalBought += model.get( 'bought' );

                if( -1 !== model.get( 'limit' ) ) {
                    this.totalLimit += model.get( 'limit' );
                }
            } , this );
        }

        // Given an inventory list, create corresponding Item models
        , populate: function( foreignCollection ) {
            var hadItemsAtStart = Boolean( this.length );

            foreignCollection.each( function( foreignModel ) {
                if( ! this.get( foreignModel.id ) ) {
                    var model = new this.model();

                    _.each( foreignModel.attributes , function( value , key ) {
                        if( key in model.attributes ) {
                            model.set( key , value );
                        }
                    } , this );

                    model.set( {
                        rarity: (
                            hadItemsAtStart
                            ? CONSTANTS.DEFAULT_ITEM_RARITY
                            : CONSTANTS.DEFAULT_ITEM_RARITY_INIT
                        )

                        , limit: (
                            Boolean( model.get( 'ownerPermissions' ) & CONSTANTS.PERM_COPY ) // bitwise intentional
                            ? CONSTANTS.DEFAULT_ITEM_LIMIT_COPY
                            : CONSTANTS.DEFAULT_ITEM_LIMIT_NOCOPY
                        )

                        , bought: 0
                    } );

                    this.add( model );
                }
            } , this );
        }
    } );

    return exports;
} );
