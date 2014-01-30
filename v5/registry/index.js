define( [

    'underscore'
    , 'marionette'
    , 'hbs!registry/templates/index'
    , 'css!registry/styles/index'
    , 'bootstrap'

] , function(

    _
    , Marionette
    , template
    , styles
    , bootstrap

) {
    'use strict';

    var exports = Marionette.Layout.extend( {
        template: template
    } );

    return exports;

} );
