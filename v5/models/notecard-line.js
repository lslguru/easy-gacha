define( [

    'models/base-sl-lookup'

] , function(

    BaseModel

) {
    'use strict';

    // .set( 'lookup' , [ notecardName , lineNumberIndexFromZero ] )

    var exports = BaseModel.extend( {
        subject: 'notecard-line'
    } );

    return exports;
} );
