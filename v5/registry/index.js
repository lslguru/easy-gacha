define( [

    'underscore'
    , 'marionette'
    , 'hbs!registry/templates/index'
    , 'css!registry/styles/index'
    , 'bootstrap'
    , 'models/registry'

] , function(

    _
    , Marionette
    , template
    , styles
    , bootstrap
    , Registry

) {
    'use strict';

    var exports = Marionette.Layout.extend( {
        template: template

        , initialize: function() {
            this.collection = new Registry();

            // For debug convenience
            window.registry = this.collection;
        }
    } );

    return exports;

} );
