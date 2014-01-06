define( [

    'underscore'
    , 'marionette'
    , 'hbs!./templates/index'
    , './header'

] , function(

    _
    , Marionette
    , template
    , HeaderView

) {
    'use strict';

    var exports = Marionette.Layout.extend( {
        template: template

        , regions: {
            'header': '#header'
            , 'inventory': '#inventory'
        }

        , onRender: function() {
            var info = this.options.app.info;
            info.fetch();

            this.header.show( new HeaderView( _.extend( {} , this.options , {
                model: info
            } ) ) );
        }
    } );

    return exports;

} );
