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
            'default': '[href=#tab-items]' // duplicate on purpose
            , 'items': '[href=#tab-items]'
            , 'price': '[href=#tab-price]'
            , 'payouts': '[href=#tab-payouts]'
            , 'comms': '[href=#tab-comms]'
            , 'advanced': '[href=#tab-advanced]'
            , 'export': '[href=#tab-export]'
            , 'import': '[href=#tab-import]'
            , 'tabLinks': '[data-toggle=tab]'
        }

        , regions: {
            'items': '#tab-items'
            , 'price': '#tab-price'
            , 'payouts': '#tab-payouts'
            , 'comms': '#tab-comms'
            , 'advanced': '#tab-advanced'
            , 'export': '#tab-export'
            , 'import': '#tab-import'
        }

        , events: {
            'click @ui.tabLinks': 'showTab'
        }

        , subviews: {
            'items': {
                view: ItemsView
                , collectionFromAttribute: 'items'
            }

            , 'price': {
                view: PriceView
            }

            , 'payouts': {
                view: PayoutsView
                , collectionFromAttribute: 'payouts'
            }

            , 'comms': {
                view: CommsView
            }

            , 'advanced': {
                view: AdvancedView
            }

            , 'export': {
                view: ExportView
            }

            , 'import': {
                view: ImportView
            }
        }

        , initialize: function() {
            this.constructor.__super__.initialize.apply( this , arguments );
            this.model = this.options.model;
        }

        , showTab: function( jEvent ) {
            jEvent.preventDefault();

            var target = $( jEvent.currentTarget );
            target.tab( 'show' );

            var subviewName = target.data( 'subviewName' );
            var subviewConfig = this.subviews[ subviewName ];
            if( _.isFunction( subviewConfig.instance.onTabShown ) ) {
                target.one( 'shown.bs.tab' , function() {
                    subviewConfig.instance.onTabShown();
                } );
            }
        }

        , onRender: function() {
            _.each( this.subviews , function( subviewConfig , subviewName ) {
                // Subview instantiation and listeners
                var opts = this.options;
                if( subviewConfig.collectionFromAttribute ) {
                    opts = _.extend( {} , this.options , {
                        collection: this.model.get( subviewConfig.collectionFromAttribute )
                    } );
                }
                subviewConfig.instance = new subviewConfig.view( opts );
                this.listenTo( subviewConfig.instance , 'updateTabStatus' , _.partial( this.updateTabStatus , subviewName ) );

                // Region
                this[ subviewName ].show( subviewConfig.instance );

                // UI
                this.ui[ subviewName ].data( 'subviewName' , subviewName );
            } , this );

            this.options.app.vent.on( 'selectTab' , function( tabName ) {
                this.ui[ tabName ].tab( 'show' );
            } , this );

            this.ui.default.tab( 'show' );
        }

        , updateTabStatus: function( tabName , newStatus ) {
            var tabUi = this.ui[ tabName ];

            _.each( ( tabUi.attr( 'class' ) || '' ).split( /\s+/ ) , function( className ) {
                if( /^text-/.test( className ) ) {
                    tabUi.removeClass( className );
                }
            } , this );

            if( null !== newStatus ) {
                tabUi.addClass( 'text-' + newStatus );
            }
        }
    } );

    return exports;

} );
