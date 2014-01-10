define( [

    'marionette'
    , 'hbs!config/templates/header'
    , 'css!config/styles/header'
    , 'bootstrap'
    , 'css!//netdna.bootstrapcdn.com/font-awesome/4.0.3/css/font-awesome'
    , 'lib/constants'
    , 'lib/tooltip-placement'

] , function(

    Marionette
    , template
    , headerStyles
    , bootstrap
    , fontawesomeStyles
    , CONSTANTS
    , tooltipPlacement

) {
    'use strict';

    var exports = Marionette.ItemView.extend( {
        template: template

        , ui: {
            'tooltips': '[data-toggle=tooltip]'
        }

        , templateHelpers: function() {
            if( null === this.model.get( 'freeMemory' ) ) {
                return {};
            }

            return {
                mapUrl: (
                    'secondlife:///worldmap/'
                    + encodeURIComponent( this.model.get( 'regionName' ) )
                    + '/'
                    + Math.round( this.model.get( 'position' ).x )
                    + '/'
                    + Math.round( this.model.get( 'position' ).y )
                    + '/'
                    + Math.round( this.model.get( 'position' ).z )
                )

                , dangerMemory: (
                    null !== this.model.get( 'freeMemory' )
                    && this.model.get( 'freeMemory' ) < CONSTANTS.DANGER_MEMORY_THRESHOLD
                )

                , warnMemory: (
                    null !== this.model.get( 'freeMemory' )
                    && this.model.get( 'freeMemory' ) < CONSTANTS.WARN_MEMORY_THRESHOLD
                )

                , ownerUrl: (
                    'secondlife:///app/agent/'
                    + this.model.get( 'ownerKey' )
                    + '/about'
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
    } );

    return exports;

} );
