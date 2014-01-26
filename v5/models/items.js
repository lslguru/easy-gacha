define( [

    'underscore'
    , 'models/base-sl-collection'
    , 'models/item'
    , 'lib/constants'
    , 'models/agents-cache'

] , function(

    _
    , BaseCollection
    , Item
    , CONSTANTS
    , agentsCache

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
                // Never add the script
                if( inv.id === scriptName ) {
                    // Let the cache know this is the creator of this script
                    agentsCache.fetch( {
                        id: inv.get( 'creator' )
                        , scriptCreator: true
                    } );

                    return;
                }

                // Use existing, otherwise create
                var model = this.get( inv.id ) || new this.model();

                // Import all inv settings
                model.set( inv.attributes );

                // If it's new
                if( ! this.get( inv.id ) ) {
                    // Set first-seen values
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

                    // Add to collection because it's new
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

        , getChecked: function() {
            return this.filter( function( item ) {
                return item.get( 'selectedForBatchOperation' );
            } );
        }

    } );

    return exports;
} );
