define( [

    'underscore'
    , 'models/base-sl-model'
    , 'lib/constants'
    , 'models/agents-cache'

] , function(

    _
    , BaseModel
    , CONSTANTS
    , agentsCache

) {
    'use strict';

    var exports = BaseModel.extend( {
        url: 'inv'
        , idAttribute: 'name'

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

            var i = 0;
            var parsed = {};

            parsed.index = parseInt( data[i++] , 10 );
            parsed.name = data[i++];
            parsed.type = CONSTANTS.INVENTORY_NUMBER_TO_TYPE[ parseInt( data[i++] , 10 ) ] || 'INVENTORY_UNKNOWN';
            parsed.creator = data[i++];
            parsed.key = data[i++] || CONSTANTS.NULL_KEY;
            parsed.ownerPermissions = parseInt( data[i++] , 10 );
            parsed.groupPermissions = parseInt( data[i++] , 10 );
            parsed.publicPermissions = parseInt( data[i++] , 10 );
            parsed.nextPermissions = parseInt( data[i++] , 10 );

            return parsed;
        }

        , fetch: function( options ) {
            var success = options.success;
            var fetchOptions = _.clone( options );

            fetchOptions.success = _.bind( function( model , resp ) {
                if( CONSTANTS.NULL_KEY == model.get( 'creator' ) ) {
                    if( success ) {
                        success.call( this , model , resp , options );
                    }

                    return;
                }

                agentsCache.fetch( {
                    id: model.get( 'creator' )
                    , context: this
                    , success: function( agent ) {
                        this.set( {
                            creatorUserName: agent.get( 'username' )
                            , creatorDisplayName: agent.get( 'displayname' )
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
