define( [

    'models/base-sl-collection'
    , 'models/item'

] , function(

    BaseCollection
    , Item

) {
    'use strict';

    var exports = BaseCollection.extend( {
        model: Item

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
    } );

    return exports;
} );
