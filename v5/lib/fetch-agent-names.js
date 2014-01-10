define( [

    'underscore'
    , 'models/username'
    , 'models/displayname'

] , function(

    _
    , UserName
    , DisplayName

) {
    'use strict';

    var cache = {};

    var exports = function( agentKey , fetchOptions , callback , context ) {
        if( context ) {
            callback = _.bind( callback , context );
        }

        if( cache[ agentKey ] ) {
            // Keep it async, just in case
            _.defer( callback , cache[ agentKey ] );
            return;
        }

        var username = new UserName( {
            lookup: agentKey
        } );

        var usernameOptions = _.clone( fetchOptions );
        usernameOptions.success = function( username_model , username_resp , username_options ) {
            var displayname = new DisplayName( {
                lookup: agentKey
            } );

            var displaynameOptions = _.clone( fetchOptions );
            displaynameOptions.success = function( displayname_model , displayname_resp , displayname_options ) {
                cache[ agentKey ] = {
                    user: username.get( 'result' )
                    , display: displayname.get( 'result' )
                };

                callback( cache[ agentKey ] );
            };

            displayname.fetch( displaynameOptions );
        };

        username.fetch( usernameOptions );
    };

    return exports;

} );
