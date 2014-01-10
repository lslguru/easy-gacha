define( [

    'models/base-sl-model'

] , function(

    BaseModel

) {
    'use strict';

    var exports = BaseModel.extend( {
        url: 'email'

        , defaults: {
            address: null
        }

        , toPostJSON: function( options , syncMethod , xhrType ) {
            return [
                this.get( 'address' )
            ];
        }

        , parse: function( data ) {
            if( null === data ) {
                return {};
            }

            return {
                address: data[0]
            };
        }
    } );

    return exports;
} );
