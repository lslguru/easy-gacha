define( [

    'underscore'
    , 'marionette'
    , 'hbs!registry/templates/index'
    , 'css!registry/styles/index'
    , 'bootstrap'
    , 'models/registry'
    , 'registry/search'
    , 'registry/results'

] , function(

    _
    , Marionette
    , template
    , styles
    , bootstrap
    , Registry
    , SearchView
    , ResultsView

) {
    'use strict';

    var exports = Marionette.Layout.extend( {
        template: template

        , regions: {
            'search': '#search-region'
            , 'results': '#results-region'
        }

        , onRender: function() {
            this.collection = new Registry();

            // For debug convenience
            window.registry = this.collection;

            // Because it's nice
            document.title = 'Easy Gacha Registry';

            this.search.show( new SearchView( {
                model: this.collection.urlParams
            } ) );

            this.results.show( new ResultsView( {
                model: this.collection.urlParams
                , collection: this.collection
            } ) );
        }
    } );

    return exports;

} );
