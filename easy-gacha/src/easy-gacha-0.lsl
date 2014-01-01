// easy-gacha-0: Boot script: Check that all scripts are present and accounted-for

#include lib/CONSTANTS.lsl
#include tools/Message.lsl

#define INVENTORY_SETTLE_TIME 5.0

#start states

    default {

        state_entry() {
            llSetTimerEvent( INVENTORY_SETTLE_TIME );
        }

        changed( integer changeMask ) {
            if( ( CHANGED_INVENTORY | CHANGED_LINK ) & changeMask ) {
                llSetTimerEvent( 0.0 );
                llSetTimerEvent( INVENTORY_SETTLE_TIME );
            }
        }

        timer() {
            llSetTimerEvent( 0.0 );

            #include lib/message-configs.lsl
            Message( MESSAGE_VIA_HOVER | MESSAGE_VIA_OWNER , "Initializing, please wait..." );

            // Check for all scripts
            list scripts = [
                SCRIPT_BOOT
            ];
            integer x;
            string script;
            for( x = 0 ; x < llGetListLength( scripts ) ; x += 1 ) {
                script = llList2String( scripts , x );
                if( INVENTORY_SCRIPT != llGetInventoryType( script ) ) {
                    Message( MESSAGE_ERROR , "Missing script: " + script );
                    return;
                }
                if( llGetInventoryCreator( llGetScriptName() ) != llGetInventoryCreator( script ) ) {
                    Message( MESSAGE_ERROR , "WARNING: This script was created by someone else and may be part of a different set: " + script );
                }
            }

            // If there's no config, skip straight to validating inventory
            if( INVENTORY_NOTECARD != llGetInventoryType( CONFIG_NOTECARD ) ) {
                llSetScriptState( SCRIPT_VALIDATE_INVENTORY , TRUE );
            } else {
                llSetScriptState( SCRIPT_VALIDATE_CONFIG , TRUE );
            }

            // Set timer event for next time we wake and disable self - no lag, woot!
            llSetTimerEvent( INVENTORY_SETTLE_TIME );
            llSetScriptState( llGetScriptName() , FALSE );
        }

    }

#end states
