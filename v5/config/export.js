define( [

    'underscore'
    , 'jquery'
    , 'marionette'
    , 'hbs!config/templates/export'
    , 'css!config/styles/export'
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
            , 'lineTooLongWarning': '#line-too-long'
            , 'lineTooLong': '#line-which-is-too-long'
            , 'exportField': '#export'
        }

        , events: {
            'focus #export': 'highlightAll'
            , 'click #export': 'highlightAll'
            , 'mouseup #export': 'highlightAll'
            , 'shown': 'updateExportField'
        }

        , modelEvents: {
            'change': 'updateExportField'
        }

        , onRender: function() {
            this.ui.tooltips.tooltip( {
                html: true
                , container: 'body'
                , placement: tooltipPlacement
            } );

            this.updateExportField();
        }

        , updateExportField: function() {
            var jsonString = JSON.stringify( this.model.toNotecardJSON() , null , 1 );
            var jsonLines = jsonString.split( '\n' );

            this.ui.exportField.text( jsonString );

            var longLines = '';
            _.each( jsonLines , function( line , index ) {
                if( line.length > CONSTANTS.MAX_NOTECARD_LINE_LENGTH ) {
                    longLines += 'Line #' + (index+1) + ': ' + line + '\n';
                }
            } );

            var hideComplete = _.bind( function() {
                this.ui.lineTooLongWarning.hide();
            } , this );

            if( longLines.length ) {
                this.ui.lineTooLongWarning.show().addClass( 'in' );
                this.ui.lineTooLong.text( longLines );
            } else {
                this.ui.lineTooLongWarning.removeClass( 'in' );
                if( $.support.transition ) {
                    this.ui.lineTooLongWarning
                        .one( $.support.transition.end , hideComplete )
                        .emulateTransitionEnd( 150 )
                    ;
                } else {
                    hideComplete();
                }
            }

            this.ui.exportField.attr( 'rows' , jsonLines.length );
            this.ui.exportField.focus();
        }

        , highlightAll: function() {
            this.ui.exportField.select();
        }

    } );

    return exports;

} );
