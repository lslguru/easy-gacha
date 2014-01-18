define( [

    'underscore'
    , 'jquery'
    , 'marionette'
    , 'hbs!config/templates/comms'
    , 'css!config/styles/comms'
    , 'bootstrap'
    , 'lib/constants'
    , 'lib/tooltip-placement'
    , 'lib/validate-email-address'

] , function(

    _
    , $
    , Marionette
    , template
    , headerStyles
    , bootstrap
    , CONSTANTS
    , tooltipPlacement
    , validateEmailAddress

) {
    'use strict';

    var exports = Marionette.ItemView.extend( {
        template: template

        , ui: {
            'tooltips': '[data-toggle=tooltip]'
            , 'allowHoverOff': '#allowHover-off'
            , 'allowHoverOn': '#allowHover-on'
            , 'email': '#email'
            , 'imOff': '#im-off'
            , 'imOwner': '#im-owner'
            , 'imSelected': '#im-selected'
            , 'imOther': '#im-other'
        }

        , events: {
            'click #allowHover-off': 'setAllowHover'
            , 'click #allowHover-on': 'setAllowHover'
            , 'keyup #email': 'updateEmail'
            , 'change #email': 'updateEmail'
            , 'click #clear-email': 'clearEmail'
            , 'click #im-off': 'selectIm'
            , 'click #im-owner': 'selectIm'
            , 'click #im-selected': 'selectIm'
            , 'click #im-other': 'selectIm'
        }

        , modelEvents: {
            'change:allowHover': 'updateSelections'
            , 'change:email': 'updateSelections'
            , 'change:im': 'updateSelections'
        }

        , onRender: function() {
            this.ui.tooltips.tooltip( {
                html: true
                , container: 'body'
                , placement: tooltipPlacement
            } );

            this.ui.imOwner.text( this.model.get( 'ownerDisplayName' ) );
            this.updateSelections();
        }

        , updateSelections: function() {
            this.ui.allowHoverOff.toggleClass( 'active' , !this.model.get( 'allowHover' ) );
            this.ui.allowHoverOn.toggleClass( 'active' , this.model.get( 'allowHover' ) );
            this.ui.email.parent().removeClass( 'has-error' );
            this.ui.email.val( this.model.get( 'email' ) );

            this.ui.imOff.removeClass( 'active' );
            this.ui.imOwner.removeClass( 'active' );
            this.ui.imSelected.removeClass( 'active' ).hide();

            if( CONSTANTS.NULL_KEY === this.model.get( 'im' ) ) {
                this.ui.imOff.addClass( 'active' );
            } else if( this.model.get( 'ownerKey' ) === this.model.get( 'im' ) ) {
                this.ui.imOwner.addClass( 'active' );
            } else {
                this.ui.imSelected.addClass( 'active' ).show().text( this.model.get( 'imDisplayName' ) );
            }
        }

        , clearEmail: function() {
            this.ui.email.val( '' );
            this.updateEmail();
        }

        , setAllowHover: function( jEvent ) {
            var target = $( jEvent.currentTarget );
            var newValue = Boolean( parseInt( target.data( 'value' ) , 10 ) );
            this.model.set( 'allowHover' , newValue );
        }

        , updateEmail: function() {
            if( '' !== this.ui.email.val() && ! validateEmailAddress( this.ui.email.val() ) ) {
                this.ui.email.parent().addClass( 'has-error' );
            } else {
                this.ui.email.parent().removeClass( 'has-error' );
                this.model.set( 'email' , this.ui.email.val() );
            }
        }

        , selectIm: function( jEvent ) {
            var target = $( jEvent.currentTarget );

            if( this.ui.imOff.is( target ) ) {
                this.model.set( {
                    im: CONSTANTS.NULL_KEY
                    , imUserName: null
                    , imDisplayName: null
                } );
            }
            if( this.ui.imOwner.is( target ) ) {
                this.model.set( {
                    im: this.model.get( 'ownerKey' )
                    , imUserName: this.model.get( 'ownerUserName' )
                    , imDisplayName: this.model.get( 'ownerDisplayName' )
                } );
            }
            if( this.ui.imOther.is( target ) ) {
                this.options.lookupAgentDialog( {
                    selected: _.bind( function( agent ) {
                        this.model.set( {
                            im: agent.get( 'id' )
                            , imUserName: agent.get( 'username' )
                            , imDisplayName: agent.get( 'displayname' )
                        } );
                    } , this )
                } );
            }
        }
    } );

    return exports;

} );
