define( [

    'marionette'
    , 'hbs!dashboard/templates/items'

] , function(

    Marionette
    , template

) {
    'use strict';

    // TODO: CompositeView
    var exports = Marionette.ItemView.extend( {
        template: template
    } );

    return exports;

} );
