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
    , 'config/items-empty'

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
    , EmptyView

) {
    'use strict';

    var exports = Marionette.CompositeView.extend( {
        template: template
        , itemView: ItemView
        , itemViewContainer: 'tbody'
        , emptyView: EmptyView

        , itemViewOptions: function() {
            var options = _.clone( this.options );
            delete options.model;
            return options;
        }

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

    } );

    return exports;

} );
