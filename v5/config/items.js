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
    , ItemView
    , EmptyView
    , fade

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
            , 'noItemsWarning': '#no-items-selected-warning'
        }

        , modelEvents: {
            'change:totalRarity': 'updateDisplay'
        }

        , onRender: function() {
            this.ui.tooltips.tooltip( {
                html: true
                , container: 'body'
                , placement: tooltipPlacement
            } );

            this.updateDisplay();
        }

        , updateDisplay: function() {
            var dangerStatus = false;

            fade( this.ui.noItemsWarning , !Boolean( this.model.get( 'totalRarity' ) ) );
            dangerStatus = dangerStatus || !Boolean( this.model.get( 'totalRarity' ) );

            // Update tab
            this.trigger( 'updateTabStatus' , (
                dangerStatus
                ? 'danger'
                : null
            ) );
        }

    } );

    return exports;

} );
