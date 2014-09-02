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
    , 'lib/google-analytics'

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
    , ga

) {
    'use strict';

    var exports = Marionette.Layout.extend( {
        template: template

        , defaultTab: 'items'
        , afterScriptResetTab: 'export'

        , ui: {
            'items': '[href=#tab-items]'
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

        , initialize: function initialize( options ) {
            Marionette.Layout.prototype.initialize.apply( this , arguments );
            this.defaultTab = options && options.defaultTab || this.defaultTab;
        }

        , setCurrentTab: function( tabName ) {
            this.options.app.router.navigate( 'config/' + tabName , { replace: true } );

            ga( 'set' , 'page' , '/config/' + tabName );
            ga( 'send' , 'pageview' );
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

            this.setCurrentTab( subviewName );
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

                // Listen for warning/danger
                this.listenTo( this.model , 'change:hasWarning_' + subviewName + ' change:hasDanger_' + subviewName , this.updateTabStatuses );

                // Region
                this[ subviewName ].show( subviewConfig.instance );

                // UI
                this.ui[ subviewName ].data( 'subviewName' , subviewName );
            } , this );

            this.options.app.vent.on( 'selectTab' , function( tabName ) {
                if( 'default' === tabName ) {
                    tabName = this.defaultTab;
                }

                this.ui[ tabName ].tab( 'show' );
                this.setCurrentTab( tabName );
            } , this );

            this.ui[ this.defaultTab ].tab( 'show' );
            this.setCurrentTab( this.defaultTab );

            this.listenTo( this.options.app.vent , 'lslScriptReset' , this.resetOccurred );

            this.updateTabStatuses();
        }

        , updateTabStatuses: function() {
            _.each( this.subviews , function( subviewConfig , subviewName ) {
                var hasWarning = this.model.get( 'hasWarning_' + subviewName );
                var hasDanger = this.model.get( 'hasDanger_' + subviewName );
                var tabUiColorize = this.ui[ subviewName ].find( '.colorize' );

                tabUiColorize.toggleClass( 'text-danger' , Boolean( hasDanger ) );
                tabUiColorize.toggleClass( 'text-warning' , Boolean( !hasDanger && hasWarning ) );
            } , this );
        }

        , resetOccurred: function() {
            _.each( this.subviews , function( subviewConfig , subviewName ) {
                if( this.afterScriptResetTab === subviewName ) {
                    this.ui[ subviewName ].tab( 'show' );
                } else {
                    this.ui[ subviewName ].remove();
                    this[ subviewName ].close();
                }
            } , this );
        }
    } );

    return exports;

} );
