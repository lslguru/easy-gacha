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

    var exports = Marionette.ItemView.extend( {
        template: template

        , ui: {
            'tooltips': '[data-toggle=tooltip]'
            , 'lineTooLongWarning': '#line-too-long'
            , 'lineTooLong': '#line-which-is-too-long'
            , 'exportField': '#export'
        }

        , events: {
            'focus @ui.exportField': 'highlightAll' // should fire on tabbing, but some browsers don't
            , 'click @ui.exportField': 'highlightAll' // every time the field is clicked, reestablish
            , 'keyup @ui.exportField': 'highlightAll' // occurs if you tab into the field
            , 'mouseover @ui.exportField': 'highlightAll' // heck, why not
        }

        , modelEvents: {
            'change': 'updateExportField'
        }

        , onTabShown: function() {
            this.updateExportField();
            this.highlightAll();

            // Counter scroll effect from selection only when switching tabs
            $(window).scrollTop(0);
        }

        , onRender: function() {
            this.ui.tooltips.tooltip( {
                html: true
                , container: 'body'
                , placement: tooltipPlacement
            } );

            this.updateExportField();

            // Chrome is the odd man out this time. onmouseup deselects...
            this.ui.exportField[0].onmouseup = function() { return false; };
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
            this.ui.exportField.focus(); // Make sure cursor is in the box
            this.ui.exportField.select(); // Make sure text is highlighted
        }

    } );

    return exports;

} );
