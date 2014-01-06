define( [

    'models/base-sl-collection'
    , 'models/item'

] , function(

    BaseCollection
    , Item

) {
    'use strict';

    var exports = BaseCollection.extend( {
        model: Item
    } );

    return exports;
} );
