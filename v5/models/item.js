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
            , selectedForBatchOperation: false

            // From: models/inv
            , creator: null
            , creatorUserName: null
            , creatorDisplayName: null
            , key: null
            , ownerPermissions: null
            , groupPermissions: null
            , publicPermissions: null
            , nextPermissions: null
        }

        , initialize: function() {
            this.constructor.__super__.initialize.apply( this , arguments );
            this.on( 'change:ownerPermissions' , this.applyNoCopyLimit , this );
            this.on( 'change:limit' , this.applyEffectiveLimit , this );
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

            return parsed;
        }

        , shouldIncludeInSave: function() {
            return Boolean( this.get( 'rarity' ) && 0 !== this.get( 'limit' ) );
        }
    } );

    return exports;
} );
