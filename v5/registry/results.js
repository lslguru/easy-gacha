define( [

    'underscore'
    , 'jquery'
    , 'marionette'
    , 'hbs!registry/templates/results'
    , 'css!registry/styles/results'
    , 'registry/result-agent'
    , 'lib/tooltip-placement'
    , 'bootstrap'
    , 'lib/fade'
    , 'backbone'

] , function(

    _
    , $
    , Marionette
    , template
    , styles
    , ItemView
    , tooltipPlacement
    , bootstrap
    , fade
    , Backbone

) {
    'use strict';

    var exports = Marionette.CompositeView.extend( {
        template: template
        , itemView: ItemView
        , itemViewContainer: '#results'

        , ui: {
            'tooltips': '[data-toggle=tooltip]'
            , 'loading': '#loading'
        }

        , modelEvents: {
            'change:fetching': 'onChangeFetching loadMore'
        }

        , initialize: function() {
            this.loadMore = _.bind( this.loadMore , this );

            Marionette.CompositeView.prototype.initialize.apply( this , arguments );

            var realCollection = this.realCollection = this.collection;
            var collection = this.collection = new Backbone.Collection();
            realCollection.on( 'add' , function( model /* , collection , eventOptions */ ) {
                var ownerUsername = model.get( 'ownerUsername' );

                var subModel = collection.get( ownerUsername );
                if( !subModel ) {
                    subModel = new Backbone.Model( {
                        id: ownerUsername
                        , ownerUsername: model.get( 'ownerUsername' )
                        , ownerDisplayname: model.get( 'ownerDisplayname' )
                        , gachas: new Backbone.Collection()
                    } );
                    collection.add( subModel );
                }

                subModel.get( 'gachas' ).add( model );
            } , this );
            realCollection.on( 'remove' , function( model /* , collection , eventOptions */ ) {
                var ownerUsername = model.get( 'ownerUsername' );
                var subModel = collection.get( ownerUsername );
                subModel.get( 'gachas' ).remove( model );
                if( 0 === subModel.get( 'gachas' ) ) {
                    collection.remove( subModel );
                }
            } , this );
            realCollection.on( 'reset' , function( model /* , collection , eventOptions */ ) {
                collection.reset();
            } , this );
        }

        , onRender: function() {
            this.ui.tooltips.tooltip( {
                html: true
                , container: 'body'
                , placement: tooltipPlacement
            } );

            this.onChangeFetching();

            $( window ).on( 'scroll' , this.loadMore );
            $( window ).on( 'resize' , this.loadMore );

            this.loadMore();
        }

        , onChangeFetching: function() {
            fade( this.ui.loading , this.model.get( 'fetching' ) );
        }

        , onClose: function() {
            $( window ).off( 'scroll' , this.loadMore );
            $( window ).off( 'resize' , this.loadMore );
            this.ui.tooltips.tooltip( 'destroy' );
        }

        , onItemRemoved: function() {
            this.loadMore();
        }

        , onAfterItemAdded: function() {
            this.loadMore();
        }

        , loadMore: function() {
            // If we cannot load more, this is moot

            if( !this.realCollection.canLoadMore() ) {
                return;
            }

            // Find the bottom of the screen relative to the document

            var scrollTop = $( window ).scrollTop();
            var windowHeight = $( window ).height();
            var scrollBottom = scrollTop + windowHeight;

            // Find the top of the last element displayed

            var collectionLength = this.collection.length;
            if( !collectionLength ) {
                return;
            }

            var lastModel = this.collection.models[ collectionLength - 1 ];
            var lastView = this.children.findByModel( lastModel );
            if( !lastView ) {
                return;
            }

            var lastEl = lastView.$el;
            if( !lastEl ) {
                return;
            }

            var lastElOffset = lastEl.offset();
            var lastElTop = lastElOffset.top;

            // If the top of the last element is visible, keep going

            if( lastElTop < scrollBottom ) {
                this.realCollection.fetch();
            }
        }
    } );

    return exports;

} );
