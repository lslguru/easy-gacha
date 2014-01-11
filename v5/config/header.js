define( [

    'marionette'
    , 'hbs!config/templates/header'
    , 'css!config/styles/header'
    , 'bootstrap'
    , 'lib/constants'
    , 'lib/tooltip-placement'
    , 'lib/map-uri'

] , function(

    Marionette
    , template
    , headerStyles
    , bootstrap
    , CONSTANTS
    , tooltipPlacement
    , mapUri

) {
    'use strict';

    var exports = Marionette.ItemView.extend( {
        template: template

        , events: {
            'click #dashboard': 'clickDashboard'
            , 'click #dashboard-confirm': 'confirmDashboard'
            , 'click #save': 'clickSave'
        }

        , ui: {
            'tooltips': '[data-toggle=tooltip]'
            , 'dashboardConfirmation': '#dashboard-confirmation'
            , 'saveBtn': '#save'
        }

        , gachaEvents: {
            'change': 'updateSaveBtn'
        }

        , initialize: function() {
            this.constructor.__super__.initialize.apply( this , arguments );
            Marionette.bindEntityEvents( this , this.options.gacha , Marionette.getOption( this , 'gachaEvents' ) );
        }

        , templateHelpers: function() {
            if( null === this.model.get( 'freeMemory' ) ) {
                return {};
            }

            return {
                mapUrl: mapUri(
                    this.model.get( 'regionName' )
                    , this.model.get( 'position' ).x
                    , this.model.get( 'position' ).y
                    , this.model.get( 'position' ).z
                )

                , dangerMemory: (
                    null !== this.model.get( 'freeMemory' )
                    && this.model.get( 'freeMemory' ) < CONSTANTS.DANGER_MEMORY_THRESHOLD
                )

                , warnMemory: (
                    null !== this.model.get( 'freeMemory' )
                    && this.model.get( 'freeMemory' ) < CONSTANTS.WARN_MEMORY_THRESHOLD
                )

                , ownerUrl: (
                    'secondlife:///app/agent/'
                    + this.model.get( 'ownerKey' )
                    + '/about'
                )
            };
        }

        , onRender: function() {
            this.ui.tooltips.tooltip( {
                html: true
                , container: 'body'
                , placement: tooltipPlacement
            } );

            this.ui.dashboardConfirmation.modal( {
                backdrop: true
                , keyboard: true
                , show: false
            } );

            this.updateSaveBtn();
        }

        , confirmDashboard: function() {
            this.options.app.router.navigate( 'dashboard' , { trigger: true } );
        }

        , hasChanges: function() {
            return Boolean( this.options.gacha.fetchedJSON && ! _.isEqual( this.options.gacha.toJSON() , this.options.gacha.fetchedJSON ) );
        }

        , clickDashboard: function() {
            if( ! this.hasChanges() ) {
                this.confirmDashboard();
                return;
            }

            this.ui.dashboardConfirmation.modal( 'show' );
        }

        , clickSave: function() {
            if( ! this.ui.saveBtn.hasClass( 'disabled' ) ) {
                this.options.gacha.save();
            }
        }

        , updateSaveBtn: function() {
            if( this.hasChanges() ) {
                this.ui.saveBtn.removeClass( 'disabled' );
                this.ui.saveBtn.addClass( 'btn-primary' );
                this.ui.saveBtn.text( 'Save' );
            } else {
                this.ui.saveBtn.removeClass( 'btn-primary' );
                this.ui.saveBtn.addClass( 'disabled' );
                this.ui.saveBtn.text( 'Saved' );
            }
        }
    } );

    return exports;

} );
