define( [

    'underscore'
    , 'marionette'
    , 'hbs!templates/loader'
    , 'css!styles/loader'
    , 'bootstrap'

] , function(

    _
    , Marionette
    , template
    , styles
    , bootstrap

) {
    'use strict';

    var exports = Marionette.ItemView.extend( {
        template: template

        , modelEvents: {
            'change:progressPercentage': 'updateProgress'
            , 'change:progressStep': 'updateProgress'
        }

        , ui: {
            'progressBar': '.progress-bar'
            , 'srValue': '.sr-only .value'
            , 'stepMessage': '#loader-step-message'
        }

        , updateProgress: function() {
            if( ! _.isString( this.ui.progressBar ) ) {
                var progressPercentage = this.model.get( 'progressPercentage' );
                this.ui.progressBar.attr( 'aria-valuenow' , progressPercentage );
                this.ui.progressBar.css( 'width' , progressPercentage + '%' );
                this.ui.srValue.text( progressPercentage );
                this.ui.stepMessage.text( this.model.get( 'progressStep' ) );
            }
        }
    } );

    return exports;

} );

