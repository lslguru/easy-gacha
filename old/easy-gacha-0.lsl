// easy-gacha-0: Boot script: Check that all scripts are present and accounted-for

#include lib/CONSTANTS.lsl
#include tools/Message.lsl

#start globalfunctions

    LoadMessageConfigs() {
        #include lib/message-configs.lsl
    }

#end globalfunctions

#start states

    default {

        state_entry() {
            llSetTimerEvent( INVENTORY_SETTLE_TIME );

            LoadMessageConfigs();
            Message( MESSAGE_DEBUG , "llGetFreeMemory(): " + (string)llGetFreeMemory() );
        }

        changed( integer changeMask ) {
            if( CHANGED_INVENTORY & changeMask ) {
                LoadMessageConfigs();
                Message( MESSAGE_DEBUG , "Inventory changed, resetting timer" );

                llSetTimerEvent( 0.0 );
                llSetTimerEvent( INVENTORY_SETTLE_TIME );
            }
        }

        timer() {
            llSetTimerEvent( 0.0 );

            LoadMessageConfigs();
            Message( MESSAGE_VIA_HOVER , "Initializing, please wait..." );

            // Check for all scripts
            list scripts = [
                SCRIPT_BOOT,
                SCRIPT_VALIDATE_CONFIG,
                SCRIPT_VALIDATE_INVENTORY
            ];
            integer x;
            string script;
            for( x = 0 ; x < llGetListLength( scripts ) ; ++x ) {
                script = llList2String( scripts , x );
                Message( MESSAGE_DEBUG , "Checking script: " + script );

                if( INVENTORY_SCRIPT != llGetInventoryType( script ) ) {
                    Message( MESSAGE_ERROR , "Missing script: " + script );
                    return;
                }

                if( llGetInventoryCreator( llGetScriptName() ) != llGetInventoryCreator( script ) ) {
                    Message( MESSAGE_WARNING , "WARNING: This script was created by someone else and may be part of a different set: " + script );
                }
            }

            // If there's no config, skip straight to validating inventory
            if( INVENTORY_NONE == llGetInventoryType( CONFIG_NOTECARD ) ) {
                Message( MESSAGE_WARNING , CONFIG_NOTECARD + " not found, using auto-configuration" );
                llSetScriptState( SCRIPT_VALIDATE_INVENTORY , TRUE );
            } else if( INVENTORY_NOTECARD != llGetInventoryType( CONFIG_NOTECARD ) ) {
                Message( MESSAGE_WARNING , CONFIG_NOTECARD + " is not a notecard, using auto-configuration" );
                llSetScriptState( SCRIPT_VALIDATE_INVENTORY , TRUE );
            } else if( NULL_KEY == llGetInventoryKey( CONFIG_NOTECARD ) ) {
                Message( MESSAGE_WARNING , "Unable to read " + CONFIG_NOTECARD + ", using auto-configuration" );
                llSetScriptState( SCRIPT_VALIDATE_INVENTORY , TRUE );
            } else {
                llSetScriptState( SCRIPT_VALIDATE_CONFIG , TRUE );
            }

            Message( MESSAGE_DEBUG , "llGetFreeMemory(): " + (string)llGetFreeMemory() );

            // No lag, woot!
            llSetScriptState( llGetScriptName() , FALSE );
        }

    }

#end states
