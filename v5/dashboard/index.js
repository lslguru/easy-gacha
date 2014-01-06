define( [

    'underscore'
    , 'marionette'
    , 'hbs!dashboard/templates/index'
    , './header'
    , './items'

] , function(

    _
    , Marionette
    , template
    , HeaderView
    , ItemsView

) {
    'use strict';

    var exports = Marionette.Layout.extend( {
        template: template

        , regions: {
            'header': '#header'
            , 'items': '#items'
        }

        , onRender: function() {
            var info = this.options.app.info;
            info.fetch();

            this.header.show( new HeaderView( _.extend( {} , this.options , {
                model: info
            } ) ) );

            this.items.show( new ItemsView( _.extend( {} , this.options , {
                collection: null
            } ) ) );
        }
    } );

    return exports;

} );
