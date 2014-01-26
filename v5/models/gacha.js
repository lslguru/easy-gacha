define( [

    'underscore'
    , 'models/info'
    , 'models/config'
    , 'models/items'
    , 'models/payouts'
    , 'models/invs'
    , 'models/email'
    , 'models/im'
    , 'models/configured'
    , 'lib/admin-key'
    , 'models/agents-cache'
    , 'models/base-sl-model'
    , 'lib/constants'

] , function(

    _
    , Info
    , Config
    , Items
    , Payouts
    , Invs
    , Email
    , Im
    , Configured
    , adminKey
    , agentsCache
    , BaseSlModel
    , CONSTANTS

) {
    'use strict';

    var submodelProgress = function( submodelName , gachaInfoProperty , gacha , length ) {
        var submodelExpectedCount = ( gacha.get( gachaInfoProperty ) + 1 );
        var submodelProgressPercentage = ( length / submodelExpectedCount * 100 );
        gacha.submodels[ submodelName ].progressPercentage = submodelProgressPercentage;
        gacha.updateProgress();
    };

    var exports = BaseSlModel.extend( {
        defaults: {
            isValid: false
            , progressPercentage: 0
            , progressStep: ''
            , agentsCache: agentsCache
            , hasChangesToSave: false
            , autoModified: null
            , ackAutoModified: false

            // From models/info
            , isAdmin: null
            , ownerKey: null
            , ownerUserName: null
            , ownerDisplayName: null
            , ready: null
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
            , numberOfPrims: null
            , scriptLinkNumber: null
            , creatorKey: null
            , creatorUserName: null
            , creatorDisplayname: null
            , groupKey: null
            , scriptCount: null
            , scriptTime: null
            , prim: null
            , isRootOrOnlyPrim: null

            // From models/info/extra
            , button_price: null
            , button_default: null
            , button_0: null
            , button_1: null
            , button_2: null
            , button_3: null
            , zeroPriceOkay: false
            , suggestedButtonOrder: null
            , ignoreButtonsOutOfOrder: false
            , ackNoCopyItemsMeansSingleItemPlay: false

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
            , apiPurchasesEnabled: null
            , apiItemsGivenEnabled: null
            , rootClickActionNeeded: false
            , ackEmailSlowness: false

            // From models/email
            , email: null

            // From models/im
            , im: null
            , imUserName: null
            , imDisplayName: null

            // From models/items
            , totalItems: 0
            , totalItemsAvailable: 0
            , totalRarity: 0
            , unlimitedRarity: 0
            , lowestLimitedRarity: 0
            , totalBought: 0
            , countUnlimited: 0
            , countLimited: 0
            , totalLimit: 0
            , willHandOutNoCopyObjects: false
            , anySelectedForBatchOperation: false
            , allSelectedForBatchOperation: false
            , totalItemsCopy: 0
            , totalItemsMod: 0
            , totalItemsTrans: 0

            // Warnings and Dangers
        }

        , includeInNotecard: [
            'button_price'
            , 'button_default'
            , 'button_0'
            , 'button_1'
            , 'button_2'
            , 'button_3'
            , 'zeroPriceOkay'
            , 'ignoreButtonsOutOfOrder'
            , 'ackNoCopyItemsMeansSingleItemPlay'
            , 'folderForSingleItem'
            , 'rootClickAction'
            , 'group'
            , 'allowHover'
            , 'maxPerPurchase'
            , 'maxBuys'
            , 'email'
            , 'im'
            , 'payouts'
            , 'items'
            , 'ackEmailSlowness'
            , 'apiPurchasesEnabled'
            , 'apiItemsGivenEnabled'
        ]

        , fetchedJSON: null

        , submodels: null // instances
        , Submodels: {

            info: {
                model: Info
                , type: 'merge'
                , weight: 5
                , adminOnly: false
                , fetchSuccess: function( gacha , info ) {
                    gacha.set( info.get( 'extra' ) );

                    // Nice smooth progress bar
                    var totalCalls = 1;
                    _.each( gacha.submodels , function( submodelConfig ) {
                        if( info.get( 'isAdmin' ) || !submodelConfig.adminOnly ) {
                            ++totalCalls; // We make at least one call, and if collections one extra call

                            if( 'attribute' === submodelConfig.type && submodelConfig.countAttribute ) {
                                totalCalls += info.get( submodelConfig.countAttribute );
                            }
                        }
                    } );
                    _.each( gacha.submodels , function( submodelConfig ) {
                        var weight = 0;

                        if( info.get( 'isAdmin' ) || !submodelConfig.adminOnly ) {
                            ++weight; // We make at least one call, and if collections one extra call

                            if( 'attribute' === submodelConfig.type && submodelConfig.countAttribute ) {
                                weight += info.get( submodelConfig.countAttribute );
                            }
                        }

                        submodelConfig.weight = weight / totalCalls * 100;
                    } );
                }
                , save: false
                , name: 'Object Info'
            }

            , config: {
                model: Config
                , type: 'merge'
                , weight: 5
                , adminOnly: true
                , save: true
                , preSave: function( gacha , config ) {
                    config.set( 'extra' , {
                        button_price: gacha.get( 'button_price' )
                        , button_default: gacha.get( 'button_default' )
                        , button_0: gacha.get( 'button_0' )
                        , button_1: gacha.get( 'button_1' )
                        , button_2: gacha.get( 'button_2' )
                        , button_3: gacha.get( 'button_3' )
                        , zeroPriceOkay: gacha.get( 'zeroPriceOkay' )
                        , suggestedButtonOrder: gacha.get( 'suggestedButtonOrder' )
                        , ignoreButtonsOutOfOrder: gacha.get( 'ignoreButtonsOutOfOrder' )
                        , ackNoCopyItemsMeansSingleItemPlay: gacha.get( 'ackNoCopyItemsMeansSingleItemPlay' )
                        , ackEmailSlowness: gacha.get( 'ackEmailSlowness' )
                    } );
                }
                , name: 'Configuration'
            }

            , email: {
                model: Email
                , type: 'merge'
                , weight: 5
                , adminOnly: true
                , save: true
                , name: 'Email Setting'
            }

            , im: {
                model: Im
                , type: 'merge'
                , weight: 5
                , adminOnly: true
                , save: true
                , name: 'IM Setting'
            }

            , payouts: {
                model: Payouts
                , type: 'attribute'
                , weight: 5
                , adminOnly: true
                , countAttribute: 'payoutCount'
                , progressCallback: _.partial( submodelProgress , 'payouts' , 'payoutCount' )
                , save: true
                , name: 'Payouts'
            }

            , items: {
                model: Items
                , type: 'attribute'
                , weight: 20
                , adminOnly: false
                , countAttribute: 'itemCount'
                , progressCallback: _.partial( submodelProgress , 'items' , 'itemCount' )
                , save: true
                , name: 'Configured Items'
            }

            , invs: {
                model: Invs
                , type: 'attribute'
                , weight: 45
                , adminOnly: true
                , countAttribute: 'inventoryCount'
                , progressCallback: _.partial( submodelProgress , 'invs' , 'inventoryCount' )
                , save: false
                , name: 'Available Inventory'
            }

            , configured: {
                model: Configured
                , type: 'merge'
                , weight: 5
                , adminOnly: true
                , save: true
                , name: 'Configuration'
            }

        }

        , initialize: function() {
            /////// Sub-Models ///////

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

            /////// Calculated values ///////

            this.get( 'items' ).on( 'add remove reset change' , this.updateItemAggregates , this );

            this.on( 'change:button_price' , this.updateZeroPriceOkay , this );

            this.on( 'change:button_0 change:button_1 change:button_2 change:button_3' , this.updateButtonsOutOfOrder , this );

            this.on( 'change:scriptLinkNumber change:rootClickAction' , this.updateRootClickActionNeeded , this );

            this.on( 'change:scriptLinkNumber' , this.updateIsRootOrOnlyPrim , this );

            this.on( 'change:email' , this.updateAckEmailSlowness , this );

            this.on( 'change:button_price change:totalLimit change:willHandOutNoCopyObjects change:button_default change:button_0 change:button_1 change:button_2 change:button_3' , this.updateBuyButtons , this );

            this.on( 'change:button_price' , this.recalculateOwnerAmount , this );
            this.get( 'payouts' ).on( 'add remove reset change:amount' , this.recalculateOwnerAmount , this );

            this.on( 'all' , this.updateHasChangesToSave , this );
            this.on( 'all' , this.updateConfigured , this );

            /////// Init ///////

            this.updateItemAggregates();
        }

        , recalculateOwnerAmount: function() {
            var ownerPayout = this.get( 'payouts' ).get( this.get( 'ownerKey' ) );

            if( ! ownerPayout ) {
                return;
            }

            ownerPayout.set( 'amount' , (
                // The new price
                this.get( 'button_price' )

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

            // This method should never quite reach 100%, that should always be
            // explicitly set when complete
            progressPercentage *= 0.999;

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

            // If we've modified settings on a fetch, count that as a first-run
            if( this.get( 'hasChangesToSave' ) ) {
                this.set( 'autoModified' , true );
            } else {
                this.set( 'autoModified' , false );
            }
        }

        , fetch: function( options ) {
            // Input normalization
            options = options || {};

            // Get list of submodels to fetch
            var submodelNames = _.keys( this.submodels );
            var success = options.success;

            // Reset all progress
            _.each( this.submodels , function( submodelConfig ) {
                submodelConfig.progressPercentage = 0;
            } , this );
            this.set( 'progressPercentage' , 0 );
            this.updateProgress();

            // Method to process one submodel
            var next = _.bind( function() {
                // Get next submodelName or we're done
                var submodelName = submodelNames.shift();
                if( ! submodelName ) {
                    // Cache the finalized fetched data meant for export/import
                    this.fetchedNotecardJSON = this.toNotecardJSON();

                    // NOTE: Doing these AFTER saving the fetchedJSON
                    this.dataInitializations( options.loadAdmin );

                    // Now tell everyone that we're done
                    this.set( 'progressPercentage' , 100 );

                    // And call any specific completion request
                    if( _.isFunction( success ) ) {
                        success();
                    }

                    return;
                }

                // Cache
                var submodelConfig = this.submodels[ submodelName ];
                var submodel = submodelConfig.instance;

                // Update display
                this.set( 'progressStep' , 'Loading ' + submodelConfig.name );

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
                    if( submodelConfig.fetchSuccess ) {
                        submodelConfig.fetchSuccess( this , submodel );
                    }

                    if( 'merge' === submodelConfig.type ) {
                        this.set( submodel.pick.apply( submodel , this.keys() ) );
                    }

                    submodelConfig.progressPercentage = 100;
                    this.updateProgress();

                    next();
                } , this );
                if( submodelConfig.progressCallback ) {
                    fetchOptions.progress = _.partial( submodelConfig.progressCallback , this );
                }

                // And start the fetch
                submodel.fetch( fetchOptions );
            } , this );

            next();
        }

        , save: function( attributes , options ) {
            // This shouldn't be called unless we're admin
            if( ! adminKey.load() ) {
                return;
            }

            // Store any changes, just keeping the original method pattern
            this.set( attributes || {} );

            // Input normalization
            options = options || {};

            // Get list of submodels to fetch
            var submodelNames = _.keys( this.submodels );
            var success = options.success;

            // Reset all progress
            _.each( this.submodels , function( submodelConfig ) {
                submodelConfig.progressPercentage = 0;
            } , this );
            this.set( 'progressPercentage' , 0 );
            this.updateProgress();

            // Method to process one submodel
            var next = _.bind( function() {
                // Get next submodelName or we're done
                var submodelName = submodelNames.shift();
                if( ! submodelName ) {
                    // Automatic changes have now been saved
                    this.set( 'autoModified' , false );

                    if( options.fetchAfter ) {
                        // Refresh all data
                        options.success = success;
                        options.loadAdmin = true;
                        this.fetch( options );
                    } else if( _.isFunction( success ) ) {
                        success();
                    }

                    return;
                }

                // Cache
                var submodelConfig = this.submodels[ submodelName ];
                var submodel = submodelConfig.instance;

                // Update display
                this.set( 'progressStep' , 'Saving ' + submodelConfig.name );

                // Skip non-saving submodels
                if( !submodelConfig.save ) {
                    submodelConfig.progressPercentage = 100;
                    this.updateProgress();
                    next();
                    return;
                }

                // Cache
                var submodelConfig = this.submodels[ submodelName ];
                var submodel = submodelConfig.instance;

                // Override success with next callback
                var saveOptions = _.clone( options );
                saveOptions.success = _.bind( function() {
                    submodelConfig.progressPercentage = 100;
                    this.updateProgress();

                    next();
                } , this );
                if( submodelConfig.progressCallback ) {
                    saveOptions.progress = _.partial( submodelConfig.progressCallback , this , submodel );
                }

                // If there's work to be done before the save
                if( submodelConfig.preSave ) {
                    submodelConfig.preSave( this , submodel );
                }

                // And start the save
                if( 'merge' === submodelConfig.type ) {
                    submodel.save( this.pick.apply( this , submodel.keys() ) , saveOptions );
                } else {
                    submodel.save( {} , saveOptions );
                }
            } , this );

            next();
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
            this.dataInitializations( true );
            return returnValue;
        }

        , updateHasChangesToSave: function() {
            this.set( 'hasChangesToSave' , ! _.isEqual( this.toNotecardJSON() , this.fetchedNotecardJSON ) );
        }

        , updateZeroPriceOkay: function() {
            if( 0 === this.get( 'button_price' ) ) {
                this.set( 'ignoreButtonsOutOfOrder' , false );
            }
        }

        , updateConfigured: function() {
            var configured = true;

            // If no items available
            if( 0 === this.get( 'totalRarity' ) ) {
                configured = false;
            }

            // Check price and buttons
            var button_price = parseInt( this.get( 'button_price' ) , 10 );
            if( _.isNaN( button_price ) ) {
                configured = false;
            } else if( 0 > button_price ) {
                configured = false;
            } else if( 0 === button_price && !this.get( 'zeroPriceOkay' ) ) {
                configured = false;
            } else if( 0 !== button_price ) {
                var hasPaymentOptions = false;

                _.each( [ 'default' , '0' , '1' , '2' , '3' ] , function( button ) {
                    var button_val = parseInt( this.get( 'button_' + button ) , 10 );

                    if( _.isNaN( button_val ) ) {
                        configured = false;
                    } else if( 0 > button_val ) {
                        configured = false;
                    } else if( CONSTANTS.MAX_PER_PURCHASE < button_val ) {
                        configured = false;
                    } else if( this.get( 'maxPerPurchase' ) < button_val ) {
                        configured = false;
                    }

                    if( 0 < button_val ) {
                        hasPaymentOptions = true;
                    }
                } , this );

                if( !hasPaymentOptions ) {
                    configured = false;
                }
            }

            // TODO: payouts

            // If they haven't acknowledge the warning
            if( '' !== this.get( 'email' ) && !this.get( 'ackEmailSlowness' ) ) {
                configured = false;
            }

            // Whether or not we're in the root prim and have made up our minds
            if( this.get( 'rootClickActionNeeded' ) ) {
                configured = false;
            }

            this.set( 'configured' , configured );
        }

        , updateRootClickActionNeeded: function() {
            this.set( 'rootClickActionNeeded' , (
                CONSTANTS.LINK_ROOT === this.get( 'scriptLinkNumber' )
                && -1 === this.get( 'rootClickAction' )
            ) );
        }

        , updateIsRootOrOnlyPrim: function() {
            this.set( 'isRootOrOnlyPrim' , (
                CONSTANTS.LINK_ROOT === this.get( 'scriptLinkNumber' ) // root prim
                || 0 === this.get( 'scriptLinkNumber' ) // only prim
            ) );
        }

        , updateButtonsOutOfOrder: function() {
            var buttons = [
                this.get( 'button_0' )
                , this.get( 'button_1' )
                , this.get( 'button_2' )
                , this.get( 'button_3' )
            ];

            var buttonsOrdered = _.clone( buttons ).sort( function( a , b ) {
                if( 0 === a ) return  1;
                if( 0 === b ) return -1;
                return a - b;
            } );

            this.set( 'suggestedButtonOrder' , (
                _.isEqual( buttons , buttonsOrdered )
                ? null
                : buttonsOrdered
            ) );
        }

        , effectiveButtonCount: function( button_val ) {
            button_val = parseInt( button_val , 10 );

            if( _.isNaN( button_val ) ) {
                return 0;
            } else if( 0 > button_val ) {
                return 0;
            } else if( CONSTANTS.MAX_PER_PURCHASE < button_val ) {
                return Math.min( CONSTANTS.MAX_PER_PURCHASE , this.get( 'maxPerPurchase' ) );
            } else if( this.get( 'maxPerPurchase' ) < button_val ) {
                return Math.min( CONSTANTS.MAX_PER_PURCHASE , this.get( 'maxPerPurchase' ) );
            }

            return button_val;
        }

        , updateBuyButtons: function() {
            var button_price = this.get( 'button_price' );

            this.set( {
                payPrice: (
                    button_price && this.effectiveButtonCount( this.get( 'button_default' ) )
                    ? button_price * this.effectiveButtonCount( this.get( 'button_default' ) )
                    : CONSTANTS.PAY_HIDE
                )

                , payPriceButton0: (
                    button_price && this.effectiveButtonCount( this.get( 'button_0' ) )
                    ? button_price * this.effectiveButtonCount( this.get( 'button_0' ) )
                    : CONSTANTS.PAY_HIDE
                )

                , payPriceButton1: (
                    button_price && this.effectiveButtonCount( this.get( 'button_1' ) )
                    ? button_price * this.effectiveButtonCount( this.get( 'button_1' ) )
                    : CONSTANTS.PAY_HIDE
                )

                , payPriceButton2: (
                    button_price && this.effectiveButtonCount( this.get( 'button_2' ) )
                    ? button_price * this.effectiveButtonCount( this.get( 'button_2' ) )
                    : CONSTANTS.PAY_HIDE
                )

                , payPriceButton3: (
                    button_price && this.effectiveButtonCount( this.get( 'button_3' ) )
                    ? button_price * this.effectiveButtonCount( this.get( 'button_3' ) )
                    : CONSTANTS.PAY_HIDE
                )
            } );
        }

        , updateAckEmailSlowness: function() {
            if( '' === this.get( 'email' ) ) {
                this.set( 'ackEmailSlowness' , false );
            }
        }

        , updateItemAggregates: function() {
            var totalItemsAvailable = 0;
            var totalRarity = 0;
            var unlimitedRarity = 0;
            var lowestLimitedRarity = 0;
            var totalBought = 0;
            var countUnlimited = 0;
            var countLimited = 0;
            var totalLimit = 0;
            var willHandOutNoCopyObjects = false;
            var anySelectedForBatchOperation = false;
            var allSelectedForBatchOperation = true;
            var totalItemsCopy = 0;
            var totalItemsMod = 0;
            var totalItemsTrans = 0;

            _.each( this.get( 'items' ).models , function( item ) {
                var copy = Boolean( CONSTANTS.PERM_COPY & item.get( 'ownerPermissions' ) );
                var mod = Boolean( CONSTANTS.PERM_MODIFY & item.get( 'ownerPermissions' ) );
                var trans = Boolean( CONSTANTS.PERM_TRANSFER & item.get( 'ownerPermissions' ) );

                totalBought += item.get( 'bought' );

                if( trans || ( 0 !== item.get( 'limit' ) && 0 !== item.get( 'rarity' ) ) ) {
                    if( 0 !== item.get( 'limit' ) ) {
                        ++totalItemsAvailable;
                        totalRarity += item.get( 'rarity' );

                        if( !copy && item.get( 'rarity' ) ) {
                            willHandOutNoCopyObjects = true;
                        }
                    }

                    if( -1 === item.get( 'limit' ) ) {
                        ++countUnlimited;
                        unlimitedRarity += item.get( 'rarity' );
                    } else {
                        totalLimit += item.get( 'limit' );

                        if( 0 !== item.get( 'limit' ) ) {
                            ++countLimited;
                        }

                        if( 0 === lowestLimitedRarity || ( item.get( 'rarity' ) && item.get( 'rarity' ) < lowestLimitedRarity ) ) {
                            lowestLimitedRarity = item.get( 'rarity' );
                        }
                    }
                }

                if( item.get( 'selectedForBatchOperation' ) ) {
                    anySelectedForBatchOperation = true;
                } else {
                    allSelectedForBatchOperation = false;
                }

                totalItemsCopy += copy;
                totalItemsMod += mod;
                totalItemsTrans += trans;
            } , this );

            this.set( {
                totalItems: this.get( 'items' ).length
                , totalItemsAvailable: totalItemsAvailable
                , totalRarity: totalRarity
                , unlimitedRarity: unlimitedRarity
                , lowestLimitedRarity: lowestLimitedRarity
                , totalBought: totalBought
                , countUnlimited: countUnlimited
                , countLimited: countLimited
                , totalLimit: totalLimit
                , willHandOutNoCopyObjects: willHandOutNoCopyObjects
                , anySelectedForBatchOperation: anySelectedForBatchOperation
                , allSelectedForBatchOperation: allSelectedForBatchOperation
                , totalItemsCopy: totalItemsCopy
                , totalItemsMod: totalItemsMod
                , totalItemsTrans: totalItemsTrans
            } );

            _.each( this.get( 'items' ).models , function( item ) {
                var rarity = item.get( 'rarity' );

                var myUnlimitedRarity = unlimitedRarity;
                if( -1 !== item.get( 'limit' ) ) {
                    myUnlimitedRarity += rarity;
                }

                var lowRarityPercentage = ( totalRarity ? rarity / totalRarity * 100 : 0 );
                var highRarityPercentage = ( myUnlimitedRarity ? rarity / myUnlimitedRarity * 100 : 0 );
                var boughtPercentage = ( totalBought ? item.get( 'bought' ) / totalBought * 100 : 0 );

                // Generally sort by configured rarity, then actual seen rarity
                var sortRarity = ( lowRarityPercentage * 100 ) + boughtPercentage;

                item.set( {
                    lowRarityPercentage: lowRarityPercentage
                    , highRarityPercentage: highRarityPercentage
                    , boughtPercentage: boughtPercentage
                    , sortRarity: sortRarity
                } );
            } , this );
        }

    } );

    return exports;
} );
