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
            , 'unlimitedButton': '[data-column-contents=limit] .unlimited'
            , 'limitedButton': '[data-column-contents=limit] .limited'
            , 'limitField': '[data-column-contents=limit] input'
            , 'importButton': '.config-import-button'
            , 'deleteButton': '.item-delete-button'
            , 'setLimitButton': '.set-limit'
            , 'startProbability': '.start-probability'
            , 'endProbability': '.end-probability'
            , 'selectForBatchOperation': '[data-column-contents=multi-select] input[type=checkbox]'
        }

        , events: {
            'change @ui.rarityField': 'setRarity'
            , 'keyup @ui.rarityField': 'setRarity'
            , 'click @ui.setLimitButton': 'setLimitMode'
            , 'change @ui.limitField': 'setLimit'
            , 'keyup @ui.limitField': 'setLimit'
            , 'click @ui.deleteButton': 'deleteItem'
            , 'click @ui.importButton': 'importNotecard'
            , 'change @ui.selectForBatchOperation': 'setSelected'
        }

        , modelEvents: {
            'change:rarity': 'updateValues updateDeleteButton'
            , 'change:limit': 'updateValues updateLimit updateDeleteButton'
            , 'change:selectedForBatchOperation': 'updateSelected'
            , 'change:lowRarityPercentage': 'updateValues'
            , 'change:highRarityPercentage': 'updateValues'
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
            this.updateDeleteButton();

            if( 'INVENTORY_NOTECARD' !== this.model.get( 'type' ) ) {
                this.ui.importButton.remove();
            } else if(
                CONSTANTS.NULL_KEY === this.model.get( 'key' )
                || !( this.model.get( 'ownerPermissions' ) & CONSTANTS.PERM_COPY )
                || !( this.model.get( 'ownerPermissions' ) & CONSTANTS.PERM_MODIFY )
                || !( this.model.get( 'ownerPermissions' ) & CONSTANTS.PERM_TRANSFER )
            ) {
                this.ui.importButton.remove();
            }
        }

        , onClose: function() {
            this.ui.tooltips.tooltip( 'destroy' );
        }

        , updateValues: function() {
            if( _.isString( this.ui.rarityField ) ) {
                return;
            }

            if( parseFloat( this.ui.rarityField.val() , 10 ) != this.model.get( 'rarity' ) ) {
                this.ui.rarityField.val( this.model.get( 'rarity' ) || 0 );
            }

            this.ui.rarityLow.text( Math.round( this.model.get( 'lowRarityPercentage' ) * 10 ) / 10 );
            this.ui.rarityHigh.text( Math.round( this.model.get( 'highRarityPercentage' ) * 10 ) / 10 );
            fade( this.ui.endProbability , ( this.model.get( 'lowRarityPercentage' ) !== this.model.get( 'highRarityPercentage' ) ) );

            if( 0 === this.model.get( 'limit' ) ) {
                fade( this.ui.rarityAvailable , false , function() {
                    fade( this.ui.rarityNotSold , true );
                } , this );
            } else {
                if( 0 === this.model.get( 'rarity' ) ) {
                    fade( this.ui.rarityCalculated , false , function() {
                        fade( this.ui.rarityNotSold , true , function() {
                            fade( this.ui.rarityAvailable , true );
                        } , this );
                    } , this );
                } else {
                    fade( this.ui.rarityNotSold , false , function() {
                        fade( this.ui.rarityCalculated , true , function() {
                            fade( this.ui.rarityAvailable , true );
                        } , this );
                    } , this );
                }
            }
        }

        , setRarity: function() {
            var rarity = this.ui.rarityField.val();
            rarity = parseFloat( rarity , 10 );

            if( _.isNaN( rarity ) ) {
                this.ui.rarityField.parent().addClass( 'has-error' );
                this.model.set( 'hasDanger_item_rarity' , true );
                return;
            }

            if( 0 > rarity ) {
                this.ui.rarityField.parent().addClass( 'has-error' );
                this.model.set( 'hasDanger_item_rarity' , true );
                return;
            }

            this.ui.rarityField.parent().removeClass( 'has-error' );
            this.model.set( 'hasDanger_item_rarity' , false );
            this.model.set( 'rarity' , rarity );
        }

        , updateLimit: function() {
            var limit = this.model.get( 'limit' );

            if( ! ( CONSTANTS.PERM_TRANSFER & this.model.get( 'ownerPermissions' ) ) ) {
                fade( this.ui.noCopyMessage , false , function() {
                    fade( this.ui.limitInputs , false , function() {
                        fade( this.ui.noTransMessage , true );
                    } , this );
                } , this );
            } else if( ! ( CONSTANTS.PERM_COPY & this.model.get( 'ownerPermissions' ) ) ) {
                fade( this.ui.noTransMessage , false , function() {
                    fade( this.ui.limitInputs , false , function() {
                        fade( this.ui.noCopyMessage , true );
                    } , this );
                } , this );
            } else if( -1 === limit ) {
                fade( this.ui.noTransMessage , false , function() {
                    fade( this.ui.noCopyMessage , false , function() {
                        this.ui.unlimitedButton.addClass( 'active' );
                        this.ui.limitedButton.removeClass( 'active' );
                        fade( this.ui.limitInputs , true );
                        fade( this.ui.limitField , false );
                    } , this );
                } , this );
            } else {
                fade( this.ui.noTransMessage , false , function() {
                    fade( this.ui.noCopyMessage , false , function() {
                        this.ui.unlimitedButton.removeClass( 'active' );
                        this.ui.limitedButton.addClass( 'active' );
                        this.ui.limitField.val( limit );
                        fade( this.ui.limitInputs , true );
                        fade( this.ui.limitField , true );
                    } , this );
                } , this );
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
            limit = parseInt( limit , 10 );

            if( _.isNaN( limit ) ) {
                this.ui.limitField.parent().addClass( 'has-error' );
                this.model.set( 'hasDanger_item_limit' , true );
                return;
            }

            if( 0 > limit ) {
                this.ui.limitField.parent().addClass( 'has-error' );
                this.model.set( 'hasDanger_item_limit' , true );
                return;
            }

            if( this.ui.limitField.val() != limit ) {
                this.ui.limitField.parent().addClass( 'has-error' );
                this.model.set( 'hasDanger_item_limit' , true );
                return;
            }

            this.ui.limitField.parent().removeClass( 'has-error' );
            this.model.set( 'hasDanger_item_limit' , false );
            this.model.set( 'limit' , limit );
        }

        , updateDeleteButton: function() {
            if(
                'INVENTORY_UNKNOWN' !== this.model.get( 'type' )
                && 'INVENTORY_NONE' !== this.model.get( 'type' )
            ) {
                this.ui.deleteButton.remove();
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

        , setSelected: function() {
            this.model.set( 'selectedForBatchOperation' , Boolean( this.ui.selectForBatchOperation.prop( 'checked' ) ) );
        }

        , updateSelected: function() {
            this.ui.selectForBatchOperation.prop( 'checked' , this.model.get( 'selectedForBatchOperation' ) );
        }

    } );

    return exports;

} );
