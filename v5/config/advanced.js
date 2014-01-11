define( [

    'underscore'
    , 'jquery'
    , 'marionette'
    , 'hbs!config/templates/advanced'
    , 'css!config/styles/advanced'
    , 'bootstrap'
    , 'lib/constants'
    , 'lib/tooltip-placement'

] , function(

    _
    , $
    , Marionette
    , template
    , headerStyles
    , bootstrap
    , CONSTANTS
    , tooltipPlacement

) {
    'use strict';

    var exports = Marionette.ItemView.extend( {
        template: template
    } );

    return exports;

} );
