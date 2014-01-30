define( [

    'backbone'
    , 'models/registry-gacha'

] , function(

    Backbone
    , Gacha

) {
    'use strict';

    var exports = Backbone.Collection.extend( {
        model: Gacha

        , urlParams: null
        , countModel: null

        , initialize: function() {
            this.constructor.__super__.initialize.apply( this , arguments );

            this.urlParams = new Backbone.Model( {
                maxPrice: null
                , searchString: null
                , randomize: false
            } );

            this.urlParams.on( 'change' , function() {
                this.reset();
                this.fetchCount();
            } , this );
        }

        , fetchCount: function() {
            var countModel = this.countModel = new Gacha();
            countModel.urlParams = this.urlParams.attributes;
            countModel.fetch( {
                success: _.bind( function() {
                    // If this is still the requested count
                    if( countModel === this.countModel ) {
                        this.fetch();
                    }
                } , this )
            } );
        }

        // Only fetches the next 1 item and adds it to the collection if
        // successful
        , fetch: function() {
            console.log( 'TODO' );
        }
    } );

    return exports;
} );
