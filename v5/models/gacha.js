define( [

    'backbone'

] , function(

    Backbone

) {
    'use strict';

    var exports = Backbone.Model.extend( {
        defaults: {
            percentageLoaded: 0
            , info: null
            , config: null
            , payouts: null
            , items: null
            , invs: null
            , isValid: false
        }

        // TODO: Fetch (move out from loaders)
        // TODO: Validity checks
        // TODO: Save
    } );

    return exports;
} );
