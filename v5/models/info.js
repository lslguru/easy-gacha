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
            , inventoryChanged: null
            , lastPing: null
            , inventoryCount: null
            , itemCount: null
            , payoutCount: null
            , regionName: null
            , position: null
            , configured: null
            , price: null
            , extra: null
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

            if( '(No Description)' === data[3] ) {
                data[3] = '';
            }

            try {
                data[16] = JSON.parse( data[16] );
            } catch( e ) {
                data[16] = {};
            }

            return {
                isAdmin: Boolean( parseInt( data[0] , 10 ) )
                , ownerKey: data[1]
                , objectName: data[2]
                , objectDesc: data[3]
                , scriptName: data[4]
                , freeMemory: parseInt( data[5] , 10 )
                , debitPermission: Boolean( parseInt( data[6] , 10 ) )
                , inventoryChanged: Boolean( parseInt( data[7] , 10 ) )
                , lastPing: moment( parseInt( data[8] , 10 ) , 'X' )
                , inventoryCount: parseInt( data[9] , 10 )
                , itemCount: parseInt( data[10] , 10 )
                , payoutCount: parseInt( data[11] , 10 )
                , regionName: data[12]
                , position: new Vector( data[13] )
                , configured: Boolean( parseInt( data[14] , 10 ) )
                , price: parseInt( data[15] , 10 )
                , extra: data[16]
            };
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
