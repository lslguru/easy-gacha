define( [

    'underscore'
    , 'models/base-sl-model'
    , 'lib/constants'
    , 'lib/fetch-agent-names'

] , function(

    _
    , BaseModel
    , CONSTANTS
    , fetchAgentNames

) {
    'use strict';

    var exports = BaseModel.extend( {
        url: 'inv'

        , toPostJSON: function( options , syncMethod , xhrType ) {
            // TODO: Save

            return [
                this.get( 'index' )
            ];
        }

        , defaults: {
            index: null
            , name: null
            , type: null
            , creator: null
            , creatorUserName: null
            , creatorDisplayName: null
            , key: null
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
                , name: data[1]
                , type: CONSTANTS.INVENTORY_NUMBER_TO_TYPE[ parseInt( data[2] , 10 ) ] || 'INVENTORY_UNKNOWN'
                , creator: data[3]
                , key: data[4]
                , ownerPermissions: parseInt( data[5] , 10 )
                , groupPermissions: parseInt( data[6] , 10 )
                , publicPermissions: parseInt( data[7] , 10 )
                , nextPermissions: parseInt( data[8] , 10 )
            };
        }

        , fetch: function( options ) {
            var success = options.success;
            var fetchOptions = _.clone( options );

            fetchOptions.success = _.bind( function( model , resp ) {
                if( !model.get( 'creator' ) || CONSTANTS.NULL_KEY == model.get( 'creator' ) ) {
                    if( success ) {
                        success.call( this , model , resp , options );
                    }

                    return;
                }

                fetchAgentNames( model.get( 'creator' ) , fetchOptions , function( agentNames ) {
                    this.set( {
                        creatorUserName: agentNames.user
                        , creatorDisplayName: agentNames.display
                    } );

                    if( success ) {
                        options.success.call( this , model , resp , options );
                    }
                } , this );
            } , this );

            BaseModel.prototype.fetch.call( this , fetchOptions );
        }
    } );

    return exports;
} );
