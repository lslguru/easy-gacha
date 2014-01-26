define( [

    'underscore'
    , 'jquery'
    , 'marionette'
    , 'hbs!templates/lookup-agent'
    , 'css!styles/lookup-agent'
    , 'bootstrap'
    , 'lib/is-sl-viewer'
    , 'models/agents-cache'
    , 'lib/key'
    , 'lib/tooltip-placement'

] , function(

    _
    , $
    , Marionette
    , template
    , styles
    , bootstrap
    , isSlViewer
    , agentsCache
    , keylib
    , tooltipPlacement

) {
    'use strict';

    var exports = Marionette.ItemView.extend( {
        template: template

        , ui: {
            'tooltips': '[data-toggle=tooltip]'
            , 'tooltipContainer': '.modal-content'
            , 'lookupAgentDialog': '#lookup-agent'
            , 'lookupAgentKey': '#lookup-agent-key'
            , 'lookupAgentButton': '#lookup-agent-button'
            , 'lookupAgentKeyInputGroup': '#lookup-agent-key-input-group'
            , 'knownAgentLink': 'a'
        }

        , events: {
            'hidden.bs.modal @ui.lookupAgentDialog': 'onModalHidden'
            , 'click @ui.knownAgentLink': 'selectAgent'
            , 'click @ui.lookupAgentButton': 'lookupAgent'
        }

        , triedNonKeyLookup: false
        , triedKeyLookup: false

        , onRender: function() {
            this.ui.tooltips.tooltip( {
                html: true
                , container: this.ui.tooltipContainer
                , placement: tooltipPlacement
            } );

            this.ui.lookupAgentDialog.toggleClass( 'fade' , !isSlViewer() ).modal( {
                backdrop: true
                , keyboard: true
                , show: true
            } );

            this.ui.lookupAgentButton.button();
        }

        , onClose: function() {
            this.ui.tooltips.tooltip( 'destroy' );
        }

        , onModalHidden: function() {
            if( this.agentSelected ) {
                this.options.selected( this.agentSelected );
            }

            this.close();
        }

        , selectAgent: function( jEvent ) {
            var target = $( jEvent.currentTarget );
            var selected = target.data( 'agent-id' );
            var agent = agentsCache.get( selected );
            this.agentSelected = agent;
            this.ui.lookupAgentDialog.modal( 'hide' );
        }

        , lookupNonKey: function( str ) {
            // Secondary lookup attempt... we'll try http://w-hat.com/#name2key
            $.ajax( {
                url: 'http://w-hat.com/name2key/' + encodeURIComponent( this.ui.lookupAgentKey.val() )
                , dataType: 'text'
                , context: this
                , success: function( data ) {
                    if( ! this.isClosed ) {
                        this.ui.lookupAgentKey.val( data );
                        this.lookupAgent();
                    }
                }
                , error: function() {
                    this.lookupAgent();
                }
            } );
        }

        , lookupKey: function() {
            agentsCache.fetch( {
                id: this.ui.lookupAgentKey.val()
                , context: this
                , success: function( agent ) {
                    if( ! this.isClosed ) {
                        this.agentSelected = agent;
                        this.ui.lookupAgentDialog.modal( 'hide' );
                    }
                }
                , error: function() {
                    this.lookupAgent();
                }
            } );
        }

        , lookupAgent: function() {
            if( '' === this.ui.lookupAgentKey.val() ) {
                return;
            }

            this.ui.lookupAgentButton.button( 'loading' );
            this.ui.lookupAgentKey.prop( 'disabled' , 'disabled' );

            if(
                ( !this.triedKeyLookup && keylib.isKey( this.ui.lookupAgentKey.val() ) )
                || ( this.triedNonKeyLookup && !this.triedKeyLookup )
            ) {
                this.lookupKey();
                this.triedKeyLookup = true;
                return;
            }

            if( !this.triedNonKeyLookup ) {
                this.lookupNonKey();
                this.triedNonKeyLookup = true;
                return;
            }

            this.triedKeyLookup = false;
            this.triedNonKeyLookup = false;

            if( ! this.isClosed ) {
                this.ui.lookupAgentKeyInputGroup.addClass( 'has-error' );
                this.ui.lookupAgentButton.button( 'reset' );
                this.ui.lookupAgentKey.prop( 'disabled' , '' );
            }
        }
    } );

    return exports;

} );
