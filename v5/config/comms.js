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
            , 'allowHover': '#allowHover'
            , 'email': '#email'
            , 'emailContainer': '#email-container'
            , 'imOff': '#im-off'
            , 'imOwner': '#im-owner'
            , 'imSelected': '#im-selected'
            , 'imOther': '#im-other'
        }

        , events: {
            'change #allowHover': 'updateConfigs'
            , 'keyup #email': 'updateConfigs'
            , 'change #email': 'updateConfigs'
            , 'click #im-off': 'selectIm'
            , 'click #im-owner': 'selectIm'
            , 'click #im-selected': 'selectIm'
            , 'click #im-other': 'selectIm'
            , 'click #clear-email': 'clearEmail'
        }

        , modelEvents: {
            'change:im': 'updateImSelection'
        }

        , onRender: function() {
            this.ui.tooltips.tooltip( {
                html: true
                , container: 'body'
                , placement: tooltipPlacement
            } );

            this.ui.allowHover.prop( 'checked' , this.model.get( 'allowHover' ) );
            this.ui.email.val( this.model.get( 'email' ) || '' );

            this.ui.imOwner.text( this.options.gacha.get( 'info' ).get( 'ownerDisplayName' ) );
            this.updateImSelection();
        }

        , updateConfigs: function() {
            this.model.set( {
                allowHover: Boolean( this.ui.allowHover.prop( 'checked' ) )
                , email: this.ui.email.val()
            } );

            this.validate();
        }

        , clearEmail: function() {
            this.ui.email.val( '' );
            this.updateConfigs();
        }

        , updateImSelection: function() {
            this.ui.imOff.removeClass( 'active' );
            this.ui.imOwner.removeClass( 'active' );
            this.ui.imSelected.removeClass( 'active' ).hide();

            if( ! this.model.get( 'im' ) || CONSTANTS.NULL_KEY === this.model.get( 'im' ) ) {
                this.ui.imOff.addClass( 'active' );
            } else if( this.options.gacha.get( 'info' ).get( 'ownerKey' ) === this.model.get( 'im' ) ) {
                this.ui.imOwner.addClass( 'active' );
            } else {
                this.ui.imSelected.addClass( 'active' ).show().text( this.model.get( 'imDisplayName' ) );
            }
        }

        , selectIm: function( jEvent ) {
            var target = $( jEvent.currentTarget );

            if( this.ui.imOff.is( target ) ) {
                this.model.set( {
                    im: ''
                    , imUserName: null
                    , imDisplayName: null
                } );

                this.updateImSelection();
            }
            if( this.ui.imOwner.is( target ) ) {
                this.model.set( {
                    im: this.options.gacha.get( 'info' ).get( 'ownerKey' )
                    , imUserName: this.options.gacha.get( 'info' ).get( 'ownerUserName' )
                    , imDisplayName: this.options.gacha.get( 'info' ).get( 'ownerDisplayName' )
                } );

                this.updateImSelection();
            }
            if( this.ui.imOther.is( target ) ) {
                this.options.lookupAgentDialog( {
                    selected: _.bind( function( agent ) {
                        this.model.set( {
                            im: agent.get( 'id' )
                            , imUserName: agent.get( 'username' )
                            , imDisplayName: agent.get( 'displayname' )
                        } );

                        this.updateImSelection();
                    } , this )
                } );
            }
        }

        , validate: function() {
            if( '' !== this.ui.email.val() && ! validateEmailAddress( this.ui.email.val() ) ) {
                this.ui.emailContainer.addClass( 'has-error' );
            } else {
                this.ui.emailContainer.removeClass( 'has-error' );
            }
        }
    } );

    return exports;

} );
