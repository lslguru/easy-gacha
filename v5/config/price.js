define( [

    'underscore'
    , 'jquery'
    , 'marionette'
    , 'hbs!config/templates/price'
    , 'css!config/styles/price'
    , 'bootstrap'
    , 'lib/constants'
    , 'lib/tooltip-placement'
    , 'image!images/pay-window.png'
    , 'lib/fade'

] , function(

    _
    , $
    , Marionette
    , template
    , headerStyles
    , bootstrap
    , CONSTANTS
    , tooltipPlacement
    , payWindowImage
    , fade

) {
    'use strict';

    var exports = Marionette.ItemView.extend( {
        template: template

        , ui: {
            'tooltips': '[data-toggle=tooltip]'
            , 'btn_price': '#btn-price'
            , 'btn_default': '#btn-default'
            , 'btn_0': '#btn-0'
            , 'btn_1': '#btn-1'
            , 'btn_2': '#btn-2'
            , 'btn_3': '#btn-3'
            , 'priceButtonsContainer': '#price-buttons'
            , 'payPreviewBg': '#pay-preview-background'
            , 'payPreview_default': '#pay-preview-default'
            , 'payPreview_0': '#pay-preview-button-0'
            , 'payPreview_1': '#pay-preview-button-1'
            , 'payPreview_2': '#pay-preview-button-2'
            , 'payPreview_3': '#pay-preview-button-3'
            , 'payPreviewName': '#pay-preview-name'
            , 'payPriceZeroWarning': '#price-zero-warning'
            , 'payPriceZeroWarningClose': '#prize-zero-okay'
            , 'btnOrderWarning': '#buttons-not-ordered-warning'
            , 'btnOrderIgnore': '#ignore-buttons-out-of-order'
            , 'btnOrderFix': '#fix-button-order'
            , 'noPaymentsWarning': '#no-payment-options-warning'
        }

        , modelEvents: {
            'change:payPrice': 'updateDisplay'
            , 'change:payPriceButton0': 'updateDisplay'
            , 'change:payPriceButton1': 'updateDisplay'
            , 'change:payPriceButton2': 'updateDisplay'
            , 'change:payPriceButton3': 'updateDisplay'
            , 'change:btn_price': 'updateDisplay'
            , 'change:btn_default': 'updateDisplay'
            , 'change:btn_0': 'updateDisplay'
            , 'change:btn_1': 'updateDisplay'
            , 'change:btn_2': 'updateDisplay'
            , 'change:btn_3': 'updateDisplay'
            , 'change:zeroPriceOkay': 'updateDisplay'
            , 'change:suggestedButtonOrder': 'updateDisplay'
            , 'change:ignoreButtonsOutOfOrder': 'updateDisplay'
            , 'change:maxPerPurchase': 'updateDisplay'
        }

        , events: {
            'change #btn-price': 'setField'
            , 'keyup #btn-price': 'setField'
            , 'change #btn-default': 'setField'
            , 'keyup #btn-default': 'setField'
            , 'change #btn-0': 'setField'
            , 'keyup #btn-0': 'setField'
            , 'change #btn-1': 'setField'
            , 'keyup #btn-1': 'setField'
            , 'change #btn-2': 'setField'
            , 'keyup #btn-2': 'setField'
            , 'change #btn-3': 'setField'
            , 'keyup #btn-3': 'setField'
            , 'click @ui.payPriceZeroWarningClose': 'clearPayPriceWarning'
            , 'click @ui.btnOrderIgnore': 'clearButtonOrderWarning'
            , 'click @ui.btnOrderFix': 'fixButtonOrder'
        }

        , onRender: function() {
            this.ui.tooltips.tooltip( {
                html: true
                , container: 'body'
                , placement: tooltipPlacement
            } );

            var img = $(payWindowImage).clone();
            this.ui.payPreviewBg.prepend( img );
            this.setButtons();
            this.updateDisplay();
        }

        , effectiveCount: function( btn_val ) {
            btn_val = parseInt( btn_val , 10 );

            if( _.isNaN( btn_val ) ) {
                return 0;
            } else if( 0 > btn_val ) {
                return 0;
            } else if( CONSTANTS.MAX_PER_PURCHASE < btn_val ) {
                return Math.min( CONSTANTS.MAX_PER_PURCHASE , this.model.get( 'maxPerPurchase' ) );
            } else if( this.model.get( 'maxPerPurchase' ) < btn_val ) {
                return Math.min( CONSTANTS.MAX_PER_PURCHASE , this.model.get( 'maxPerPurchase' ) );
            }

            return btn_val;
        }

        , updateDisplay: function() {
            var warningStatus = false;
            var dangerStatus = false;

            var btn_price = this.model.get( 'btn_price' );

            if( '' === this.ui.btn_price.val() || btn_price != this.ui.btn_price.val() ) {
                this.ui.btn_price.val( btn_price );
            }

            btn_price = parseInt( btn_price , 10 );

            var btn_price_has_error = false;
            if( _.isNaN( btn_price ) ) {
                btn_price_has_error = true;
            } else if( 0 > btn_price ) {
                btn_price_has_error = true;
            }

            if( btn_price_has_error ) {
                dangerStatus = true;
                btn_price = 0;
            }

            this.ui.btn_price.parent().toggleClass( 'has-error' , btn_price_has_error );

            // Placeholder
            var hasPaymentOptions = false;

            // If it should be shown
            if( 0 !== btn_price ) {
                _.each( [ 'default' , '0' , '1' , '2' , '3' ] , function( btn ) {
                    var btn_val = this.model.get( 'btn_' + btn );
                    var btn_el = this.ui[ 'btn_' + btn ];
                    var hasError = false;

                    if( '' === btn_el.val() || btn_val != btn_el.val() ) {
                        btn_el.val( btn_val );
                    }

                    btn_val = parseInt( btn_val , 10 );

                    if( _.isNaN( btn_val ) ) {
                        hasError = true;
                    } else if( 0 > btn_val ) {
                        hasError = true;
                    } else if( CONSTANTS.MAX_PER_PURCHASE < btn_val ) {
                        hasError = true;
                    } else if( this.model.get( 'maxPerPurchase' ) < btn_val ) {
                        hasError = true;
                    }

                    btn_el.parent().toggleClass( 'has-error' , hasError );
                    if( hasError ) {
                        dangerStatus = true;
                    }

                    if( 0 < btn_val ) {
                        hasPaymentOptions = true;
                    }

                    btn_val = this.effectiveCount( btn_val );

                    this.ui[ 'payPreview_' + btn ].text(
                        btn_val
                        ? 'L$' + ( btn_val * btn_price )
                        : ''
                    );

                    this.ui[ 'payPreview_' + btn ].toggleClass( 'pay-hide' , !btn_val );

                } , this );

                // Show no-payments warning
                if( !hasPaymentOptions ) {
                    dangerStatus = true;
                }

                // Set the example-area owner name to the actual owner of this object
                this.ui.payPreviewName.text( this.model.get( 'ownerDisplayName' ) + ' (' + this.model.get( 'ownerUserName' ) + ')' );
            }

            // If there are payment options
            fade( this.ui.noPaymentsWarning , ( 0 !== btn_price && !hasPaymentOptions ) );

            // If it should be hidden
            fade( this.ui.priceButtonsContainer , ( 0 !== btn_price ) );

            // Show the zero-price message if needed
            if( 0 === this.model.get( 'btn_price' ) && !this.model.get( 'zeroPriceOkay' ) ) {
                fade( this.ui.payPriceZeroWarning , true );
                dangerStatus = true;
            } else {
                fade( this.ui.payPriceZeroWarning , false );
            }

            // Show or hide the button-out-of-order message
            if( 0 !== this.model.get( 'btn_price' ) && null !== this.model.get( 'suggestedButtonOrder' ) && !this.model.get( 'ignoreButtonsOutOfOrder' ) ) {
                fade( this.ui.btnOrderWarning , true );
                warningStatus = true;
            } else {
                fade( this.ui.btnOrderWarning , false );
            }

            // Update tab
            this.trigger( 'updateTabStatus' , (
                dangerStatus
                ? 'danger'
                : (
                    warningStatus
                    ? 'warning'
                    : null
                )
            ) );
        }

        , clearPayPriceWarning: function() {
            this.model.set( 'zeroPriceOkay' , true );
        }

        , clearButtonOrderWarning: function() {
            this.model.set( 'ignoreButtonsOutOfOrder' , true );
        }

        , fixButtonOrder: function() {
            var correctOrder = this.model.get( 'suggestedButtonOrder' );
            this.model.set( {
                btn_0: correctOrder[ 0 ]
                , btn_1: correctOrder[ 1 ]
                , btn_2: correctOrder[ 2 ]
                , btn_3: correctOrder[ 3 ]
            } );
        }

        , setField: function( jEvent ) {
            var target = $( jEvent.currentTarget );
            var field = target.data( 'extra-field' );
            var val = parseInt( target.val() , 10 );

            if( _.isNaN( val ) ) {
                this.model.set( field , target.val() );
            } else {
                this.model.set( field , val );
            }

            this.setButtons();
            this.updateDisplay();
        }

        , setButtons: function() {
            var btn_price = this.model.get( 'btn_price' );

            this.model.set( {
                payPrice: (
                    btn_price && this.effectiveCount( this.model.get( 'btn_default' ) )
                    ? btn_price * this.effectiveCount( this.model.get( 'btn_default' ) )
                    : CONSTANTS.PAY_HIDE
                )

                , payPriceButton0: (
                    btn_price && this.effectiveCount( this.model.get( 'btn_0' ) )
                    ? btn_price * this.effectiveCount( this.model.get( 'btn_0' ) )
                    : CONSTANTS.PAY_HIDE
                )

                , payPriceButton1: (
                    btn_price && this.effectiveCount( this.model.get( 'btn_1' ) )
                    ? btn_price * this.effectiveCount( this.model.get( 'btn_1' ) )
                    : CONSTANTS.PAY_HIDE
                )

                , payPriceButton2: (
                    btn_price && this.effectiveCount( this.model.get( 'btn_2' ) )
                    ? btn_price * this.effectiveCount( this.model.get( 'btn_2' ) )
                    : CONSTANTS.PAY_HIDE
                )

                , payPriceButton3: (
                    btn_price && this.effectiveCount( this.model.get( 'btn_3' ) )
                    ? btn_price * this.effectiveCount( this.model.get( 'btn_3' ) )
                    : CONSTANTS.PAY_HIDE
                )
            } );

            this.updateDisplay();
        }

    } );

    return exports;

} );
