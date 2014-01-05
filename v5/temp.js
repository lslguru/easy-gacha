define( [
    'jquery'
    , 'text!page-loading.html'
    , 'css!vendor/bootstrap/css/bootstrap'
    , 'css!//netdna.bootstrapcdn.com/font-awesome/4.0.3/css/font-awesome'
    , 'css!all'
    , 'image!test.gif'
] , function(
    $
    , pageLoadingTemplate
    , bootstrapCss
    , fontAwesomeCss
    , projectCss
    , testImg
) {
    $( 'body' ).html( pageLoadingTemplate );
    $( 'body' ).append( testImg );
} );
