define( [

    'underscore'
    , 'marionette'
    , 'hbs!dashboard/templates/items'
    , 'css!dashboard/styles/items'
    , 'dashboard/item'
    , 'dashboard/items-empty'
    , 'tablesorter'
    , 'lib/tooltip-placement'
    , 'bootstrap'

] , function(

    _
    , Marionette
    , template
    , styles
    , ItemView
    , EmptyView
    , tablesorter
    , tooltipPlacement
    , bootstrap

) {
    'use strict';

    var exports = Marionette.CompositeView.extend( {
        template: template
        , itemView: ItemView
        , itemViewContainer: 'tbody'
        , emptyView: EmptyView

        , ui: {
            'table': 'table'
            , 'tooltips': '[data-toggle=tooltip]'
        }

        , onRender: function() {
            if( !_.isString( this.ui.table ) ) {
                // tablesorter dies horribly when there are no data rows
                if( this.collection.length ) {
                    this.ui.table.tablesorter( {
                        sortList: [[0,0]]
                        , textExtraction: function( node ) {
                            return $( node ).data( 'raw-value' ) || $( node ).text();
                        }
                    } );
                }

                this.ui.tooltips.tooltip( {
                    html: true
                    , container: 'body'
                    , placement: tooltipPlacement
                } );
            }
        }

        , onClose: function() {
            this.ui.tooltips.tooltip( 'destroy' );
            this.ui.table.data( 'tablesorter' ) && this.ui.table.tablesorter( 'destroy' );
        }
    } );

    return exports;

} );
