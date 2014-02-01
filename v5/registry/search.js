define( [

    'underscore'
    , 'jquery'
    , 'marionette'
    , 'hbs!registry/templates/search'
    , 'css!registry/styles/search'
    , 'lib/constants'
    , 'lib/tooltip-placement'
    , 'bootstrap'
    , 'lib/fade'

] , function(

    _
    , $
    , Marionette
    , template
    , styles
    , CONSTANTS
    , tooltipPlacement
    , bootstrap
    , fade

) {
    'use strict';

    var exports = Marionette.ItemView.extend( {
        template: template

        , ui: {
            'tooltips': '[data-toggle=tooltip]'
            , 'maxPrice': '#max-price'
            , 'searchString': '#search-string'
            , 'randomizeButtons': '.randomize-button'
            , 'clearSearch': '#clear-search'
        }

        , events: {
            'change @ui.maxPrice': 'setMaxPrice'
            , 'keyup @ui.maxPrice': 'setMaxPrice'
            , 'change @ui.searchString': 'setSearchString'
            , 'keyup @ui.searchString': 'setSearchString'
            , 'click @ui.randomizeButtons': 'setRandomize'
            , 'click @ui.clearSearch': 'clearSearch'
        }

        , onRender: function() {
            this.ui.tooltips.tooltip( {
                html: true
                , container: 'body'
                , placement: tooltipPlacement
            } );
        }

        , onClose: function() {
            this.ui.tooltips.tooltip( 'destroy' );
        }

        , setMaxPrice: function() {
            this.ui.maxPrice.parent().removeClass( 'has-error' );
            var maxPrice = this.ui.maxPrice.val();

            if( '' === maxPrice ) {
                this.model.set( 'maxPrice' , null );
                return;
            }

            maxPrice = parseInt( maxPrice , 10 );

            if(
                ( _.isNaN( maxPrice ) )
                || ( 0 > maxPrice )
                || ( this.ui.maxPrice.val() != maxPrice )
            ) {
                this.ui.maxPrice.parent().addClass( 'has-error' );
                return;
            }

            this.model.set( 'maxPrice' , maxPrice );
        }

        , setSearchString: function() {
            var searchString = this.ui.searchString.val();

            if( '' === searchString ) {
                searchString = null;
            }

            this.model.set( 'searchString' , searchString );
        }

        , setRandomize: function( jEvent ) {
            this.model.set( 'randomize' , Boolean( parseInt( $( jEvent.currentTarget ).val() , 10 ) ) );
            this.ui.randomizeButtons.removeClass( 'active' );
            $( jEvent.currentTarget ).addClass( 'active' );
        }

        , clearSearch: function() {
            this.ui.searchString.val( '' );
            this.setSearchString();
        }

    } );

    return exports;

} );
