define( [

    'models/base-sl-model'
    , 'lib/vector'
    , 'lib/rotation'
    , 'lib/constants'

] , function(

    BaseModel
    , Vector
    , Rotation
    , CONSTANTS

) {
    'use strict';

    var exports = BaseModel.extend( {
        url: 'prim'

        , linkNumber: CONSTANTS.LINK_THIS
        , faceNumber: 0

        , defaults: {
            primTexture: null // key
            , primTextureRepeats: null // vector
            , primTextureOffsets: null // vector
            , primTextureRotation: null // float
            , primColor: null // vector
            , primAlpha: null // float
            , primShiny: null // integer
            , primBump: null // integer
            , primFullbright: null // boolean
            , primTexgenMode: null // integer
            , primGlow: null // float
        }

        , toPostJSON: function() {
            return [
                this.linkNumber
                , this.faceNumber
            ];
        }

        , parse: function( data ) {
            if( null === data ) {
                return {};
            }

            var i = 0;
            var parsed = {};

            parsed.primTexture = data[i++] || CONSTANTS.NULL_KEY;
            parsed.primTextureRepeats = new Vector( data[i++] );
            parsed.primTextureOffsets = new Vector( data[i++] );
            parsed.primTextureRotation = parseFloat( data[i++] , 10 );
            parsed.primColor = new Vector( data[i++] );
            parsed.primAlpha = parseFloat( data[i++] , 10 );
            parsed.primShiny = parseInt( data[i++] , 10 );
            parsed.primBump = parseInt( data[i++] , 10 );
            parsed.primFullbright = Boolean( parseInt( data[i++] , 10 ) );
            parsed.primTexgenMode = parseInt( data[i++] , 10 );
            parsed.primGlow = parseFloat( data[i++] , 10 );

            return parsed;
        }
    } );

    return exports;
} );
