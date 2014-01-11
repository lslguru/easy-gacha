define( [

    'models/base-sl-model'
    , 'lib/vector'
    , 'moment'
    , 'lib/constants'
    , 'models/agents-cache'

] , function(

    BaseModel
    , Vector
    , moment
    , CONSTANTS
    , agentsCache

) {
    'use strict';

    var exports = BaseModel.extend( {
        url: 'info'

        , defaults: {
            isAdmin: null
            , ownerKey: null
            , ownerUserName: null
            , ownerDisplayName: null
            , objectName: null
            , objectDesc: null
            , scriptName: null
            , freeMemory: null
            , debitPermission: null
            , lastPing: null
            , inventoryCount: null
            , itemCount: null
            , payoutCount: null
            , regionName: null
            , position: null
            , configured: null
            , price: null
            , extra: null
            , primName: null
            , primDesc: null
        }

        , toPostJSON: function() {
            return [
                this.get( 'configured' )
                , JSON.stringify( this.get( 'extra' ) )
            ];
        }

        , parse: function( data ) {
            if( null === data ) {
                return {};
            }

            var i = 0;
            var ret = {};

            ret.isAdmin = Boolean( parseInt( data[i++] , 10 ) );
            ret.ownerKey = data[i++];
            ret.objectName = data[i++];

            if( '(No Description)' === data[i] ) {
                data[i] = '';
            }
            ret.objectDesc = data[i++];

            ret.scriptName = data[i++];
            ret.freeMemory = parseInt( data[i++] , 10 );
            ret.debitPermission = Boolean( parseInt( data[i++] , 10 ) );
            ret.lastPing = moment( parseInt( data[i++] , 10 ) , 'X' );
            ret.inventoryCount = parseInt( data[i++] , 10 );
            ret.itemCount = parseInt( data[i++] , 10 );
            ret.payoutCount = parseInt( data[i++] , 10 );
            ret.regionName = data[i++];
            ret.position = new Vector( data[i++] );
            ret.configured = Boolean( parseInt( data[i++] , 10 ) );
            ret.price = parseInt( data[i++] , 10 );

            try {
                data[i] = JSON.parse( data[i] );
            } catch( e ) {
                data[i] = {};
            }
            ret.extra = data[i++];

            ret.primName = data[i++];
            ret.primDesc = data[i++];

            return ret;
        }

        , fetch: function( options ) {
            var success = options.success;
            var fetchOptions = _.clone( options );

            fetchOptions.success = _.bind( function( model , resp ) {
                if( !model.get( 'ownerKey' ) || CONSTANTS.NULL_KEY == model.get( 'ownerKey' ) ) {
                    if( success ) {
                        success.call( this , model , resp , options );
                    }

                    return;
                }

                agentsCache.fetch( {
                    id: model.get( 'ownerKey' )
                    , context: this
                    , success: function( agent ) {
                        this.set( {
                            ownerUserName: agent.get( 'username' )
                            , ownerDisplayName: agent.get( 'displayname' )
                        } );

                        if( success ) {
                            options.success.call( this , model , resp , options );
                        }
                    }
                } );
            } , this );

            BaseModel.prototype.fetch.call( this , fetchOptions );
        }
    } );

    return exports;
} );
