define( [

    'underscore'
    , 'jquery'
    , 'marionette'
    , 'hbs!templates/lookup-agent'
    , 'css!styles/lookup-agent'
    , 'bootstrap'
    , 'lib/is-sl-viewer'
    , 'models/agents-cache'

] , function(

    _
    , $
    , Marionette
    , template
    , styles
    , bootstrap
    , isSlViewer
    , agentsCache

) {
    'use strict';

    var exports = Marionette.ItemView.extend( {
        template: template

        , ui: {
            'lookupAgentDialog': '#lookup-agent'
            , 'lookupAgentKey': '#lookup-agent-key'
            , 'lookupAgentButton': '#lookup-agent-btn'
            , 'lookupAgentKeyInputGroup': '#lookup-agent-key-input-group'
            , 'knownAgentLink': 'a'
        }

        , events: {
            'hidden.bs.modal @ui.lookupAgentDialog': 'onModalHidden'
            , 'click @ui.knownAgentLink': 'selectAgent'
            , 'click @ui.lookupAgentButton': 'lookupAgent'
        }

        , onRender: function() {
            this.ui.lookupAgentDialog.toggleClass( 'fade' , !isSlViewer() ).modal( {
                backdrop: true
                , keyboard: true
                , show: true
            } );

            this.ui.lookupAgentButton.button();
        }

        , onModalHidden: function() {
            this.options.selected( this.agentSelected );
            this.close();
        }

        , selectAgent: function( jEvent ) {
            var target = $( jEvent.currentTarget );
            var selected = target.data( 'agent-id' );
            var agent = agentsCache.get( selected );
            this.agentSelected = agent;
            this.ui.lookupAgentDialog.modal( 'hide' );
        }

        , lookupAgent: function() {
            agentsCache.fetch( {
                id: this.ui.lookupAgentKey.val()
                , context: this
                , success: function( agent ) {
                    this.agentSelected = agent;
                    this.ui.lookupAgentDialog.modal( 'hide' );
                }
                , error: function() {
                    this.ui.lookupAgentKeyInputGroup.addClass( 'has-error' );
                    this.ui.lookupAgentButton.button( 'reset' );
                    this.ui.lookupAgentKey.prop( 'disabled' , '' );
                }
            } );

            this.ui.lookupAgentButton.button( 'loading' );
            this.ui.lookupAgentKey.prop( 'disabled' , 'disabled' );
        }
    } );

    return exports;

} );
