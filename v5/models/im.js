define( [

    'models/base-sl-model'
    , 'lib/constants'

] , function(

    BaseModel
    , CONSTANTS

) {
    'use strict';

    var exports = BaseModel.extend( {
        url: 'im'

        , defaults: {
            key: null
        }

        , toPostJSON: function( options , syncMethod , xhrType ) {
            return [
                this.get( 'key' ) || CONSTANTS.NULL_KEY
            ];
        }

        , parse: function( data ) {
            if( null === data ) {
                return {};
            }

            return {
                key: data[0]
            };
        }
    } );

    return exports;
} );
