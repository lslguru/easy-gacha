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
            , 'button_price': '#button-price'
            , 'button_default': '#button-default'
            , 'button_0': '#button-0'
            , 'button_1': '#button-1'
            , 'button_2': '#button-2'
            , 'button_3': '#button-3'
            , 'payFields': '.pay-field'
            , 'priceButtonsContainer': '#price-buttons'
            , 'payPreviewFields': '.pay-preview-field'
            , 'payPreviewBg': '#pay-preview-background'
            , 'payPreview_default': '#pay-preview-default'
            , 'payPreview_0': '#pay-preview-button-0'
            , 'payPreview_1': '#pay-preview-button-1'
            , 'payPreview_2': '#pay-preview-button-2'
            , 'payPreview_3': '#pay-preview-button-3'
            , 'payPreviewName': '#pay-preview-name'
            , 'payPriceZeroWarning': '#price-zero-warning'
            , 'payPriceZeroWarningClose': '#prize-zero-okay'
            , 'buttonOrderWarning': '#buttons-not-ordered-warning'
            , 'buttonOrderIgnore': '#ignore-buttons-out-of-order'
            , 'buttonOrderFix': '#fix-button-order'
            , 'noPaymentsWarning': '#no-payment-options-warning'
            , 'oneItemModeWarning': '#plays-fixed-because-no-copy'
            , 'ackNoCopyWarning': '#ack-no-copy-items-means-single-item-play'
        }

        , modelEvents: {
            'change:payPrice': 'updateDisplay'
            , 'change:payPriceButton0': 'updateDisplay'
            , 'change:payPriceButton1': 'updateDisplay'
            , 'change:payPriceButton2': 'updateDisplay'
            , 'change:payPriceButton3': 'updateDisplay'
            , 'change:button_price': 'updateDisplay'
            , 'change:button_default': 'updateDisplay'
            , 'change:button_0': 'updateDisplay'
            , 'change:button_1': 'updateDisplay'
            , 'change:button_2': 'updateDisplay'
            , 'change:button_3': 'updateDisplay'
            , 'change:zeroPriceOkay': 'updateDisplay'
            , 'change:suggestedButtonOrder': 'updateDisplay'
            , 'change:ignoreButtonsOutOfOrder': 'updateDisplay'
            , 'change:maxPerPurchase': 'updateDisplay'
            , 'change:willHandOutNoCopyObjects': 'updateDisplay'
            , 'change:ackNoCopyItemsMeansSingleItemPlay': 'updateDisplay'
        }

        , events: {
            'change @ui.button_price': 'setField'
            , 'keyup @ui.button_price': 'setField'
            , 'change @ui.button_default': 'setField'
            , 'keyup @ui.button_default': 'setField'
            , 'change @ui.button_0': 'setField'
            , 'keyup @ui.button_0': 'setField'
            , 'change @ui.button_1': 'setField'
            , 'keyup @ui.button_1': 'setField'
            , 'change @ui.button_2': 'setField'
            , 'keyup @ui.button_2': 'setField'
            , 'change @ui.button_3': 'setField'
            , 'keyup @ui.button_3': 'setField'
            , 'click @ui.payPriceZeroWarningClose': 'clearPayPriceWarning'
            , 'click @ui.buttonOrderIgnore': 'clearButtonOrderWarning'
            , 'click @ui.buttonOrderFix': 'fixButtonOrder'
            , 'click @ui.ackNoCopyWarning': 'ackNoCopyWarning'
            , 'click @ui.payPreviewFields': 'focusOnPayField'
            , 'focus @ui.payFields': 'onPayFieldFocus'
            , 'blur @ui.payFields': 'onPayFieldBlur'
        }

        , onRender: function() {
            this.ui.tooltips.tooltip( {
                html: true
                , container: 'body'
                , placement: tooltipPlacement
            } );

            var img = $(payWindowImage).clone();
            this.ui.payPreviewBg.prepend( img );
            this.updateDisplay();
        }

        , updateDisplay: function() {
            var warningStatus = false;
            var dangerStatus = false;

            var button_price = this.model.get( 'button_price' );

            if( '' === this.ui.button_price.val() || button_price != this.ui.button_price.val() ) {
                this.ui.button_price.val( button_price );
            }

            button_price = parseInt( button_price , 10 );

            var button_price_has_error = false;
            if( _.isNaN( button_price ) ) {
                button_price_has_error = true;
            } else if( 0 > button_price ) {
                button_price_has_error = true;
            }

            if( button_price_has_error ) {
                dangerStatus = true;
                button_price = 0;
            }

            this.ui.button_price.parent().toggleClass( 'has-error' , button_price_has_error );

            // Placeholder
            var hasPaymentOptions = false;

            // If it should be shown
            if( 0 !== button_price ) {
                _.each( [ 'default' , '0' , '1' , '2' , '3' ] , function( button ) {
                    var button_val = this.model.get( 'button_' + button );
                    var button_el = this.ui[ 'button_' + button ];
                    var hasError = false;

                    if( '' === button_el.val() || button_val != button_el.val() ) {
                        button_el.val( button_val );
                    }

                    button_val = parseInt( button_val , 10 );

                    if( _.isNaN( button_val ) ) {
                        hasError = true;
                    } else if( 0 > button_val ) {
                        hasError = true;
                    } else if( CONSTANTS.MAX_PER_PURCHASE < button_val ) {
                        hasError = true;
                    } else if( this.model.get( 'maxPerPurchase' ) < button_val ) {
                        hasError = true;
                    }

                    button_el.parent().toggleClass( 'has-error' , hasError );
                    if( hasError ) {
                        dangerStatus = true;
                    }

                    if( 0 < button_val ) {
                        hasPaymentOptions = true;
                    }

                    button_val = this.model.effectiveButtonCount( button_val );

                    this.ui[ 'payPreview_' + button ].text(
                        button_val
                        ? 'L$' + ( button_val * button_price )
                        : ''
                    );

                    this.ui[ 'payPreview_' + button ].toggleClass( 'pay-hide' , !button_val );

                } , this );

                // Show no-payments warning
                if( !hasPaymentOptions ) {
                    dangerStatus = true;
                }

                // Set the example-area owner name to the actual owner of this object
                this.ui.payPreviewName.text( this.model.get( 'ownerDisplayName' ) + ' (' + this.model.get( 'ownerUserName' ) + ')' );
            }

            // If there are payment options
            fade( this.ui.noPaymentsWarning , ( 0 !== button_price && !hasPaymentOptions ) );

            // If it should be hidden
            fade( this.ui.priceButtonsContainer , ( 0 !== button_price ) );

            // Show the zero-price message if needed
            if( 0 === this.model.get( 'button_price' ) && !this.model.get( 'zeroPriceOkay' ) ) {
                fade( this.ui.payPriceZeroWarning , true );
                dangerStatus = true;
            } else {
                fade( this.ui.payPriceZeroWarning , false );
            }

            // Show or hide the button-out-of-order message
            if( 0 !== this.model.get( 'button_price' ) && null !== this.model.get( 'suggestedButtonOrder' ) && !this.model.get( 'ignoreButtonsOutOfOrder' ) ) {
                fade( this.ui.buttonOrderWarning , true );
                warningStatus = true;
            } else {
                fade( this.ui.buttonOrderWarning , false );
            }

            // Show or hide the limited play message
            if( 0 !== this.model.get( 'button_price' ) && this.model.get( 'willHandOutNoCopyObjects' ) && !this.model.get( 'ackNoCopyItemsMeansSingleItemPlay' ) ) {
                fade( this.ui.oneItemModeWarning , true );
                warningStatus = true;
            } else {
                fade( this.ui.oneItemModeWarning , false );
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

        , ackNoCopyWarning: function() {
            this.model.set( 'ackNoCopyItemsMeansSingleItemPlay' , true );
        }

        , clearButtonOrderWarning: function() {
            this.model.set( 'ignoreButtonsOutOfOrder' , true );
        }

        , fixButtonOrder: function() {
            var correctOrder = this.model.get( 'suggestedButtonOrder' );
            this.model.set( {
                button_0: correctOrder[ 0 ]
                , button_1: correctOrder[ 1 ]
                , button_2: correctOrder[ 2 ]
                , button_3: correctOrder[ 3 ]
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

            this.updateDisplay();
        }

        , focusOnPayField: function( jEvent ) {
            var target = $( jEvent.currentTarget );
            var field = target.data( 'preview-of-field' );
            this.$el.find( field ).focus();
        }

        , onPayFieldFocus: function( jEvent ) {
            var target = $( jEvent.currentTarget );
            var preview = target.data( 'preview-el' );
            this.$el.find( preview ).addClass( 'focus' );
        }

        , onPayFieldBlur: function( jEvent ) {
            var target = $( jEvent.currentTarget );
            var preview = target.data( 'preview-el' );
            this.$el.find( preview ).removeClass( 'focus' );
        }

    } );

    return exports;

} );
