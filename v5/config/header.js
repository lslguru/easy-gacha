define( [

    'marionette'
    , 'hbs!config/templates/header'
    , 'css!config/styles/header'
    , 'bootstrap'
    , 'lib/constants'
    , 'lib/tooltip-placement'
    , 'lib/map-uri'
    , 'lib/is-sl-viewer'
    , 'lib/fade'

] , function(

    Marionette
    , template
    , headerStyles
    , bootstrap
    , CONSTANTS
    , tooltipPlacement
    , mapUri
    , isSlViewer
    , fade

) {
    'use strict';

    var exports = Marionette.ItemView.extend( {
        template: template

        , ui: {
            'tooltips': '[data-toggle=tooltip]'
            , 'dropdowns': '[data-toggle=dropdown]'
            , 'dashboardConfirmation': '#dashboard-confirmation'
            , 'dashboardConfirmed': '#dashboard-confirm'
            , 'reloadButton': '#reload'
            , 'reloadConfirmation': '#reload-confirmation'
            , 'reloadConfirmed': '#reload-confirm'
            , 'reloadSaveFirst': '#reload-save-first'
            , 'saveButton': '#save'
            , 'dashboardBtn': '#dashboard'
            , 'firstRunMessage': '#first-run-message'
            , 'firstRunMessageCloseButton': '#first-run-message .close'
        }

        , events: {
            'click @ui.dashboardBtn': 'clickDashboard'
            , 'click @ui.dashboardConfirmed': 'confirmDashboard'
            , 'click @ui.reloadButton': 'clickReload'
            , 'click @ui.reloadConfirmed': 'confirmReload'
            , 'click @ui.reloadSaveFirst': 'confirmReloadSaveFirst'
            , 'click @ui.saveButton': 'clickSave'
            , 'click @ui.firstRunMessageCloseButton': 'hideAutoModifiedMessage'
        }

        , modelEvents: {
            'change:hasChangesToSave': 'updateSaveBtn'
            , 'change:autoModified': 'toggleAutoModifiedMessage'
            , 'change:ackAutoModified': 'toggleAutoModifiedMessage'
        }

        , initialize: function() {
            this.constructor.__super__.initialize.apply( this , arguments );
            this.listenTo( this.options.app.vent , 'reloadRequested' , this.clickReload );
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
                    ? 'fa-exclamation-triangle'
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
                        ? 'fa-exclamation-triangle'
                        : (
                            this.model.get( 'scriptTime' )
                            ? 'fa-check-circle'
                            : 'fa-smile-o'
                        )
                    )
                )

                , overallState: (
                    null !== this.model.get( 'freeMemory' )
                    && this.model.get( 'freeMemory' ) < CONSTANTS.DANGER_MEMORY_THRESHOLD
                    ? 'danger'
                    : (
                        (
                            null !== this.model.get( 'freeMemory' )
                            && this.model.get( 'freeMemory' ) < CONSTANTS.WARN_MEMORY_THRESHOLD
                        )
                        || (
                            1 === this.model.get( 'scriptCount' )
                            && CONSTANTS.WARN_SCRIPT_TIME < this.model.get( 'scriptTime' )
                        )
                        ? 'warning'
                        : 'default'
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

            this.ui.dashboardConfirmation.toggleClass( 'fade' , !isSlViewer() ).modal( {
                backdrop: true
                , keyboard: true
                , show: false
            } );

            this.ui.reloadConfirmation.toggleClass( 'fade' , !isSlViewer() ).modal( {
                backdrop: true
                , keyboard: true
                , show: false
            } );

            this.updateSaveBtn();
            this.toggleAutoModifiedMessage();
        }

        , hideAutoModifiedMessage: function() {
            this.model.set( 'ackAutoModified' , true );
        }

        , toggleAutoModifiedMessage: function() {
            fade( this.ui.firstRunMessage , this.model.get( 'autoModified' ) && !this.model.get( 'ackAutoModified' ) );
        }

        , confirmReloadSaveFirst: function( jEvent ) {
            var moveAlong = _.bind( function() {
                this.model.save( {
                    success: _.bind( function() {
                        this.options.app.router.navigate( 'temp' , { replace: true } );
                        this.options.app.router.navigate( 'config' , { trigger: true , replace: true } );
                    } , this )
                } );
            } , this );

            this.ui.reloadConfirmation.one( 'hidden.bs.modal' , moveAlong );
            this.ui.reloadConfirmation.modal( 'hide' );
        }

        , confirmReload: function( jEvent ) {
            var moveAlong = _.bind( function() {
                this.model.fetch( {
                    loadAdmin: true
                } );
            } , this );

            if( jEvent ) {
                this.ui.reloadConfirmation.one( 'hidden.bs.modal' , moveAlong );
                this.ui.reloadConfirmation.modal( 'hide' );
            } else {
                moveAlong();
            }
        }

        , confirmDashboard: function( jEvent ) {
            var moveAlong = _.bind( function() {
                this.options.app.router.navigate( 'dashboard' , { trigger: true } );
            } , this );

            if( jEvent ) {
                this.ui.dashboardConfirmation.one( 'hidden.bs.modal' , moveAlong );
                this.ui.dashboardConfirmation.modal( 'hide' );
            } else {
                moveAlong();
            }
        }

        , clickReload: function() {
            if( ! this.model.get( 'hasChangesToSave' ) ) {
                this.confirmReload();
                return;
            }

            this.ui.reloadConfirmation.modal( 'show' );
        }

        , clickDashboard: function() {
            if( ! this.model.get( 'hasChangesToSave' ) ) {
                this.confirmDashboard();
                return;
            }

            this.ui.dashboardConfirmation.modal( 'show' );
        }

        , clickSave: function() {
            if( ! this.ui.saveButton.hasClass( 'disabled' ) ) {
                this.model.save();
                this.model.set( 'overrideProgress' , 0 );
            }
        }

        , updateSaveBtn: function() {
            if( this.model.get( 'hasChangesToSave' ) ) {
                this.ui.saveButton.removeClass( 'disabled' );
            } else {
                this.ui.saveButton.addClass( 'disabled' );
            }
        }
    } );

    return exports;

} );
