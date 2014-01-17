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
            'keyup #import': 'expandImportField'
            , 'change #import': 'expandImportField'
            , 'click #import-btn': 'importConfig'
        }

        , initialize: function() {
            this.constructor.__super__.initialize.apply( this , arguments );
            this.options.app.vent.on( 'importNotecard' , this.importNotecard , this );
        }

        , onRender: function() {
            this.ui.tooltips.tooltip( {
                html: true
                , container: 'body'
                , placement: tooltipPlacement
            } );

            this.ui.importErrorModal.modal( {
                backdrop: true
                , keyboard: true
                , show: false
            } );

            this.ui.importSuccessModal.modal( {
                backdrop: true
                , keyboard: true
                , show: false
            } );

            this.expandImportField();
            this.ui.progressArea.hide();
        }

        , expandImportField: function() {
            this.ui.importField.attr( 'rows' , this.ui.importField.val().split( '\n' ).length );
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
            this.expandImportField();

            this.ui.importSuccessModal.modal( 'show' );
            this.ui.importSuccessModal.one( 'hidden.bs.modal' , _.bind( function() {
                this.options.app.vent.trigger( 'selectTab' , 'default' );
            } , this ) );
        }

        , importNotecard: function( notecardName ) {
            this.ui.progressArea.show();
            this.ui.inputArea.hide();

            var onComplete = _.bind( function( alertType , message ) {
                this.ui.progressArea.hide();
                this.ui.inputArea.show();

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
                    this.expandImportField();
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
