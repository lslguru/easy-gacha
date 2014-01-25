define( [

    'marionette'
    , 'hbs!dashboard/templates/items-empty'
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
    } );

    return exports;

} );
