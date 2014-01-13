define( [

    'underscore'
    , 'backbone'
    , 'models/info'
    , 'models/config'
    , 'models/items'
    , 'models/payouts'
    , 'models/invs'
    , 'lib/admin-key'
    , 'models/agents-cache'
    , 'models/base-sl-model'

] , function(

    _
    , Backbone
    , Info
    , Config
    , Items
    , Payouts
    , Invs
    , adminKey
    , agentsCache
    , BaseSlModel

) {
    'use strict';

    var submodelProgress = function( gachaProgressProperty , gachaInfoProperty , gacha , submodel ) {
        var submodelExpectedCount = ( gacha.get( 'info' ).get( gachaInfoProperty ) + 1 );
        var submodelProgressPercentage = ( submodel.length / submodelExpectedCount * 100 );
        gacha.set( gachaProgressProperty , submodelProgressPercentage );
    };

    var exports = Backbone.Model.extend( {
        defaults: {
            isValid: false
            , progressPercentage: 0
            , agentsCache: agentsCache
            , overrideProgress: null
        }

        , fetchedJSON: null

        , submodels: {

            info: {
                model: Info
                , weight: 10
                , adminOnly: false
            }

            , config: {
                model: Config
                , weight: 10
                , adminOnly: true
            }

            , payouts: {
                model: Payouts
                , weight: 20
                , adminOnly: true
                , progress: _.partial( submodelProgress , 'payoutsProgressPercentage' , 'payoutCount' )
            }

            , items: {
                model: Items
                , weight: 30
                , adminOnly: false
                , progress: _.partial( submodelProgress , 'itemsProgressPercentage' , 'itemCount' )
            }

            , invs: {
                model: Invs
                , weight: 30
                , adminOnly: true
                , progress: _.partial( submodelProgress , 'invsProgressPercentage' , 'inventoryCount' )
            }

        }

        , initialize: function() {
            this.on( 'change' , this.updateProgress , this );

            _.each( this.submodels , function( submodelConfig , name ) {
                this.set( name , new submodelConfig.model() , { silent: true } );
                this.set( name + 'ProgressPercentage' , 0 , { silent: true } );

                // Echo all sub-model events as native on this model
                this.get( name ).on( 'all' , function() {
                    this.trigger.apply( this , arguments );
                } , this );
            } , this );
        }

        , updateProgress: function() {
            var progressPercentage = 0;

            _.each( this.submodels , function( submodelConfig , key ) {
                progressPercentage += ( this.get( key + 'ProgressPercentage' ) / 100 * submodelConfig.weight );
            } , this );

            if( null !== this.get( 'overrideProgress' ) ) {
                progressPercentage = this.get( 'overrideProgress' );
            }

            this.set( 'progressPercentage' , progressPercentage );
        }

        , fetch: function( options ) {
            // Input normalization
            options = options || {};

            // Get list of submodels to fetch
            var submodels = _.keys( this.submodels );
            var success = options.success;

            // Set my initial progress
            this.set( 'progressPercentage' , 0 );

            // Method to process one submodel
            var next = _.bind( function() {
                // Get next submodelName or we're done
                var submodelName = submodels.shift();
                if( ! submodelName ) {
                    this.set( 'progressPercentage' , 100 );

                    this.fetchedNotecardJSON = this.toNotecardJSON();

                    // NOTE: Doing this AFTER saving the fetchedJSON
                    if( this.get( 'items' ) && this.get( 'invs' ) ) {
                        this.get( 'items' ).populate( this.get( 'invs' ) );
                    }

                    if( success ) {
                        success();
                    }

                    return;
                }

                // Cache
                var submodelConfig = this.submodels[ submodelName ];
                var submodel = this.get( submodelName );

                // Skip admin-only if we're not admin
                if(
                    ( !options.loadAdmin && submodelConfig.adminOnly )
                    || ( ! adminKey.load() && submodelConfig.adminOnly )
                ) {
                    this.set( submodelName + 'ProgressPercentage' , 100 );
                    next();
                    return;
                }

                // Override success with next callback
                var fetchOptions = _.clone( options );
                fetchOptions.success = _.bind( function() {
                    this.set( submodelName + 'ProgressPercentage' , 100 );
                    next();
                } , this );
                if( submodelConfig.progress ) {
                    fetchOptions.progress = _.partial( submodelConfig.progress , this , submodel );
                }

                // And start the fetch
                submodel.fetch( fetchOptions );
            } , this );

            next();
        }

        , validate: function() {
            console.log( 'TODO' );
            this.set( 'isValid' , false );
        }

        , save: function() {
            console.log( 'TODO' );
        }

        , toJSON: function() {
            var json = this.constructor.__super__.toJSON.apply( this , arguments );

            _.each( json , function( value , key ) {
                // If the value has a toJSON method
                if( _.isObject( value ) && _.isFunction( value.toJSON ) ) {
                    json[ key ] = value.toJSON();
                }
            } , this );

            return json;
        }

        , fromNotecardJSON: function() {
            var returnValue = BaseSlModel.prototype.fromNotecardJSON.apply( this , arguments );
            this.get( 'items' ).populate( this.get( 'invs' ) );
            return returnValue;
        }

        , toNotecardJSON: function() {
            var json = this.constructor.__super__.toJSON.apply( this , arguments );

            _.each( json , function( value , key ) {
                // Only keep if the value has a toNotecardJSON method
                if( _.isObject( value ) && _.isFunction( value.toNotecardJSON ) ) {
                    json[ key ] = value.toNotecardJSON();
                } else {
                    delete json[ key ];
                }
            } , this );

            return json;
        }
    } );

    return exports;
} );
