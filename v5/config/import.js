define( [

    'underscore'
    , 'jquery'
    , 'marionette'
    , 'hbs!config/templates/import'
    , 'css!config/styles/import'
    , 'bootstrap'
    , 'lib/constants'
    , 'lib/tooltip-placement'
    , 'models/notecard'
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
    , Notecard
    , isSlViewer
    , fade

) {
    'use strict';

    var exports = Marionette.ItemView.extend( {
        template: template

        , ui: {
            'tooltips': '[data-toggle=tooltip]'
            , 'importField': '#import'
            , 'importButton': '#import-btn'
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

        , onImportFieldChange: function() {
            this.ui.importField.attr( 'rows' , this.ui.importField.val().split( '\n' ).length );
            this.ui.importButton.attr( 'disabled' , ( this.ui.importField.val().length ? null : 'disabled' ) );
        }

        , importConfig: function() {
            var config = this.ui.importField.val();

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
        }

        , importNotecard: function( notecardName ) {
            fade( this.ui.progressArea , true );
            fade( this.ui.inputArea , false );

            var onComplete = _.bind( function( alertType , message ) {
                fade( this.ui.progressArea , false );
                fade( this.ui.inputArea , true );

                this.ui.progressResultAlert.html(
                    '<div class="alert alert-' + alertType + ' alert-dismissable" xmlns="http://www.w3.org/1999/xhtml">'
                        + '<button type="button" class="close" data-dismiss="alert" aria-hidden="true">&#215;</button>'
                        + message
                    + '</div>'
                );
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
                    onComplete( 'success' , 'Your notecard has been loaded. Please review the data, then press the "Import" button to continue.' );
                } , this )

                , error: _.bind( function( err ) {
                    onComplete( 'danger' , 'There was an error loading your notecard: <pre>' + err + '</pre>' );
                } , this )
            } );
        }

    } );

    return exports;

} );
