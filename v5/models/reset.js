define( [

    'models/base-sl-model'

] , function(

    BaseModel

) {
    'use strict';

    // If fetched/saved/deleted, will cause script to completely reset,
    // invalidating our control URL

    var exports = BaseModel.extend( {
        url: 'reset'

        , toPostJSON: function( options , method , type ) {
            return [];
        }
    } );

    return exports;
} );
