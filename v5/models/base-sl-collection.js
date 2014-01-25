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
                            options.progress( collection.length );
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

        , fromNotecardJSON: function( json ) {
            this.set( json , { remove: true } );
            return true;
        }

        , toNotecardJSON: function( options ) {
            var json = [];

            _.each( this.models , function( model ) {
                if( _.isFunction( model.toNotecardJSON ) ) {
                    var modelJSON = model.toNotecardJSON();

                    if( ! _.isEmpty( modelJSON ) ) {
                        json.push( modelJSON );
                    }
                }
            } , this );

            return json;
        }

        // No base function for collections, so use just options as our
        // implementation
        , save: function( valuesToSet , options ) {
            options = options || {};
            var success = options.success;

            var index = -1; // Will be incremented before use
            var next = _.bind( function() {
                ++index; // Before processing next model, increment

                if( index >= this.length ) {
                    if( _.isFunction( success ) ) {
                        success.apply( this , arguments );
                    }

                    return;
                }

                if( _.isFunction( options.progress ) ) {
                    options.progress( index );
                }

                var shouldIncludeInSave = true;
                if( _.isFunction( this.models[ index ].shouldIncludeInSave ) ) {
                    shouldIncludeInSave = this.models[ index ].shouldIncludeInSave();
                }

                if( shouldIncludeInSave ) {
                    this.models[ index ].save( {} , options );
                } else {
                    next();
                }
            } , this );

            // After each successful call, start the next one
            options.success = next;

            // Empty the list first
            var reset = new this.model();
            reset.destroy( options );
        }
    } ) );

    return exports;
} );
