define( 'main' , [
    'jquery'
    , 'text!page-loading.html'
] , function(
    $
    , pageLoadingTemplate
) {
    $( 'body' ).html( pageLoadingTemplate );
} );
require.config( {
    text: {
        useXhr: function() { return true; }
    }
} );
require( [ 'main' ] );
