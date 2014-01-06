define( [

    'backbone'
    , 'models/base-sl'

] , function(

    Backbone
    , BaseSl

) {
    'use strict';

    var exports = Backbone.Model.extend( BaseSl );

    return exports;
} );
