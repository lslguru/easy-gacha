define( [

    'underscore'
    , 'backbone'
    , 'models/base-sl'

] , function(

    _
    , Backbone
    , BaseSl

) {
    'use strict';

    var exports = Backbone.Collection.extend( _.extend( {} , BaseSl , {
        fetch: function( options ) {
            var collection = this;
            collection.reset();

            function fetchNext( index ) {
                var model = new collection.model( {
                    index: index
                } );

                model.fetch( {
                    success: function() {
                        collection.add( model );

                        if( _.isFunction( options.progress ) ) {
                            options.progress( model );
                        }

                        fetchNext( index + 1 );
                    }

                    , error: function() {
                        if( options.success ) {
                            options.success( collection , null , options );
                        }

                        collection.trigger( 'sync' , collection , null , options );
                    }
                } );
            }

            fetchNext( 0 );
        }
    } ) );

    return exports;
} );
