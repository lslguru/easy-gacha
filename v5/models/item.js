define( [

    'models/base-sl-model'
    , 'lib/constants'

] , function(

    BaseModel
    , CONSTANTS

) {
    'use strict';

    var exports = BaseModel.extend( {
        url: 'item'

        , toPostJSON: function( options , syncMethod , xhrType ) {
            // TODO: Save?

            return [
                this.get( 'index' )
            ];
        }

        , defaults: {
            index: null
            , rarity: null
            , limit: null
            , bought: null
            , name: null
            , type: null
            , creator: null
            , keyAvailable: null
            , ownerPermissions: null
            , groupPermissions: null
            , publicPermissions: null
            , nextPermissions: null
        }

        , parse: function( data ) {
            if( null === data ) {
                return {};
            }

            return {
                index: parseInt( data[0] , 10 )
                , rarity: parseFloat( data[1] , 10 )
                , limit: parseInt( data[2] , 10 )
                , bought: parseInt( data[3] , 10 )
                , name: data[4]
                , type: CONSTANTS.INVENTORY_NUMBER_TO_TYPE[ parseInt( data[5] , 10 ) ] || 'INVENTORY_NONE'
                , creator: data[6]
                , keyAvailable: Boolean( parseInt( data[7] , 10 ) )
                , ownerPermissions: parseInt( data[8] , 10 )
                , groupPermissions: parseInt( data[9] , 10 )
                , publicPermissions: parseInt( data[10] , 10 )
                , nextPermissions: parseInt( data[11] , 10 )
            };
        }
    } );

    return exports;
} );
