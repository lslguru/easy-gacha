define( [

    'underscore'
    , 'backbone'
    , 'models/agent'

] , function(

    _
    , Backbone
    , Agent

) {
    'use strict';

    var exports = Backbone.Collection.extend( {

        model: Agent

        , comparator: 'displayname'

        , fetch: function( options ) {
            if( ! options || ! options.id ) {
                throw 'Forgot to pass id to fetch';
            }

            if( options.success && options.context ) {
                options.success = _.bind( options.success , options.context );
            }

            if( options.error && options.context ) {
                options.error = _.bind( options.error , options.context );
            }

            if( this.get( options.id ) ) {
                if( options.objectOwner ) {
                    this.get( options.id ).set( 'objectOwner' , true );
                }
                if( options.scriptCreator ) {
                    this.get( options.id ).set( 'scriptCreator' , true );
                }

                // Keep it async, just in case
                if( _.isFunction( options.success ) ) {
                    _.defer( options.success , this.get( options.id ) );
                }
                return;
            }

            var agent = new Agent( {
                id: options.id
                , objectOwner: Boolean( options.objectOwner )
                , scriptCreator: Boolean( options.scriptCreator )
            } );

            var agentFetchOptions = _.clone( options );
            agentFetchOptions.success = _.bind( function() {
                this.add( agent );

                if( _.isFunction( options.success ) ) {
                    options.success( agent );
                }
            } , this );

            agent.fetch( agentFetchOptions );
        }
    } );

    return exports;

} );
