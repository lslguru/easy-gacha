define( [

    'underscore'
    , 'jquery'
    , 'marionette'
    , 'hbs!config/templates/advanced'
    , 'css!config/styles/advanced'
    , 'bootstrap'
    , 'lib/constants'
    , 'lib/tooltip-placement'
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
    , fade

) {
    'use strict';

    var exports = Marionette.ItemView.extend( {
        template: template

        , ui: {
            'tooltips': '[data-toggle=tooltip]'
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
            , 'rootClickWarning': '#root-prim-choice-needed-warning'
            , 'apiPerPlayOff': '#api-signal-play-off'
            , 'apiPerPlayOn': '#api-signal-play-on'
            , 'apiPerItemOff': '#api-signal-item-off'
            , 'apiPerItemOn': '#api-signal-item-on'
        }

        , events: {
            'click @ui.folderForSingleItemOff': 'setFolderForSingleItem'
            , 'click @ui.folderForSingleItemOn': 'setFolderForSingleItem'
            , 'click @ui.maxBuysUnlimited': 'toggleMaxBuysLimited'
            , 'click @ui.maxBuysLimited': 'toggleMaxBuysLimited'
            , 'change @ui.maxBuysLimit': 'setMaxBuysCount'
            , 'keyup @ui.maxBuysLimit': 'setMaxBuysCount'
            , 'change @ui.maxPerPurchase': 'setMaxPerPurchase'
            , 'keyup @ui.maxPerPurchase': 'setMaxPerPurchase'
            , 'click @ui.groupOff': 'setGroup'
            , 'click @ui.groupOn': 'setGroup'
            , 'click @ui.rootClickOff': 'setRootClickAction'
            , 'click @ui.rootClickOn': 'setRootClickAction'
            , 'click @ui.apiPerPlayOff': 'setBooleanField'
            , 'click @ui.apiPerPlayOn': 'setBooleanField'
            , 'click @ui.apiPerItemOff': 'setBooleanField'
            , 'click @ui.apiPerItemOn': 'setBooleanField'
        }

        , modelEvents: {
            'change:folderForSingleItem': 'updateFolderForSingleItem'
            , 'change:maxBuys': 'updateMaxBuys'
            , 'change:maxPerPurchase': 'updateMaxPerPurchase'
            , 'change:group': 'updateGroup'
            , 'change:rootClickAction': 'updateRootClickAction'
            , 'change:scriptLinkNumber': 'updateRootClickAction'
            , 'change:apiPurchasesEnabled': 'updateApiPerPlay'
            , 'change:apiItemsGivenEnabled': 'updateApiPerItem'
        }

        , templateHelpers: function() {
            return {
                MAX_PER_PURCHASE: CONSTANTS.MAX_PER_PURCHASE
            };
        }

        , onRender: function() {
            this.ui.tooltips.tooltip( {
                html: true
                , container: 'body'
                , placement: tooltipPlacement
            } );

            this.updateFolderForSingleItem();
            this.updateMaxBuys();
            this.updateMaxPerPurchase();
            this.updateGroup();
            this.updateRootClickAction();
            this.updateApiPerPlay();
            this.updateApiPerItem();
        }

        , onClose: function() {
            this.ui.tooltips.tooltip( 'destroy' );
        }

        , updateFolderForSingleItem: function() {
            this.ui.folderForSingleItemOff.toggleClass( 'active' , !this.model.get( 'folderForSingleItem' ) );
            this.ui.folderForSingleItemOn.toggleClass( 'active' , this.model.get( 'folderForSingleItem' ) );
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
            } else {
                this.ui.maxBuysUnlimited.removeClass( 'active' );
                this.ui.maxBuysLimited.addClass( 'active' );
                this.ui.maxBuysLimit.prop( 'disabled' , '' );
                this.ui.maxBuysLimit.val( this.model.get( 'maxBuys' ) );
            }

            this.ui.maxBuysLimit.parent().removeClass( 'has-error' );
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
            this.ui.rootClickOff.toggleClass( 'active' , ( 0 === this.model.get( 'rootClickAction' ) ) );
            this.ui.rootClickOn.toggleClass( 'active' , ( 1 === this.model.get( 'rootClickAction' ) ) );

            fade( this.ui.rootClickWarning , this.model.get( 'rootClickActionNeeded' ) );
            this.trigger( 'updateTabStatus' , (
                this.model.get( 'rootClickActionNeeded' )
                ? 'danger'
                : null
            ) );
        }

        , updateApiPerPlay: function() {
            this.ui.apiPerPlayOff.toggleClass( 'active' , !this.model.get( 'apiPurchasesEnabled' ) );
            this.ui.apiPerPlayOn.toggleClass( 'active' , this.model.get( 'apiPurchasesEnabled' ) );
        }

        , updateApiPerItem: function() {
            this.ui.apiPerItemOff.toggleClass( 'active' , !this.model.get( 'apiItemsGivenEnabled' ) );
            this.ui.apiPerItemOn.toggleClass( 'active' , this.model.get( 'apiItemsGivenEnabled' ) );
        }

        , setRootClickAction: function( jEvent ) {
            var target = $( jEvent.currentTarget );
            var newValue = parseInt( target.data( 'value' ) , 10 );
            this.model.set( 'rootClickAction' , newValue );
        }

        , setBooleanField: function( jEvent ) {
            var target = $( jEvent.currentTarget );
            var field = target.data( 'field' );
            var newValue = Boolean( parseInt( target.data( 'value' ) , 10 ) );
            this.model.set( field , newValue );
        }

    } );

    return exports;

} );
