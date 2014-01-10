define( [

    'models/agents'

] , function(

    Agents

) {
    'use strict';

    // Singleton
    var exports = new Agents();

    return exports;

} );
