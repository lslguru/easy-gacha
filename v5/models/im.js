define( [

    'models/base-sl-model'
    , 'lib/constants'
    , 'models/agents-cache'

] , function(

    BaseModel
    , CONSTANTS
    , agentsCache

) {
    'use strict';

    var exports = BaseModel.extend( {
        url: 'im'

        , defaults: {
            im: null
            , imUserName: null
            , imDisplayName: null
        }

        , toPostJSON: function( options , syncMethod , xhrType ) {
            if( 'read' !== syncMethod ) {
                return [
                    this.get( 'im' ) || CONSTANTS.NULL_KEY
                ];
            } else {
                return [];
            }
        }

        , parse: function( data ) {
            if( null === data ) {
                return {};
            }

            return {
                im: data[0] || CONSTANTS.NULL_KEY
            };
        }

        , fetch: function( options ) {
            var success = options.success;
            var fetchOptions = _.clone( options );

            if( _.isFunction( success ) && fetchOptions.context ) {
                success = _.bind( success , fetchOptions.context );
            }

            fetchOptions.success = _.bind( function( model , resp ) {
                if( CONSTANTS.NULL_KEY === model.get( 'im' ) ) {
                    if( success ) {
                        success( model , resp , options );
                    }

                    return;
                }

                agentsCache.fetch( {
                    id: model.get( 'im' )
                    , success: _.bind( function( agent ) {
                        this.set( {
                            imUserName: agent.get( 'username' )
                            , imDisplayName: agent.get( 'displayname' )
                        } );

                        if( success ) {
                            success( model , resp , options );
                        }
                    } , this )
                } );
            } , this );

            this.constructor.__super__.fetch.call( this , fetchOptions );
        }
    } );

    return exports;
} );
