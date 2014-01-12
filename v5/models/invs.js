define( [

    'models/base-sl-collection'
    , 'models/inv'

] , function(

    BaseCollection
    , Inv

) {
    'use strict';

    var exports = BaseCollection.extend( {
        model: Inv
        , comparator: 'name'

        , fromNotecardJSON: null
        , toNotecardJSON: null
    } );

    return exports;
} );
