define( [

    'underscore'
    , 'jquery'
    , 'marionette'
    , 'hbs!dashboard/templates/item'
    , 'css!dashboard/styles/item'
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
            'nameFields': '[data-column-contents="name"]'
            , 'nameTooltips': '[data-column-contents="name"]'
            , 'probabilityTooltips': '[data-column-contents="probability"]'
        }

        , templateHelpers: function() {
            // Human formatting
            if( -1 === this.model.get( 'limit' ) ) {
                // infinity symbol
                var inventory = '&#x221e;';
            } else {
                // Add thousands commas
                var inventory = this.model.get( 'remainingInventory' ).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
            }

            // Initialize probability numbers
            var rarityPercentage = this.model.get( 'lowRarityPercentage' );
            var boughtPercentage = this.model.get( 'boughtPercentage' );
            var matchedBarPercentage = 0;
            var differenceBarPercentage = 0;
            var rarityDisparityTargetSide = '';

            // Calculate green and red bars
            if( boughtPercentage < rarityPercentage ) {
                matchedBarPercentage = boughtPercentage;
                differenceBarPercentage = ( rarityPercentage - boughtPercentage );
                rarityDisparityTargetSide = 'right';
            } else {
                matchedBarPercentage = rarityPercentage;
                differenceBarPercentage = ( boughtPercentage - rarityPercentage );
                rarityDisparityTargetSide = 'left';
            }

            // Human formatting
            rarityPercentage = Math.round( rarityPercentage * 1000 ) / 1000; // Nearest thousandth
            boughtPercentage = Math.round( boughtPercentage * 1000 ) / 1000; // Nearest thousandth

            return {
                inventory: inventory
                , rarityPercentage: rarityPercentage
                , boughtPercentage: boughtPercentage
                , matchedBarPercentage: matchedBarPercentage
                , differenceBarPercentage: differenceBarPercentage
                , typeName: CONSTANTS.INVENTORY_TYPE_NAME[ this.model.get( 'type' ) ]
                , rarityDisparityTargetSide: rarityDisparityTargetSide
            };
        }

        , onRender: function() {
            this.ui.nameTooltips.tooltip( {
                html: true
                , container: 'body'
                , placement: tooltipPlacement
            } );

            this.ui.probabilityTooltips.tooltip( {
                html: true
                , container: 'body'
                , template: '<div class="tooltip"><div class="tooltip-arrow"></div><div class="tooltip-inner item-probability-tooltip"></div></div>'
                , placement: tooltipPlacement
            } );

            this.ui.nameFields.each( function( item ) {
                var type = $( this ).data( 'inventory-type' );
                var image = CONSTANTS.INVENTORY_TYPE_ICON[ type ];
                var insert = $( image ).clone();

                insert.prependTo( this );
            } );
        }

        , onClose: function() {
            this.ui.nameTooltips.tooltip( 'destroy' );
            this.ui.probabilityTooltips.tooltip( 'destroy' );
        }
    } );

    return exports;

} );
