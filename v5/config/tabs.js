define( [

    'underscore'
    , 'jquery'
    , 'marionette'
    , 'hbs!config/templates/tabs'
    , 'css!config/styles/tabs'
    , 'bootstrap'
    , 'config/comms'
    , 'config/advanced'

] , function(

    _
    , $
    , Marionette
    , template
    , styles
    , bootstrap
    , CommsView
    , AdvancedView

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
            , 'advanced': '#tab-advanced'
            , 'imp': '#tab-import'
            , 'exp': '#tab-export'
        }

        , onRender: function() {
            this.comms.show( new CommsView( _.extend( {} , this.options , {
                model: this.options.model.get( 'config' )
            } ) ) );

            this.advanced.show( new AdvancedView( _.extend( {} , this.options , {
                model: this.options.model.get( 'config' )
            } ) ) );

            this.ui.tabLinks.click( function( e ) {
                e.preventDefault();
                $( this ).tab( 'show' );
            } );

            this.ui.defaultTab.tab( 'show' );
        }
    } );

    return exports;

} );
