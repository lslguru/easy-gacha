// Generic includes
#include lib/CONSTANTS.lsl
#include lib/MessageConfig.lsl

#start globalvariables

    integer OnScriptNumber;

#end globalvariables

#start states

    default {
        state_entry() {
            MessageConfig();
            Message( MESSAGE_DEBUG , "default::state_entry() Free Memory: " + (string)llGetFreeMemory() );
            llSetScriptState( llGetScriptName() , FALSE );
        }

        link_message( integer fromPrim , integer messageInt , string messageStr , key messageKey ) {
            list scripts = [
                "SCRIPT_VALIDATE_CONFIG_FORMATS"
                , "SCRIPT_PURCHASE_BUTTONS"
                , "SCRIPT_STATS_ENGINE"
                , "SCRIPT_PAYOUTS"
                , "SCRIPT_INFO"
            ];

            string scriptName;

            // If we're being started by our parent script
            if( SIGNAL_CORE_TO_VALIDATOR_START == messageInt ) {
                MessageConfig();

                // Set iterator to before beginning of list
                OnScriptNumber = -1;

                // Override messageInt to cause next section to trigger
                messageInt = SIGNAL_SUB_SCRIPT_TO_VALIDATOR_FINISHED;
            }

            // If the sub-script we were processing has completed
            if( SIGNAL_SUB_SCRIPT_TO_VALIDATOR_FINISHED == messageInt ) {
                // Move to the next one
                OnScriptNumber += 1;

                // If we're past the last one, then we're done
                if( llGetListLength( scripts ) == OnScriptNumber ) {
                    // Tell the parent that we're done
                    llMessageLinked( LINK_THIS , SIGNAL_VALIDATOR_TO_CORE_FINISHED , "" , NULL_KEY );
                    llSleep( 0.05 ); // FORCED_DELAY 0.05 seconds: Strictly limit rate to prevent queue overflow

                    // Jump out early
                    jump sleep0;
                }

                // Cache this because we use it multiple times
                scriptName = llList2String( scripts , OnScriptNumber );

                // If the script isn't present
                if( INVENTORY_SCRIPT != llGetInventoryType( scriptName ) ) {
                    Message( MESSAGE_ERROR , "Missing or not a script: " + scriptName );

                    // Jump out early
                    jump sleep0;
                }

                // If the script wasn't created by the same person that created this one
                if( llGetInventoryCreator( scriptName ) != llGetInventoryCreator( llGetScriptName() ) ) {
                    Message( MESSAGE_ERROR , "Invalid script: " + scriptName );

                    // Jump out early
                    jump sleep0;
                }

                // Otherwise tell next script to go
                Message( MESSAGE_SET_TEXT , "Processing: " + scriptName );
                llSetScriptState( scriptName , TRUE ); // Occurs immediately, although script may not be processing yet
                llSleep( 0.1 ); // FORCED_DELAY 0.1 seconds: Stall until end of time slice to make sure script has started
                llMessageLinked( LINK_THIS , 3000168 , "" , NULL_KEY ); // Queues event for script
                llSleep( 0.05 ); // FORCED_DELAY 0.05 seconds: Strictly limit rate to prevent queue overflow

                // Debug message
                Message( MESSAGE_DEBUG , "default::link_message() Free Memory: " + (string)llGetFreeMemory() );

                // And jump out without going back to sleep
                return;
            }

            @sleep0;
            llSetScriptState( llGetScriptName() , FALSE );
        }
    }

#end states
