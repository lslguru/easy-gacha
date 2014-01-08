define( [

    'marionette'
    , 'hbs!dashboard/templates/items'
    , 'css!dashboard/styles/items'
    , 'dashboard/item'
    , 'tablesorter'

] , function(

    Marionette
    , template
    , styles
    , ItemView
    , tablesorter

) {
    'use strict';

    var exports = Marionette.CompositeView.extend( {
        template: template
        , itemView: ItemView
        , itemViewContainer: 'tbody'

        , ui: {
            'table': 'table'
            , 'tooltips': '[data-toggle=tooltip]'
        }

        , onRender: function() {
            this.ui.table.tablesorter( {
                sortList: [[0,0]]
                , textExtraction: function( node ) {
                    return $( node ).data( 'raw-value' ) || $( node ).text();
                }
            } );

            this.ui.tooltips.tooltip( {
                html: true
                , container: 'body'
                , placement: function( tip , el ) {
                    return $(el).data('tooltip-placement') || 'auto';
                }
            } );
        }
    } );

    return exports;

} );
