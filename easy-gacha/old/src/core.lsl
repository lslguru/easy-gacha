// TODO: eg_folder_for_one
// TODO: eg_price
// TODO: eg_rarity
// TODO: eg_buy_max_items

// Generic includes
#include lib/CONSTANTS.lsl
#include lib/MessageConfig.lsl

// Include after Message to override SCRIPT_NAME and OWNER
#include lib/CheckBaseAssumptions.lsl

// Local defines
#define INVENTORY_COUNT InventoryCount
#define TEXTURE_COUNT TextureCount

#start globalvariables

    integer InventoryCount; // cache this and only update it in setup
    integer TextureCount; // cache this and only update it in setup

#end globalvariables

#start states

    default {
        state_entry() {
            CheckBaseAssumptions();
            MessageConfig();

            // Give an extra prompt so it's obvious what's being waited on
            Message( MESSAGE_TEXT_AND_OWNER , "Please grant debit permission (touch to reset)..." );
            Message( MESSAGE_DEBUG , "Free Memory: " + (string)llGetFreeMemory() );

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

            InventoryCount = llGetInventoryNumber( INVENTORY_ALL );
            TextureCount = llGetInventoryNumber( INVENTORY_TEXTURE );

            MessageConfig();
            Message( MESSAGE_DEBUG , "config_check::state_entry() Free Memory: " + (string)llGetFreeMemory() );

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
            llResetOtherScript( "SCRIPT_VALIDATOR" );
            llSleep( 0.1 ); // FORCED_DELAY 0.1 seconds: Stall until end of time slice to make sure script has started
            llMessageLinked( LINK_THIS , SIGNAL_CORE_TO_VALIDATOR_START , "" , NULL_KEY ); // Queues event for script
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
                Message( MESSAGE_SET_TEXT , "Inventory changes detected, please wait..." );

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
                    Message( MESSAGE_SET_TEXT , "Resetting per your request, please wait..." );

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
            if( SIGNAL_VALIDATOR_TO_CORE_FINISHED == messageInt ) {
                llOwnerSay( "TODO: Continue" );
                Message( MESSAGE_DEBUG , "Free Memory: " + (string)llGetFreeMemory() );
            }
        }
    }

#end states
