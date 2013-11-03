// TODO: eg_folder_for_one
// TODO: eg_price
// TODO: eg_rarity
// TODO: eg_buy_max_items

#include lib/CONSTANTS.lsl
#include lib/CheckBaseAssumptions.lsl
#include lib/ConvertBooleanSetting.lsl
#include lib/FindConfig_1Part_ByVerb_Value.lsl
#include lib/Message.lsl

#start states

    default {
        state_entry() {
            CheckBaseAssumptions();

            // Check up front for opposite of default values
            if( TRUE == ConvertBooleanSetting( FindConfig_1Part_ByVerb_Value( 0 , "eg_verbose" ) ) ) {
                MessageVerbose = TRUE;
            }
            if( FALSE == ConvertBooleanSetting( FindConfig_1Part_ByVerb_Value( 0 , "eg_hover_text" ) ) ) {
                MessageHoverText = TRUE;
            }

            // Give an extra prompt so it's obvious what's being waited on
            Message( MESSAGE_TEXT_AND_OWNER , "Please grant debit permission (touch to reset)..." );

            // Ask for permission
            llRequestPermissions( Owner , PERMISSION_DEBIT );
        }

        attach( key avatarId ){ CheckBaseAssumptions(); }
        on_rez( integer rezParam ) { CheckBaseAssumptions(); }

        run_time_permissions( integer permissionMask ) {
            CheckBaseAssumptions(); // This will reset the script if permission hasn't been given
            state config_check;
        }

        touch_end( integer detected ) {
            while( 0 <= ( detected -= 1 ) ) {
                if( Owner == llDetectedKey( detected ) ) {
                    CheckBaseAssumptions();
                }
            }
        }
    }

    state reset_config_check {
        state_entry() {
            state config_check;
        }
    }

    state config_check {
        state_entry() {
            CheckBaseAssumptions();

            if( INVENTORY_SCRIPT != llGetInventoryType( "SCRIPT_VALIDATOR" ) ) {
                Message( MESSAGE_ERROR , "Missing or not a script: SCRIPT_VALIDATOR" );
                return;
            }

            if( llGetInventoryCreator( "SCRIPT_VALIDATOR" ) != llGetInventoryCreator( ScriptName ) ) {
                Message( MESSAGE_ERROR , "Invalid script: SCRIPT_VALIDATOR" );
                return;
            }

            // Start up config checker and tell it to begin its work
            llSetScriptState( "SCRIPT_VALIDATOR" , TRUE ); // Occurs immediately, although script may not be processing yet
            llMessageLinked( LINK_THIS , 3000166 , "" , NULL_KEY ); // Queues event for script, even if it's not processing yet
            llSleep( 0.05 ); // FORCED_DELAY 0.05 seconds: Strictly limit rate to prevent queue overflow
        }

        run_time_permissions( integer permissionMask ) { CheckBaseAssumptions(); }
        attach( key avatarId ){ CheckBaseAssumptions(); }
        on_rez( integer rezParam ) { CheckBaseAssumptions(); }
        changed( integer changeMask ) {
            CheckBaseAssumptions();

            if( ( CHANGED_INVENTORY | CHANGED_LINK ) & changeMask ) {
                // TODO: Reset all child scripts to prevent weirdness during config

                // Tell them why we're not doing anything right now
                Message( MESSAGE_TEXT_AND_OWNER , "Inventory changes detected, please wait..." );

                // Reset timer so we can absorb multiple inventory change
                // events at once, in case inventory is still changing
                // (debounce event)
                llSetTimerEvent( 0.0 ); // Take timer event off the queue
                llSetTimerEvent( 1.0 ); // Add it to the end of the queue
            }
        }

        touch_end( integer detected ) {
            while( 0 <= ( detected -= 1 ) ) {
                if( Owner == llDetectedKey( detected ) ) {
                    // Tell them why we're not doing anything right now
                    Message( MESSAGE_TEXT_AND_OWNER , "Resetting per your request, please wait..." );

                    llSetTimerEvent( 0.0 ); // Take timer event off the queue
                    llSetTimerEvent( 1.0 ); // Add it to the end of the queue
                }
            }
        }

        timer() {
            llSetTimerEvent( 0.0 );
            state reset_config_check;
        }

        link_message( integer fromPrim , integer messageInt , string messageStr , key messageKey ) {
            // If the config checker came back and said everything is ready
            if( 3000167 == messageInt ) {
                llOwnerSay( "TODO: Continue" );
            }
        }
    }

#end states
