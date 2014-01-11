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
            , isRootPrim: null
        }

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

            return {
                folderForSingleItem: Boolean( parseInt( data[0] , 10 ) )
                , rootClickAction: Boolean( parseInt( data[1] , 10 ) )
                , group: Boolean( parseInt( data[2] , 10 ) )
                , allowHover: Boolean( parseInt( data[3] , 10 ) )
                , maxPerPurchase: parseInt( data[4] , 10 )
                , maxBuys: parseInt( data[5] , 10 )
                , payPrice: parseInt( data[6] , 10 )
                , payPriceButton0: parseInt( data[7] , 10 )
                , payPriceButton1: parseInt( data[8] , 10 )
                , payPriceButton2: parseInt( data[9] , 10 )
                , payPriceButton3: parseInt( data[10] , 10 )
                , isRootPrim: Boolean( parseInt( data[11] , 10 ) )
            };
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

                        if( !model.get( 'im' ) || CONSTANTS.NULL_KEY === model.get( 'im' ) ) {
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
