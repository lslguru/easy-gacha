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
        }

        , modelEvents: {
            'change:payPrice': 'updateDisplay'
            , 'change:payPriceButton0': 'updateDisplay'
            , 'change:payPriceButton1': 'updateDisplay'
            , 'change:payPriceButton2': 'updateDisplay'
            , 'change:payPriceButton3': 'updateDisplay'
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
        }

        , priceButtonsContainerShown: false

        , onRender: function() {
            this.ui.tooltips.tooltip( {
                html: true
                , container: 'body'
                , placement: tooltipPlacement
            } );

            var img = $(payWindowImage).clone();
            this.ui.payPreviewBg.prepend( img );
            this.updateDisplay();

            this.listenTo( this.options.gacha.get( 'info_extra' ) , 'change:btn_price' , this.updateDisplay );
            this.listenTo( this.options.gacha.get( 'info_extra' ) , 'change:btn_default' , this.updateDisplay );
            this.listenTo( this.options.gacha.get( 'info_extra' ) , 'change:btn_0' , this.updateDisplay );
            this.listenTo( this.options.gacha.get( 'info_extra' ) , 'change:btn_1' , this.updateDisplay );
            this.listenTo( this.options.gacha.get( 'info_extra' ) , 'change:btn_2' , this.updateDisplay );
            this.listenTo( this.options.gacha.get( 'info_extra' ) , 'change:btn_3' , this.updateDisplay );
        }

        , updateDisplay: function() {
            var extra = this.model.get( 'info_extra' );
            var btn_price = extra.get( 'btn_price' );

            if( btn_price != this.ui.btn_price.val() ) {
                this.ui.btn_price.val( btn_price );
            }

            this.ui.btn_price.parent().removeClass( 'has-error' );

            _.each( [ 'default' , '0' , '1' , '2' , '3' ] , function( btn ) {
                if( extra.get( 'btn_' + btn ) != this.ui[ 'btn_' + btn ].val() ) {
                    this.ui[ 'btn_' + btn ].val( extra.get( 'btn_' + btn ) );
                }

                this.ui[ 'btn_' + btn ].parent().removeClass( 'has-error' );

                this.ui[ 'payPreview_' + btn ].text(
                    extra.get( 'btn_' + btn )
                    ? 'L$' + ( extra.get( 'btn_' + btn ) * btn_price )
                    : ''
                );

                this.ui[ 'payPreview_' + btn ].toggleClass( 'pay-hide' , !extra.get( 'btn_' + btn ) );
            } , this );

            // If it should be shown
            if( false === this.priceButtonsContainerShown && 0 !== btn_price ) {
                this.priceButtonsContainerShown = true;

                this.ui.priceButtonsContainer.removeClass( 'hide' );
                _.defer( _.bind( function() {
                    this.ui.priceButtonsContainer.addClass( 'in' );
                } , this ) );
            }

            // If it should be hidden
            if( true === this.priceButtonsContainerShown && 0 === btn_price ) {
                this.priceButtonsContainerShown = false;

                if( ! $.support.transition ) {
                    this.ui.priceButtonsContainer.addClass( 'hide' );
                } else {
                    this.ui.priceButtonsContainer.removeClass( 'in' );
                    this.ui.priceButtonsContainer.one( $.support.transition.end , _.bind( function() {
                        this.ui.priceButtonsContainer.addClass( 'hide' );
                    } , this ) );
                }
            }

            this.ui.payPreviewName.text( this.model.get( 'info' ).get( 'ownerDisplayName' ) + ' (' + this.model.get( 'info' ).get( 'ownerUserName' ) + ')' );
        }

        , setField: function( jEvent ) {
            var target = $( jEvent.currentTarget );
            var field = target.data( 'extra-field' );
            var val = parseInt( target.val() , 10 );

            if( _.isNaN( val ) ) {
                this.ui[ field ].parent().addClass( 'has-error' );
                return;
            }

            if( 0 > val ) {
                this.ui[ field ].parent().addClass( 'has-error' );
                return;
            }

            this.model.get( 'info_extra' ).set( field , val );
            this.setButtons();
            this.updateDisplay();
        }

        , setButtons: function() {
            var config = this.model.get( 'config' );
            var extra = this.model.get( 'info_extra' );
            var btn_price = extra.get( 'btn_price' );

            config.set( {
                payPrice: (
                    btn_price && extra.get( 'btn_default' )
                    ? btn_price * extra.get( 'btn_default' )
                    : CONSTANTS.PAY_HIDE
                )

                , payPriceButton0: (
                    btn_price && extra.get( 'btn_0' )
                    ? btn_price * extra.get( 'btn_0' )
                    : CONSTANTS.PAY_HIDE
                )

                , payPriceButton1: (
                    btn_price && extra.get( 'btn_1' )
                    ? btn_price * extra.get( 'btn_1' )
                    : CONSTANTS.PAY_HIDE
                )

                , payPriceButton2: (
                    btn_price && extra.get( 'btn_2' )
                    ? btn_price * extra.get( 'btn_2' )
                    : CONSTANTS.PAY_HIDE
                )

                , payPriceButton3: (
                    btn_price && extra.get( 'btn_3' )
                    ? btn_price * extra.get( 'btn_3' )
                    : CONSTANTS.PAY_HIDE
                )
            } );

            this.updateDisplay();
        }

    } );

    return exports;

} );
