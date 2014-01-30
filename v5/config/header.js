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
    , 'models/reset'

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
    , Reset

) {
    'use strict';

    var exports = Marionette.ItemView.extend( {
        template: template

        , ui: {
            'tooltips': '[data-toggle=tooltip]'
            , 'dropdowns': '[data-toggle=dropdown]'
            , 'dashboardConfirmation': '#dashboard-confirmation'
            , 'dashboardConfirmed': '#dashboard-confirm'
            , 'resetButton': '#reset'
            , 'resetConfirmation': '#reset-confirmation'
            , 'resetConfirmed': '#reset-confirm'
            , 'reloadButton': '#reload'
            , 'reloadConfirmation': '#reload-confirmation'
            , 'reloadConfirmed': '#reload-confirm'
            , 'reloadSaveFirst': '#reload-save-first'
            , 'dashboardButton': '#dashboard'
            , 'firstRunMessage': '#first-run-message'
            , 'firstRunMessageCloseButton': '#first-run-message .close'
            , 'navLinks': '.nav-links'
            , 'slViewerOnlyMessage': '.sl-viewer-only'
            , 'saveButton': '#save'
            , 'saveButtonMessageDangerChanges': '#save .danger-changes'
            , 'saveButtonMessageNoChanges': '#save .no-changes'
            , 'saveButtonMessageSaveChanges': '#save .save-changes'
            , 'saveButtonMessageSuccessChanges': '#save .success-changes'
            , 'saveStatresetConfirmation': '#statreset-confirmation'
            , 'saveStatresetConfirm': '#statreset-confirm'
            , 'registryButton': '#registry'
            , 'registryConfirmation': '#registry-confirmation'
            , 'registryConfirmed': '#registry-confirm'
        }

        , events: {
            'click @ui.dashboardButton': 'clickDashboard'
            , 'click @ui.dashboardConfirmed': 'confirmDashboard'
            , 'click @ui.reloadButton': 'clickReload'
            , 'click @ui.reloadConfirmed': 'confirmReload'
            , 'click @ui.reloadSaveFirst': 'confirmReloadSaveFirst'
            , 'click @ui.resetButton': 'clickReset'
            , 'click @ui.resetConfirmed': 'confirmReset'
            , 'click @ui.saveButton': 'clickSave'
            , 'click @ui.saveStatresetConfirm': 'confirmSave'
            , 'click @ui.firstRunMessageCloseButton': 'hideAutoModifiedMessage'
            , 'click @ui.registryButton': 'clickRegistry'
            , 'click @ui.registryConfirmed': 'confirmRegistry'
        }

        , modelEvents: {
            'change:hasChangesToSave': 'updateSaveButton'
            , 'change:hasWarning': 'updateSaveButton'
            , 'change:hasDanger': 'updateSaveButton'
            , 'change:configured': 'updateSaveButton'
            , 'change:autoModified': 'toggleAutoModifiedMessage'
            , 'change:ackAutoModified': 'toggleAutoModifiedMessage'
        }

        , initialize: function() {
            this.constructor.__super__.initialize.apply( this , arguments );
            this.listenTo( this.options.app.vent , 'reloadRequested' , this.clickReload );
            this.listenTo( this.options.app.vent , 'lslScriptReset' , this.resetOccurred );
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

            this.ui.registryConfirmation.toggleClass( 'fade' , !isSlViewer() ).modal( {
                backdrop: true
                , keyboard: true
                , show: false
            } );

            this.ui.saveStatresetConfirmation.toggleClass( 'fade' , !isSlViewer() ).modal( {
                backdrop: true
                , keyboard: true
                , show: false
            } );

            this.ui.reloadConfirmation.toggleClass( 'fade' , !isSlViewer() ).modal( {
                backdrop: true
                , keyboard: true
                , show: false
            } );

            this.ui.resetConfirmation.toggleClass( 'fade' , !isSlViewer() ).modal( {
                backdrop: true
                , keyboard: true
                , show: false
            } );

            this.updateSaveButton();
            this.toggleAutoModifiedMessage();
        }

        , onClose: function() {
            this.ui.tooltips.tooltip( 'destroy' );
        }

        , hideAutoModifiedMessage: function() {
            this.model.set( 'ackAutoModified' , true );
        }

        , toggleAutoModifiedMessage: function() {
            fade( this.ui.firstRunMessage , this.model.get( 'autoModified' ) && !this.model.get( 'ackAutoModified' ) );
        }

        , confirmReloadSaveFirst: function( jEvent ) {
            var finish = _.bind( function() {
                this.model.save( {
                    success: _.bind( function() {
                        this.options.app.router.navigate( 'temp' , { replace: true } );
                        this.options.app.router.navigate( 'config' , { trigger: true , replace: true } );
                    } , this )
                } );
            } , this );

            this.ui.reloadConfirmation.one( 'hidden.bs.modal' , finish );
            this.ui.reloadConfirmation.modal( 'hide' );
        }

        , confirmReload: function( jEvent ) {
            var finish = _.bind( function() {
                this.model.fetch( {
                    loadAdmin: true
                } );
            } , this );

            if( jEvent ) {
                this.ui.reloadConfirmation.one( 'hidden.bs.modal' , finish );
                this.ui.reloadConfirmation.modal( 'hide' );
            } else {
                finish();
            }
        }

        , confirmDashboard: function( jEvent ) {
            var finish = _.bind( function() {
                this.options.app.router.navigate( 'dashboard' , { trigger: true } );
            } , this );

            if( jEvent ) {
                this.ui.dashboardConfirmation.one( 'hidden.bs.modal' , finish );
                this.ui.dashboardConfirmation.modal( 'hide' );
            } else {
                finish();
            }
        }

        , confirmRegistry: function( jEvent ) {
            var finish = _.bind( function() {
                this.options.app.router.navigate( 'registry' , { trigger: true } );
            } , this );

            if( jEvent ) {
                this.ui.registryConfirmation.one( 'hidden.bs.modal' , finish );
                this.ui.registryConfirmation.modal( 'hide' );
            } else {
                finish();
            }
        }

        , clickReload: function() {
            if( ! this.model.get( 'hasChangesToSave' ) ) {
                this.confirmReload();
                return;
            }

            this.ui.reloadConfirmation.modal( 'show' );
        }

        , resetOccurred: function() {
            this.ui.navLinks.remove();
            this.ui.slViewerOnlyMessage.remove();
            this.ui.firstRunMessage.remove();
        }

        , confirmReset: function( jEvent ) {
            var finish = _.bind( function() {
                var reset = new Reset();
                reset.fetch();

                this.options.app.vent.trigger( 'lslScriptReset' );
            } , this );

            this.ui.resetConfirmation.one( 'hidden.bs.modal' , finish );
            this.ui.resetConfirmation.modal( 'hide' );
        }

        , clickReset: function() {
            this.ui.resetConfirmation.modal( 'show' );
        }

        , clickDashboard: function() {
            if( ! this.model.get( 'hasChangesToSave' ) ) {
                this.confirmDashboard();
                return;
            }

            this.ui.dashboardConfirmation.modal( 'show' );
        }

        , clickRegistry: function() {
            if( ! this.model.get( 'hasChangesToSave' ) ) {
                this.confirmRegistry();
                return;
            }

            this.ui.registryConfirmation.modal( 'show' );
        }

        , confirmSave: function( jEvent ) {
            var finish = _.bind( function() {
                if( this.model.get( 'configured' ) ) {
                    this.model.save( {} , {
                        success: _.bind( function() {
                            this.options.app.router.navigate( 'dashboard' , { trigger: true } );
                        } , this )
                    } );
                } else {
                    this.model.save( {} , { fetchAfter: true } );
                }
            } , this );

            if( jEvent ) {
                this.ui.saveStatresetConfirmation.one( 'hidden.bs.modal' , finish );
                this.ui.saveStatresetConfirmation.modal( 'hide' );
            } else {
                finish();
            }
        }

        , clickSave: function() {
            if( ! this.model.get( 'totalBought' ) ) {
                this.confirmSave();
                return;
            }

            this.ui.saveStatresetConfirmation.modal( 'show' );
        }

        , updateSaveButton: function() {
            this.ui.saveButton.removeClass( 'btn-danger' );
            this.ui.saveButton.removeClass( 'btn-warning' );
            this.ui.saveButton.removeClass( 'btn-primary' );
            this.ui.saveButton.removeClass( 'btn-success' );
            this.ui.saveButton.removeClass( 'btn-default' );
            if( this.model.get( 'hasDanger' ) ) {
                this.ui.saveButton.addClass( 'btn-danger' );
            } else if( this.model.get( 'hasWarning' ) ) {
                this.ui.saveButton.addClass( 'btn-warning' );
            } else if( !this.model.get( 'hasChangesToSave' ) ) {
                this.ui.saveButton.addClass( 'btn-default' );
            } else if( this.model.get( 'configured' ) ) {
                this.ui.saveButton.addClass( 'btn-success' );
            } else {
                this.ui.saveButton.addClass( 'btn-primary' );
            }

            this.ui.saveButton.prop( 'disabled' , Boolean( !this.model.get( 'hasChangesToSave' ) || this.model.get( 'hasDanger' ) ) );

            fade( this.ui.saveButtonMessageDangerChanges , false );
            fade( this.ui.saveButtonMessageNoChanges , false );
            fade( this.ui.saveButtonMessageSaveChanges , false );
            fade( this.ui.saveButtonMessageSuccessChanges , false );
            if( this.model.get( 'hasDanger' ) ) {
                fade( this.ui.saveButtonMessageDangerChanges , true );
            } else if( this.model.get( 'hasChangesToSave' ) && this.model.get( 'configured' ) ) {
                fade( this.ui.saveButtonMessageSuccessChanges , true );
            } else if( this.model.get( 'hasChangesToSave' ) ) {
                fade( this.ui.saveButtonMessageSaveChanges , true );
            } else {
                fade( this.ui.saveButtonMessageNoChanges , true );
            }
        }
    } );

    return exports;

} );
