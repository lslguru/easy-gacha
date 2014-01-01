// easy-gacha-#: SHORT_NAME: DESCRIPTION

#include lib/CONSTANTS.lsl
#include tools/Message.lsl

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
            state TODO;
        }

    }

    state TODO {
        state_entry() {
            // TODO
        }
    }

#end states
