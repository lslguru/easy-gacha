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
    , 'lib/google-analytics'

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
    , ga

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

                    this.ui.table.bind( 'sortEnd' , function( jEvent ) {
                        var sortList = jEvent.target.config.sortList;
                        var readableSortList = [];

                        _.each( sortList , function( pair ) {
                            var columnIndex = pair[ 0 ];
                            var headerElement = jEvent.target.config.headerList[ columnIndex ];
                            var columnContents = $( headerElement ).data( 'column-contents' );
                            var direction = ( pair[ 1 ] ? 'DESC' : 'ASC' );

                            readableSortList.push( columnContents + ' ' + direction );
                        } , this );

                        var sortQuery = readableSortList.join( ', ' );

                        ga( 'send' , 'event' , 'dashboard' , 'sort' , sortQuery );
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
