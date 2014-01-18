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
            'click @ui.tabLinks': 'signalTabShown'
        }

        , initialize: function() {
            this.constructor.__super__.initialize.apply( this , arguments );
            this.model = this.options.model;
        }

        , onRender: function() {
            this.itemsView = ( new ItemsView( _.extend( {} , this.options , {
                collection: this.model.get( 'items' )
            } ) ) );

            this.priceView = ( new PriceView( this.options ) );

            this.payoutsView = ( new PayoutsView( _.extend( {} , this.options , {
                collection: this.model.get( 'payouts' )
            } ) ) );

            this.commsView = ( new CommsView( this.options ) );
            this.advancedView = ( new AdvancedView( this.options ) );
            this.exportView = ( new ExportView( this.options ) );
            this.importView = ( new ImportView( this.options ) );

            _.each( [ 'items' , 'price' , 'payouts' , 'comms' , 'advanced' , 'export' , 'import' ] , function( name ) {
                this.listenTo( this[ name + 'View' ] , 'updateStatus' , _.partial( this.updateTabStatus , name + 'Tab' ) );
            } , this );

            this.ui.tabLinks.click( function( e ) {
                e.preventDefault();
                $( this ).tab( 'show' );
            } );

            this.options.app.vent.on( 'selectTab' , function( tabName ) {
                this.ui[ tabName + 'Tab' ].tab( 'show' );
            } , this );

            this.itemsTab.show( this.itemsView );
            this.priceTab.show( this.priceView );
            this.payoutsTab.show( this.payoutsView );
            this.commsTab.show( this.commsView );
            this.advancedTab.show( this.advancedView );
            this.exportTab.show( this.exportView );
            this.importTab.show( this.importView );

            this.ui.defaultTab.tab( 'show' );
        }

        , updateTabStatus: function( tabName , newStatus ) {
            var tabUi = this.ui[ tabName ];

            _.each( ( tabUi.attr( 'class' ) || '' ).split( /\s+/ ) , function( className ) {
                if( /^text-/.test( className ) ) {
                    tabUi.removeClass( className );
                }
            } , this );

            tabUi.addClass( 'text-' + newStatus );
        }

        , signalTabShown: function( jEvent ) {
            this.$( $( jEvent.currentTarget ).attr( 'href' ) ).children().trigger( 'shown' );
        }
    } );

    return exports;

} );
