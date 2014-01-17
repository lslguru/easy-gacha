define( [
] , function(
) {
    'use strict';

    var exports = function() {
        return Boolean( String( window.navigator.userAgent ).match( /\bSecondLife\b/i ) );
    };

    return exports;

} );
