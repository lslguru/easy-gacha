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

        , defaults: {
            primName: null
            , primDesc: null
            , primType: null
            , primTypeHoleShape: null
            , primTypeCut: null
            , primTypeHollow: null
            , primTypeTwist: null
            , primTypeTopSize: null
            , primTypeTopShear: null
            , primTypeDimple: null
            , primTypeHoleSize: null
            , primTypeAdvancedCut: null
            , primTypeTaper: null
            , primTypeRevolutions: null
            , primTypeRadiusOffset: null
            , primTypeSkew: null
            , primTypeSculptMap: null
            , primTypeSculptType: null
            , primSlice: null
            , primPhysicsShapeType: null
            , primMaterial: null
            , primPhysics: null
            , primTempOnRez: null
            , primPhantom: null
            , primPosition: null
            , primPosLocal: null
            , primRotation: null
            , primRotLocal: null
            , primSize: null
            , primText: null
            , primTextColor: null
            , primTextAlpha: null
            , primFlexible: null
            , primFlexibleSoftness: null
            , primFlexibleGravity: null
            , primFlexibleFriction: null
            , primFlexibleWind: null
            , primFlexibleTension: null
            , primFlexibleForce: null
            , primPointLight: null
            , primPointLightColor: null
            , primPointLightIntensity: null
            , primPointLightRadius: null
            , primPointLightFalloff: null
            , primOmegaAxis: null
            , primOmegaSpinrate: null
            , primOmegaGain: null
        }

        , toPostJSON: function() {
            return [
                this.linkNumber
            ];
        }

        , parse: function( data ) {
            if( null === data ) {
                return {};
            }

            var i = 0;
            var parsed = {};

            if( 'Object' == data[i] ) {
                data[i] = 'Unnamed';
            }
            parsed.primName = data[i++];

            if( '(No Description)' === data[i] ) {
                data[i] = '';
            }
            parsed.primDesc = data[i++];

            parsed.primType = parseInt( data[i++] , 10 );
            if(
                CONSTANTS.PRIM_TYPE_BOX === parsed.primType
                || CONSTANTS.PRIM_TYPE_CYLINDER === parsed.primType
                || CONSTANTS.PRIM_TYPE_PRISM === parsed.primType
            ) {
                parsed.primTypeHoleShape = parseInt( data[i++] , 10 );
                parsed.primTypeCut = new Vector( data[i++] );
                parsed.primTypeHollow = parseFloat( data[i++] , 10 );
                parsed.primTypeTwist = new Vector( data[i++] );
                parsed.primTypeTopSize = new Vector( data[i++] );
                parsed.primTypeTopShear = new Vector( data[i++] );
            }
            if( CONSTANTS.PRIM_TYPE_SPHERE === parsed.primType ) {
                parsed.primTypeHoleShape = parseInt( data[i++] , 10 );
                parsed.primTypeCut = new Vector( data[i++] );
                parsed.primTypeHollow = parseFloat( data[i++] , 10 );
                parsed.primTypeTwist = new Vector( data[i++] );
                parsed.primTypeDimple = new Vector( data[i++] );
            }
            if(
                CONSTANTS.PRIM_TYPE_TORUS === parsed.primType
                || CONSTANTS.PRIM_TYPE_TUBE === parsed.primType
                || CONSTANTS.PRIM_TYPE_RING === parsed.primType
            ) {
                parsed.primTypeHoleShape = parseInt( data[i++] , 10 );
                parsed.primTypeCut = new Vector( data[i++] );
                parsed.primTypeHollow = parseFloat( data[i++] , 10 );
                parsed.primTypeTwist = new Vector( data[i++] );
                parsed.primTypeHoleSize = new Vector( data[i++] );
                parsed.primTypeTopShear = new Vector( data[i++] );
                parsed.primTypeAdvancedCut = new Vector( data[i++] );
                parsed.primTypeTaper = new Vector( data[i++] );
                parsed.primTypeRevolutions = parseFloat( data[i++] , 10 );
                parsed.primTypeRadiusOffset = parseFloat( data[i++] , 10 );
                parsed.primTypeSkew = parseFloat( data[i++] , 10 );
            }
            if( CONSTANTS.PRIM_TYPE_SCULPT === parsed.primType ) {
                parsed.primTypeSculptMap = data[i++];
                parsed.primTypeSculptType = parseInt( data[i++] , 10 );
            }

            parsed.primSlice = new Vector( data[i++] );

            parsed.primPhysicsShapeType = parseInt( data[i++] , 10 );

            parsed.primMaterial = parseInt( data[i++] , 10 );

            parsed.primPhysics = Boolean( data[i++] , 10 );

            parsed.primTempOnRez = Boolean( data[i++] , 10 );

            parsed.primPhantom = Boolean( data[i++] , 10 );

            parsed.primPosition = new Vector( data[i++] );

            parsed.primPosLocal = new Vector( data[i++] );

            parsed.primRotation = new Rotation( data[i++] );

            parsed.primRotLocal = new Rotation( data[i++] );

            parsed.primSize = new Vector( data[i++] );

            parsed.primText = data[i++];
            parsed.primTextColor = new Vector( data[i++] );
            parsed.primTextAlpha = parseFloat( data[i++] , 10 );

            parsed.primFlexible = Boolean( parseInt( data[i++] , 10 ) );
            parsed.primFlexibleSoftness = parseInt( data[i++] , 10 );
            parsed.primFlexibleGravity = parseFloat( data[i++] , 10 );
            parsed.primFlexibleFriction = parseFloat( data[i++] , 10 );
            parsed.primFlexibleWind = parseFloat( data[i++] , 10 );
            parsed.primFlexibleTension = parseFloat( data[i++] , 10 );
            parsed.primFlexibleForce = new Vector( data[i++] );

            parsed.primPointLight = Boolean( parseInt( data[i++] , 10 ) );
            parsed.primPointLightColor = new Vector( data[i++] );
            parsed.primPointLightIntensity = parseFloat( data[i++] , 10 );
            parsed.primPointLightRadius = parseFloat( data[i++] , 10 );
            parsed.primPointLightFalloff = parseFloat( data[i++] , 10 );

            parsed.primOmegaAxis = new Vector( data[i++] );
            parsed.primOmegaSpinrate = parseFloat( data[i++] , 10 );
            parsed.primOmegaGain = parseFloat( data[i++] , 10 );

            return parsed;
        }
    } );

    return exports;
} );
