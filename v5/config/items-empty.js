define( [

    'marionette'
    , 'hbs!config/templates/items-empty'
    , 'bootstrap'

] , function(

    Marionette
    , template
    , bootstrap

) {
    'use strict';

    var exports = Marionette.ItemView.extend( {
        template: template
        , tagName: 'tr'

        , ui: {
            'reloadLink': '.trigger-reload'
        }

        , events: {
            'click @ui.reloadLink': 'reload'
        }

        , reload: function() {
            this.options.app.vent.trigger( 'reloadRequested' );
        }
    } );

    return exports;

} );
