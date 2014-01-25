define( [

    'models/base-sl-model'

] , function(

    BaseModel

) {
    'use strict';

    var exports = BaseModel.extend( {
        url: 'email'

        , defaults: {
            email: null
        }

        , toPostJSON: function( options , syncMethod , xhrType ) {
            if( 'read' !== syncMethod ) {
                return [
                    this.get( 'email' )
                ];
            } else {
                return [];
            }
        }

        , parse: function( data ) {
            if( null === data ) {
                return {};
            }

            return {
                email: data[0]
            };
        }
    } );

    return exports;
} );
