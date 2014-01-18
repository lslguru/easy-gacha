define( [

    'underscore'
    , 'backbone'
    , 'models/base-sl'

] , function(

    _
    , Backbone
    , BaseSl

) {
    'use strict';

    var exports = Backbone.Model.extend( _.extend( {} , BaseSl , {

        includeInNotecard: []

        , fromNotecardJSON: function( json ) {
            for( var key in json ) {
                if( key in this.attributes ) {
                    if( _.isObject( this.get( key ) ) && this.get( key ).fromNotecardJSON ) {
                        var result = this.get( key ).fromNotecardJSON( json[ key ] );
                        if( true !== result ) {
                            return result;
                        }
                    } else {
                        this.set( key , json[ key ] );
                    }
                } else {
                    return 'Unexpected key: ' + key;
                }
            }

            return true;
        }

        , toNotecardJSON: function() {
            var json = {};

            _.each( this.constructor.__super__.toJSON.apply( this , arguments ) , function( value , key ) {
                if( -1 !== this.includeInNotecard.indexOf( key ) ) {
                    if( value && value.toNotecardJSON ) {
                        json[ key ] = value.toNotecardJSON();
                    } else {
                        json[ key ] = value;
                    }
                }
            } , this );

            return json;
        }
        
    } ) );

    return exports;
} );
