define( [

    'marionette'
    , 'hbs!config/templates/tabs'
    , 'bootstrap'
    , 'jquery'

] , function(

    Marionette
    , template
    , bootstrap
    , $

) {
    'use strict';

    var exports = Marionette.Layout.extend( {
        template: template

        , ui: {
            'tabLinks': '[data-toggle=tab]'
            , 'defaultTab': '[href=#tab-inv]'
        }

        , regions: {
            'inv': '#tab-inv'
            , 'pay': '#tab-pay'
            , 'comms': '#tab-comms'
            , 'adv': '#tab-advanced'
            , 'imp': '#tab-import'
            , 'exp': '#tab-export'
        }

        , onRender: function() {
            this.ui.tabLinks.click( function( e ) {
                e.preventDefault();
                $( this ).tab( 'show' );
            } );

            this.ui.defaultTab.tab( 'show' );
        }
    } );

    return exports;

} );
