define( [

    'underscore'
    , 'marionette'
    , 'hbs!registry/templates/result-gacha'
    , 'css!registry/styles/result-gacha'
    , 'lib/tooltip-placement'
    , 'bootstrap'

] , function(

    _
    , Marionette
    , template
    , styles
    , tooltipPlacement
    , bootstrap

) {
    'use strict';

    var exports = Marionette.ItemView.extend( {
        template: template
        , className: 'gacha'

        , ui: {
            'tooltips': '[data-toggle=tooltip]'
        }

        , onRender: function() {
            this.ui.tooltips.tooltip( {
                html: true
                , container: 'body'
                , placement: tooltipPlacement
            } );
        }

        , onClose: function() {
            this.ui.tooltips.tooltip( 'destroy' );
        }
    } );

    return exports;

} );
