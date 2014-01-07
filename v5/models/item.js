define( [

    'underscore'
    , 'models/base-sl-model'
    , 'lib/constants'
    , 'models/username'
    , 'models/displayname'

] , function(

    _
    , BaseModel
    , CONSTANTS
    , UserName
    , DisplayName

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
                , type: CONSTANTS.INVENTORY_NUMBER_TO_TYPE[ parseInt( data[5] , 10 ) ] || 'INVENTORY_UNKNOWN'
                , creator: data[6]
                , keyAvailable: Boolean( parseInt( data[7] , 10 ) )
                , ownerPermissions: parseInt( data[8] , 10 )
                , groupPermissions: parseInt( data[9] , 10 )
                , publicPermissions: parseInt( data[10] , 10 )
                , nextPermissions: parseInt( data[11] , 10 )
            };
        }

        , fetch: function( options ) {
            var success = options.success;
            var fetchOptions = _.clone( options );

            fetchOptions.success = function( model , resp ) {
                if( !model.get( 'creator' ) || CONSTANTS.NULL_KEY == model.get( 'creator' ) ) {
                    if( success ) {
                        success.call( this , model , resp , options );
                    }

                    return;
                }

                var username = new UserName( {
                    lookup: model.get( 'creator' )
                } );

                var usernameOptions = _.clone( options );
                usernameOptions.success = function( username_model , username_resp , username_options ) {
                    model.set( 'creatorUserName' , username.get( 'result' ) );

                    var displayname = new DisplayName( {
                        lookup: model.get( 'creator' )
                    } );

                    var displaynameOptions = _.clone( options );
                    displaynameOptions.success = function( displayname_model , displayname_resp , displayname_options ) {
                        model.set( 'creatorDisplayName' , displayname.get( 'result' ) );

                        if( success ) {
                            options.success.call( this , model , resp , options );
                        }
                    };

                    displayname.fetch( displaynameOptions );
                };

                username.fetch( usernameOptions );
            };

            BaseModel.prototype.fetch.call( this , fetchOptions );
        }
    } );

    return exports;
} );
