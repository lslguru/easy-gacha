define( [

    'underscore'
    , 'marionette'
    , 'hbs!registry/templates/result-gacha'
    , 'css!registry/styles/result-gacha'
    , 'lib/tooltip-placement'
    , 'bootstrap'
    , 'lib/map-uri'
    , 'google-analytics'

] , function(

    _
    , Marionette
    , template
    , styles
    , tooltipPlacement
    , bootstrap
    , mapUri
    , ga

) {
    'use strict';

    var exports = Marionette.ItemView.extend( {
        template: template
        , className: 'gacha'

        , ui: {
            'tooltips': '[data-toggle=tooltip]'
            , 'loadGachaPageLink': '.load-gacha-page-link'
            , 'teleportToGachaLink': '.teleport-to-gacha-link'
        }

        , events: {
            'mousedown @ui.loadGachaPageLink': 'decorateLink'
            , 'keydown @ui.loadGachaPageLink': 'decorateLink'
            , 'click @ui.teleportToGachaLink': 'teleportLink'
        }

        , templateHelpers: function() {
            return {
                mapUrl: mapUri(
                    this.model.get( 'regionName' )
                    , this.model.get( 'position' ).x
                    , this.model.get( 'position' ).y
                    , this.model.get( 'position' ).z
                )

                , objectDescPrefixed: (
                    this.model.get( 'objectDesc' )
                    ? 'Object Description: ' + this.model.get( 'objectDesc' )
                    : ''
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

        , decorateLink: function( jEvent ) {
            var originalHref = jEvent.currentTarget.href;
            var target = jEvent.currentTarget;

            ga( 'linker:decorate' , target );

            _.delay( function() {
                target.href = originalHref;
            } , 100 );
        }

        , teleportLink: function() {
            ga( 'send' , 'event' , 'registry' , 'teleport' );
        }
    } );

    return exports;

} );
