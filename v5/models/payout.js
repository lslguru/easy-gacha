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
        , idAttribute: 'agentKey'

        , includeInNotecard: [
            'agentKey'
            , 'amount'
            , 'userName'
            , 'displayName'
        ]

        , toPostJSON: function( options , syncMethod , xhrType ) {
            return [
                this.get( 'agentKey' )
                , this.get( 'amount' )
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

            var i = 0;
            var parsed = {};

            parsed.index = parseInt( data[i++] , 10 );
            parsed.agentKey = data[i++] || CONSTANTS.NULL_KEY;
            parsed.amount = parseInt( data[i++] , 10 );

            return parsed;
        }

        , fetch: function( options ) {
            var success = options.success;
            var fetchOptions = _.clone( options );

            fetchOptions.success = function( model , resp ) {
                if( CONSTANTS.NULL_KEY == model.get( 'agentKey' ) ) {
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
