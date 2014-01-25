define( [

    'underscore'
    , 'models/base-sl-model'
    , 'lib/constants'

] , function(

    _
    , BaseModel
    , CONSTANTS

) {
    'use strict';

    var exports = BaseModel.extend( {
        url: 'configured'

        , defaults: {
            configured: null
        }

        , toPostJSON: function( options , syncMethod , xhrType ) {
            if( 'read' !== syncMethod ) {
                return [
                    Number( this.get( 'configured' ) )
                ];
            } else {
                return [];
            }
        }
    } );

    return exports;
} );
