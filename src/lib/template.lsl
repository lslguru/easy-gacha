// easy-gacha-#: SHORT_NAME: DESCRIPTION

#include lib/CONSTANTS.lsl
#include tools/Message.lsl

#start globalvariables
#end globalvariables

#start globalfunctions
#end globalfunctions

#start states

    default {

        state_entry() {
            llSetTimerEvent( 1.0 );
            llSetScriptState( llGetScriptName() , FALSE );
        }

        changed( integer changeMask ) {
            if( ( CHANGED_INVENTORY | CHANGED_LINK ) & changeMask ) {
                llSetScriptState( SCRIPT_BOOT , TRUE );
                llResetScript();
            }
        }

        timer() {
            #include lib/message-configs.lsl
            Message( MESSAGE_DEBUG , "llGetFreeMemory(): " + (string)llGetFreeMemory() );
            state TODO;
        }

    }

    state TODO {
        state_entry() {
            // Message( MESSAGE_VIA_HOVER , "Initializing, please wait...\nStep #: 0%" );
            // TODO
        }

        changed( integer changeMask ) {
            if( ( CHANGED_INVENTORY | CHANGED_LINK ) & changeMask ) {
                llSetScriptState( SCRIPT_BOOT , TRUE );
                llResetScript();
            }
        }
    }

#end states
