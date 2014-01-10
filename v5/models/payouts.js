define( [

    'models/base-sl-collection'
    , 'models/payout'

] , function(

    BaseCollection
    , Payout

) {
    'use strict';

    var exports = BaseCollection.extend( {
        model: Payout

        , initialize: function() {
            BaseCollection.prototype.initialize.apply( this , arguments );

            this.bind( 'reset' , function() {
                this.totalPrice = 0;
            } , this );

            this.bind( 'add' , function( model ) {
                this.totalPrice += model.get( 'amount' );
            } , this );
        }
    } );

    return exports;
} );
