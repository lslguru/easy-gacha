define( [

    'underscore'
    , 'jquery'
    , 'marionette'
    , 'hbs!config/templates/tabs'
    , 'css!config/styles/tabs'
    , 'bootstrap'
    , 'config/items'
    , 'config/price'
    , 'config/payouts'
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
    , PriceView
    , PayoutsView
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
            , 'itemsTab': '[href=#tab-items]'
            , 'priceTab': '[href=#tab-price]'
            , 'payoutsTab': '[href=#tab-payouts]'
            , 'commsTab': '[href=#tab-comms]'
            , 'advancedTab': '[href=#tab-advanced]'
            , 'exportTab': '[href=#tab-export]'
            , 'importTab': '[href=#tab-import]'
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

        , initialize: function() {
            this.constructor.__super__.initialize.apply( this , arguments );
            this.model = this.options.model;
        }

        , onRender: function() {
            this.itemsTab.show( new ItemsView( _.extend( {} , this.options , {
                collection: this.model.get( 'items' )
            } ) ) );

            this.priceTab.show( new PriceView( this.options ) );

            this.payoutsTab.show( new PayoutsView( _.extend( {} , this.options , {
                collection: this.model.get( 'payouts' )
            } ) ) );

            this.commsTab.show( new CommsView( this.options ) );
            this.advancedTab.show( new AdvancedView( this.options ) );
            this.exportTab.show( new ExportView( this.options ) );
            this.importTab.show( new ImportView( this.options ) );

            this.ui.tabLinks.click( function( e ) {
                e.preventDefault();
                $( this ).tab( 'show' );
            } );

            this.ui.defaultTab.tab( 'show' );

            this.options.app.vent.on( 'selectTab' , function( tabName ) {
                this.ui[ tabName + 'Tab' ].tab( 'show' );
            } , this );

        }

        , signalTabShown: function( jEvent ) {
            this.$( $( jEvent.currentTarget ).attr( 'href' ) ).children().trigger( 'shown' );
        }
    } );

    return exports;

} );
