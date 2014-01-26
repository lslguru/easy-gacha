define( [

    'underscore'
    , 'models/base-sl-model'
    , 'lib/constants'

] , function(

    _
    , BaseModel
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
            , apiPurchasesEnabled: null
            , apiItemsGivenEnabled: null
            , extra: null
        }

        , toPostJSON: function( options , syncMethod , xhrType ) {
            if( 'read' !== syncMethod ) {
                return [
                    Number( this.get( 'folderForSingleItem' ) )
                    , this.get( 'rootClickAction' )
                    , Number( this.get( 'group' ) )
                    , Number( this.get( 'allowHover' ) )
                    , this.get( 'maxPerPurchase' )
                    , this.get( 'maxBuys' )
                    , this.get( 'payPrice' )
                    , this.get( 'payPriceButton0' )
                    , this.get( 'payPriceButton1' )
                    , this.get( 'payPriceButton2' )
                    , this.get( 'payPriceButton3' )
                    , Number( this.get( 'apiPurchasesEnabled' ) )
                    , Number( this.get( 'apiItemsGivenEnabled' ) )
                    , JSON.stringify( this.get( 'extra' ) || {} )
                ];
            } else {
                return [];
            }
        }

        , parse: function( data ) {
            if( null === data ) {
                return {};
            }

            var i = 0;
            var parsed = {};

            parsed.folderForSingleItem = Boolean( parseInt( data[i++] , 10 ) );
            parsed.rootClickAction = parseInt( data[i++] , 10 ); // -1 == not asked, otherwise boolean via int
            parsed.group = Boolean( parseInt( data[i++] , 10 ) );
            parsed.allowHover = Boolean( parseInt( data[i++] , 10 ) );
            parsed.maxPerPurchase = parseInt( data[i++] , 10 );
            parsed.maxBuys = parseInt( data[i++] , 10 );
            parsed.payPrice = parseInt( data[i++] , 10 );
            parsed.payPriceButton0 = parseInt( data[i++] , 10 );
            parsed.payPriceButton1 = parseInt( data[i++] , 10 );
            parsed.payPriceButton2 = parseInt( data[i++] , 10 );
            parsed.payPriceButton3 = parseInt( data[i++] , 10 );
            parsed.apiPurchasesEnabled = Boolean( parseInt( data[i++] , 10 ) );
            parsed.apiItemsGivenEnabled = Boolean( parseInt( data[i++] , 10 ) );

            return parsed;
        }
    } );

    return exports;
} );
