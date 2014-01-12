define( [

    'underscore'
    , 'jquery'
    , 'marionette'
    , 'hbs!config/templates/import'
    , 'css!config/styles/import'
    , 'bootstrap'
    , 'lib/constants'
    , 'lib/tooltip-placement'

] , function(

    _
    , $
    , Marionette
    , template
    , headerStyles
    , bootstrap
    , CONSTANTS
    , tooltipPlacement

) {
    'use strict';

    // _.reduce( JSON.stringify( gacha.toJSON() , null , 1 ).split( '\n' ) , function( memo , line ) { if( line.length > memo ) return line.length; return memo; } , 0 );

    var exports = Marionette.ItemView.extend( {
        template: template

        , ui: {
            'tooltips': '[data-toggle=tooltip]'
            , 'importField': '#import'
            , 'importButton': '#import-btn'
            , 'importErrorModal': '#import-error'
            , 'importErrorMessage': '#import-error-message'
            , 'importSuccessModal': '#import-success'
        }

        , events: {
            'keyup #import': 'expandImportField'
            , 'change #import': 'expandImportField'
            , 'click #import-btn': 'importConfig'
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
            this.ui.importSuccessModal.modal( 'show' );
        }

    } );

    return exports;

} );
