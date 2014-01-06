define( [

    'models/base-sl-lookup'

] , function(

    BaseModel

) {
    'use strict';

    var exports = BaseModel.extend( {
        subject: 'username'
    } );

    return exports;
} );
