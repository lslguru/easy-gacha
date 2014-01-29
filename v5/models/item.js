define( [

    'underscore'
    , 'models/base-sl-model'
    , 'lib/constants'
    , 'models/agents-cache'

] , function(

    _
    , BaseModel
    , CONSTANTS
    , agentsCache

) {
    'use strict';

    var exports = BaseModel.extend( {
        url: 'item'
        , idAttribute: 'name'

        , defaults: {
            index: null
            , rarity: null
            , limit: null
            , bought: 0
            , name: null
            , type: 'INVENTORY_UNKNOWN'

            // UI
            , selectedForBatchOperation: false

            // Calculated
            , remainingInventory: null

            // Calculated by Gacha
            , lowRarityPercentage: null
            , highRarityPercentage: null
            , boughtPercentage: null
            , sortRarity: null

            // From: models/inv
            , creator: null
            , creatorUserName: null
            , creatorDisplayName: null
            , key: null
            , ownerPermissions: null
            , groupPermissions: null
            , publicPermissions: null
            , nextPermissions: null

            // Warnings and Dangers:
            // {hasWarning|hasDanger}_{viewName}_{valueName} = {true|false}
            , hasDanger_item_rarity: false
            , hasDanger_item_limit: false
        }

        , initialize: function() {
            this.constructor.__super__.initialize.apply( this , arguments );
            this.on( 'change:ownerPermissions' , this.applyNoCopyLimit , this );
            this.on( 'change:limit' , this.applyEffectiveLimit , this );
            this.on( 'change:limit change:bought' , this.updateRemainingInventory , this );
        }

        , updateRemainingInventory: function() {
            var limit = this.get( 'limit' );
            var bought = this.get( 'bought' );

            if( -1 === limit ) {
                this.set( 'remainingInventory' , Number.POSITIVE_INFINITY );
            } else if( bought > limit ) {
                this.set( 'remainingInventory' , 0 );
            } else {
                this.set( 'remainingInventory' , limit - bought );
            }
        }

        , applyNoCopyLimit: function() {
            if( null !== this.get( 'ownerPermissions' ) && !( CONSTANTS.PERM_COPY & this.get( 'ownerPermissions' ) ) ) {
                this.set( 'limit' , 1 );
            }
        }

        , applyEffectiveLimit: function() {
            // Cannot apply until we know this
            if( null === this.get( 'ownerPermissions' ) ) {
                return;
            }

            // Overrides
            if( !( CONSTANTS.PERM_TRANSFER & this.get( 'ownerPermissions' ) ) ) {
                this.set( 'limit' , 0 );
            } else if( !( CONSTANTS.PERM_COPY & this.get( 'ownerPermissions' ) ) ) {
                this.set( 'limit' , 1 );
            }
        }

        , includeInNotecard: [
            'rarity'
            , 'limit'
            , 'bought'
            , 'name'
        ]

        , toPostJSON: function( options , syncMethod , xhrType ) {
            if( 'delete' === syncMethod ) {
                return [];
            }
            
            if( 'read' !== syncMethod ) {
                return [
                    this.get( 'name' )
                    , this.get( 'rarity' )
                    , this.get( 'limit' )
                ];
            }

            return [
                this.get( 'index' )
            ];
        }

        , parse: function( data ) {
            if( null === data ) {
                return {};
            }

            var i = 0;
            var parsed = {};

            parsed.index = parseInt( data[i++] , 10 );
            parsed.rarity = parseFloat( data[i++] , 10 );
            parsed.limit = parseInt( data[i++] , 10 );
            parsed.bought = parseInt( data[i++] , 10 );
            parsed.name = data[i++];
            parsed.type = CONSTANTS.INVENTORY_NUMBER_TO_TYPE[ parseInt( data[i++] , 10 ) ] || 'INVENTORY_UNKNOWN';
            parsed.creator = data[i++];

            return parsed;
        }

        , fetch: function( options ) {
            var success = options.success;
            var fetchOptions = _.clone( options );

            fetchOptions.success = _.bind( function( model , resp ) {
                if( CONSTANTS.NULL_KEY == model.get( 'creator' ) ) {
                    if( success ) {
                        success.call( this , model , resp , options );
                    }

                    return;
                }

                agentsCache.fetch( {
                    id: model.get( 'creator' )
                    , context: this
                    , success: function( agent ) {
                        this.set( {
                            creatorUserName: agent.get( 'username' )
                            , creatorDisplayName: agent.get( 'displayname' )
                        } );

                        if( success ) {
                            options.success.call( this , model , resp , options );
                        }
                    }
                } );
            } , this );

            BaseModel.prototype.fetch.call( this , fetchOptions );
        }

        , shouldIncludeInSave: function() {
            return Boolean( this.get( 'rarity' ) && 0 !== this.get( 'limit' ) );
        }
    } );

    return exports;
} );
