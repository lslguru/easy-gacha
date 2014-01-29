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
    , 'lib/fade'

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
    , fade

) {
    'use strict';

    var exports = Marionette.ItemView.extend( {
        template: template

        , ui: {
            'tooltips': '[data-toggle=tooltip]'
            , 'allowHoverOff': '#allowHover-off'
            , 'allowHoverOn': '#allowHover-on'
            , 'email': '#email'
            , 'emailIsSlowWarning': '#email-is-slow-warning'
            , 'emailSlownessAck': '#email-is-slow-warning-dismiss'
            , 'imOff': '#im-off'
            , 'imOwner': '#im-owner'
            , 'imSelected': '#im-selected'
            , 'imOther': '#im-other'
            , 'clearEmail': '#clear-email'
        }

        , events: {
            'click @ui.allowHoverOff': 'setAllowHover'
            , 'click @ui.allowHoverOn': 'setAllowHover'
            , 'keyup @ui.email': 'updateEmail'
            , 'change @ui.email': 'updateEmail'
            , 'click @ui.clearEmail': 'clearEmail'
            , 'click @ui.imOff': 'selectIm'
            , 'click @ui.imOwner': 'selectIm'
            , 'click @ui.imSelected': 'selectIm'
            , 'click @ui.imOther': 'selectIm'
            , 'click @ui.emailSlownessAck': 'dismissEmailSlowness'
        }

        , modelEvents: {
            'change:allowHover': 'updateSelections'
            , 'change:email': 'updateSelections'
            , 'change:ackEmailSlowness': 'updateSelections'
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

        , onClose: function() {
            this.ui.tooltips.tooltip( 'destroy' );
        }

        , updateSelections: function() {
            this.ui.allowHoverOff.toggleClass( 'active' , !this.model.get( 'allowHover' ) );
            this.ui.allowHoverOn.toggleClass( 'active' , this.model.get( 'allowHover' ) );

            this.ui.imOff.removeClass( 'active' );
            this.ui.imOwner.removeClass( 'active' );

            this.ui.imSelected.removeClass( 'active' );
            fade( this.ui.imSelected , false );

            if( CONSTANTS.NULL_KEY === this.model.get( 'im' ) ) {
                this.ui.imOff.addClass( 'active' );
            } else if( this.model.get( 'ownerKey' ) === this.model.get( 'im' ) ) {
                this.ui.imOwner.addClass( 'active' );
            } else {
                this.ui.imSelected
                    .addClass( 'active' )
                    .text( this.model.get( 'imDisplayName' ) )
                ;

                fade( this.ui.imSelected , true );
            }

            this.ui.email.parent().removeClass( 'has-error' );
            this.ui.email.val( this.model.get( 'email' ) );
            this.model.set( 'hasDanger_comms_email' , false );

            var emailSlowWarning = (
                '' !== this.model.get( 'email' )
                && !this.model.get( 'ackEmailSlowness' )
            );

            fade( this.ui.emailIsSlowWarning , emailSlowWarning );
            this.model.set( 'hasWarning_comms_emailSlowness' , emailSlowWarning );
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
                this.model.set( 'hasDanger_comms_email' , true );
            } else {
                this.ui.email.parent().removeClass( 'has-error' );
                this.model.set( 'hasDanger_comms_email' , false );
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

        , dismissEmailSlowness: function() {
            this.model.set( 'ackEmailSlowness' , true );
        }
    } );

    return exports;

} );
