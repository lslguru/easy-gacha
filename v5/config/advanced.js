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
    , 'google-analytics'

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
    , ga

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
            , 'showInRegistryOff': '#show-in-registry-off'
            , 'showInRegistryOn': '#show-in-registry-on'
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
            , 'click @ui.showInRegistryOff': 'setBooleanField'
            , 'click @ui.showInRegistryOn': 'setBooleanField'
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
            , 'change:showInRegistry': 'updateShowInRegistry'
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
            this.updateShowInRegistry();
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

            ga( 'send' , 'event' , 'config' , 'folderForSingleItem' , newValue ? 'true' : 'false' );
        }

        , updateMaxBuys: function() {
            this.ui.maxBuysLimit.parent().removeClass( 'has-error' );
            this.model.set( 'hasDanger_advanced_maxBuysLimit' , false );

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
        }

        , toggleMaxBuysLimited: function( jEvent ) {
            var target = $( jEvent.currentTarget );
            if( target.data( 'limited' ) ) {
                this.model.set( 'maxBuys' , 1 );
            } else {
                this.model.set( 'maxBuys' , -1 );
            }

            ga( 'send' , 'event' , 'config' , 'maxBuys' , this.model.get( 'maxBuys' ) );
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
                this.model.set( 'hasDanger_advanced_maxBuysLimit' , true );
                return;
            }

            // If out of bounds
            if( newValue < 0 ) {
                this.ui.maxBuysLimit.parent().addClass( 'has-error' );
                this.model.set( 'hasDanger_advanced_maxBuysLimit' , true );
                return;
            }

            // If parsed doesn't match entered
            if( newValue != this.ui.maxBuysLimit.val() ) {
                this.ui.maxBuysLimit.parent().addClass( 'has-error' );
                this.model.set( 'hasDanger_advanced_maxBuysLimit' , true );
                return;
            }

            this.model.set( 'maxBuys' , newValue );
            this.updateMaxBuys(); // Model may not fire change even if value is the same

            ga( 'send' , 'event' , 'config' , 'maxBuys' , newValue );
        }

        , updateMaxPerPurchase: function() {
            this.ui.maxPerPurchase.val( this.model.get( 'maxPerPurchase' ) );
            this.ui.maxPerPurchase.parent().removeClass( 'has-error' );
            this.model.set( 'hasDanger_advanced_maxPerPurchase' , false );
        }

        , setMaxPerPurchase: function( jEvent ) {
            // Get parse value
            var newValue = parseInt( this.ui.maxPerPurchase.val() , 10 );

            // Make sure it's a number
            if( _.isNaN( newValue ) ) {
                this.ui.maxPerPurchase.parent().addClass( 'has-error' );
                this.model.set( 'hasDanger_advanced_maxPerPurchase' , true );
                return;
            }

            // If out of bounds
            if( newValue < 1 || newValue > CONSTANTS.MAX_PER_PURCHASE ) {
                this.ui.maxPerPurchase.parent().addClass( 'has-error' );
                this.model.set( 'hasDanger_advanced_maxPerPurchase' , true );
                return;
            }

            // If value doesn't equal parsed value
            if( newValue != this.ui.maxPerPurchase.val() ) {
                this.ui.maxPerPurchase.parent().addClass( 'has-error' );
                this.model.set( 'hasDanger_advanced_maxPerPurchase' , true );
                return;
            }

            this.model.set( 'maxPerPurchase' , newValue );
            this.updateMaxPerPurchase();

            ga( 'send' , 'event' , 'config' , 'maxPerPurchase' , newValue );
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

            ga( 'send' , 'event' , 'config' , 'group' , newValue ? 'true' : 'false' );
        }

        , updateRootClickAction: function() {
            this.ui.rootClickOff.toggleClass( 'active' , ( 0 === this.model.get( 'rootClickAction' ) ) );
            this.ui.rootClickOn.toggleClass( 'active' , ( 1 === this.model.get( 'rootClickAction' ) ) );

            fade( this.ui.rootClickWarning , this.model.get( 'rootClickActionNeeded' ) );
            this.model.set( 'hasDanger_advanced_rootClickActionNeeded' , this.model.get( 'rootClickActionNeeded' ) );
        }

        , updateApiPerPlay: function() {
            this.ui.apiPerPlayOff.toggleClass( 'active' , !this.model.get( 'apiPurchasesEnabled' ) );
            this.ui.apiPerPlayOn.toggleClass( 'active' , this.model.get( 'apiPurchasesEnabled' ) );
        }

        , updateApiPerItem: function() {
            this.ui.apiPerItemOff.toggleClass( 'active' , !this.model.get( 'apiItemsGivenEnabled' ) );
            this.ui.apiPerItemOn.toggleClass( 'active' , this.model.get( 'apiItemsGivenEnabled' ) );
        }

        , updateShowInRegistry: function() {
            this.ui.showInRegistryOff.toggleClass( 'active' , !this.model.get( 'showInRegistry' ) );
            this.ui.showInRegistryOn.toggleClass( 'active' , this.model.get( 'showInRegistry' ) );
        }

        , setRootClickAction: function( jEvent ) {
            var target = $( jEvent.currentTarget );
            var newValue = parseInt( target.data( 'value' ) , 10 );
            this.model.set( 'rootClickAction' , newValue );

            ga( 'send' , 'event' , 'config' , 'rootClickAction' , newValue ? 'true' : 'false' );
        }

        , setBooleanField: function( jEvent ) {
            var target = $( jEvent.currentTarget );
            var field = target.data( 'field' );
            var newValue = Boolean( parseInt( target.data( 'value' ) , 10 ) );
            this.model.set( field , newValue );

            ga( 'send' , 'event' , 'config' , field , newValue ? 'true' : 'false' );
        }

    } );

    return exports;

} );
