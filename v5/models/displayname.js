define( [

    'models/base-sl-lookup'

] , function(

    BaseModel

) {
    'use strict';

    var exports = BaseModel.extend( {
        subject: 'displayname'
    } );

    return exports;
} );
