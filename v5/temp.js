define( [
    'jquery'
    , 'text!page-loading.html'
    , 'css!vendor/bootstrap/css/bootstrap'
    , 'css!//netdna.bootstrapcdn.com/font-awesome/4.0.3/css/font-awesome'
    , 'css!all'
] , function(
    $
    , pageLoadingTemplate
    , bootstrapCss
    , fontAwesomeCss
    , projectCss
) {
    $( 'body' ).html( pageLoadingTemplate );
    console.log( bootstrapCss );
    console.log( fontAwesomeCss );
    console.log( projectCss );
} );
