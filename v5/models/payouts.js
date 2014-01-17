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

            this.on( 'reset' , this.updateTotalPrice , this );
            this.on( 'add' , this.updateTotalPrice , this );
            this.on( 'remove' , this.updateTotalPrice , this );
            this.on( 'change:amount' , this.updateTotalPrice , this );
        }

        , updateTotalPrice: function() {
            this.totalPrice = this.reduce( function( memo , model ) {
                return memo + model.get( 'amount' )
            } , 0 );
        }
    } );

    return exports;
} );
