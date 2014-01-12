define( [

    'underscore'
    , 'models/base-sl-model'
    , 'models/email'
    , 'models/im'
    , 'models/agents-cache'
    , 'lib/constants'

] , function(

    _
    , BaseModel
    , Email
    , Im
    , agentsCache
    , CONSTANTS

) {
    'use strict';

    var exports = BaseModel.extend( {
        url: 'configs'

        , defaults: {
            folderForSingleItem: null
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
            'folderForSingleItem'
            , 'rootClickAction'
            , 'group'
            , 'allowHover'
            , 'maxPerPurchase'
            , 'maxBuys'
            , 'payPrice'
            , 'payPriceButton0'
            , 'payPriceButton1'
            , 'payPriceButton2'
            , 'payPriceButton3'
            , 'email'
            , 'im'
            , 'setFolderName'
        ]

        , toPostJSON: function( options , syncMethod , xhrType ) {
            // TODO: Save

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

            parsed.folderForSingleItem = Boolean( parseInt( data[i++] , 10 ) );
            parsed.rootClickAction = Boolean( parseInt( data[i++] , 10 ) );
            parsed.group = Boolean( parseInt( data[i++] , 10 ) );
            parsed.allowHover = Boolean( parseInt( data[i++] , 10 ) );
            parsed.maxPerPurchase = parseInt( data[i++] , 10 );
            parsed.maxBuys = parseInt( data[i++] , 10 );
            parsed.payPrice = parseInt( data[i++] , 10 );
            parsed.payPriceButton0 = parseInt( data[i++] , 10 );
            parsed.payPriceButton1 = parseInt( data[i++] , 10 );
            parsed.payPriceButton2 = parseInt( data[i++] , 10 );
            parsed.payPriceButton3 = parseInt( data[i++] , 10 );

            return parsed;
        }

        , fetch: function( options ) {
            var success = options.success;
            var fetchOptions = _.clone( options );

            if( success ) {
                success = _.bind( success , this );
            }

            fetchOptions.success = function( model , resp ) {
                var email = new Email();

                var emailOptions = _.clone( options );
                emailOptions.success = function( email_model , email_resp , email_options ) {
                    model.set( 'email' , email.get( 'address' ) );

                    var im = new Im();

                    var imOptions = _.clone( options );
                    imOptions.success = function( im_model , im_resp , im_options ) {
                        model.set( 'im' , im.get( 'key' ) );

                        if( CONSTANTS.NULL_KEY === model.get( 'im' ) ) {
                            if( success ) {
                                success( model , resp , options );
                            }

                            return;
                        }

                        agentsCache.fetch( {
                            id: model.get( 'im' )
                            , context: this
                            , success: function( agent ) {
                                this.set( {
                                    imUserName: agent.get( 'username' )
                                    , imDisplayName: agent.get( 'displayname' )
                                } );

                                if( success ) {
                                    success( model , resp , options );
                                }
                            }
                        } );
                    };

                    im.fetch( imOptions );
                };

                email.fetch( emailOptions );
            };

            BaseModel.prototype.fetch.call( this , fetchOptions );
        }
    } );

    return exports;
} );
