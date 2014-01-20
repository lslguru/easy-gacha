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
            this.constructor.__super__.initialize.apply( this , arguments );
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
