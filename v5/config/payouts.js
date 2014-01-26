define( [

    'underscore'
    , 'jquery'
    , 'marionette'
    , 'hbs!config/templates/payouts'
    , 'css!config/styles/payouts'
    , 'bootstrap'
    , 'lib/constants'
    , 'lib/tooltip-placement'
    , 'config/payout'

] , function(

    _
    , $
    , Marionette
    , template
    , headerStyles
    , bootstrap
    , CONSTANTS
    , tooltipPlacement
    , ItemView

) {
    'use strict';

    var exports = Marionette.CompositeView.extend( {
        template: template
        , itemView: ItemView
        , itemViewContainer: 'tbody'

        , itemViewOptions: function() {
            var options = _.clone( this.options );
            delete options.model;
            return options;
        }

        , ui: {
            'tooltips': '[data-toggle=tooltip]'
            , 'countPayouts': '#count-payouts'
            , 'totalPayouts': '#total-payouts'
            , 'addNewPayoutButton': '#payouts-add-new'
        }

        , events: {
            'click @ui.addNewPayoutButton': 'addPayout'
        }

        , collectionEvents: {
            'add': 'updateTotals'
            , 'remove': 'updateTotals'
            , 'reset': 'updateTotals'
            , 'change:amount': 'updateTotals'
        }

        , onRender: function() {
            this.ui.tooltips.tooltip( {
                html: true
                , container: 'body'
                , placement: tooltipPlacement
            } );
        }

        , onClose: function() {
            this.ui.tooltips.tooltip( 'destroy' );
        }

        , updateTotals: function() {
            this.ui.countPayouts.text( this.collection.length );
            this.ui.totalPayouts.text( this.collection.reduce( function( memo , model ) {
                return memo + model.get( 'amount' );
            } , 0 ) );
        }

        , addPayout: function() {
            this.options.lookupAgentDialog( {
                selected: _.bind( function( agent ) {
                    this.collection.add( {
                        agentKey: agent.get( 'id' )
                        , userName: agent.get( 'username' )
                        , displayName: agent.get( 'displayname' )
                        , amount: 0
                    } );
                } , this )
            } );
        }

    } );

    return exports;

} );
