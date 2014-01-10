define( [

    'underscore'
    , 'marionette'
    , 'hbs!config/templates/index'
    , 'backbone'
    , 'bootstrap'
    , 'config/loader'
    , 'config/header'

] , function(

    _
    , Marionette
    , template
    , Backbone
    , bootstrap
    , LoaderView
    , HeaderView

) {
    'use strict';

    var exports = Marionette.Layout.extend( {
        template: template

        , regions: {
            'loader': '#loader'
            , 'header': '#header'
            // TODO: Other regions
        }

        , onRender: function() {
            var data = new Backbone.Model();

            this.loader.show( new LoaderView( _.extend( {} , this.options , {
                model: data
            } ) ) );

            data.bind( 'change:percentage' , function( data , percentage , options ) {
                if( 100 === percentage ) {
                    this.loader.close();

                    this.loader.show( new HeaderView( _.extend( {} , this.options , {
                        model: data.get( 'info' )
                    } ) ) );

                    // TODO: Show other regions
                }
            } , this );
        }
    } );

    return exports;

} );
