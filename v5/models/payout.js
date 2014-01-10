define( [

    'underscore'
    , 'models/base-sl-model'
    , 'models/username'
    , 'models/displayname'
    , 'lib/constants'

] , function(

    _
    , BaseModel
    , UserName
    , DisplayName
    , CONSTANTS

) {
    'use strict';

    var exports = BaseModel.extend( {
        url: 'payout'

        , toPostJSON: function( options , syncMethod , xhrType ) {
            // TODO: Save

            return [
                this.get( 'index' )
            ];
        }

        , defaults: {
            index: null
            , agentKey: null
            , amount: null
            , userName: null
            , displayName: null
        }

        , parse: function( data ) {
            if( null === data ) {
                return {};
            }

            return {
                index: parseInt( data[0] , 10 )
                , agentKey: data[1]
                , amount: parseInt( data[2] , 10 )
            };
        }

        , fetch: function( options ) {
            var success = options.success;
            var fetchOptions = _.clone( options );

            fetchOptions.success = function( model , resp ) {
                if( !model.get( 'agentKey' ) || CONSTANTS.NULL_KEY == model.get( 'agentKey' ) ) {
                    if( success ) {
                        success.call( this , model , resp , options );
                    }

                    return;
                }

                var username = new UserName( {
                    lookup: model.get( 'agentKey' )
                } );

                var usernameOptions = _.clone( options );
                usernameOptions.success = function( username_model , username_resp , username_options ) {
                    model.set( 'userName' , username.get( 'result' ) );

                    var displayname = new DisplayName( {
                        lookup: model.get( 'agentKey' )
                    } );

                    var displaynameOptions = _.clone( options );
                    displaynameOptions.success = function( displayname_model , displayname_resp , displayname_options ) {
                        model.set( 'displayName' , displayname.get( 'result' ) );

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
