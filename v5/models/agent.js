define( [

    'underscore'
    , 'backbone'
    , 'models/username'
    , 'models/displayname'

] , function(

    _
    , Backbone
    , UserName
    , DisplayName

) {
    'use strict';

    var exports = Backbone.Model.extend( {

        defaults: {
            id: null
            , username: null
            , displayname: null
            , objectOwner: false
            , scriptCreator: false
        }

        , fetch: function( options ) {
            var username = new UserName( {
                lookup: this.get( 'id' )
            } );

            if( options.success && options.context ) {
                options.success = _.bind( options.success , options.context );
            }

            var usernameOptions = _.clone( options );
            usernameOptions.success = _.bind( function( username_model , username_resp , username_options ) {
                this.set( 'username' , username.get( 'result' ) );

                var displayname = new DisplayName( {
                    lookup: this.get( 'id' )
                } );

                var displaynameOptions = _.clone( options );
                displaynameOptions.success = _.bind( function( displayname_model , displayname_resp , displayname_options ) {
                    this.set( 'displayname' , displayname.get( 'result' ) );

                    if( options.success ) {
                        options.success();
                    }
                } , this );

                displayname.fetch( displaynameOptions );
            } , this );

            username.fetch( usernameOptions );
        }

    } );

    return exports;

} );
