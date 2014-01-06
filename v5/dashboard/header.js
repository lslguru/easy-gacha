define( [

    'marionette'
    , 'hbs!./templates/header'
    , 'css!./styles/header'
    , 'bootstrap'

] , function(

    Marionette
    , template
    , bootstrap

) {
    'use strict';

    var exports = Marionette.ItemView.extend( {
        template: template

        , modelEvents: {
            'change': 'render'
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
                    + encodeURIComponent( 'Here is where this Easy Gacha is located' )
                )
            };
        }

        , onRender: function() {
            this.$( '[data-toggle=tooltip][data-tooltip-placement=right]' ).tooltip( {
                html: true
                , placement: 'right'
            } );
        }
    } );

    return exports;

} );
