define( [

    'underscore'
    , 'marionette'
    , 'hbs!registry/templates/result-gacha'
    , 'css!registry/styles/result-gacha'
    , 'lib/tooltip-placement'
    , 'bootstrap'
    , 'lib/map-uri'

] , function(

    _
    , Marionette
    , template
    , styles
    , tooltipPlacement
    , bootstrap
    , mapUri

) {
    'use strict';

    var exports = Marionette.ItemView.extend( {
        template: template
        , className: 'gacha'

        , ui: {
            'tooltips': '[data-toggle=tooltip]'
        }

        , templateHelpers: function() {
            return {
                mapUrl: mapUri(
                    this.model.get( 'regionName' )
                    , this.model.get( 'position' ).x
                    , this.model.get( 'position' ).y
                    , this.model.get( 'position' ).z
                )
            };
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
