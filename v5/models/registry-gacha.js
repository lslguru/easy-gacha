define( [

    'underscore'
    , 'backbone'
    , 'lib/constants'
    , 'lib/vector'

] , function(

    _
    , Backbone
    , CONSTANTS
    , Vector

) {
    'use strict';

    var exports = Backbone.Model.extend( {
        idAttribute: 'baseUrl'

        , urlParams: {
            get: 'count'
            , maxPrice: null
            , searchString: null
        }

        , defaults: {
            count: null
            , ownerDisplayname: null
            , ownerUsername: null
            , baseUrl: null
            , objectName: null
            , objectDesc: null
            , regionName: null
            , position: null
        }

        , initialize: function() {
            this.urlParams = _.clone( this.urlParams );
        }

        , url: function() {
            var url = '//lslguru.com/api/easy-gacha/5/search.php?get=' + encodeURIComponent( this.urlParams.get );

            _.each( this.urlParams , function( value , key ) {
                if( null !== value && 'get' !== key ) {
                    url += '&' + encodeURIComponent( key ) + '=' + encodeURIComponent( value );
                }
            } , this );

            return url;
        }

        , parse: function( data ) {
            // If a count was requested instead of details
            if( _.isNumber( data ) ) {
                return {
                    count: data
                };
            }

            // If this record is no longer valid, exit early
            if( null === data ) {
                return null;
            }

            // People who leave these in should have them treated as empty
            if( data.objectDesc && -1 !== CONSTANTS.EMPTY_DESCRIPTIONS.indexOf( data.objectDesc ) ) {
                data.objectDesc = '';
            }

            // Convert to native data type
            data.position = new Vector( data.position );

            return data;
        }
    } );

    return exports;
} );
