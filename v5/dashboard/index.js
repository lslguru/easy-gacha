define( [

    'underscore'
    , 'marionette'
    , 'hbs!dashboard/templates/index'
    , './loader'
    , './header'
    , './items'
    , 'backbone'

] , function(

    _
    , Marionette
    , template
    , LoaderView
    , HeaderView
    , ItemsView
    , Backbone

) {
    'use strict';

    var exports = Marionette.Layout.extend( {
        template: template

        , regions: {
            'loader': '#data-loader'
            , 'header': '#header'
            , 'items': '#items'
        }

        , onRender: function() {
            var data = new Backbone.Model();

            this.loader.show( new LoaderView( _.extend( {} , this.options , {
                model: data
            } ) ) );

            data.bind( 'change:percentage' , function( data , percentage , options ) {
                if( 100 === percentage ) {
                    this.loader.close();

                    this.header.show( new HeaderView( _.extend( {} , this.options , {
                        model: data.get( 'info' )
                    } ) ) );

                    this.items.show( new ItemsView( _.extend( {} , this.options , {
                        collection: null
                    } ) ) );
                }
            } , this );
        }
    } );

    return exports;

} );
