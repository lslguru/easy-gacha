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
// 1: Getting notecard line count
// 2: Lookup inventory notecard line
// 3: Lookup user name
// 4: Getting permission
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//
// Constants
//
////////////////////////////////////////////////////////////////////////////////

string SOURCE_CODE_LINK = "https://github.com/zannalov/opensl";
string CONFIG = "Easy Gacha Config";
integer LOW_MEMORY_THRESHOLD = 16000;
integer MAX_FOLDER_NAME_LENGTH = 63;

////////////////////////////////////////////////////////////////////////////////
//
// GLOBAL VARIABLES
//
////////////////////////////////////////////////////////////////////////////////

integer InitState = 0;
integer AllowRootPrim = FALSE;
integer CountConfigLines = 0;
integer LastTouch = 0;
string ScriptName;
key Owner;

list Inventory = []; // Strided list of [ Inventory Name , Non Zero Positive Probability Number ]
integer CountInventory = 0; // List length (not strided item length)
float SumProbability = 0.0; // Sum

list Payees = []; // Strided list of [ Agent Key , Number of Lindens ]
integer CountPayees = 0; // List length (not strided item length)
integer Price = 0; // Sum
integer MaxPerPurchase = 100; // Not to exceed 100
integer PayButton1 = 2; // Item count during config, price after config
integer PayButton2 = 5; // Item count during config, price after config
integer PayButton3 = 10; // Item count during config, price after config
integer PayAnyAmount = 1; // 0/1 during config ends, price after config

key DataServerRequest;
integer DataServerRequestIndex = 0;

////////////////////////////////////////////////////////////////////////////////
//
// GLOBAL METHODS
//
////////////////////////////////////////////////////////////////////////////////

SetText( string msg ) {
    llSetText( llGetObjectName() + ": " + ScriptName + "\n" + msg + "\n|\n|\n|\n|\n|" , <1,0,0>, 1 );
}

ShowError( string msg ) {
    SetText( "ERROR: " + msg );
    llOwnerSay( ScriptName + ": ERROR: " + msg );
}

BadConfig( string reason , string data ) {
    ShowError( reason + "Bad configuration on line " + (string)(DataServerRequestIndex + 1) + ": " + data );
}

NextConfigLine() {
    DataServerRequest = llGetNotecardLine( CONFIG , DataServerRequestIndex += 1 );
    SetText( "Checking config " + (string)( DataServerRequestIndex * 100 / CountConfigLines ) + "%, please wait..." );
    llSetTimerEvent( 30.0 );
}

integer MemoryError() {
    if( llGetFreeMemory() < LOW_MEMORY_THRESHOLD ) {
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
            if( Owner == llDetectedKey( detected ) ) {
                llResetScript();
            }
        }
    }

    // If the owner changes, copy permissions may no longer apply for
    // inventory. If the inventory changes, we have to recertify everything
    // anyway.
    changed( integer changeMask ) {
        if( changeMask & ( CHANGED_INVENTORY | CHANGED_OWNER | CHANGED_LINK ) ) {
            llResetScript();
        }
    }

    ///////////////////
    // state default //
    ///////////////////

    state_entry() {
        Owner = llGetOwner();
        ScriptName = llGetScriptName();
        SetText( "Initializing, please wait..." );
        llOwnerSay( ScriptName + "\nInitializing, please wait..." );

        // Config notecard not found at all
        if( INVENTORY_NOTECARD != llGetInventoryType( CONFIG ) ) {
            ShowError( "\"" + CONFIG + "\" is missing from inventory" );
            return;
        }

        // Full perm required to use llGetInventoryKey() successfully
        if( ! ( PERM_COPY & llGetInventoryPermMask( CONFIG , MASK_OWNER ) ) ) {
            ShowError( "\"" + CONFIG + "\" is not copyable" );
            return;
        }
        if( ! ( PERM_MODIFY & llGetInventoryPermMask( CONFIG , MASK_OWNER ) ) ) {
            ShowError( "\"" + CONFIG + "\" is not modifiable" );
            return;
        }
        if( ! ( PERM_TRANSFER & llGetInventoryPermMask( CONFIG , MASK_OWNER ) ) ) {
            ShowError( "\"" + CONFIG + "\" is not transferable" );
            return;
        }

        // No key returned despite permissions == no contents (which would blow
        // up llGetNotecardLine)
        if( NULL_KEY == llGetInventoryKey( CONFIG ) ) {
            ShowError( "\"" + CONFIG + "\" is new and has not yet been saved" );
            return;
        }

        InitState = 1;
        DataServerRequest = llGetNumberOfNotecardLines( CONFIG );
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
        key k0;

        // Stop/reset timeout timer
        llSetTimerEvent( 0.0 );

        // Memory check before proceeding, having just gotten a new string
        if( MemoryError() ) return;

        if( 1 == InitState ) {
            CountConfigLines = (integer)data;
            InitState = 2;
            DataServerRequestIndex = -1; // Next method increments to zero
            NextConfigLine(); return;
        }

        // If the result is the lookup of a line from the CONFIG
        if( 2 == InitState ) {
            // If the line is blank, skip it
            if( "" == data ) {
                NextConfigLine(); return;
            }

            // If the line starts with a hash, skip it
            if( "#" == llGetSubString( data , 0 , 0 ) ) {
                NextConfigLine(); return;
            }

            // If we're past the last line
            if( EOF == data ) {
                // Check that at least one was configured
                if( 0 == CountInventory ) {
                    ShowError( "Bad configuration: No items were listed!" );
                    return;
                }

                // Check that at least one was configured
                if( 0 == CountPayees ) {
                    ShowError( "Bad configuration: No payouts were listed!" );
                    return;
                }

                // Check that pay buttons aren't out of bounds
                if( PayButton1 && PayButton1 > MaxPerPurchase ) {
                    ShowError( "Bad configuration: buy_button 1 exceeds maximum of " + (string)MaxPerPurchase );
                    return;
                }
                if( PayButton2 && PayButton2 > MaxPerPurchase ) {
                    ShowError( "Bad configuration: buy_button 2 exceeds maximum of " + (string)MaxPerPurchase );
                    return;
                }
                if( PayButton3 && PayButton3 > MaxPerPurchase ) {
                    ShowError( "Bad configuration: buy_button 3 exceeds maximum of " + (string)MaxPerPurchase );
                    return;
                }

                // Check that duplicate buttons weren't provided
                if( PayButton1 && PayButton1 == PayButton2 ) {
                    ShowError( "Bad configuration: buy_button 1 and buy_button 2 are the same" );
                    return;
                }
                if( PayButton1 && PayButton1 == PayButton3 ) {
                    ShowError( "Bad configuration: buy_button 1 and buy_button 3 are the same" );
                    return;
                }
                if( PayButton2 && PayButton2 == PayButton3 ) {
                    ShowError( "Bad configuration: buy_button 2 and buy_button 3 are the same" );
                    return;
                }

                // If we shouldn't allow the root prim in a linked set
                if( !AllowRootPrim && LINK_ROOT == llGetLinkNumber() ) {
                    ShowError( "This script is in the root prim of a linked set. It will override the default click action for the ENTIRE OBJECT, setting it to click-to-pay. If this is really what you want, change the config to: allow_root_prim yes" );
                    return;
                }

                // Report percentages now that we know the totals
                for( i0 = 0 ; i0 < CountInventory ; i0 += 2 ) {
                    f0 = ( llList2Float( Inventory , i0 + 1 ) / SumProbability );
                    llOwnerSay( ScriptName + ": \"" + llList2String( Inventory , i0 ) + "\" has a probability of " + (string)( f0 * 100 ) + "%" );
                }

                // Set payment option
                if( 0 == PayAnyAmount ) { PayAnyAmount = PAY_HIDE; } else { PayAnyAmount  = Price; }
                if( 0 == PayButton1   ) { PayButton1   = PAY_HIDE; } else { PayButton1   *= Price; }
                if( 0 == PayButton2   ) { PayButton2   = PAY_HIDE; } else { PayButton2   *= Price; }
                if( 0 == PayButton3   ) { PayButton3   = PAY_HIDE; } else { PayButton3   *= Price; }

                // Memory check before proceeding, having just tested a bunch of things and potentially changed things
                if( MemoryError() ) return;

                // Load first line of config
                SetText( "Checking payouts 0%, please wait..." );
                InitState = 3;
                DataServerRequest = llRequestUsername( llList2Key( Payees , DataServerRequestIndex = 0 ) );
                llSetTimerEvent( 30.0 );
                return;
            }

            // Process new line
            i0 = llSubStringIndex( data , " " );

            // If there's no space on the line, it's invalid
            if( 0 >= i0 ) {
                BadConfig( "" , data ); return;
            }

            // Handle an item entry
            if( "item " == llToLower( llGetSubString( data , 0 , i0 ) ) ) {
                // Strip "item " off the front
                s0 = llGetSubString( data , 5 , -1 );

                // Find second space
                i0 = llSubStringIndex( s0 , " " );

                // If there's not another space on the line, it's invalid
                if( 0 >= i0 ) {
                    BadConfig( "" , data ); return;
                }

                // Pull the probability number off the front of the string
                f0 = (float)llGetSubString( s0 , 0 , i0 );

                // If the probability is out of bounds
                if( 0.0 >= f0 ) {
                    BadConfig( "Number must be greater than zero. " , data ); return;
                }

                // Grab inventory name off string
                s0 = llGetSubString( s0 , i0 + 1 , -1 );

                // Name must be provided
                if( "" == s0 ) {
                    BadConfig( "Inventory name must be provided. " , data ); return;
                }

                // Inventory must exist
                if( INVENTORY_NONE == llGetInventoryType( s0 ) ) {
                    BadConfig( "Cannot find \"" + s0 + "\" in inventory. " , data ); return;
                }

                // Inventory must be copyable
                if( ! ( PERM_COPY & llGetInventoryPermMask( s0 , MASK_OWNER ) ) ) {
                    BadConfig( "\"" + s0 + "\" is not copyable. If given, it would disappear from inventory, so it cannot be used. " , data ); return;
                }

                // Inventory must be transferable
                if( ! ( PERM_TRANSFER & llGetInventoryPermMask( s0 , MASK_OWNER ) ) ) {
                    BadConfig( "\"" + s0 + "\" is not transferable. So how can I give it out? " , data ); return;
                }

                // If they put the same item in twice
                if( -1 != llListFindList( Inventory , [ s0 ] ) ) {
                    BadConfig( "\"" + s0 + "\" was listed twice. Did you mean to list it once with a rarity of " + (string)( llList2Float( Inventory , llListFindList( Inventory , [ s0 ] ) + 1 ) + f0 ) + "? " , data ); return;
                }

                // Store the configuration and add probably to the sum
                SumProbability += f0;
                Inventory = ( Inventory = [] ) + Inventory + [ s0 , f0 ]; // Voodoo for better memory usage
                CountInventory += 2;

                // Memory check before proceeding, having just messed with a list
                if( MemoryError() ) return;

                // Load next line of config
                NextConfigLine(); return;
            } // end if( "item" ... )

            // Handle a payout entry
            // Valid money formats: L$#, $#, #, #L
            if( "payout " == llToLower( llGetSubString( data , 0 , i0 ) ) ) {
                // Strip "payout " off the front
                s0 = llGetSubString( data , 7 , -1 );

                // Strip "L" off the front
                if( "l" == llToLower( llGetSubString( s0 , 0 , 0 ) ) ) {
                    s0 = llGetSubString( s0 , 1 , -1 );
                }

                // Strip "$" off the front
                if( "$" == llGetSubString( s0 , 0 , 0 ) ) {
                    s0 = llGetSubString( s0 , 1 , -1 );
                }

                // Find second space
                i0 = llSubStringIndex( s0 , " " );

                // If there's not another space on the line, it's invalid
                if( 0 >= i0 ) {
                    BadConfig( "" , data ); return;
                }

                // Pull the payment number off the front of the string
                i1 = (integer)llGetSubString( s0 , 0 , i0 );

                // If the payment is out of bounds
                if( 0 >= i1 ) {
                    BadConfig( "L$ to give must be greater than zero. " , data ); return;
                }

                // Grab agent key off the string
                s0 = llGetSubString( s0 , i0 + 1 , -1 );

                // Name must be provided
                if( "" == s0 ) {
                    BadConfig( "User key must be provided. " , data ); return;
                }

                // Convert to key
                k0 = (key)s0;
                if( "owner" == s0 ) {
                    k0 = Owner;
                }
                if( "creator" == s0 ) {
                    k0 = llGetCreator();
                }
                if( "scriptor" == s0 ) {
                    k0 = llGetInventoryCreator( ScriptName );
                }

                // If they put the same item in twice
                if( -1 != llListFindList( Payees , [ k0 ] ) ) {
                    if( Owner == k0 ) {
                        s0 = "owner";
                    }
                    if( llGetCreator() == k0 ) {
                        s0 = "creator";
                    }
                    if( llGetInventoryCreator( ScriptName ) == k0 ) {
                        s0 = "scriptor";
                    }

                    BadConfig( s0 + " was listed twice. Did you mean to list them once with a payout of " + (string)( llList2Integer( Payees , llListFindList( Payees , [ k0 ] ) + 1 ) + i1 ) + "? " , data ); return;
                }

                // Store the configuration
                Price += i1;
                Payees = ( Payees = [] ) + Payees + [ k0 , i1 ]; // Voodoo for better memory usage
                CountPayees += 2;

                // Memory check before proceeding, having just messed with a list
                if( MemoryError() ) return;

                // Load next line of config
                NextConfigLine(); return;
            }

            // Advanced option
            if( "buy_button " == llToLower( llGetSubString( data , 0 , i0 ) ) ) {
                // Strip "buy_button " off the front
                s0 = llGetSubString( data , 11 , -1 );

                // Find second space
                i0 = llSubStringIndex( s0 , " " );

                // If there's not another space on the line, it's invalid
                if( 0 >= i0 ) {
                    BadConfig( "" , data ); return;
                }

                // Get the number off the end first (number of items)
                if( "off" == llGetSubString( s0 , i0 + 1 , -1 ) ) {
                    i1 = 0;
                } else {
                    i1 = (integer)llGetSubString( s0 , i0 + 1 , -1 );
                }

                // Then reuse for button number
                i0 = (integer)llGetSubString( s0 , 0 , i0 - 1 );

                // If item count isn't greater than 1 and isn't PAY_HIDE, bad
                // format
                if( 0 != i1 && 1 >= i1 ) {
                    BadConfig( "" , data ); return;
                }

                // Store button value
                if( 1 == i0 ) {
                    PayButton1 = i1;
                } else if( 2 == i0 ) {
                    PayButton2 = i1;
                } else if( 3 == i0 ) {
                    PayButton3 = i1;
                } else {
                    BadConfig( "" , data ); return;
                }

                // Memory check before proceeding, having just completed this line
                if( MemoryError() ) return;

                // Load next line of config
                NextConfigLine(); return;
            }

            // Advanced option
            if( "pay_any_amount " == llToLower( llGetSubString( data , 0 , i0 ) ) ) {
                // Strip "pay_any_amount " off the front
                s0 = llGetSubString( data , 15 , -1 );

                if( "yes" == llToLower( s0 ) ) {
                    PayAnyAmount = 1;
                } else if( "no" == llToLower( s0 ) ) {
                    PayAnyAmount = 0;
                } else {
                    BadConfig( "" , data ); return;
                }

                // Memory check before proceeding, having just completed this line
                if( MemoryError() ) return;

                // Load next line of config
                NextConfigLine(); return;
            }

            // Advanced option
            if( "buy_max_items " == llToLower( llGetSubString( data , 0 , i0 ) ) ) {
                // Strip "buy_max_items " off the front
                s0 = llGetSubString( data , 14 , -1 );

                // Get config value
                i1 = (integer)llGetSubString( s0 , 0 , i0 );

                // If the payment is out of bounds
                if( 0 >= i1 || 100 < i1 ) {
                    BadConfig( "" , data ); return;
                }

                // Store the new value
                MaxPerPurchase = i1;

                // Memory check before proceeding, having just completed this line
                if( MemoryError() ) return;

                // Load next line of config
                NextConfigLine(); return;
            }

            // Miscellaneous
            if( "allow_root_prim " == llToLower( llGetSubString( data , 0 , i0 ) ) ) {
                // Strip "allow_root_prim " off the front
                s0 = llGetSubString( data , 16 , -1 );

                if( "yes" == llToLower( s0 ) ) {
                    AllowRootPrim = TRUE;
                } else if( "no" == llToLower( s0 ) ) {
                    AllowRootPrim = FALSE;
                } else {
                    BadConfig( "" , data ); return;
                }

                // Memory check before proceeding, having just completed this line
                if( MemoryError() ) return;

                // Load next line of config
                NextConfigLine(); return;
            }
        } // end if( 2 == InitState )

        // If the result is the lookup of a user from the Payees
        if( 3 == InitState ) {
            // Note that this user was looked up correctly and report the amount to be given
            llOwnerSay( ScriptName + ": Will give L$" + (string)llList2Integer( Payees , DataServerRequestIndex + 1 ) + " to " + data + " for each item purchased." );

            // Increment to next value
            DataServerRequestIndex += 2;
            SetText( "Checking payouts " + (string)( DataServerRequestIndex * 100 / CountPayees ) + "%, please wait..." );

            // Memory check before proceeding, having just completed this check
            if( MemoryError() ) return;

            // If there are more to look up
            if( DataServerRequestIndex < CountPayees ) {
                // Look up the next one
                DataServerRequest = llRequestUsername( llList2Key( Payees , DataServerRequestIndex ) );
                llSetTimerEvent( 30.0 );
                return;
            }

            // Report total price
            llOwnerSay( ScriptName + ": The total price is L$" + (string)Price );

            // Get permission to give money (so we can give refunds at least)
            llOwnerSay( ScriptName + ": Getting ability to debit, please grant permission..." );
            SetText( "Getting permission..." );
            llRequestPermissions( Owner , PERMISSION_DEBIT );
            llSetTimerEvent( 30.0 );
            InitState = 4;
        }
    }

    timer() {
        // Reset/stop timer
        llSetTimerEvent( 0.0 );

        if( 1 == InitState ) {
            ShowError( "Timed out while trying to get line count for \"" + CONFIG );
        } else if( 2 == InitState ) {
            ShowError( "Timed out while trying to fetch line " + (string)(DataServerRequestIndex + 1) + " from \"" + CONFIG );
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
            state ready;
        }
    }

    state_exit() {
        llOwnerSay( ScriptName + ": This is free and unencumbered software released into the public domain. The source code can be found at: " + SOURCE_CODE_LINK );
        llOwnerSay( ScriptName + ": Ready! Free memory: " + (string)llGetFreeMemory() );
    }
}

state ready {
    ////////////
    // Resets //
    ////////////

    // If the object is attached or detached, reset
    attach( key avatarId ){
        llSetTimerEvent( 0.01 );
    }

    // Each time the object is rezzed, reset
    on_rez( integer rezParam ) {
        llSetTimerEvent( 0.01 );
    }

    // If the owner changes, copy permissions may no longer apply for
    // inventory. If the inventory changes, we have to recertify everything
    // anyway.
    changed( integer changeMask ) {
        if( changeMask & ( CHANGED_INVENTORY | CHANGED_OWNER | CHANGED_LINK ) ) {
            llSetTimerEvent( 0.01 );
        }
    }

    // If the money permission gets revoked, start over
    run_time_permissions( integer permissionMask ) {
        if( ! ( PERMISSION_DEBIT & permissionMask ) ) {
            llSetTimerEvent( 0.01 );
        }
    }

    // We use the timer event to prevent the queue from being dumped.
    // See http://wiki.secondlife.com/wiki/State#Notes
    timer() {
        llResetScript();
    }

    /////////////////
    // state ready //
    /////////////////

    state_entry() {
        llSetText( "" , ZERO_VECTOR , 0.0 );
        llSetClickAction( CLICK_ACTION_PAY );
        llSetPayPrice( PayAnyAmount , [ Price , PayButton1 , PayButton2 , PayButton3 ] );
    }

    // Rate limited
    touch_end( integer detected ) {
        if( llGetUnixTime() != LastTouch ) {
            llWhisper( 0 , ScriptName + ": This is free and unencumbered software released into the public domain. The source code can be found at: " + SOURCE_CODE_LINK );
            LastTouch = llGetUnixTime();
        }
    }

    // Switching states here would prevent further orders from being placed
    // while this one is being processed, but would also flush the event queue,
    // which would kill any orders placed in parallel. We have to honor the
    // event queue, so... do things as fast and efficiently as we can
    money( key buyerId , integer lindensReceived ) {
        float random;
        integer selected;
        integer countItemsToSend = 0;
        list itemsToSend = [];
        string change = "";
        string itemPlural = " items ";
        string hasHave = "have ";
        string objectName = llGetObjectName();

        // Let them know we're thinking
        SetText( "Please wait, getting random items for " + llGetDisplayName( buyerId ) );

        // If not enough money
        if( lindensReceived < Price ) {
            // Give money back
            llGiveMoney( buyerId , lindensReceived );
            llWhisper( 0 , "Sorry, the price is L$" + (string)Price );
            return;
        }

        // While there's still enough money for another item
        while( lindensReceived >= Price && countItemsToSend < MaxPerPurchase ) {
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
            itemsToSend = ( itemsToSend = [] ) + itemsToSend + [ llList2String( Inventory , selected ) ]; // Voodoo for better memory usage
            countItemsToSend += 1;
            lindensReceived -= Price;
        }

        // Distribute the money
        integer x;
        for( x = 0 ; x < CountPayees ; x += 2 ) {
            if( Owner != llList2Key( Payees , x ) ) {
                llGiveMoney( llList2Key( Payees , x ) , llList2Integer( Payees , x + 1 ) * countItemsToSend );
            }
        }

        // If too much money was given
        if( lindensReceived ) {
            // Give back the excess
            llGiveMoney( buyerId , lindensReceived );
            change = " Your change is L$" + (string)lindensReceived;
        }

        // If only one item was given, fix the wording
        if( 1 == countItemsToSend ) {
            itemPlural = " item ";
            hasHave = "has ";
        }

        // Thank them for their purchase
        llWhisper( 0 , "Thank you " + llGetDisplayName( buyerId ) + " for your purchase! Your " + (string)countItemsToSend + itemPlural + hasHave + "been sent." + change );

        // Build the name of the folder to give
        string folderSuffix = ( " (Easy Gacha " + (string)countItemsToSend + itemPlural + llGetDate() + ")" );
        if( llStringLength( objectName ) + llStringLength( folderSuffix ) > MAX_FOLDER_NAME_LENGTH ) {
            objectName = ( llGetSubString( objectName , 0 , MAX_FOLDER_NAME_LENGTH - llStringLength( folderSuffix ) - 4 /* 3 for ellipses, 1 because this is end index, not count */ ) + "..." );
        }

        // Give the inventory
        llGiveInventoryList( buyerId , objectName + folderSuffix , itemsToSend ); // FORCED_DELAY 3.0 seconds

        // Clear the thinkin' text
        llSetText( "" , ZERO_VECTOR , 0.0 );
    }
}
