define( [

    'underscore'
    , 'backbone'
    , 'models/registry-gacha'
    , 'lib/constants'
    , 'lib/google-analytics'

] , function(

    _
    , Backbone
    , Gacha
    , CONSTANTS
    , ga

) {
    'use strict';

    var exports = Backbone.Collection.extend( {
        model: Gacha

        , urlParams: null
        , countModel: null
        , nextIndex: 0
        , indexesFetched: null

        , initialize: function() {
            this.constructor.__super__.initialize.apply( this , arguments );

            this.urlParams = new Backbone.Model( {
                maxPrice: null
                , searchString: null
                , randomize: false
                , fetching: false
            } );

            this.searchCriteriaChanged = _.debounce( _.bind( this.searchCriteriaChanged , this ) , 500 );

            this.indexesFetched = [];

            this.fetchCount = _.debounce( this.fetchCount , CONSTANTS.SEARCH_DEBOUNCE );

            this.urlParams.on( 'change:maxPrice' , this.searchCriteriaChanged , this );
            this.urlParams.on( 'change:searchString' , this.searchCriteriaChanged , this );
            this.urlParams.on( 'change:randomize' , this.searchCriteriaChanged , this );

            this.searchCriteriaChanged();
        }

        , searchCriteriaChanged: function() {
            this.reset();
            this.nextIndex = 0;
            this.indexesFetched = [];
            this.urlParams.set( 'fetching' , true );
            this.fetchCount();

            ga( 'send' , 'event' , 'registry' , 'search' , {
                'dimension3': this.urlParams.get( 'maxPrice' )
                , 'dimension4': this.urlParams.get( 'searchString' )
                , 'dimension5': this.urlParams.get( 'randomize' )
            } );
        }

        , fetchCount: function() {
            var countModel = this.countModel = new Gacha();
            _.extend( countModel.urlParams , this.urlParams.attributes );

            countModel.fetch( {
                success: _.bind( function() {
                    // If this is still the requested count
                    if( countModel === this.countModel ) {
                        // Mark that this part of the fetch completed
                        this.urlParams.set( 'fetching' , false );

                        // Then pre-fetch the first record for convenience
                        this.fetch();
                    }
                } , this )
            } );
        }

        // Only fetches the next 1 item and adds it to the collection if
        // successful
        , fetch: function( options ) {
            // Turn into an object
            options = Object( options );

            // If we cannot load more, exit early
            if( !this.canLoadMore() ) {
                return false;
            }

            // If a callback with context was passed
            if( _.isObject( options.context ) && _.isFunction( options.success ) ) {
                options.success = _.bind( option.success , options.context );
            }

            // If we need to mix it up...
            if( this.urlParams.get( 'randomize' ) ) {
                // Get a random index, and if we've already tried that index,
                // keep guessing until we find one we haven't tried. Will only
                // be inefficient if you've loaded almost everything in a long
                // list. The shorter the list or the fewer you've already
                // fetched, the better this will work.
                do {
                    this.nextIndex = Math.floor( Math.random() * this.countModel.get( 'count' ) );
                } while( -1 !== this.indexesFetched.indexOf( this.nextIndex ) );
            }

            // Create a model to use for fetching
            var nextGacha = new Gacha();
            _.extend( nextGacha.urlParams , this.urlParams.attributes );
            nextGacha.urlParams.get = this.nextIndex;
            this.indexesFetched.push( this.nextIndex );

            // Mark that we've started fetching - signals views to update too
            this.urlParams.set( 'fetching' , true );

            // Fetch the model from the server
            var fetchOptions = _.clone( options );
            fetchOptions.success = _.bind( function() {
                // If we're in random mode, this won't matter. Otherwise it
                // is essential
                ++this.nextIndex;

                // Mark that this fetch completed
                this.urlParams.set( 'fetching' , false );

                if( this.get( nextGacha.id ) || null === nextGacha.get( 'baseUrl' ) ) {
                    // If we already have this one or it's invalid, things may
                    // have shifted on the server, gachas may have been found
                    // to be offline, etc. Just quietly skip this one and try
                    // the next one.
                    this.fetch();
                } else {
                    // Otherwise add this model as the fetch succeeded in its
                    // goal.
                    this.add( nextGacha );

                    if( _.isFunction( options.success ) ) {
                        options.success.apply( this , arguments );
                    }
                }
            } , this );
            nextGacha.fetch( fetchOptions );
        }

        , canLoadMore: function() {
            // Count not yet fetched, so we cannot load more
            if( null === this.countModel || null === this.countModel.get( 'count' ) ) {
                return false;
            }

            // All fetched, so cannot load more
            if( this.indexesFetched.length >= this.countModel.get( 'count' ) ) {
                return false;
            }

            // Currently fetching - prevents race conditions
            if( this.urlParams.get( 'fetching' ) ) {
                return false;
            }

            return true;
        }
    } );

    return exports;
} );
