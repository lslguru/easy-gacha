define( [
] , function(
) {
    'use strict';

    return {
        load: function() {
            return window.localStorage.getItem( 'easy-gacha-adminKey: ' + window.location.origin + window.location.pathname ) || null;
        }

        , save: function( adminKey ) {
            window.localStorage.setItem( 'easy-gacha-adminKey: ' + window.location.origin + window.location.pathname , adminKey );
        }
    };

} );
