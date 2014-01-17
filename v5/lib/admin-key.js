define( [

    'vendor/docCookies'

] , function(

    docCookies

) {
    'use strict';

    // Prefer to use localStorage over cookies as it lessens the amount of data
    // sent over the network, but SecondLife's built-in browser doesn't support
    // localStorage

    var exports = {
        getKey: function() {
            return 'easy-gacha-adminKey: ' + window.location.origin + window.location.pathname;
        }

        , load: function() {
            if( window.localStorage ) {
                return window.localStorage.getItem( exports.getKey() ) || null;
            } else {
                return docCookies.getItem( exports.getKey() ) || null;
            }
        }

        , save: function( adminKey ) {
            if( window.localStorage ) {
                window.localStorage.setItem( exports.getKey() , adminKey );
            } else {
                docCookies.setItem( exports.getKey() , adminKey );
            }
        }
    };

    return exports;

} );
