// Generic includes
#include lib/ConvertBooleanSetting.lsl
#include lib/FindConfig_1Part_ByVerb_Value.lsl
#include lib/Message.lsl

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
            llSetScriptState( llGetScriptName() , FALSE );
        }

        link_message( integer fromPrim , integer messageInt , string messageStr , key messageKey ) {
            // If the config checker came back and said everything is ready
            if( 3000168 == messageInt ) {
                InventoryCount = llGetInventoryNumber( INVENTORY_ALL );
                TextureCount = llGetInventoryNumber( INVENTORY_TEXTURE );

            }
        }
    }

#end states
