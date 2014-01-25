define( [

    'underscore'
    , 'jquery'
    , 'marionette'
    , 'hbs!config/templates/items'
    , 'css!config/styles/items'
    , 'bootstrap'
    , 'lib/constants'
    , 'lib/tooltip-placement'
    , 'config/item'
    , 'config/items-empty'
    , 'lib/is-sl-viewer'
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
    , ItemView
    , EmptyView
    , isSlViewer
    , fade

) {
    'use strict';

    var exports = Marionette.CompositeView.extend( {
        template: template
        , itemView: ItemView
        , itemViewContainer: 'tbody'
        , emptyView: EmptyView

        , itemViewOptions: function() {
            var options = _.clone( this.options );
            delete options.model;
            return options;
        }

        , ui: {
            'tooltips': '[data-toggle=tooltip]'
            , 'noItemsWarning': '#no-items-selected-warning'
            , 'totalItemsCount': '#total-items-count'
            , 'totalItemsAvailableCount': '#total-items-available-count'
            , 'totalRarity': '#total-rarity'
            , 'totalUnlimitedRarity': '#total-unlimited-rarity'
            , 'totalUnlimitedRarityContainer': '#total-unlimited-rarity-container'
            , 'selectAllCheckbox': '#select-all-items'
            , 'totalItemsCopy': '#total-copy'
            , 'totalItemsMod': '#total-mod'
            , 'totalItemsTrans': '#total-trans'
            , 'countUnlimitedContainer': '#count-unlimited-container'
            , 'countUnlimited': '#count-unlimited'
            , 'countLimitedContainer': '#count-limited-container'
            , 'countLimited': '#count-limited'
            , 'batchActionsContainer': '#batch-actions'
            , 'batchRarity': '#batch-rarity'
            , 'batchRarityDialog': '#batch-rarity-dialog'
            , 'batchRarityField': '#batch-rarity-value'
            , 'batchRaritySet': '#batch-rarity-set'
            , 'batchLimit': '#batch-limit'
            , 'batchLimitDialog': '#batch-limit-dialog'
            , 'batchLimitField': '#batch-limit-value'
            , 'batchLimitLimited': '#batch-limit-limited'
            , 'batchLimitUnlimited': '#batch-limit-unlimited'
            , 'batchDelete': '#batch-delete'
            , 'batchDeleteConfirmation': '#batch-delete-confirmation'
            , 'batchDeleteConfirmed': '#batch-delete-confirm'
        }

        , modelEvents: {
            'change:totalRarity': 'updateDisplay'
            , 'change:unlimitedRarity': 'updateDisplay'
            , 'change:totalItems': 'updateDisplay'
            , 'change:totalItemsAvailable': 'updateDisplay'
            , 'change:lowestLimitedRarity': 'updateDisplay'
            , 'change:anySelectedForBatchOperation': 'updateDisplay'
            , 'change:allSelectedForBatchOperation': 'updateDisplay'
            , 'change:totalItemsCopy': 'updateDisplay'
            , 'change:totalItemsMod': 'updateDisplay'
            , 'change:totalItemsTrans': 'updateDisplay'
            , 'change:countUnlimited': 'updateDisplay'
            , 'change:countLimited': 'updateDisplay'
        }

        , events: {
            'change @ui.selectAllCheckbox': 'toggleAllSelections'
            , 'click @ui.batchRarity': 'batchRarity'
            , 'click @ui.batchLimit': 'batchLimit'
            , 'click @ui.batchDelete': 'batchDelete'
            , 'click @ui.batchDeleteConfirmed': 'batchDeleteConfirmed'
            , 'click @ui.batchLimitLimited': 'batchLimitLimited'
            , 'click @ui.batchLimitUnlimited': 'batchLimitUnlimited'
            , 'keyup @ui.batchLimitField': 'batchLimitValidate'
            , 'change @ui.batchLimitField': 'batchLimitValidate'
            , 'click @ui.batchRaritySet': 'batchRaritySet'
            , 'keyup @ui.batchRarityField': 'batchRarityValidate'
            , 'change @ui.batchRarityField': 'batchRarityValidate'
        }

        , onRender: function() {
            this.ui.tooltips.tooltip( {
                html: true
                , container: 'body'
                , placement: tooltipPlacement
            } );

            this.ui.batchRarityDialog.toggleClass( 'fade' , !isSlViewer() ).modal( {
                backdrop: true
                , keyboard: true
                , show: false
            } );

            this.ui.batchLimitDialog.toggleClass( 'fade' , !isSlViewer() ).modal( {
                backdrop: true
                , keyboard: true
                , show: false
            } );

            this.ui.batchDeleteConfirmation.toggleClass( 'fade' , !isSlViewer() ).modal( {
                backdrop: true
                , keyboard: true
                , show: false
            } );

            this.updateDisplay();
        }

        , updateDisplay: function() {
            var dangerStatus = false;

            fade( this.ui.noItemsWarning , !Boolean( this.model.get( 'totalRarity' ) ) );
            dangerStatus = dangerStatus || !Boolean( this.model.get( 'totalRarity' ) );

            // Update totals
            this.ui.totalItemsCount.text( this.model.get( 'totalItems' ) );
            this.ui.totalItemsAvailableCount.text( this.model.get( 'totalItemsAvailable' ) );
            this.ui.totalItemsCopy.text( this.model.get( 'totalItemsCopy' ) );
            this.ui.totalItemsMod.text( this.model.get( 'totalItemsMod' ) );
            this.ui.totalItemsTrans.text( this.model.get( 'totalItemsTrans' ) );
            this.ui.totalRarity.text( this.model.get( 'totalRarity' ) );
            this.ui.totalUnlimitedRarity.text( this.model.get( 'lowestLimitedRarity' ) + this.model.get( 'unlimitedRarity' ) );
            this.ui.countUnlimited.text( this.model.get( 'countUnlimited' ) );
            this.ui.countLimited.text( this.model.get( 'countLimited' ) );
            fade( this.ui.totalUnlimitedRarityContainer , ( this.model.get( 'totalRarity' ) !== this.model.get( 'unlimitedRarity' ) ) );
            fade( this.ui.countUnlimitedContainer , Boolean( this.model.get( 'countUnlimited' ) ) );
            fade( this.ui.countLimitedContainer , Boolean( this.model.get( 'countLimited' ) ) );

            // Update checkbox stuff
            fade( this.ui.batchActionsContainer , this.model.get( 'anySelectedForBatchOperation' ) );
            this.ui.selectAllCheckbox.prop( 'checked' , this.model.get( 'allSelectedForBatchOperation' ) );

            // Update tab
            this.trigger( 'updateTabStatus' , (
                dangerStatus
                ? 'danger'
                : null
            ) );
        }

        , toggleAllSelections: function() {
            var newSetting = !this.model.get( 'allSelectedForBatchOperation' );
            this.collection.each( function( item ) {
                item.set( 'selectedForBatchOperation' , newSetting );
            } );
        }

        , batchRarityValidate: function() {
            var rarity = this.ui.batchRarityField.val();
            rarity = parseFloat( rarity , 10 );

            if( _.isNaN( rarity ) ) {
                this.ui.batchRarityField.parent().addClass( 'has-error' );
                this.ui.batchRaritySet.prop( 'disabled' , 'disabled' );
                return;
            }

            if( 0 > rarity ) {
                this.ui.batchRarityField.parent().addClass( 'has-error' );
                this.ui.batchRaritySet.prop( 'disabled' , 'disabled' );
                return;
            }

            this.ui.batchRarityField.parent().removeClass( 'has-error' );
            this.ui.batchRaritySet.prop( 'disabled' , '' );
        }

        , batchRaritySet: function() {
            var finish = _.bind( function() {
                _.each( this.collection.getChecked() , function( item ) {
                    item.set( 'rarity' , parseFloat( this.ui.batchRarityField.val() , 10 ) );
                } , this );
            } , this );

            this.ui.batchRarityDialog.one( 'hidden.bs.modal' , finish );
            this.ui.batchRarityDialog.modal( 'hide' );
        }

        , batchRarity: function() {
            this.ui.batchRarityDialog.modal( 'show' );
        }

        , batchLimitValidate: function() {
            var limit = this.ui.batchLimitField.val();
            limit = parseInt( limit , 10 );

            if( _.isNaN( limit ) ) {
                this.ui.batchLimitField.parent().addClass( 'has-error' );
                this.ui.batchLimitLimited.prop( 'disabled' , 'disabled' );
                return;
            }

            if( 0 > limit ) {
                this.ui.batchLimitField.parent().addClass( 'has-error' );
                this.ui.batchLimitLimited.prop( 'disabled' , 'disabled' );
                return;
            }

            if( this.ui.batchLimitField.val() != limit ) {
                this.ui.batchLimitField.parent().addClass( 'has-error' );
                this.ui.batchLimitLimited.prop( 'disabled' , 'disabled' );
                return;
            }

            this.ui.batchLimitField.parent().removeClass( 'has-error' );
            this.ui.batchLimitLimited.prop( 'disabled' , '' );
        }

        , batchLimitLimited: function() {
            var finish = _.bind( function() {
                _.each( this.collection.getChecked() , function( item ) {
                    item.set( 'limit' , parseInt( this.ui.batchLimitField.val() , 10 ) );
                } , this );
            } , this );

            this.ui.batchLimitDialog.one( 'hidden.bs.modal' , finish );
            this.ui.batchLimitDialog.modal( 'hide' );
        }

        , batchLimitUnlimited: function() {
            var finish = _.bind( function() {
                _.each( this.collection.getChecked() , function( item ) {
                    item.set( 'limit' , -1 );
                } , this );
            } , this );

            this.ui.batchLimitDialog.one( 'hidden.bs.modal' , finish );
            this.ui.batchLimitDialog.modal( 'hide' );
        }

        , batchLimit: function() {
            this.ui.batchLimitDialog.modal( 'show' );
        }

        , batchDeleteConfirmed: function() {
            var finish = _.bind( function() {
                this.collection.remove( this.collection.getChecked() );
                this.model.dataInitializations( true );
            } , this );

            this.ui.batchDeleteConfirmation.one( 'hidden.bs.modal' , finish );
            this.ui.batchDeleteConfirmation.modal( 'hide' );
        }

        , batchDelete: function() {
            this.ui.batchDeleteConfirmation.modal( 'show' );
        }

        // Overridden Marionette method
        , appendHtml: function( compositeView , itemView , index ) {
            if( compositeView.isBuffering ) {
                compositeView.elBuffer.appendChild( itemView.el );
            } else {
                var childrenContainer = this.getItemViewContainer( compositeView );
                var children = childrenContainer.children();

                if( children.size() <= index ) {
                    childrenContainer.append( itemView.el );
                } else {
                    children.eq( index ).before( itemView.el );
                }
            }
        }

    } );

    return exports;

} );
