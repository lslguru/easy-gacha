define( [

    'require'
    , 'marionette'
    , 'hbs!dashboard/templates/header'
    , 'css!dashboard/styles/header'
    , 'bootstrap'
    , 'css!//netdna.bootstrapcdn.com/font-awesome/4.0.3/css/font-awesome'
    , 'lib/constants'

] , function(

    require
    , Marionette
    , template
    , headerStyles
    , bootstrap
    , fontawesomeStyles
    , CONSTANTS

) {
    'use strict';

    var exports = Marionette.ItemView.extend( {
        template: template

        , modelEvents: {
            'change': 'render'
        }

        , ui: {
            'tooltips': '[data-toggle=tooltip]'
        }

        , templateHelpers: function() {
            if( null === this.model.get( 'freeMemory' ) ) {
                return {};
            }

            return {
                mapUrl: (
                    'http://maps.secondlife.com/secondlife/'
                    + encodeURIComponent( this.model.get( 'regionName' ) )
                    + '/'
                    + Math.round( this.model.get( 'position' ).x )
                    + '/'
                    + Math.round( this.model.get( 'position' ).y )
                    + '/'
                    + Math.round( this.model.get( 'position' ).z )
                    + '/?title='
                    + encodeURIComponent( this.model.get( 'objectName' ) )
                    + '&msg='
                    + encodeURIComponent( 'Here is where the Easy Gacha is located' )
                    + '&img='
                    + require.toUrl( 'images/transparent-pixel.gif' ).replace( /:/g , '%3A' ) // Not a full escape... per their odd specification
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
                , placement: 'auto'
            } );
        }
    } );

    return exports;

} );
