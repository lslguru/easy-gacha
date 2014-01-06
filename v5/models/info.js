define( [

    'models/base-sl-model'
    , 'lib/vector'

] , function(

    BaseModel
    , Vector

) {
    'use strict';

    var exports = BaseModel.extend( {
        url: 'info'

        , defaults: {
            isAdmin: null
            , ownerKey: null
            , objectName: null
            , objectDesc: null
            , scriptName: null
            , freeMemory: null
            , debitPermission: null
            , inventoryChanged: null
            , lastPing: null
            , inventoryCount: null
            , payoutCount: null
            , regionName: null
            , position: null
        }

        , parse: function( data ) {
            if( null === data ) {
                return {};
            }

            var lastPing = new Date();
            lastPing.setTime( data[8] * 1000 );

            if( '(No Description)' === data[3] ) {
                data[3] = '';
            }

            return {
                isAdmin: Boolean(data[0])
                , ownerKey: data[1]
                , objectName: data[2]
                , objectDesc: data[3]
                , scriptName: data[4]
                , freeMemory: Number(data[5])
                , debitPermission: Boolean(data[6])
                , inventoryChanged: Boolean(data[7])
                , lastPing: lastPing
                , inventoryCount: Number(data[9])
                , payoutCount: Number(data[10])
                , regionName: data[11]
                , position: new Vector( data[12] )
            };
        }
    } );

    return exports;
} );
