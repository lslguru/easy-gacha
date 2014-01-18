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
            this.model = new Gacha();
            this.options.model = this.model;
            this.options.gacha = this.model;
            window.gacha = this.model;

            this.loader.show( new LoaderView( this.options ) );

            this.model.on( 'change:progressPercentage' , function( gacha , percentage , options ) {
                if( 100 === percentage ) {
                    this.loader.close();

                    this.header.show( new HeaderView( this.options ) );

                    this.items.show( new ItemsView( _.extend( {} , this.options , {
                        collection: this.model.get( 'items' )
                    } ) ) );
                }
            } , this );

            var updatePageTitle = _.bind( function() {
                if( this.model.get( 'objectName' ) ) {
                    document.title = this.model.get( 'objectName' ) + ' - Easy Gacha Dashboard';
                } else {
                    document.title = 'Easy Gacha Dashboard';
                }
            } , this );

            this.model.on( 'change:objectName' , updatePageTitle );
            updatePageTitle();
            this.model.fetch();
        }
    } );

    return exports;

} );
