define( [

    'underscore'
    , 'jquery'
    , 'marionette'
    , 'hbs!config/templates/advanced'
    , 'css!config/styles/advanced'
    , 'bootstrap'
    , 'lib/constants'
    , 'lib/tooltip-placement'

] , function(

    _
    , $
    , Marionette
    , template
    , headerStyles
    , bootstrap
    , CONSTANTS
    , tooltipPlacement

) {
    'use strict';

    var exports = Marionette.ItemView.extend( {
        template: template

        , ui: {
            'tooltips': '[data-toggle=tooltip]'
            , 'folderName': '#folder-name'
            , 'folderForSingleItemOff': '#always-folder-off'
            , 'folderForSingleItemOn': '#always-folder-on'
            , 'maxBuysUnlimited': '#max-buys-unlimited'
            , 'maxBuysLimited': '#max-buys-limited'
            , 'maxBuysLimit': '#max-buys-count'
            , 'maxPerPurchase': '#max-per-purchase-count'
            , 'groupOff': '#group-off'
            , 'groupOn': '#group-on'
            , 'rootClickOff': '#root-click-off'
            , 'rootClickOn': '#root-click-on'
        }

        , events: {
            'change #folder-name': 'setFolderName'
            , 'click #always-folder-off': 'setFolderForSingleItem'
            , 'click #always-folder-on': 'setFolderForSingleItem'
            , 'click #max-buys-unlimited': 'toggleMaxBuysLimited'
            , 'click #max-buys-limited': 'toggleMaxBuysLimited'
            , 'change #max-buys-count': 'setMaxBuysCount'
            , 'keyup #max-buys-count': 'setMaxBuysCount'
            , 'change #max-per-purchase-count': 'setMaxPerPurchase'
            , 'keyup #max-per-purchase-count': 'setMaxPerPurchase'
            , 'click #group-off': 'setGroup'
            , 'click #group-on': 'setGroup'
            , 'click #root-click-off': 'setRootClickAction'
            , 'click #root-click-on': 'setRootClickAction'
        }

        , modelEvents: {
            'change:folderForSingleItem': 'updateFolderForSingleItem'
            , 'change:maxBuys': 'updateMaxBuys'
            , 'change:maxPerPurchase': 'updateMaxPerPurchase'
            , 'change:group': 'updateGroup'
            , 'change:rootClickAction': 'updateRootClickAction'
        }

        , templateHelpers: function() {
            return {
                isRootOrOnlyPrim: (
                    1 === this.options.gacha.get( 'info' ).get( 'numberOfPrims' )
                    || CONSTANTS.LINK_ROOT === this.options.gacha.get( 'info' ).get( 'scriptLinkNumber' )
                )

                , MAX_PER_PURCHASE: CONSTANTS.MAX_PER_PURCHASE
            };
        }

        , onRender: function() {
            this.ui.tooltips.tooltip( {
                html: true
                , container: 'body'
                , placement: tooltipPlacement
            } );

            this.ui.folderName.val( this.options.gacha.get( 'info' ).get( 'primName' ) );
            this.updateFolderForSingleItem();
            this.updateMaxBuys();
            this.updateMaxPerPurchase();
            this.updateGroup();
            this.updateRootClickAction();
        }

        , setFolderName: function() {
            this.model.set( 'setFolderName' , this.ui.folderName.val() );
        }

        , updateFolderForSingleItem: function() {
            if( this.model.get( 'folderForSingleItem' ) ) {
                this.ui.folderForSingleItemOff.removeClass( 'active' );
                this.ui.folderForSingleItemOn.addClass( 'active' );
            } else {
                this.ui.folderForSingleItemOff.addClass( 'active' );
                this.ui.folderForSingleItemOn.removeClass( 'active' );
            }
        }

        , setFolderForSingleItem: function( jEvent ) {
            var target = $( jEvent.currentTarget );
            var newValue = Boolean( parseInt( target.data( 'value' ) , 10 ) );
            this.model.set( 'folderForSingleItem' , newValue );
        }

        , updateMaxBuys: function() {
            if( -1 == this.model.get( 'maxBuys' ) ) {
                this.ui.maxBuysUnlimited.addClass( 'active' );
                this.ui.maxBuysLimited.removeClass( 'active' );
                this.ui.maxBuysLimit.prop( 'disabled' , 'disabled' );
                this.ui.maxBuysLimit.val( '' );
                this.ui.maxBuysLimit.parent().removeClass( 'has-error' );
            } else {
                this.ui.maxBuysUnlimited.removeClass( 'active' );
                this.ui.maxBuysLimited.addClass( 'active' );
                this.ui.maxBuysLimit.prop( 'disabled' , '' );
                this.ui.maxBuysLimit.val( this.model.get( 'maxBuys' ) );
                this.ui.maxBuysLimit.parent().removeClass( 'has-error' );
            }
        }

        , toggleMaxBuysLimited: function( jEvent ) {
            var target = $( jEvent.currentTarget );
            if( target.data( 'limited' ) ) {
                this.model.set( 'maxBuys' , 0 );
            } else {
                this.model.set( 'maxBuys' , -1 );
            }
        }

        , setMaxBuysCount: function( jEvent ) {
            // In case we're not picking up an event from setting this to
            // unlimited
            if( -1 === this.model.get( 'maxBuys' ) ) {
                return;
            }

            // Get parsed value
            var newValue = parseInt( this.ui.maxBuysLimit.val() , 10 );

            // Make sure it's a number
            if( _.isNaN( newValue ) ) {
                this.ui.maxBuysLimit.parent().addClass( 'has-error' );
                return;
            } else {
                this.ui.maxBuysLimit.parent().removeClass( 'has-error' );
            }

            // If out of bounds
            if( newValue < 0 ) {
                this.ui.maxBuysLimit.parent().addClass( 'has-error' );
                return;
            }

            this.model.set( 'maxBuys' , newValue );
        }

        , updateMaxPerPurchase: function() {
            this.ui.maxPerPurchase.val( this.model.get( 'maxPerPurchase' ) );
            this.ui.maxPerPurchase.parent().removeClass( 'has-error' );
        }

        , setMaxPerPurchase: function( jEvent ) {
            // Get parse value
            var newValue = parseInt( this.ui.maxPerPurchase.val() , 10 );

            // Make sure it's a number
            if( _.isNaN( newValue ) ) {
                this.ui.maxPerPurchase.parent().addClass( 'has-error' );
                return;
            } else {
                this.ui.maxPerPurchase.parent().removeClass( 'has-error' );
            }

            // If out of bounds
            if( newValue < 1 || newValue > CONSTANTS.MAX_PER_PURCHASE ) {
                this.ui.maxPerPurchase.parent().addClass( 'has-error' );
                return;
            }

            this.model.set( 'maxPerPurchase' , newValue );
        }

        , updateGroup: function() {
            if( this.model.get( 'group' ) ) {
                this.ui.groupOff.removeClass( 'active' );
                this.ui.groupOn.addClass( 'active' );
            } else {
                this.ui.groupOff.addClass( 'active' );
                this.ui.groupOn.removeClass( 'active' );
            }
        }

        , setGroup: function( jEvent ) {
            var target = $( jEvent.currentTarget );
            var newValue = Boolean( parseInt( target.data( 'value' ) , 10 ) );
            this.model.set( 'group' , newValue );
        }

        , updateRootClickAction: function() {
            if( -1 === this.model.get( 'rootClickAction' ) ) {
                this.ui.rootClickOff.removeClass( 'active' );
                this.ui.rootClickOn.removeClass( 'active' );
            } else if( 0 === this.model.get( 'rootClickAction' ) ) {
                this.ui.rootClickOff.addClass( 'active' );
                this.ui.rootClickOn.removeClass( 'active' );
            } else if( 1 === this.model.get( 'rootClickAction' ) ) {
                this.ui.rootClickOff.removeClass( 'active' );
                this.ui.rootClickOn.addClass( 'active' );
            }
        }

        , setRootClickAction: function( jEvent ) {
            var target = $( jEvent.currentTarget );
            var newValue = parseInt( target.data( 'value' ) , 10 );
            this.model.set( 'rootClickAction' , newValue );
        }

    } );

    return exports;

} );
