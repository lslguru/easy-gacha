define( [

    'underscore'
    , 'models/base-sl-model'

] , function(

    _
    , BaseModel

) {
    'use strict';

    var exports = BaseModel.extend( {
        defaults: {
            lookup: null
            , raw: null
            , result: null
        }

        , url: function() {
            return 'lookup/';
        }

        , toPostJSON: function() {
            if( _.isArray( this.get( 'lookup' ) ) ) {
                return [ this.subject ].concat( this.get( 'lookup' ) );
            } else {
                return [ this.subject , this.get( 'lookup' ) ];
            }
        }

        , parse: function( data ) {
            return {
                raw: data
                , result: _.first( data )
            };
        }
    } );

    return exports;
} );
