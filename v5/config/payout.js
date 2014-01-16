define( [

    'underscore'
    , 'jquery'
    , 'marionette'
    , 'hbs!config/templates/payout'
    , 'css!config/styles/payout'
    , 'lib/constants'
    , 'lib/tooltip-placement'
    , 'bootstrap'

] , function(

    _
    , $
    , Marionette
    , template
    , styles
    , CONSTANTS
    , tooltipPlacement
    , bootstrap

) {
    'use strict';

    var exports = Marionette.ItemView.extend( {
        template: template
        , tagName: 'tr'

        , ui: {
            'tooltips': '[data-toggle=tooltip]'
            , 'amount': '.payout-amount'
            , 'deleteBtn': '.payout-delete-btn'
        }

        , events: {
            'keyup .payout-amount': 'setAmount'
            , 'change .payout-amount': 'setAmount'
            , 'click .payout-delete-btn': 'deletePayout'
        }

        , modelEvents: {
            'change:amount': 'updateAmount'
        }

        , onRender: function() {
            this.ui.tooltips.tooltip( {
                html: true
                , container: 'body'
                , placement: tooltipPlacement
            } );

            // If this record is the owner, they may not change it because it
            // is calculated on the fly based on the total price
            if( this.options.gacha.get( 'info' ).get( 'ownerKey' ) === this.model.get( 'agentKey' ) ) {
                this.ui.deleteBtn.remove();
                this.ui.amount.attr( 'readonly' , 'readonly' );

                this.options.gacha.get( 'info' ).on( 'change:extra' , this.recalculateOwnerAmount , this );
                this.options.gacha.get( 'payouts' ).on( 'add' , this.recalculateOwnerAmount , this );
                this.options.gacha.get( 'payouts' ).on( 'remove' , this.recalculateOwnerAmount , this );
                this.options.gacha.get( 'payouts' ).on( 'reset' , this.recalculateOwnerAmount , this );
                this.options.gacha.get( 'payouts' ).on( 'change:amount' , this.recalculateOwnerAmount , this );
            }

            this.ui.amount.val( '0' ); // In case no amount is set
            this.updateAmount();
        }

        , recalculateOwnerAmount: function() {
            this.model.set( 'amount' , (
                // The new price
                this.options.gacha.get( 'info' ).get( 'extra' ).btn_price

                // Minus the total of all payouts
                - this.model.collection.reduce( function( memo , model ) {
                    return memo + model.get( 'amount' );
                } , 0 )

                // But don't count the owner in total payouts
                + this.model.get( 'amount' )
            ) );

            if( 0 > this.model.get( 'amount' ) ) {
                this.ui.amount.parent().addClass( 'has-error' );
            }
        }

        , updateAmount: function() {
            this.ui.amount.parent().removeClass( 'has-error' );

            if( this.ui.amount.val() != this.model.get( 'amount' ) ) {
                this.ui.amount.val( this.model.get( 'amount' ) );
            }
        }

        , deletePayout: function() {
            this.model.collection.remove( this.model );
        }

        , setAmount: function( jEvent ) {
            var target = $( jEvent.currentTarget );
            var val = parseInt( target.val() , 10 );

            if( _.isNaN( val ) ) {
                this.ui.amount.parent().addClass( 'has-error' );
                return;
            }

            if( 0 > val ) {
                this.ui.amount.parent().addClass( 'has-error' );
                return;
            }

            this.model.set( 'amount' , val );
            this.updateAmount();
        }
    } );

    return exports;

} );
