////////////////////////////////////////////////////////////////////////////////
//
// LICENSE
//
// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or distribute
// this software, either in source code form or as a compiled binary, for any
// purpose, commercial or non-commercial, and by any means.
//
// In jurisdictions that recognize copyright laws, the author or authors of
// this software dedicate any and all copyright interest in the software to the
// public domain. We make this dedication for the benefit of the public at
// large and to the detriment of our heirs and successors. We intend this
// dedication to be an overt act of relinquishment in perpetuity of all present
// and future rights to this software under copyright law.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
// AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// For more information, please refer to <http://unlicense.org/>
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//
// NOTES
//
// Script description should contain a direct link to the specific commit that
// created the script. This information will be output each time it is
// initialized.
//
// InitState
// 0: default::state_entry()
// 1: Lookup inventory notecard line
// 2: Lookup payee notecard line
// 3: Lookup user name
// 4: Getting permission
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//
// GLOBAL VARIABLES
//
////////////////////////////////////////////////////////////////////////////////

string InventoryNotecard = "Easy Gacha Inventory";
string PayeeNotecard = "Easy Gacha Payees";
integer InitState = 0;

list Inventory = []; // Strided list of [ Inventory Name , Non Zero Positive Probability Number ]
integer CountInventory = 0;
float SumProbability = 0.0;

list Payees = []; // Strided list of [ Agent Key , Number of Lindens ]
integer CountPayees = 0;
integer Price = 0;

key DataServerRequest;
integer DataServerRequestIndex = 0;

integer MaxPerPurchase = 100;
integer LowMemoryThreshold = 16000;

////////////////////////////////////////////////////////////////////////////////
//
// GLOBAL METHODS
//
////////////////////////////////////////////////////////////////////////////////

ShowError( string msg ) {
    llSetText( llGetScriptName() + ": ERROR: " + msg + "\n|\n|\n|\n|\n|" , <1,0,0>, 1 );
    llOwnerSay( llGetScriptName() + ": ERROR: " + msg );
}

integer MemoryError() {
    if( llGetFreeMemory() < LowMemoryThreshold ) {
        ShowError( "Not enough free memory to handle large orders. Too many items in configuration?" );
        return TRUE;
    }

    return FALSE;
}

////////////////////////////////////////////////////////////////////////////////
//
// STATES
//
////////////////////////////////////////////////////////////////////////////////

default {
    ////////////
    // Resets //
    ////////////

    // If the object is attached or detached, reset
    attach( key avatarId ){
        llResetScript();
    }

    // Each time the object is rezzed, reset
    on_rez( integer rezParam ) {
        llResetScript();
    }

    // If the owner touches the object before it's initialized, restart
    // initialization
    touch_end( integer detected ) {
        while( 0 <= ( detected -= 1 ) ) {
            if( llGetOwner() == llDetectedKey( detected ) ) {
                llResetScript();
            }
        }
    }

    // If the owner changes, copy permissions may no longer apply for
    // inventory. If the inventory changes, we have to recertify everything
    // anyway.
    changed( integer changeMask ) {
        if( changeMask & ( CHANGED_INVENTORY | CHANGED_OWNER ) ) {
            llResetScript();
        }
    }

    ///////////////////
    // state default //
    ///////////////////

    state_entry() {
        llSetText( llGetScriptName() + ": Initializing, please wait..." + "\n|\n|\n|\n|\n|" , <1,0,0>, 1 );
        llOwnerSay( llGetScriptName() + ": Initializing, please wait..." );

        if( INVENTORY_NOTECARD != llGetInventoryType( InventoryNotecard ) ) {
            ShowError( "\"" + InventoryNotecard + "\" is missing from inventory" );
            return;
        }

        if( INVENTORY_NOTECARD != llGetInventoryType( PayeeNotecard ) ) {
            ShowError( "\"" + PayeeNotecard + "\" is missing from inventory" );
            return;
        }

        if( NULL_KEY == llGetInventoryKey( InventoryNotecard ) ) {
            ShowError( "\"" + InventoryNotecard + "\" is new and has not yet been saved" );
            return;
        }

        if( NULL_KEY == llGetInventoryKey( PayeeNotecard ) ) {
            ShowError( "\"" + PayeeNotecard + "\" is new and has not yet been saved" );
            return;
        }

        InitState = 1;
        DataServerRequest = llGetNotecardLine( InventoryNotecard , DataServerRequestIndex = 0 );
        llSetTimerEvent( 30.0 );
    } // end state_entry()

    dataserver( key queryId , string data ) {
        // Ignore other results that might show up
        if( queryId != DataServerRequest ) {
            return;
        }

        // Temporary storage
        integer i0;
        integer i1;
        float f0;
        string s0;

        // Stop/reset timeout timer
        llSetTimerEvent( 0.0 );

        // Memory check before proceeding, having just gotten a new string
        if( MemoryError() ) return;

        // If the result is the lookup of a line from the InventoryNotecard
        if( 1 == InitState ) {
            // If the line is blank, skip it
            if( "" == data ) {
                DataServerRequest = llGetNotecardLine( InventoryNotecard , DataServerRequestIndex += 1 );
                llSetTimerEvent( 30.0 );
                return;
            }

            // If the line starts with a hash, skip it
            if( "#" == llGetSubString( data , 0 , 0 ) ) {
                DataServerRequest = llGetNotecardLine( InventoryNotecard , DataServerRequestIndex += 1 );
                llSetTimerEvent( 30.0 );
                return;
            }

            // If we're past the last line
            if( EOF == data ) {
                // Report percentages now that we know the totals
                for( i0 = 0 ; i0 < CountInventory ; i0 += 2 ) {
                    llOwnerSay( llGetScriptName() + ": \"" + llList2String( Inventory , i0 ) + "\" has a probability of " + (string)( llList2Float( Inventory , i0 + 1 ) / SumProbability * 100 ) + "%" );
                }

                // Load first line of config
                InitState = 2;
                DataServerRequest = llGetNotecardLine( PayeeNotecard , DataServerRequestIndex = 0 );
                llSetTimerEvent( 30.0 );
                return;
            }

            // Process new line
            i0 = llSubStringIndex( data , " " );

            // If there's no space on the line, it's invalid
            if( 0 >= i0 ) {
                ShowError( "Bad configuration in \"" + InventoryNotecard + "\" on line " + (string)(DataServerRequestIndex + 1) + ": " + data );
                return;
            }

            // Pull the probability number off the front of the string
            f0 = (float)llGetSubString( data , 0 , i0 );

            // If the probability is out of bounds
            if( 0.0 >= f0 ) {
                ShowError( "Number must be greater than zero. Bad configuration in \"" + InventoryNotecard + "\" on line " + (string)(DataServerRequestIndex + 1) + ": " + data );
                return;
            }

            // Grab inventory name off string
            s0 = llGetSubString( data , i0 + 1 , -1 );

            // Name must be provided
            if( "" == s0 ) {
                ShowError( "Inventory name must be provided. Bad configuration in \"" + InventoryNotecard + "\" on line " + (string)(DataServerRequestIndex + 1) + ": " + data );
                return;
            }

            // Inventory must exist
            if( INVENTORY_NONE == llGetInventoryType( s0 ) ) {
                ShowError( "Cannot find \"" + s0 + "\" in inventory. Bad configuration in \"" + InventoryNotecard + "\" on line " + (string)(DataServerRequestIndex + 1) + "." );
                return;
            }

            // Inventory must be copyable
            if( ! ( PERM_COPY & llGetInventoryPermMask( s0 , MASK_OWNER ) ) ) {
                ShowError( "\"" + s0 + "\" is not copyable. If given, it would disappear from inventory, so it cannot be used. Bad configuration in \"" + InventoryNotecard + "\" on line " + (string)(DataServerRequestIndex + 1) + "." );
                return;
            }

            // Inventory must be transferable
            if( ! ( PERM_TRANSFER & llGetInventoryPermMask( s0 , MASK_OWNER ) ) ) {
                ShowError( "\"" + s0 + "\" is not transferable. So how can I give it out? Bad configuration in \"" + InventoryNotecard + "\" on line " + (string)(DataServerRequestIndex + 1) + "." );
                return;
            }

            // Store the configuration and add probably to the sum
            SumProbability += f0;
            Inventory = ( Inventory = [] ) + Inventory + [ s0 , f0 ];
            CountInventory += 2;

            // Memory check before proceeding, having just messed with a list
            if( MemoryError() ) return;

            // Load next line of config
            DataServerRequest = llGetNotecardLine( InventoryNotecard , DataServerRequestIndex += 1 );
            llSetTimerEvent( 30.0 );
            return;
        }

        // If the result is the lookup of a line from the PayeeNotecard
        if( 2 == InitState ) {
            // If the line is blank, skip it
            if( "" == data ) {
                DataServerRequest = llGetNotecardLine( PayeeNotecard , DataServerRequestIndex += 1 );
                llSetTimerEvent( 30.0 );
                return;
            }

            // If the line starts with a hash, skip it
            if( "#" == llGetSubString( data , 0 , 0 ) ) {
                DataServerRequest = llGetNotecardLine( PayeeNotecard , DataServerRequestIndex += 1 );
                llSetTimerEvent( 30.0 );
                return;
            }

            // If we're past the last line
            if( EOF == data ) {
                InitState = 3;
                DataServerRequest = llRequestUsername( llList2Key( Payees , DataServerRequestIndex = 0 ) );
                llSetTimerEvent( 30.0 );
                return;
            }

            // Process new line
            i0 = llSubStringIndex( data , " " );

            // If there's no space on the line, it's invalid
            if( 0 >= i0 ) {
                ShowError( "Bad configuration in \"" + PayeeNotecard + "\" on line " + (string)(DataServerRequestIndex + 1) + ": " + data );
                return;
            }

            // Pull the payment number off the front of the string
            i1 = (integer)llGetSubString( data , 0 , i0 );

            // If the payment is out of bounds
            if( 0 >= i1 ) {
                ShowError( "L$ to give must be greater than zero. Bad configuration in \"" + PayeeNotecard + "\" on line " + (string)(DataServerRequestIndex + 1) + ": " + data );
                return;
            }

            // Grab agent key off the string
            s0 = llGetSubString( data , i0 + 1 , -1 );

            // Name must be provided
            if( "" == s0 ) {
                ShowError( "User key must be provided. Bad configuration in \"" + PayeeNotecard + "\" on line " + (string)(DataServerRequestIndex + 1) + ": " + data );
                return;
            }

            // Convert special values
            if( "owner" == s0 ) {
                s0 = (string)llGetOwner();
            }
            if( "creator" == s0 ) {
                s0 = (string)llGetCreator();
            }
            if( "scriptor" == s0 ) {
                s0 = (string)llGetInventoryCreator( llGetScriptName() );
            }

            // Store the configuration
            Price += i1;
            Payees = ( Payees = [] ) + Payees + [ (key)s0 , i1 ];
            CountPayees += 2;

            // Memory check before proceeding, having just messed with a list
            if( MemoryError() ) return;

            // Load next line of config
            DataServerRequest = llGetNotecardLine( PayeeNotecard , DataServerRequestIndex += 1 );
            llSetTimerEvent( 30.0 );
            return;
        }

        // If the result is the lookup of a user from the Payees
        if( 3 == InitState ) {
            // Note that this user was looked up correctly and report the amount to be given
            llOwnerSay( llGetScriptName() + ": Will give L$" + (string)llList2Integer( Payees , DataServerRequestIndex + 1 ) + " to " + data + " for each item purchased." );

            // Increment to next value
            DataServerRequestIndex += 2;

            // If there are more to look up
            if( DataServerRequestIndex < CountPayees ) {
                // Look up the next one
                DataServerRequest = llRequestUsername( llList2Key( Payees , DataServerRequestIndex ) );
                llSetTimerEvent( 30.0 );
                return;
            }

            // Report total price
            llOwnerSay( llGetScriptName() + ": The total price is L$" + (string)Price );

            // Get permission to give money (so we can give refunds at least)
            llRequestPermissions( llGetOwner() , PERMISSION_DEBIT );
            llSetTimerEvent( 30.0 );
            InitState = 4;
        }
    }

    timer() {
        // Reset/stop timer
        llSetTimerEvent( 0.0 );

        if( 1 == InitState ) {
            ShowError( "Timed out while trying to fetch line " + (string)(DataServerRequestIndex + 1) + " from \"" + InventoryNotecard );
        } else if( 2 == InitState ) {
            ShowError( "Timed out while trying to fetch line " + (string)(DataServerRequestIndex + 1) + " from \"" + PayeeNotecard );
        } else if( 3 == InitState ) {
            ShowError( "Timed out while trying to look up user key. The user \"" + llList2String( Payees , DataServerRequestIndex ) + "\" doesn't seem to exist, or the data server is being too slow." );
        } else if( 4 == InitState ) {
            ShowError( "Timed out while trying to get permission. Please touch to reset and make sure to grant the money permission when asked." );
        } else {
            ShowError( "Timed out." );
        }
    }

    run_time_permissions( integer permissionMask ) {
        if( ! ( PERMISSION_DEBIT & permissionMask ) ) {
            llResetScript();
        } else {
            llOwnerSay( llGetScriptName() + ": This is free and unencumbered software released into the public domain. The source code can be found at: https://github.com/zannalov/opensl" );
            llOwnerSay( llGetScriptName() + ": Ready! Free memory: " + (string)llGetFreeMemory() );
            state ready;
        }
    }
}

state ready {
    ////////////
    // Resets //
    ////////////

    // If the object is attached or detached, reset
    attach( key avatarId ){
        llResetScript();
    }

    // Each time the object is rezzed, reset
    on_rez( integer rezParam ) {
        llResetScript();
    }

    // If the owner changes, copy permissions may no longer apply for
    // inventory. If the inventory changes, we have to recertify everything
    // anyway.
    changed( integer changeMask ) {
        if( changeMask & ( CHANGED_INVENTORY | CHANGED_OWNER ) ) {
            llResetScript();
        }
    }

    // If the money permission gets revoked, start over
    run_time_permissions( integer permissionMask ) {
        if( ! ( PERMISSION_DEBIT & permissionMask ) ) {
            llResetScript();
        }
    }

    /////////////////
    // state ready //
    /////////////////

    state_entry() {
        llSetText( "" , ZERO_VECTOR , 0.0 );
        llSetPayPrice( Price , [ Price , Price * 2 , Price * 5 , Price * 10 ] );
        llSetClickAction( CLICK_ACTION_PAY );
    }

    // Switching states here would prevent further orders from being placed
    // while this one is being processed, but would also flush the event queue,
    // which would kill any orders placed in parallel. We have to honor the
    // event queue, so... do things as fast and efficiently as we can
    money( key buyerId , integer lindensReceived ) {
        float random;
        integer selected;
        integer countSent = 0;
        list itemsToSend = [];

        // Let them know we're thinking
        llSetText( llGetScriptName() + ": Please wait, getting random items for " + llGetDisplayName( buyerId ) + "...\n|\n|\n|\n|\n|" , <1,0,0>, 1 );

        // If not enough money
        if( lindensReceived < Price ) {
            // Give money back
            llGiveMoney( buyerId , lindensReceived );
            llWhisper( 0 , "Sorry, the price is L$" + (string)Price );
            return;
        }

        // While there's still enough money for another item
        while( lindensReceived >= Price && countSent < MaxPerPurchase ) {
            random = llFrand( SumProbability ); // Generate a random number which is between [ 0.0 , SumProbability )
            selected = -2; // Start below the first object because the first iteration will definitely run once

            // While the random number is at or above zero, we haven't hit our
            // target object. Exiting the while loop will result in a random number
            // at or below zero, indicating the selected index matches an object.
            while( 0 <= random ) {
                selected += 2;
                random -= llList2Float( Inventory , selected + 1 );
            }

            // Schedule to give inventory, increment counter, decrement money
            itemsToSend = ( itemsToSend = [] ) + itemsToSend + [ llList2String( Inventory , selected ) ];
            countSent += 1;
            lindensReceived -= Price;
        }

        // Distribute the money
        integer x;
        for( x = 0 ; x < CountPayees ; x += 2 ) {
            if( llGetOwner() != llList2Key( Payees , x ) ) {
                llGiveMoney( llList2Key( Payees , x ) , llList2Integer( Payees , x + 1 ) * countSent );
            }
        }

        // If too much money was given
        if( lindensReceived ) {
            // Give back the excess
            llGiveMoney( buyerId , lindensReceived );

            // Thank them for the purchase
            llWhisper( 0 , "Thank you " + llGetDisplayName( buyerId ) + " for your purchase! Your " + (string)countSent + " items have been sent. Your change is L$" + (string)lindensReceived );
        } else {
            llWhisper( 0 , "Thank you " + llGetDisplayName( buyerId ) + " for your purchase! Your " + (string)countSent + " items have been sent." );
        }

        // Give the inventory
        llGiveInventoryList( buyerId , "Easy Gacha Rewards (" + (string)countSent + " items on " + llGetTimestamp() + ")" , itemsToSend ); // FORCED_DELAY 3.0 seconds
        llSetText( "" , ZERO_VECTOR , 0.0 );
    }
}
