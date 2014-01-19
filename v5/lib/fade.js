define( [

    'underscore'
    , 'jquery'
    , 'css!styles/fade'

] , function(

    _
    , $
    , fadeStyles

) {
    'use strict';

    var next = 0;
    var fading = {};

    function nextId() {
        return 'f' + next++;
    }

    function ifCallback( callback ) {
        if( _.isFunction( callback ) ) {
            callback();
        }
    }

    function endFade( id , show ) {
        if( show !== fading[ id ].show ) {
            return fade( fading[ id ].el , fading[ id ].show , null , true );
        }

        _.each( fading[ id ].callbacks , function( callback ) {
            ifCallback( callback );
        } );

        fading[ id ].el.removeData( 'fading-id' );
        delete fading[ id ];
    }

    function atEndOfTransition( el , callback ) {
        if( ! $.support.transition ) {
            callback();
        } else {
            el
                .one( $.support.transition.end , callback )
                .emulateTransitionEnd( 150 )
            ;
        }
    }

    function resize( el , show , callback ) {
        var position = el.css( 'position' );

        if( 'static' !== position && 'relative' !== position ) {
            callback();
            return;
        }

        // Create a temporary empty element for the growth
        var temp = $( '<div />' );
        temp.insertBefore( el );

        // Duplicate properties of hidden element
        temp.css( {
            'position': 'relative'
            , 'top': el.css( 'top' )
            , 'right': el.css( 'right' )
            , 'bottom': el.css( 'bottom' )
            , 'left': el.css( 'left' )
            , 'margin-top': el.css( 'margin-top' )
            , 'margin-right': el.css( 'margin-right' )
            , 'margin-bottom': el.css( 'margin-bottom' )
            , 'margin-left': el.css( 'margin-left' )
        } );

        // Start size
        if( show ) {
            temp.css( {
                'width': 0
                , 'height': 0
            } );
        } else {
            temp.css( {
                'width': el.outerWidth()
                , 'height': el.outerHeight()
            } );
        }

        // Add transition
        temp.addClass( 'fade-size' );

        // End size
        if( show ) {
            temp.css( {
                'width': el.outerWidth()
                , 'height': el.outerHeight()
            } );
        } else {
            temp.css( {
                'width': 0
                , 'height': 0
            } );
        }

        // Wait for transition
        atEndOfTransition( temp , function() {
            temp.remove();
            callback();
        } );
    }

    function fade( el , show , callback , force ) {
        el = $( el );
        show = Boolean( show );

        if( ! el.hasClass( 'fade' ) ) {
            el.toggleClass( 'hide' , !show );
            ifCallback( callback );
            return;
        }

        var id = el.data( 'fading-id' ) || nextId();
        el.data( 'fading-id' , id );

        // There's already a transition in progress, record settings to deal
        // with it at the end of the current transition
        if( fading[ id ] && !force ) {
            fading[ id ].show = show;

            if( callback ) {
                fading[ id ].callbacks.push( callback );
            }

            return;
        }

        // Already shown/hidden, nothing to do
        if( show && el.hasClass( 'in' ) ) {
            return ifCallback( callback );
        }
        if( !show && el.hasClass( 'hide' ) ) {
            return ifCallback( callback );
        }

        // If we're being forced, it's an internal call
        if( !force ) {
            fading[ id ] = {
                el: el
                , show: show
                , callbacks: [ callback ]
            };
        }

        // Meat and potatoes
        if( show ) {
            resize( el , show , function() {
                el.removeClass( 'hide' );

                _.defer( function() {
                    el.addClass( 'in' );

                    atEndOfTransition( el , function() {
                        endFade( id , show );
                    } );
                } );
            } );
        } else {
            el.removeClass( 'in' );

            atEndOfTransition( el , function() {
                el.addClass( 'hide' );

                resize( el , show , function() {
                    endFade( id , show );
                } );
            } );
        }
    }

    return fade;

} );
