define( [ 'jquery' ] , function( $ ) {
    'use strict';

    return function( tip , el ) {
        return $(el).data('tooltip-placement') || 'auto';
    };

} );
