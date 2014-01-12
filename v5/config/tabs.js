define( [

    'underscore'
    , 'jquery'
    , 'marionette'
    , 'hbs!config/templates/tabs'
    , 'css!config/styles/tabs'
    , 'bootstrap'
    , 'config/items'
    , 'config/comms'
    , 'config/advanced'
    , 'config/export'
    , 'config/import'

] , function(

    _
    , $
    , Marionette
    , template
    , styles
    , bootstrap
    , ItemsView
    , CommsView
    , AdvancedView
    , ExportView
    , ImportView

) {
    'use strict';

    var exports = Marionette.Layout.extend( {
        template: template

        , ui: {
            'tabLinks': '[data-toggle=tab]'
            , 'defaultTab': '[href=#tab-items]'
        }

        , regions: {
            'itemsTab': '#tab-items'
            , 'priceTab': '#tab-price'
            , 'payoutsTab': '#tab-payouts'
            , 'commsTab': '#tab-comms'
            , 'advancedTab': '#tab-advanced'
            , 'exportTab': '#tab-export'
            , 'importTab': '#tab-import'
        }

        , events: {
            'click [data-toggle=tab]': 'signalTabShown'
        }

        , onRender: function() {
            this.itemsTab.show( new ItemsView( _.extend( {} , this.options , {
                collection: this.options.model.get( 'items' )
            } ) ) );

            this.commsTab.show( new CommsView( _.extend( {} , this.options , {
                model: this.options.model.get( 'config' )
            } ) ) );

            this.advancedTab.show( new AdvancedView( _.extend( {} , this.options , {
                model: this.options.model.get( 'config' )
            } ) ) );

            this.exportTab.show( new ExportView( this.options ) );
            this.importTab.show( new ImportView( this.options ) );

            this.ui.tabLinks.click( function( e ) {
                e.preventDefault();
                $( this ).tab( 'show' );
            } );

            this.ui.defaultTab.tab( 'show' );
        }

        , signalTabShown: function( jEvent ) {
            this.$( $( jEvent.currentTarget ).attr( 'href' ) ).children().trigger( 'shown' );
        }
    } );

    return exports;

} );
