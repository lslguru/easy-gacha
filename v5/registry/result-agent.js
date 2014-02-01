define( [

    'underscore'
    , 'marionette'
    , 'hbs!registry/templates/result-agent'
    , 'css!registry/styles/result-agent'
    , 'registry/result-gacha'
    , 'lib/tooltip-placement'
    , 'bootstrap'

] , function(

    _
    , Marionette
    , template
    , styles
    , ItemView
    , tooltipPlacement
    , bootstrap

) {
    'use strict';

    var exports = Marionette.CompositeView.extend( {
        template: template
        , className: 'agent col-sm-3'
        , itemView: ItemView
        , itemViewContainer: '.list'

        , ui: {
            'tooltips': '[data-toggle=tooltip]'
        }

        , initialize: function() {
            this.collection = this.model.get( 'gachas' );
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
