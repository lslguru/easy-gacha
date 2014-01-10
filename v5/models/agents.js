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

        , fetch: function( options ) {
            if( ! options || ! options.id ) {
                throw 'Forgot to pass id to fetch';
            }

            if( options.success && options.context ) {
                options.success = _.bind( options.success , options.context );
            }

            if( this.get( options.id ) ) {
                // Keep it async, just in case
                _.defer( options.success , this.get( options.id ) );
                return;
            }

            var agent = new Agent( {
                id: options.id
            } );

            var agentFetchOptions = _.clone( options );
            agentFetchOptions.success = _.bind( function() {
                this.add( agent );

                if( options.success ) {
                    options.success( agent );
                }
            } , this );

            agent.fetch( agentFetchOptions );
        }
    } );

    return exports;

} );
