define( [

    'models/base-sl-lookup'

] , function(

    BaseModel

) {
    'use strict';

    var exports = BaseModel.extend( {
        subject: 'notecard-line-count'
    } );

    return exports;
} );
