define( [

    'underscore'
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

    var submodelProgress = function( submodelName , gachaInfoProperty , gacha , submodel ) {
        var submodelExpectedCount = ( gacha.get( gachaInfoProperty ) + 1 );
        var submodelProgressPercentage = ( submodel.length / submodelExpectedCount * 100 );
        gacha.submodels[ submodelName ].progressPercentage = submodelProgressPercentage;
        gacha.updateProgress();
    };

    var exports = BaseSlModel.extend( {
        defaults: {
            isValid: false
            , progressPercentage: 0
            , agentsCache: agentsCache
            , overrideProgress: null

            // From models/info
            , isAdmin: null
            , ownerKey: null
            , ownerUserName: null
            , ownerDisplayName: null
            , objectName: null
            , objectDesc: null
            , scriptName: null
            , freeMemory: null
            , debitPermission: null
            , lastPing: null
            , inventoryCount: null
            , itemCount: null
            , payoutCount: null
            , regionName: null
            , position: null
            , configured: null
            , price: null
            , extra: null
            , numberOfPrims: null
            , scriptLinkNumber: null
            , creatorKey: null
            , creatorUserName: null
            , creatorDisplayname: null
            , groupKey: null
            , scriptCount: null
            , scriptTime: null
            , prim: null

            // From models/info/extra
            , btn_price: null
            , btn_default: null
            , btn_0: null
            , btn_1: null
            , btn_2: null
            , btn_3: null

            // From models/config
            , folderForSingleItem: null
            , rootClickAction: null
            , group: null
            , allowHover: null
            , maxPerPurchase: null
            , maxBuys: null
            , payPrice: null
            , payPriceButton0: null
            , payPriceButton1: null
            , payPriceButton2: null
            , payPriceButton3: null
            , email: null
            , im: null
            , imUserName: null
            , imDisplayName: null
            , setFolderName: null
        }

        , includeInNotecard: [
            'btn_price'
            , 'btn_default'
            , 'btn_0'
            , 'btn_1'
            , 'btn_2'
            , 'btn_3'
            , 'folderForSingleItem'
            , 'rootClickAction'
            , 'group'
            , 'allowHover'
            , 'maxPerPurchase'
            , 'maxBuys'
            , 'email'
            , 'im'
            , 'setFolderName'
            , 'payouts'
            , 'items'
        ]

        , fetchedJSON: null

        , submodels: null // instances
        , Submodels: {

            info: {
                model: Info
                , type: 'merge'
                , weight: 10
                , adminOnly: false
                , success: function( gacha , info ) {
                    gacha.set( info.get( 'extra' ) );
                }
            }

            , config: {
                model: Config
                , type: 'merge'
                , weight: 10
                , adminOnly: true
            }

            , payouts: {
                model: Payouts
                , type: 'attribute'
                , weight: 20
                , adminOnly: true
                , progressCallback: _.partial( submodelProgress , 'payouts' , 'payoutCount' )
            }

            , items: {
                model: Items
                , type: 'attribute'
                , weight: 30
                , adminOnly: false
                , progressCallback: _.partial( submodelProgress , 'items' , 'itemCount' )
            }

            , invs: {
                model: Invs
                , type: 'attribute'
                , weight: 30
                , adminOnly: true
                , progressCallback: _.partial( submodelProgress , 'invs' , 'inventoryCount' )
            }

        }

        , initialize: function() {
            this.on( 'change' , this.updateProgress , this );
            this.submodels = {};

            _.each( this.Submodels , function( submodelConfig , name ) {
                // Clone the settings
                this.submodels[ name ] = _.clone( submodelConfig );

                // Initialize progress as zero
                this.submodels[ name ].progressPercentage = 0;

                // Create the instance
                this.submodels[ name ].instance = new submodelConfig.model( {} , { gacha: this } );

                // When the submodel is considered an attribute (not just a
                // mechanism for fetch/save)
                if( 'attribute' === submodelConfig.type ) {
                    // Store it in attributes
                    this.set( name , this.submodels[ name ].instance , { silent: true } );

                    // Echo all sub-model events as native on this model
                    this.get( name ).on( 'all' , function() {
                        this.trigger.apply( this , arguments );
                    } , this );
                }
            } , this );

            this.listenTo( this , 'change:btn_price' , this.recalculateOwnerAmount );
            this.listenTo( this.get( 'payouts' ) , 'add remove reset change:amount' , this.recalculateOwnerAmount );
        }

        , recalculateOwnerAmount: function() {
            var ownerPayout = this.get( 'payouts' ).get( this.get( 'ownerKey' ) );

            if( ! ownerPayout ) {
                return;
            }

            ownerPayout.set( 'amount' , (
                // The new price
                this.get( 'btn_price' )

                // Minus the total of all payouts
                - this.get( 'payouts' ).totalPrice

                // But don't count the owner in total payouts
                + ownerPayout.get( 'amount' )
            ) );
        }

        , updateProgress: function() {
            var progressPercentage = 0;

            _.each( this.submodels , function( submodelConfig , key ) {
                progressPercentage += ( submodelConfig.progressPercentage / 100 * submodelConfig.weight );
            } , this );

            if( null !== this.get( 'overrideProgress' ) ) {
                progressPercentage = this.get( 'overrideProgress' );
            }

            this.set( 'progressPercentage' , progressPercentage );
        }

        , dataInitializations: function( admin ) {
            // Everything from here on is admin-only
            if( !admin ) {
                return;
            }

            // Populate items with new entries from inventory
            if( this.get( 'items' ) && this.get( 'invs' ) ) {
                this.get( 'items' ).populate( this.get( 'invs' ) , this.get( 'scriptName' ) );
            }

            // If there's not at least one payout record, add one for the owner
            if( !this.get( 'payouts' ).length ) {
                this.get( 'payouts' ).add( {
                    agentKey: this.get( 'ownerKey' )
                    , userName: this.get( 'ownerUserName' )
                    , displayName: this.get( 'ownerDisplayName' )
                    , amount: this.get( 'price' )
                } );
            }
        }

        , fetch: function( options ) {
            // Input normalization
            options = options || {};

            // Get list of submodels to fetch
            var submodelNames = _.keys( this.submodels );
            var success = options.success;

            // Set my initial progress
            this.set( 'progressPercentage' , 0 );
            this.updateProgress();

            // Method to process one submodel
            var next = _.bind( function() {
                // Get next submodelName or we're done
                var submodelName = submodelNames.shift();
                if( ! submodelName ) {
                    this.set( 'progressPercentage' , 100 );
                    this.updateProgress();

                    this.fetchedNotecardJSON = this.toNotecardJSON();

                    // NOTE: Doing these AFTER saving the fetchedJSON
                    this.dataInitializations( options.loadAdmin );

                    if( success ) {
                        success();
                    }

                    return;
                }

                // Cache
                var submodelConfig = this.submodels[ submodelName ];
                var submodel = submodelConfig.instance;

                // Skip admin-only if we're not admin
                if(
                    ( !options.loadAdmin && submodelConfig.adminOnly )
                    || ( ! adminKey.load() && submodelConfig.adminOnly )
                ) {
                    submodelConfig.progressPercentage = 100;
                    this.updateProgress();
                    next();
                    return;
                }

                // Override success with next callback
                var fetchOptions = _.clone( options );
                fetchOptions.success = _.bind( function() {
                    if( submodelConfig.success ) {
                        submodelConfig.success( this , submodel );
                    }

                    if( 'merge' === submodelConfig.type ) {
                        this.set( submodel.attributes );
                    }

                    submodelConfig.progressPercentage = 100;
                    this.updateProgress();

                    next();
                } , this );
                if( submodelConfig.progressCallback ) {
                    fetchOptions.progress = _.partial( submodelConfig.progressCallback , this , submodel );
                }

                // And start the fetch
                submodel.fetch( fetchOptions );
            } , this );

            next();
        }

        , validate: function() {
            console.log( 'TODO: validate' );
            this.set( 'isValid' , false );
        }

        , save: function() {
            console.log( 'TODO: save' );
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
            this.dataInitializations();
            return returnValue;
        }

        , hasChangedSinceFetch: function() {
            return ! _.isEqual( this.toNotecardJSON() , this.fetchedNotecardJSON );
        }
    } );

    return exports;
} );
