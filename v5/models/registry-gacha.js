define( [

    'underscore'
    , 'backbone'

] , function(

    _
    , Backbone

) {
    'use strict';

    var exports = Backbone.Model.extend( {
        url: function() {
            var url = '//lslguru.com/api/easy-gacha/5/search.php?get=' + encodeURIComponent( this.urlParams.get );

            _.each( this.urlparams , function( value , key ) {
                if( null !== value && 'get' !== key ) {
                    url += '&' + encodeURIComponent( key ) + '=' + encodeURIComponent( value );
                }
            } , this );

            return url;
        }

        , idAttribute: 'baseUrl'

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
        }

        , parse: function( data ) {
            if( _.isNumber( data ) ) {
                return {
                    count: data
                };
            }

            return data;
        }
    } );

    return exports;
} );
