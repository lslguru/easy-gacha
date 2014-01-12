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
            , 'click #reload': 'clickReload'
            , 'click #reload-confirm': 'confirmReload'
            , 'click #save': 'clickSave'
        }

        , ui: {
            'tooltips': '[data-toggle=tooltip]'
            , 'dropdowns': '[data-toggle=dropdown]'
            , 'dashboardConfirmation': '#dashboard-confirmation'
            , 'reloadConfirmation': '#reload-confirmation'
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

                , memoryState: (
                    null !== this.model.get( 'freeMemory' )
                    && this.model.get( 'freeMemory' ) < CONSTANTS.DANGER_MEMORY_THRESHOLD
                    ? 'danger'
                    : (
                        null !== this.model.get( 'freeMemory' )
                        && this.model.get( 'freeMemory' ) < CONSTANTS.WARN_MEMORY_THRESHOLD
                        ? 'warning'
                        : 'success'
                    )
                )

                , memoryIcon: (
                    null !== this.model.get( 'freeMemory' )
                    && this.model.get( 'freeMemory' ) < CONSTANTS.DANGER_MEMORY_THRESHOLD
                    ? 'fa-exclamation-circle'
                    : (
                        null !== this.model.get( 'freeMemory' )
                        && this.model.get( 'freeMemory' ) < CONSTANTS.WARN_MEMORY_THRESHOLD
                        ? 'fa-info-circle'
                        : 'fa-check-circle'
                    )
                )

                , lagState: (
                    1 !== this.model.get( 'scriptCount' )
                    ? 'info'
                    : (
                        CONSTANTS.WARN_SCRIPT_TIME < this.model.get( 'scriptTime' )
                        ? 'warning'
                        : 'success'
                    )
                )

                , lagIcon: (
                    1 !== this.model.get( 'scriptCount' )
                    ? 'fa-info-circle'
                    : (
                        CONSTANTS.WARN_SCRIPT_TIME < this.model.get( 'scriptTime' )
                        ? 'fa-exclamation-circle'
                        : (
                            this.model.get( 'scriptTime' )
                            ? 'fa-check-circle'
                            : 'fa-smile-o'
                        )
                    )
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

            this.ui.dropdowns.dropdown();

            this.ui.dashboardConfirmation.modal( {
                backdrop: true
                , keyboard: true
                , show: false
            } );

            this.ui.reloadConfirmation.modal( {
                backdrop: true
                , keyboard: true
                , show: false
            } );

            this.updateSaveBtn();
        }

        , confirmReload: function() {
            this.options.app.router.navigate( 'temp' , { replace: true } );
            this.options.app.router.navigate( 'config' , { trigger: true , replace: true } );
        }

        , confirmDashboard: function() {
            this.options.app.router.navigate( 'dashboard' , { trigger: true } );
        }

        , hasChanges: function() {
            return Boolean( this.options.gacha.fetchedJSON && ! _.isEqual( this.options.gacha.toJSON() , this.options.gacha.fetchedJSON ) );
        }

        , clickReload: function() {
            if( ! this.hasChanges() ) {
                this.confirmReload();
                return;
            }

            this.ui.reloadConfirmation.modal( 'show' );
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
            } else {
                this.ui.saveBtn.addClass( 'disabled' );
            }
        }
    } );

    return exports;

} );
