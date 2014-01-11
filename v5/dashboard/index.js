define( [

    'underscore'
    , 'marionette'
    , 'hbs!dashboard/templates/index'
    , 'lib/loader-view'
    , 'dashboard/header'
    , 'dashboard/items'
    , 'models/gacha'
    , 'bootstrap'

] , function(

    _
    , Marionette
    , template
    , LoaderView
    , HeaderView
    , ItemsView
    , Gacha
    , bootstrap

) {
    'use strict';

    var exports = Marionette.Layout.extend( {
        template: template

        , regions: {
            'loader': '#loader'
            , 'header': '#header'
            , 'items': '#items'
        }

        , onRender: function() {
            var gacha = new Gacha();

            this.loader.show( new LoaderView( _.extend( {} , this.options , {
                model: gacha
            } ) ) );

            gacha.on( 'change:progressPercentage' , function( gacha , percentage , options ) {
                if( 100 === percentage ) {
                    this.loader.close();

                    this.header.show( new HeaderView( _.extend( {} , this.options , {
                        model: gacha.get( 'info' )
                    } ) ) );

                    this.items.show( new ItemsView( _.extend( {} , this.options , {
                        collection: gacha.get( 'items' )
                    } ) ) );
                }
            } , this );

            function updatePageTitle() {
                if( gacha.get( 'info' ) && gacha.get( 'info' ).get( 'objectName' ) ) {
                    document.title = gacha.get( 'info' ).get( 'objectName' ) + ' - Easy Gacha Dashboard';
                } else {
                    document.title = 'Easy Gacha Dashboard';
                }
            }

            function setupListener() {
                gacha.get( 'info' ).on( 'change:objectName' , updatePageTitle , this );
            }

            gacha.on( 'change:info' , function() {
                if( gacha.previous( 'info' ) ) {
                    gacha.previous( 'info' ).off( null , null , this );
                }

                setupListener();
                updatePageTitle();
            } , this );

            setupListener();
            updatePageTitle();
            gacha.fetch();
        }
    } );

    return exports;

} );
