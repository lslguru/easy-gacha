define( [

    'underscore'
    , 'models/base-sl-model'
    , 'lib/constants'
    , 'models/notecard-line'
    , 'models/notecard-line-count'

] , function(

    _
    , BaseModel
    , CONSTANTS
    , NotecardLine
    , NotecardLineCount

) {
    'use strict';

    var exports = BaseModel.extend( {
        defaults: {
            name: ''
            , text: ''
            , progressPercentage: 0
            , lineCount: 0
        }

        , fetch: function( options ) {
            options = options || {};

            var notecardLineCount = new NotecardLineCount( {
                lookup: this.get( 'name' )
            } );

            var nlcFetchOptions = _.clone( options );
            nlcFetchOptions.success = _.bind( function() {
                var lineCount = parseInt( notecardLineCount.get( 'result' ) , 10 ) + 1;
                this.set( 'lineCount' , lineCount );

                if( ! this.get( 'lineCount' ) ) {
                    if( options.success ) {
                        options.success();
                    }

                    return;
                }

                var lineNumber = 0;
                var notecardLine = new NotecardLine();

                var nlFetchOptions = _.clone( options );
                nlFetchOptions.success = _.bind( function() {
                    var text = this.get( 'text' );
                    var lineText = notecardLine.get( 'result' );

                    if( CONSTANTS.EOF !== notecardLine.get( 'result' ) ) {
                        this.set( {
                            text: (
                                text
                                + ( text ? '\n' : '' )
                                + lineText
                            ).replace( /\n$/ , '' )

                            , progressPercentage: (
                                ( lineNumber + 1 ) / lineCount * 100
                            )
                        } );
                    }

                    if( CONSTANTS.EOF === notecardLine.get( 'result' ) || lineCount === lineNumber + 1 ) {
                        this.set( 'progressPercentage' , 100 );

                        if( options.success ) {
                            options.success();
                        }

                        return;
                    }

                    ++lineNumber;
                    next();
                } , this );

                var next = _.bind( function() {
                    notecardLine.set( {
                        lookup: [
                            this.get( 'name' )
                            , lineNumber
                        ]
                    } );

                    notecardLine.fetch( nlFetchOptions );
                } , this );

                next();
            } , this );

            notecardLineCount.fetch( nlcFetchOptions );
        }
    } );

    return exports;
} );
