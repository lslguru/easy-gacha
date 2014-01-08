define( [

    'underscore'
    , 'jquery'
    , 'marionette'
    , 'hbs!dashboard/templates/item'
    , 'css!dashboard/styles/item'
    , 'lib/constants'

] , function(

    _
    , $
    , Marionette
    , template
    , styles
    , CONSTANTS

) {
    'use strict';

    var exports = Marionette.ItemView.extend( {
        template: template
        , tagName: 'tr'

        , ui: {
            'nameFields': '[data-column-contents="name"]'
            , 'nameTooltips': '[data-column-contents="name"]'
            , 'probabilityTooltips': '[data-column-contents="probability"]'
        }

        , templateHelpers: function() {
            // Source data
            var rarity = this.model.get( 'rarity' );
            var bought = this.model.get( 'bought' );
            var limit = this.model.get( 'limit' );
            var type = this.model.get( 'type' );
            var totalRarity = this.model.collection.totalRarity;
            var totalBought = this.model.collection.totalBought;

            // Inventory
            var inventory = limit - bought;

            // Human formatting
            if( -1 === limit ) {
                // infinity symbol
                inventory = '&#x221e;';
            } else {
                // Add thousands commas
                inventory = inventory.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
            }

            // Initialize probability numbers
            var rarityPercentage = ( totalRarity ? ( rarity * 100 / totalRarity ) : 0 );
            var boughtPercentage = ( totalBought ? ( bought * 100 / totalBought ) : 0 );
            var successBarPercentage = 0;
            var dangerBarPercentage = 0;
            var rarityDisparityTargetSide = '';

            // Calculate green and red bars
            if( boughtPercentage < rarityPercentage ) {
                successBarPercentage = boughtPercentage;
                dangerBarPercentage = ( rarityPercentage - boughtPercentage );
                rarityDisparityTargetSide = 'right';
            } else {
                successBarPercentage = rarityPercentage;
                dangerBarPercentage = ( boughtPercentage - rarityPercentage );
                rarityDisparityTargetSide = 'left';
            }

            // Human formatting
            rarityPercentage = Math.round( rarityPercentage * 1000 ) / 1000; // Nearest thousandth
            boughtPercentage = Math.round( boughtPercentage * 1000 ) / 1000; // Nearest thousandth

            return {
                inventory: inventory
                , rarityPercentage: rarityPercentage
                , boughtPercentage: boughtPercentage
                , successBarPercentage: successBarPercentage
                , dangerBarPercentage: dangerBarPercentage
                , typeName: CONSTANTS.INVENTORY_TYPE_NAME[ type ]
                , rarityDisparityTargetSide: rarityDisparityTargetSide
            };
        }

        , onRender: function() {
            this.ui.nameTooltips.tooltip( {
                html: true
                , placement: 'right'
                , container: 'body'
            } );

            this.ui.probabilityTooltips.tooltip( {
                html: true
                , placement: 'top'
                , container: 'body'
                , template: '<div class="tooltip"><div class="tooltip-arrow"></div><div class="tooltip-inner item-probability-tooltip"></div></div>'
            } );

            this.ui.nameFields.each( function( item ) {
                var type = $( this ).data( 'inventory-type' );
                var image = CONSTANTS.INVENTORY_TYPE_ICON[ type ];
                var insert = $( image ).clone();

                insert.prependTo( this );
            } );
        }
    } );

    return exports;

} );
