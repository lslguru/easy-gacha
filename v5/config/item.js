define( [

    'underscore'
    , 'jquery'
    , 'marionette'
    , 'hbs!config/templates/item'
    , 'css!config/styles/item'
    , 'lib/constants'
    , 'lib/tooltip-placement'
    , 'bootstrap'

] , function(

    _
    , $
    , Marionette
    , template
    , styles
    , CONSTANTS
    , tooltipPlacement
    , bootstrap

) {
    'use strict';

    var exports = Marionette.ItemView.extend( {
        template: template
        , tagName: 'tr'

        , ui: {
            'tooltips': '[data-toggle=tooltip]'
            , 'nameFields': '[data-column-contents=name]'
        }

        , templateHelpers: function() {
            return {
                typeName: CONSTANTS.INVENTORY_TYPE_NAME[ this.model.get( 'type' ) ]
                , ownerCanCopy: Boolean( this.model.get( 'ownerPermissions' ) & CONSTANTS.PERM_COPY )
                , nextCanCopy: Boolean( this.model.get( 'nextPermissions' ) & CONSTANTS.PERM_COPY )
                , ownerCanMod: Boolean( this.model.get( 'ownerPermissions' ) & CONSTANTS.PERM_MODIFY )
                , nextCanMod: Boolean( this.model.get( 'nextPermissions' ) & CONSTANTS.PERM_MODIFY )
                , ownerCanTrans: Boolean( this.model.get( 'ownerPermissions' ) & CONSTANTS.PERM_TRANSFER )
                , nextCanTrans: Boolean( this.model.get( 'nextPermissions' ) & CONSTANTS.PERM_TRANSFER )
            };
        }

        , onRender: function() {
            this.ui.tooltips.tooltip( {
                html: true
                , container: 'body'
                , placement: tooltipPlacement
            } );

            this.ui.nameFields.each( _.bind( function( index , item ) {
                var type = this.model.get( 'type' );
                var image = CONSTANTS.INVENTORY_TYPE_ICON[ type ];
                var insert = $( image ).clone();

                insert.prependTo( item );
            } , this ) );
        }
    } );

    return exports;

} );
