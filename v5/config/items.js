define( [

    'underscore'
    , 'jquery'
    , 'marionette'
    , 'hbs!config/templates/items'
    , 'css!config/styles/items'
    , 'bootstrap'
    , 'lib/constants'
    , 'lib/tooltip-placement'
    , 'config/item'

] , function(

    _
    , $
    , Marionette
    , template
    , headerStyles
    , bootstrap
    , CONSTANTS
    , tooltipPlacement
    , ItemView

) {
    'use strict';

    var exports = Marionette.CompositeView.extend( {
        template: template
        , itemView: ItemView
        , itemViewContainer: 'tbody'

        , ui: {
            'tooltips': '[data-toggle=tooltip]'
            , 'tables': 'table'
        }

        , onRender: function() {
            this.ui.tooltips.tooltip( {
                html: true
                , container: 'body'
                , placement: tooltipPlacement
            } );
        }

    } );

    return exports;

} );
