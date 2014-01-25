define( [

    'models/base-sl-model'
    , 'lib/vector'
    , 'moment'
    , 'lib/constants'
    , 'models/agents-cache'
    , 'models/prim'

] , function(

    BaseModel
    , Vector
    , moment
    , CONSTANTS
    , agentsCache
    , Prim

) {
    'use strict';

    var exports = BaseModel.extend( {
        url: 'info'

        , defaults: {
            isAdmin: null
            , ownerKey: null
            , ownerUserName: null
            , ownerDisplayName: null
            , ready: null
            , objectName: null
            , objectDesc: null
            , scriptName: null
            , freeMemory: null
            , usedMemory: null
            , debitPermission: null
            , inventoryCount: null
            , itemCount: null
            , payoutCount: null
            , regionName: null
            , position: null
            , price: null
            , extra: null
            , numberOfPrims: null
            , scriptLinkNumber: null
            , creatorKey: null
            , creatorUserName: null
            , creatorDisplayname: null
            , groupKey: null
            , scriptCount: null
            , scriptTime: null
            , prim: null
        }

        , toPostJSON: function( options , method , type ) {
            return [];
        }

        , parse: function( data ) {
            if( null === data ) {
                return {};
            }

            var i = 0;
            var parsed = {};

            parsed.isAdmin = Boolean( parseInt( data[i++] , 10 ) );
            parsed.ownerKey = data[i++] || CONSTANTS.NULL_KEY;
            parsed.ready = Boolean( parseInt( data[i++] , 10 ) );

            if( 'Object' == data[i] ) {
                data[i] = 'Unnamed';
            }
            parsed.objectName = data[i++];

            if( '(No Description)' === data[i] ) {
                data[i] = '';
            }
            parsed.objectDesc = data[i++];

            parsed.scriptName = data[i++];
            parsed.freeMemory = parseInt( data[i++] , 10 );
            parsed.usedMemory = parseInt( data[i++] , 10 );
            parsed.debitPermission = Boolean( parseInt( data[i++] , 10 ) );
            parsed.inventoryCount = parseInt( data[i++] , 10 );
            parsed.itemCount = parseInt( data[i++] , 10 );
            parsed.payoutCount = parseInt( data[i++] , 10 );
            parsed.regionName = data[i++];
            parsed.position = new Vector( data[i++] );
            parsed.price = parseInt( data[i++] , 10 );

            try {
                if( _.isString( data[i] ) || !_.isObject( data[i] ) || _.isEmpty( data[i] ) ) {
                    data[i] = JSON.parse( data[i] );
                }
            } catch( e ) {
                data[i] = {
                    'button_price': CONSTANTS.DEFAULT_PRICE
                    , 'button_default': CONSTANTS.DEFAULT_PAY_ANY_COUNT
                    , 'button_0': CONSTANTS.DEFAULT_BUTTON_0_COUNT
                    , 'button_1': CONSTANTS.DEFAULT_BUTTON_1_COUNT
                    , 'button_2': CONSTANTS.DEFAULT_BUTTON_2_COUNT
                    , 'button_3': CONSTANTS.DEFAULT_BUTTON_3_COUNT
                };
            }
            parsed.extra = data[i++];

            parsed.numberOfPrims = parseInt( data[i++] , 10 );
            parsed.scriptLinkNumber = parseInt( data[i++] , 10 );
            parsed.creatorKey = data[i++] || CONSTANTS.NULL_KEY;
            parsed.groupKey = data[i++] || CONSTANTS.NULL_KEY;
            parsed.scriptCount = parseInt( data[i++] , 10 ); // if not 1, next number is meaningless
            parsed.scriptTime = parseFloat( data[i++] , 10 );

            return parsed;
        }

        , fetch: function( options ) {
            var success = options.success;
            var fetchOptions = _.clone( options );

            fetchOptions.success = function( model , resp ) {
                var prim = new Prim();
                var topFetchContext = this;

                prim.fetch( {
                    success: primFetchComplete
                    , error: primFetchComplete
                } );

                function primFetchComplete() {
                    model.set( prim.attributes );
                    fetchOwnerKey( topFetchContext );
                }

                function fetchOwnerKey() {
                    if( CONSTANTS.NULL_KEY == model.get( 'ownerKey' ) ) {
                        fetchCreatorKey();
                        return;
                    }

                    agentsCache.fetch( {
                        id: model.get( 'ownerKey' )
                        , success: function( agent ) {
                            model.set( {
                                ownerUserName: agent.get( 'username' )
                                , ownerDisplayName: agent.get( 'displayname' )
                            } );

                            fetchCreatorKey();
                        }
                    } );
                }

                function fetchCreatorKey() {
                    if( CONSTANTS.NULL_KEY == model.get( 'creatorKey' ) ) {
                        done();
                        return;
                    }

                    agentsCache.fetch( {
                        id: model.get( 'creatorKey' )
                        , success: function( agent ) {
                            model.set( {
                                creatorUserName: agent.get( 'username' )
                                , creatorDisplayName: agent.get( 'displayname' )
                            } );

                            done();
                        }
                    } );
                }

                function done() {
                    if( success ) {
                        success.call( topFetchContext , model , resp , options );
                    }
                }
            };

            BaseModel.prototype.fetch.call( this , fetchOptions );
        }
    } );

    return exports;
} );
