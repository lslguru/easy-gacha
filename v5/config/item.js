define( [

    'underscore'
    , 'jquery'
    , 'marionette'
    , 'hbs!config/templates/item'
    , 'css!config/styles/item'
    , 'lib/constants'
    , 'lib/tooltip-placement'
    , 'bootstrap'
    , 'lib/fade'

] , function(

    _
    , $
    , Marionette
    , template
    , styles
    , CONSTANTS
    , tooltipPlacement
    , bootstrap
    , fade

) {
    'use strict';

    var exports = Marionette.ItemView.extend( {
        template: template
        , tagName: 'tr'

        , ui: {
            'tooltips': '[data-toggle=tooltip]'
            , 'nameFields': '[data-column-contents=name]'
            , 'rarityNotSold': '.not-sold'
            , 'rarityAvailable': '.can-set-rarity'
            , 'rarityCalculated': '.show-calculated-rarity'
            , 'rarityField': '[data-column-contents=rarity] input'
            , 'rarityLow': '.rarity-low'
            , 'rarityHigh': '.rarity-high'
            , 'noTransMessage': '[data-column-contents=limit] .no-trans'
            , 'noCopyMessage': '[data-column-contents=limit] .no-copy'
            , 'limitInputs': '[data-column-contents=limit] .input-group'
            , 'unlimitedBtn': '[data-column-contents=limit] .unlimited'
            , 'limitedBtn': '[data-column-contents=limit] .limited'
            , 'limitField': '[data-column-contents=limit] input'
            , 'importBtn': '.config-import-btn'
            , 'deleteBtn': '.item-delete-btn'
            , 'setLimitBtn': '.set-limit'
        }

        , events: {
            'change @ui.rarityField': 'setRarity'
            , 'keyup @ui.rarityField': 'setRarity'
            , 'click @ui.setLimitBtn': 'setLimitMode'
            , 'change @ui.limitField': 'setLimit'
            , 'keyup @ui.limitField': 'setLimit'
            , 'click @ui.deleteBtn': 'deleteItem'
            , 'click @ui.importBtn': 'importNotecard'
        }

        , modelEvents: {
            'change:rarity': 'updateValues updateDeleteBtn'
            , 'change:limit': 'updateValues updateLimit updateDeleteBtn'
        }

        , collectionEvents: {
            'change:rarity': 'updateValues'
            , 'change:limit': 'updateValues'
            , 'add': 'updateValues'
            , 'remove': 'updateValues'
            , 'reset': 'updateValues'
        }

        , initialize: function() {
            Marionette.bindEntityEvents( this , this.model.collection , Marionette.getOption( this , 'collectionEvents' ) );
        }

        , templateHelpers: function() {
            return {
                typeName: CONSTANTS.INVENTORY_TYPE_NAME[ this.model.get( 'type' ) ]
                , inventoryExists: Boolean( 'INVENTORY_NONE' !== this.model.get( 'type' ) )
                , ownerCanCopy: Boolean( this.model.get( 'ownerPermissions' ) & CONSTANTS.PERM_COPY )
                , nextCanCopy: Boolean( this.model.get( 'nextPermissions' ) & CONSTANTS.PERM_COPY )
                , ownerCanMod: Boolean( this.model.get( 'ownerPermissions' ) & CONSTANTS.PERM_MODIFY )
                , nextCanMod: Boolean( this.model.get( 'nextPermissions' ) & CONSTANTS.PERM_MODIFY )
                , ownerCanTrans: Boolean( this.model.get( 'ownerPermissions' ) & CONSTANTS.PERM_TRANSFER )
                , nextCanTrans: Boolean( this.model.get( 'nextPermissions' ) & CONSTANTS.PERM_TRANSFER )
            };
        }

        , onRender: function() {
            this.ui.tooltips.tooltip( {
                html: true
                , container: 'body'
                , placement: tooltipPlacement
            } );

            this.ui.nameFields.each( _.bind( function( index , item ) {
                var type = this.model.get( 'type' );
                var image = CONSTANTS.INVENTORY_TYPE_ICON[ type ];
                var insert = $( image ).clone();

                insert.prependTo( item );
            } , this ) );

            this.updateValues();
            this.updateLimit();
            this.updateDeleteBtn();

            if( 'INVENTORY_NOTECARD' !== this.model.get( 'type' ) ) {
                this.ui.importBtn.remove();
            } else if(
                CONSTANTS.NULL_KEY === this.model.get( 'key' )
                || !( this.model.get( 'ownerPermissions' ) & CONSTANTS.PERM_COPY )
                || !( this.model.get( 'ownerPermissions' ) & CONSTANTS.PERM_MODIFY )
                || !( this.model.get( 'ownerPermissions' ) & CONSTANTS.PERM_TRANSFER )
            ) {
                this.ui.importBtn.remove();
            }
        }

        , updateValues: function() {
            if( _.isString( this.ui.rarityField ) ) {
                return;
            }

            var rarity = this.model.get( 'rarity' );

            if( parseFloat( this.ui.rarityField.val() , 10 ) != rarity ) {
                this.ui.rarityField.val( rarity || 0 );
            }

            var totalRarity = this.model.collection.totalRarity;
            var unlimitedRarity = this.model.collection.unlimitedRarity;
            if( -1 !== this.model.get( 'limit' ) ) {
                unlimitedRarity += rarity;
            }

            this.ui.rarityLow.text( totalRarity ? Math.round( rarity / totalRarity * 1000 ) / 10 : 0 );
            this.ui.rarityHigh.text( totalRarity ? Math.round( rarity / unlimitedRarity * 1000 ) / 10 : 0 );

            if( 0 === this.model.get( 'limit' ) ) {
                fade( this.ui.rarityNotSold , true );
                fade( this.ui.rarityAvailable , false );
            } else {
                fade( this.ui.rarityAvailable , true );
                if( 0 === this.model.get( 'rarity' ) ) {
                    fade( this.ui.rarityCalculated , false );
                    fade( this.ui.rarityNotSold , true );
                } else {
                    fade( this.ui.rarityCalculated , true );
                    fade( this.ui.rarityNotSold , false );
                }
            }
        }

        , setRarity: function() {
            var rarity = this.ui.rarityField.val();
            rarity = parseFloat( rarity , 10 );

            if( _.isNaN( rarity ) ) {
                this.ui.rarityField.parent().addClass( 'has-error' );
                return;
            }

            if( 0 > rarity ) {
                this.ui.rarityField.parent().addClass( 'has-error' );
                return;
            }

            this.ui.rarityField.parent().removeClass( 'has-error' );
            this.model.set( 'rarity' , rarity );
        }

        , updateLimit: function() {
            var limit = this.model.get( 'limit' );

            if( ! ( CONSTANTS.PERM_TRANSFER & this.model.get( 'ownerPermissions' ) ) ) {
                fade( this.ui.noTransMessage , true );
                fade( this.ui.noCopyMessage , false );
                fade( this.ui.limitInputs , false );
            } else if( ! ( CONSTANTS.PERM_COPY & this.model.get( 'ownerPermissions' ) ) ) {
                fade( this.ui.noTransMessage , false );
                fade( this.ui.noCopyMessage , true );
                fade( this.ui.limitInputs , false );
            } else if( -1 === limit ) {
                fade( this.ui.noTransMessage , false );
                fade( this.ui.noCopyMessage , false );
                fade( this.ui.limitInputs , true );
                this.ui.unlimitedBtn.addClass( 'active' );
                this.ui.limitedBtn.removeClass( 'active' );
                fade( this.ui.limitField , false );
            } else {
                fade( this.ui.noTransMessage , false );
                fade( this.ui.noCopyMessage , false );
                fade( this.ui.limitInputs , true );
                this.ui.unlimitedBtn.removeClass( 'active' );
                this.ui.limitedBtn.addClass( 'active' );
                fade( this.ui.limitField , true );
                this.ui.limitField.val( limit );
            }
        }

        , setLimitMode: function( jEvent ) {
            var limited = Boolean( $( jEvent.currentTarget ).data( 'limited' ) );

            if( limited ) {
                this.model.set( 'limit' , 1 );
            } else {
                this.model.set( 'limit' , -1 );
            }
        }

        , setLimit: function() {
            var limit = this.ui.limitField.val();
            limit = parseFloat( limit , 10 );

            if( _.isNaN( limit ) ) {
                this.ui.limitField.parent().addClass( 'has-error' );
                return;
            }

            if( 0 > limit ) {
                this.ui.limitField.parent().addClass( 'has-error' );
                return;
            }

            this.ui.limitField.parent().removeClass( 'has-error' );
            this.model.set( 'limit' , limit );
        }

        , updateDeleteBtn: function() {
            if(
                'INVENTORY_UNKNOWN' !== this.model.get( 'type' )
                && 'INVENTORY_NONE' !== this.model.get( 'type' )
            ) {
                this.ui.deleteBtn.remove();
            }
        }

        , deleteItem: function() {
            this.ui.tooltips.tooltip( 'destroy' );
            this.model.collection.remove( this.model );
        }

        , importNotecard: function() {
            this.options.app.vent.trigger( 'selectTab' , 'import' );
            this.options.app.vent.trigger( 'importNotecard' , this.model.get( 'name' ) );
        }

    } );

    return exports;

} );
