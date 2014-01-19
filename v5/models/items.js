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

            this.on( 'add' , this.updateTotals , this );
            this.on( 'remove' , this.updateTotals , this );
            this.on( 'reset' , this.updateTotals , this );
            this.on( 'change:rarity' , this.updateTotals , this );
            this.on( 'change:limit' , this.updateTotals , this );
            this.on( 'change:bought' , this.updateTotals , this );
            this.updateTotals();
        }

        , updateTotals: function() {
            this.totalRarity = 0;
            this.unlimitedRarity = 0;
            this.totalBought = 0;
            this.totalLimit = 0;

            _.each( this.models , function( model ) {
                this.totalBought += model.get( 'bought' );

                if( CONSTANTS.PERM_TRANSFER & model.get( 'ownerPermissions' ) ) {
                    if( 0 !== model.get( 'limit' ) ) {
                        this.totalRarity += model.get( 'rarity' );
                    }

                    if( -1 === model.get( 'limit' ) ) {
                        this.unlimitedRarity += model.get( 'rarity' );
                    } else {
                        this.totalLimit += model.get( 'limit' );
                    }
                }
            } , this );
        }

        // Given an inventory list, create corresponding Item models
        , populate: function( invs , scriptName ) {
            var hadItemsAtStart = Boolean( this.length );

            invs.each( function( inv ) {
                if( ! this.get( inv.id ) && inv.id !== scriptName ) {
                    var model = new this.model();

                    _.each( inv.attributes , function( value , key ) {
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
                            Boolean( model.get( 'ownerPermissions' ) & CONSTANTS.PERM_TRANSFER ) // bitwise intentional
                            ?  (
                                Boolean( model.get( 'ownerPermissions' ) & CONSTANTS.PERM_COPY ) // bitwise intentional
                                ? CONSTANTS.DEFAULT_ITEM_LIMIT_COPY
                                : CONSTANTS.DEFAULT_ITEM_LIMIT_NOCOPY
                            )
                            : 0 // no trans
                        )

                        , bought: 0
                    } );

                    this.add( model );
                }
            } , this );
        }

        , toNotecardJSON: function() {
            var json = this.constructor.__super__.toNotecardJSON.apply( this , arguments );

            json = _.filter( json , function( item ) {
                return ( 0 !== item.limit && 0 !== item.rarity );
            } );

            return json;
        }
    } );

    return exports;
} );
