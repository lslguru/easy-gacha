define( [

    'underscore'
    , 'jquery'
    , 'marionette'
    , 'hbs!config/templates/import'
    , 'hbs!config/templates/import-alert'
    , 'css!config/styles/import'
    , 'bootstrap'
    , 'lib/constants'
    , 'lib/tooltip-placement'
    , 'models/notecard'
    , 'lib/is-sl-viewer'
    , 'lib/fade'
    , 'google-analytics'

] , function(

    _
    , $
    , Marionette
    , template
    , alertTemplate
    , headerStyles
    , bootstrap
    , CONSTANTS
    , tooltipPlacement
    , Notecard
    , isSlViewer
    , fade
    , ga

) {
    'use strict';

    var exports = Marionette.ItemView.extend( {
        template: template

        , ui: {
            'tooltips': '[data-toggle=tooltip]'
            , 'importField': '#import'
            , 'importButton': '#import-button'
            , 'importErrorModal': '#import-error'
            , 'importErrorMessage': '#import-error-message'
            , 'importSuccessModal': '#import-success'
            , 'inputArea': '.import-input'
            , 'progressArea': '.notecard-load-progress'
            , 'progressBar': '.progress-bar'
            , 'progressResultAlert': '.notecard-load-alert'
        }

        , events: {
            'keyup @ui.importField': 'onImportFieldChange'
            , 'change @ui.importField': 'onImportFieldChange'
            , 'click @ui.importButton': 'importConfig'
        }

        , initialize: function() {
            this.constructor.__super__.initialize.apply( this , arguments );
            this.options.app.vent.on( 'importNotecard' , this.importNotecard , this );
        }

        , onTabShown: function() {
            this.ui.importField.focus(); // Make sure cursor is in the box
        }

        , onRender: function() {
            this.ui.tooltips.tooltip( {
                html: true
                , container: 'body'
                , placement: tooltipPlacement
            } );

            this.ui.importErrorModal.toggleClass( 'fade' , !isSlViewer() ).modal( {
                backdrop: true
                , keyboard: true
                , show: false
            } );

            this.ui.importSuccessModal.toggleClass( 'fade' , !isSlViewer() ).modal( {
                backdrop: true
                , keyboard: true
                , show: false
            } );

            this.onImportFieldChange();
            fade( this.ui.progressArea , false );
        }

        , onClose: function() {
            this.ui.tooltips.tooltip( 'destroy' );
        }

        , onImportFieldChange: function() {
            this.ui.importField.attr( 'rows' , this.ui.importField.val().split( '\n' ).length );
            this.ui.importButton.attr( 'disabled' , ( this.ui.importField.val().length ? null : 'disabled' ) );
        }

        , importConfig: function() {
            var config = this.ui.importField.val();

            this.ui.progressResultAlert.html( '' );

            if( !config ) {
                return;
            }

            try {
                config = JSON.parse( config );
            } catch( e ) {
                this.ui.importErrorModal.modal( 'show' );
                this.ui.importErrorMessage.text( e.message );
                return;
            }

            var result = this.model.fromNotecardJSON( config );
            if( true !== result ) {
                this.ui.importErrorModal.modal( 'show' );
                this.ui.importErrorMessage.text( result );
                return;
            }

            this.ui.importField.val( '' );
            this.onImportFieldChange();

            this.ui.importSuccessModal.modal( 'show' );
            this.ui.importSuccessModal.one( 'hidden.bs.modal' , _.bind( function() {
                this.options.app.vent.trigger( 'selectTab' , 'default' );
            } , this ) );

            ga( 'send' , 'event' , 'config' , 'imported' );
        }

        , importNotecard: function( notecardName ) {
            fade( this.ui.progressArea , true );
            fade( this.ui.inputArea , false );

            var onComplete = _.bind( function( alertType , message ) {
                fade( this.ui.progressArea , false );
                fade( this.ui.inputArea , true );

                this.ui.progressResultAlert.html( alertTemplate( {
                    alertType: alertType
                    , message: message
                } ) );
            } , this );

            var notecard = new Notecard( {
                name: notecardName
            } );

            notecard.on( 'change:progressPercentage' , function( model , progressPercentage ) {
                this.ui.progressBar.attr( 'aria-valuenow' , progressPercentage );
                this.ui.progressBar.css( 'width' , progressPercentage + '%' );
            } , this );

            notecard.fetch( {
                success: _.bind( function() {
                    this.ui.importField.val( notecard.get( 'text' ) );
                    this.onImportFieldChange();
                    onComplete( 'success' , 'Your notecard has been loaded. Please review the data, then press the "' + this.ui.importButton.text() + '" button to continue.' );
                } , this )

                , error: _.bind( function( err ) {
                    onComplete( 'danger' , 'There was an error loading your notecard: <pre>' + err + '</pre>' );
                } , this )
            } );
        }

    } );

    return exports;

} );
