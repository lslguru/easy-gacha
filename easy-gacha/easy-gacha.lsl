////////////////////////////////////////////////////////////////////////////////
//
//  LICENSE
//
//  This is free and unencumbered software released into the public domain.
//
//  Anyone is free to copy, modify, publish, use, compile, sell, or distribute
//  this software, either in source code form or as a compiled binary, for any
//  purpose, commercial or non-commercial, and by any means.
//
//  In jurisdictions that recognize copyright laws, the author or authors of
//  this software dedicate any and all copyright interest in the software to
//  the public domain. We make this dedication for the benefit of the public at
//  large and to the detriment of our heirs and successors. We intend this
//  dedication to be an overt act of relinquishment in perpetuity of all
//  present and future rights to this software under copyright law.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
//  THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
//  AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//  For more information, please refer to <http://unlicense.org/>
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//
//  CONSTANTS
//
//  The following constants are distributed throughout the script and tagged.
//  If you change a value here, make sure to update EVERY instance of it in the
//  script.
//
//  string SOURCE_CODE_MESSAGE = "This is free open source software. The source can be found at: https://github.com/zannalov/opensl";
//  string SERVER_URL_CONFIG = ""; // Sent when object gets configured
//  string SERVER_URL_PURCHASE = ""; // Sent with each purchase
//  string SERVER_URL_STATS = ""; // The runtime ID gets appended to the end!
//  list HTTP_OPTIONS = [ ... ];
//
//  string VERSION = "3.2";
//  key CONFIG_INVENTORY_ID = "517a121a-e248-ea49-b901-5dbefa4b2285"; // TODO
//
//  integer HIGH_MEMORY_USE_THRESHOLD = 48000;
//  integer MAX_FOLDER_NAME_LENGTH = 63;
//  integer MAX_PER_PURCHASE = 100;
//  integer MAX_ITEMS = 100;
//
//  integer STATUS_MASK_CHECK_BASE_ASSUMPTIONS = 1;
//  integer STATUS_MASK_INVENTORY_CHANGED = 2;
//  integer STATUS_MASK_HANDOUT_NEEDED = 4;
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//
// GLOBAL VARIABLES
//
////////////////////////////////////////////////////////////////////////////////

// Basic object properties
string ScriptName; // Cached because this shouldn't change
key Owner; // Cached because this shouldn't change

// Config settings
float Rarity; // Sum
integer Price; // Sum
integer SetPrice; // Integer
integer AllowNoCopy; // boolean
integer SetPayActionOnRootPrim; // Boolean
integer AllowStatSend; // Boolean
integer AllowShowStats; // Boolean
integer BuyButton1; // Should be item count during config, price after config
integer BuyButton2; // Should be item count during config, price after config
integer BuyButton3; // Should be item count during config, price after config
integer PayAnyAmount; // 0/1 during config ends, price after config
integer MaxPerPurchase; // Not to exceed MAX_PER_PURCHASE
integer FolderForOne; // Boolean
list Items; // Strided list of [ inventory name , float probability ]
integer ItemsCount;
list Payouts; // Strided list of [ avatar key , integer lindens ]
integer PayoutsCount;
integer HasNoCopyItems;
string Settings;

// Runtime
key RuntimeId; // Generated each time inventory is scanned
integer StatusMask; // Bitmask
key DataServerRequest;
integer DataServerRequestIndex;
integer SuppressOwnerMessages; // boolean, used when we know inventory will change
integer InventoryCount; // cache this and only update it in setup
integer InventoryNumber; // we don't have nested iteration, so putting this here costs 6 extra bytes up front, and saves 11 bytes for each declaration in a function avoided
string InventoryName; // we don't have nested iteration, so putting this here costs 10 extra bytes up front, and saves 8 bytes for each declaration in a function avoided

// Delivery
integer LastTouch; // unixtime
list HandoutQueue; // Strided list of [ Agent Key , Lindens Given ]
integer HandoutQueueCount; // List length (not stride item length)

////////////////////////////////////////////////////////////////////////////////
//
// LOGIC
//
////////////////////////////////////////////////////////////////////////////////

HttpRequest( string url , list data ) {
    llHTTPRequest(
        url
        , [
            HTTP_METHOD , "POST"
            , HTTP_MIMETYPE , "text/json;charset=utf-8"
            , HTTP_BODY_MAXLENGTH , 16384
            , HTTP_VERIFY_CERT , FALSE
            , HTTP_VERBOSE_THROTTLE , FALSE
            // Put any custom headers for auth here as: , HTTP_CUSTOM_HEADER , "..." , "..."
        ] /* HTTP_OPTIONS */
        , llList2Json( JSON_ARRAY , data )
    );
}

Message( integer mode , string msg ) {
    if( 1 & mode ) {
        llSetText( ScriptName + ":\n" + msg + "\n|\n|\n|\n|\n|" , <1,0,0>, 1 );
    }
    if( 2 & mode && !SuppressOwnerMessages ) {
        llOwnerSay( ScriptName + ": " + msg );
    }
    if( 4 & mode ) {
        llWhisper( 0 , ScriptName + ": " + msg );
    }
    if( 8 & mode && !SuppressOwnerMessages ) {
        llDialog( Owner , ScriptName + ":\n\n" + msg , [] , -1 ); // FORCED_DELAY 1.0 seconds
    }
}

// attach: Could be rezzed from inventory of different user
// on_rez: Could be rezzed by new owner
// changed: Change in owner, change in inventory (script name)
// run_time_permissions: Permissions revoked or denied
CheckBaseAssumptions() {
    if(
        llGetOwner() != Owner
        || llGetScriptName() != ScriptName
        || llGetPermissionsKey() != Owner
        || ! ( llGetPermissions() & PERMISSION_DEBIT )
    ) {
        llResetScript();
    }
}

// Expected formats: "L$#" "$#" "#" "#L"
// Negative numbers are not allowed
// Leading zeroes are stripped
integer ParseLindens( string value ) {
    value = llDumpList2String( llParseStringKeepNulls( ( value = "" ) + value , [ "l" , "L" , "$" ] , [ ] ) , "" );

    // Strip leading zeroes
    while( "0" == llGetSubString( value , 0 , 0 ) && 1 < llStringLength( value ) ) {
        value = llGetSubString( value , 1 , -1 );
    }

    // There shouldn't be anything else in the string now except the raw number
    // without leading zeroes
    if( (string)((integer)value) != value ) {
        return -1;
    }

    return (integer)value;
}

////////////////////////////////////////////////////////////////////////////////
//
// STATES
//
////////////////////////////////////////////////////////////////////////////////

default {
    state_entry() {
llOwnerSay( (string)llGetUsedMemory() ); return;
        Owner = llGetOwner();
        ScriptName = llGetScriptName();

        // On the off chance they changed things and we can start out with this
        // permission because it was previously granted... don't ask for it
        if( llGetPermissionsKey() == Owner && ( llGetPermissions() & PERMISSION_DEBIT ) ) {
            state setup;
        }

        // Give an extra prompt so it's obvious what's being waited on
        Message( 3 , "Please grant debit permission (touch to reset)..." );

        // Ask for permission
        llRequestPermissions( Owner , PERMISSION_DEBIT );
    }

    attach( key avatarId ){ CheckBaseAssumptions(); }
    on_rez( integer rezParam ) { CheckBaseAssumptions(); }

    run_time_permissions( integer permissionMask ) {
        CheckBaseAssumptions(); // This will reset the script if permission hasn't been given
        state setup;
    }

    touch_end( integer detected ) {
        while( 0 <= ( detected -= 1 ) ) {
            if( Owner == llDetectedKey( detected ) ) {
                CheckBaseAssumptions();
            }
        }
    }
}

state setup {
    attach( key avatarId ){ CheckBaseAssumptions(); }
    on_rez( integer rezParam ) { CheckBaseAssumptions(); }
    run_time_permissions( integer permissionMask ) { CheckBaseAssumptions(); }

    changed( integer changeMask ) {
        CheckBaseAssumptions();

        if( ( CHANGED_INVENTORY | CHANGED_LINK ) & changeMask ) {
            state setupRestart;
        }
    }

    touch_end( integer detected ) {
        while( 0 <= ( detected -= 1 ) ) {
            if( Owner == llDetectedKey( detected ) ) {
                CheckBaseAssumptions();
                state setupRestart;
            }
        }
    }

    state_entry() {
        CheckBaseAssumptions();

        Rarity = 0.0;
        Price = 0;
        SetPrice = -1;
        AllowNoCopy = TRUE;
        SetPayActionOnRootPrim = FALSE;
        AllowStatSend = TRUE;
        AllowShowStats = TRUE;
        BuyButton1 = 2;
        BuyButton2 = 5;
        BuyButton3 = 10;
        PayAnyAmount = 1;
        MaxPerPurchase = 100/*MAX_PER_PURCHASE*/;
        FolderForOne = TRUE;
        RuntimeId = llGenerateKey();
        StatusMask = 0;
        DataServerRequest = NULL_KEY;
        DataServerRequestIndex = 0;
        LastTouch = 0;
        Items = [];
        ItemsCount = 0;
        Payouts = [];
        PayoutsCount = 0;
        HasNoCopyItems = FALSE;

        if( AllowStatSend ) {
            Settings = "# version 3.2\n";/*VERSION*/
        }

        InventoryCount = llGetInventoryNumber( INVENTORY_ALL );

        llSetTimerEvent( 0.0 );

        llSetClickAction( CLICK_ACTION_NONE );
        llSetPayPrice( PAY_DEFAULT , [ PAY_DEFAULT , PAY_DEFAULT , PAY_DEFAULT , PAY_DEFAULT ] );
        llSetTouchText( "" );

        Message( 3 , "Initializing, please wait..." );

        // Keep track of the predicates we've seen
        list seen;

        // Temporary variables
        integer i0;
        string s0;
        string s1;
        string s2;
        float f0;
        key k0;
        list l0;

        // First parse config entries
        for( InventoryNumber = 0 ; InventoryNumber < InventoryCount ; InventoryNumber += 1 ) {
            // We're going to need the name for multiple things
            InventoryName = llGetInventoryName( INVENTORY_ALL , InventoryNumber );

            // If the inventory is not a configuration string, skip it for now
            if( "517a121a-e248-ea49-b901-5dbefa4b2285"/*CONFIG_INVENTORY_ID*/ != llGetInventoryKey( InventoryName ) ) {
                jump break0;
            }

            if( AllowStatSend ) {
                // Add to config we would send to server
                Settings += InventoryName + "\n";
            }

            // Process new line
            i0 = llSubStringIndex( InventoryName , " " );

            // If there's no space on the line, or there's nothing before the
            // space or there's nothing after the space, it's invalid
            if( 0 >= i0 || llStringLength( InventoryName ) - 1 == i0 ) {
                Message( 11 , "Bad config: " + InventoryName );
                return;
            }

            // Split the verb from the config value
            s0 = llToLower( llGetSubString( InventoryName , 0 , i0 - 1 ) );
            s1 = llGetSubString( InventoryName , i0 + 1 , -1 );

            // Check for duplicate configs of things where we can't allow duplicates
            if( -1 == llListFindList( seen , [ s0 ] ) ) {
                seen = seen + s0; // Voodoo for better memory usage
            } else if( -1 != llListFindList( [ "eg_pay_any_amount" , "eg_allow_send_stats" , "eg_allow_show_stats" , "eg_set_root_prim_click" , "eg_folder_for_one" , "eg_allow_no_copy" , "eg_buy_max_items" , "eg_buy_buttons" , "eg_price" ] , [ s0 ] ) ) {
                Message( 11 , "Bad config: \"" + s0 + "\" may only be used once" );
                return;
            }

            // Booleans are easy, handle them first
            if( -1 != llListFindList( [ "eg_pay_any_amount" , "eg_allow_send_stats" , "eg_allow_show_stats" , "eg_set_root_prim_click" , "eg_folder_for_one" , "eg_allow_no_copy" ] , [ s0 ] ) ) {
                // Compare all in lower case
                s1 = llToLower( s1 );

                // Check to see if the value is valid
                if(      -1 != llListFindList( [ "no"  , "off" , "false" , "0" , "iie" , "nay" , "nope" , "-" ] , [ s1 ] ) ) { i0 = 0; }
                else if( -1 != llListFindList( [ "yes" , "on"  , "true"  , "1" , "hai" , "yea" , "yep"  , "+" ] , [ s1 ] ) ) { i0 = 1; }
                else {
                    Message( 11 , "Bad config: " + InventoryName );
                    return;
                }

                // Store the value
                if( "eg_pay_any_amount"      == s0 ) { PayAnyAmount           = i0; }
                if( "eg_allow_send_stats"    == s0 ) { AllowStatSend          = i0; }
                if( "eg_allow_show_stats"    == s0 ) { AllowShowStats         = i0; }
                if( "eg_set_root_prim_click" == s0 ) { SetPayActionOnRootPrim = i0; }
                if( "eg_folder_for_one"      == s0 ) { FolderForOne           = i0; }
                if( "eg_allow_no_copy"       == s0 ) { AllowNoCopy            = i0; }

                jump break0;
            }

            // Two-part configs (where separate by space)
            if( -1 != llListFindList( [ "eg_item" , "eg_payout" ] , [ s0 ] ) ) {
                // Find second space
                i0 = llSubStringIndex( s1 , " " );

                // If there's not another space on the line, it's invalid
                if( 0 >= i0 ) {
                    Message( 11 , "Bad config: " + InventoryName );
                    return;
                }

                // If there's nothing before the space, it's invalid
                if( 0 == i0 ) {
                    Message( 11 , "Bad config: " + InventoryName );
                    return;
                }

                // If there's nothing after the space, it's invalid
                if( llStringLength( InventoryName ) - 1 == i0 ) {
                    Message( 11 , "Bad config: " + InventoryName );
                    return;
                }

                // Split parts of value
                s2 = llGetSubString( s1 , i0 + 1 , -1 );
                s1 = llGetSubString( s1 , 0 , i0 - 1 );

                if( "eg_item" == s0 ) {
                    // Pull the probability number off the front of the string
                    f0 = (float)s1;

                    // If the probability is out of bounds
                    if( 0.0 > f0 || "0" != s1 || "0.0" != s1 ) {
                        Message( 11 , "Bad config: Number must be greater than or equal to zero: " + InventoryName );
                        return;
                    }

                    // Items should exist, if not, skip safely but tell them about it - chat only
                    if( INVENTORY_NONE == llGetInventoryType( s2 ) ) {
                        Message( 2 , "Cannot find \"" + s2 + "\" in inventory. Skipping item and not adding to probabilities." );
                        return;
                    }

                    // If they put the same item in twice
                    if( -1 != llListFindList( Items , [ s2 ] ) ) {
                        Message( 11 , "Bad config: \"" + s2 + "\" was listed twice. Did you mean to list it once with a rarity of " + (string)( llList2Float( Items , llListFindList( Items , [ s2 ] ) + 1 ) + f0 ) + "?" );
                        return;
                    }

                    // Items must be transferable
                    if( ! ( PERM_TRANSFER & llGetInventoryPermMask( InventoryName , MASK_OWNER ) ) ) {
                        Message( 11 , "Bad config: \"" + s2 + "\" is not transferable. So how can I give it out?" );
                        return;
                    }

                    // Store the configuration and add probably to the sum
                    Rarity += f0;
                    Items = Items + s2; // Voodoo for better memory usage
                    Items = Items + f0; // Voodoo for better memory usage
                    ItemsCount += 2;

                    // Check that we don't have too many types of items
                    if( ItemsCount > 200/*MAX_ITEMS * 2*/ ) {
                        Message( 11 , "Too many items. This script can only handle 100 items for sale before memory problems are likely."/*MAX_ITEMS*/ );
                        return;
                    }

                    jump break0;
                }

                if( "eg_payout" == s0 ) {
                    // Pull the payment number off the front of the string
                    i0 = ParseLindens( s1 );

                    // If the payment is out of bounds
                    if( 0 > i0 ) {
                        Message( 11 , "Bad config: L$ to give must be greater than or equal to zero: " + InventoryName );
                        return;
                    }

                    // Convert to key
                    k0 = (key)s2;
                    if( "owner"    == s2 ) { k0 = Owner;                                } // magic override
                    if( "creator"  == s2 ) { k0 = llGetCreator();                       } // magic override
                    if( "scriptor" == s2 ) { k0 = llGetInventoryCreator( ScriptName );  } // magic override

                    // If they put the same item in twice
                    if( -1 != llListFindList( Payouts , [ k0 ] ) ) {
                        if( Owner                               == k0 ) { s2 = "owner";     } // reverse lookup
                        if( llGetCreator()                      == k0 ) { s2 = "creator";   } // reverse lookup
                        if( llGetInventoryCreator( ScriptName ) == k0 ) { s2 = "scriptor";  } // reverse lookup

                        Message( 11 , "Bad config: " + s2 + " was listed twice. Did you mean to list them once with a payout of " + (string)( llList2Integer( Payouts , llListFindList( Payouts , [ k0 ] ) + 1 ) + i0 ) + "?" );
                        return;
                    }

                    // Store the configuration
                    Price += i0;
                    Payouts = Payouts + k0; // Voodoo for better memory usage
                    Payouts = Payouts + i0; // Voodoo for better memory usage
                    PayoutsCount += 2;

                    jump break0;
                }
            }

            if( "eg_buy_buttons" == s0 ) {
                l0 = llParseString2List( s1 , [ " " ] , [ ] );
                BuyButton1 = llList2Integer( l0 , 0 );
                BuyButton2 = llList2Integer( l0 , 1 );
                BuyButton3 = llList2Integer( l0 , 2 );

                if(    BuyButton1 < 0 || BuyButton1 > 100
                    || BuyButton2 < 0 || BuyButton2 > 100
                    || BuyButton3 < 0 || BuyButton3 > 100
                    || ( BuyButton1 && BuyButton1 == BuyButton2 )
                    || ( BuyButton1 && BuyButton1 == BuyButton3 )
                    || ( BuyButton2 && BuyButton2 == BuyButton3 )
                ) {
                    Message( 11 , "Bad config: " + InventoryName );
                    return;
                }

                jump break0;
            }

            if( "eg_buy_max_items" == s0 ) {
                // Get config value
                MaxPerPurchase = (integer)s1;

                // If the count is out of bounds
                if( 0 >= MaxPerPurchase || 100/*MAX_PER_PURCHASE*/ < MaxPerPurchase ) {
                    Message( 11 , "Bad config: " + InventoryName );
                    return;
                }
            }

            if( "eg_price" == s0 ) {
                // Get config value
                SetPrice = ParseLindens( s1 );

                // If the payment is out of bounds
                if( 0 > SetPrice ) {
                    Message( 11 , "Bad config: L$ must be greater than or equal to zero: " + InventoryName );
                    return;
                }
            }

            // Completely unknown verb
            Message( 11 , "Bad config: " + InventoryName );
            return;

            @break0;
        } // End first parse config entries

        // Second pass, check items
        for( InventoryNumber = 0 ; InventoryNumber < InventoryCount ; InventoryNumber += 1 ) {
            // We're going to need the name for multiple things
            InventoryName = llGetInventoryName( INVENTORY_ALL , InventoryNumber );
llOwnerSay( "Processing: " + InventoryName );

            // If it's ourself, skip it
            if( ScriptName == InventoryName ) {
                jump break1;
            }

            // If the name is a configuration string, skip it, we already
            // handled these
            if( "517a121a-e248-ea49-b901-5dbefa4b2285"/*CONFIG_INVENTORY_ID*/ == llGetInventoryKey( InventoryName ) ) {
                jump break1;
            }

            // Okay, now we know it's legitimate inventory to hand out. Start
            // other checks

            // Items must be transferable. If not, noisily skip over it
            if( ! ( PERM_TRANSFER & llGetInventoryPermMask( InventoryName , MASK_OWNER ) ) ) {
                Message( 11 , "WARNING: \"" + InventoryName + "\" is not transferable. Skipping item." );
                jump break1;
            }

            // If item is not copyable
            if( ! ( PERM_COPY & llGetInventoryPermMask( InventoryName , MASK_OWNER ) ) ) {
                Message( 11 , "WARNING: \"" + InventoryName + "\" is not copyable. When it is given out, it will disappear from inventory." );

                HasNoCopyItems = TRUE;
                BuyButton1 = 0;
                BuyButton2 = 0;
                BuyButton3 = 0;
                FolderForOne = FALSE;
                PayAnyAmount = 0;
                MaxPerPurchase = 1;
                AllowStatsSend = FALSE;
                Settings = "";
            }

            // If we already have a rarity for this, skip it
            if( -1 != llListFindList( Items , [ InventoryName ] ) ) {
                jump break1;
            }

            // Store the configuration and add probably to the sum
            Rarity += 1.0;
            Items = Items + InventoryName; // Voodoo for better memory usage
            Items = Items + 1.0; // Voodoo for better memory usage
            ItemsCount += 2;

            if( AllowStatSend ) {
                Settings += "item 1 " + InventoryName + "\n";
            }

            // Check that we don't have too many types of items
            if( ItemsCount > 200/*MAX_ITEMS * 2*/ ) {
                Message( 11 , "Too many items. This script can only handle 100 items for sale before memory problems are likely."/*MAX_ITEMS*/ );
                return;
            }

            @break1;
        }

        // If we still don't have anything (determined by rarity because a
        // rarity of 0 means "do not sell"
        if( 0.0 == Rarity ) {
            Message( 11 , "No items to hand out" );
            return;
        }

        // If no payees were configured
        if( 0 == PayoutsCount && -1 == SetPrice ) {
            Message( 11 , "No price was set. Please either use eg_price or eg_payout" );
            return;
        }

        // If they manually set the price
        if( -1 != SetPrice ) {
            // Check if they goofed their math
            if( 0 != PayoutsCount && Price != SetPrice ) {
                Message( 11 , "You used both eg_price and eg_payout, but the sum of all eg_payout lines doesn't equal the eg_price!" );
                return;
            }

            // Otherwise accept their stated price
            Price = SetPrice;
        }

        // If price is zero, then there's no way to know how many items someone
        // wants at a time without this
        if( !Price ) {
            MaxPerPurchase = 1;
        }

        // If MaxPerPurchase was lowered and a button exceeds it, just hide the
        // button
        if( BuyButton1 > MaxPerPurchase ) { BuyButton1 = 0; }
        if( BuyButton2 > MaxPerPurchase ) { BuyButton2 = 0; }
        if( BuyButton3 > MaxPerPurchase ) { BuyButton3 = 0; }

        // Now turn settings into actual price
        if( 0 == PayAnyAmount ) { PayAnyAmount = PAY_HIDE; } else { PayAnyAmount  = Price; }
        if( 0 == BuyButton1   ) { BuyButton1   = PAY_HIDE; } else { BuyButton1   *= Price; }
        if( 0 == BuyButton2   ) { BuyButton2   = PAY_HIDE; } else { BuyButton2   *= Price; }
        if( 0 == BuyButton3   ) { BuyButton3   = PAY_HIDE; } else { BuyButton3   *= Price; }

        // Report percentages now that we know the totals
        for( i0 = 0 ; i0 < ItemsCount ; i0 += 2 ) {
            Message( 2 , "\"" + llList2String( Items , i0 ) + "\" has a probability of " + (string)( llList2Float( Items , i0 + 1 ) / Rarity * 100 ) + "%" );
        }

        // Kick off payout lookups
        DataServerRequest = llRequestUsername( llList2Key( Payouts , DataServerRequestIndex = 0 ) );
        llSetTimerEvent( 30.0 );
    } // end state_entry()

    dataserver( key queryId , string data ) {
        // Ignore other results that might show up
        if( queryId != DataServerRequest ) {
            return;
        }

        // Stop/reset timeout timer
        llSetTimerEvent( 0.0 );

        // Note that this user was looked up correctly and report the amount to be given
        Message( 2 , "Will give L$" + (string)llList2Integer( Payouts , DataServerRequestIndex + 1 ) + " to " + data + " for each item purchased." );

        // Increment to next value
        DataServerRequestIndex += 2;

        // If there are more to look up
        if( DataServerRequestIndex < PayoutsCount ) {
            // Look up the next one
            DataServerRequest = llRequestUsername( llList2Key( Payouts , DataServerRequestIndex ) );
            llSetTimerEvent( 30.0 );
            return;
        }

        // Report total price
        Message( 2 , "The total price is L$" + (string)Price );

        // Send config to server
        //if( AllowStatSend ) {
            //HttpRequest( ""/*SERVER_URL_CONFIG*/ , [
                //RuntimeId
                //, Settings
                //]
            //);
        //}
        Settings = ""; // Cleanup

        // Allow time for garbage collection to work
        llSleep( 3.0 );

        // Check memory now that we're all done messing around
        if( llGetUsedMemory() > 48000/*HIGH_MEMORY_USE_THRESHOLD*/ ) {
            Message( 11 , "Not enough free memory to handle large orders. Too many items? Resetting... (Used: " + (string)llGetUsedMemory() + ")" );
            llResetScript();
        }

        // All done!
        Message( 2 , "This is free open source software. The source can be found at: https://github.com/zannalov/opensl"/*SOURCE_CODE_MESSAGE*/ );
        Message( 2 , "Ready! Memory in use: " + (string)llGetUsedMemory() );

        state ready;
    }

    timer() {
        llSetTimerEvent( 0.0 );

        Message( 11 , "Timed out while trying to look up user key. The user \"" + llList2String( Payouts , DataServerRequestIndex ) + "\" doesn't seem to exist, or the data server is being too slow." );
    }
}

state setupRestart {
    state_entry() {
        SuppressOwnerMessages = FALSE;
        state setup;
    }
}

state ready {
    attach( key avatarId ){
        StatusMask = StatusMask | 1/*STATUS_MASK_CHECK_BASE_ASSUMPTIONS*/;
        llSetTimerEvent( 0.0 ); // Take timer event off stack
        llSetTimerEvent( 0.01 ); // Add it to end of stack
    }

    on_rez( integer rezParam ) {
        StatusMask = StatusMask | 1/*STATUS_MASK_CHECK_BASE_ASSUMPTIONS*/;
        llSetTimerEvent( 0.0 ); // Take timer event off stack
        llSetTimerEvent( 0.01 ); // Add it to end of stack
    }

    run_time_permissions( integer permissionMask ) {
        StatusMask = StatusMask | 1/*STATUS_MASK_CHECK_BASE_ASSUMPTIONS*/;
        llSetTimerEvent( 0.0 ); // Take timer event off stack
        llSetTimerEvent( 0.01 ); // Add it to end of stack
    }

    changed( integer changeMask ) {
        StatusMask = StatusMask | 1/*STATUS_MASK_CHECK_BASE_ASSUMPTIONS*/;
        llSetTimerEvent( 0.0 ); // Take timer event off stack
        llSetTimerEvent( 0.01 ); // Add it to end of stack

        if( ( CHANGED_INVENTORY | CHANGED_LINK ) & changeMask ) {
            StatusMask = StatusMask | 2/*STATUS_MASK_INVENTORY_CHANGED*/;
        }
    }

    state_entry() {
        CheckBaseAssumptions();
        SuppressOwnerMessages = FALSE;
        HandoutQueue = [];
        HandoutQueueCount = 0;

        llSetText( "" , ZERO_VECTOR , 0.0 );

        if( Price ) {
            llSetPayPrice( PayAnyAmount , [ Price , BuyButton1 , BuyButton2 , BuyButton3 ] );
            llSetTouchText( "Info" );
        } else {
            llSetPayPrice( PAY_HIDE , [ PAY_HIDE , PAY_HIDE , PAY_HIDE , PAY_HIDE ] );
            llSetTouchText( "Play" );
        }

        if( SetPayActionOnRootPrim || LINK_ROOT != llGetLinkNumber() ) {
            if( Price ) {
                llSetClickAction( CLICK_ACTION_PAY );
            } else {
                llSetClickAction( CLICK_ACTION_TOUCH );
            }
        } else {
            llSetClickAction( CLICK_ACTION_NONE );
        }
    }

    touch_end( integer detected ) {
        integer messageMode = 0;

        if( AllowStatSend && AllowShowStats && LastTouch != llGetUnixTime() ) {
            messageMode = 4;
        }

        // For each person that touched
        while( 0 <= ( detected -= 1 ) ) {
            // This is the exception which will be direct to owner
            if( llDetectedKey( detected ) == Owner ) {
                // Only if we're not going to whisper it
                if( AllowStatSend && !AllowShowStats ) {
                    messageMode = messageMode | 2;
                }

                // Memory will only be shown to owner now
                Message( 2 , "Script memory usage is: " + (string)llGetUsedMemory() );
            }

            // If price is zero, has to be touch based
            if( !Price ) {
                HandoutQueue = HandoutQueue + llDetectedKey( detected ); // Voodoo for better memory usage
                HandoutQueue = HandoutQueue + 0; // Voodoo for better memory usage
                HandoutQueueCount += 2;
                StatusMask = StatusMask | 4/*STATUS_MASK_HANDOUT_NEEDED*/;
                llSetTimerEvent( 0.0 ); // Take timer event off stack
                llSetTimerEvent( 0.01 ); // Add it to end of stack
            }
        }

        // Whisper source code message
        Message( 4 , "This is free open source software. The source can be found at: https://github.com/zannalov/opensl"/*SOURCE_CODE_MESSAGE*/ );

        // Otherwise stats get whispered
        //if( AllowStatSend ) {
            //Message( messageMode , ( "Want to see some statistics for this object? Click this link: " + ""/*SERVER_URL_STATS*/ + (string)RuntimeId ) );
        //}

        LastTouch = llGetUnixTime();
    }

    // Switching states here would prevent further orders from being placed
    // while this one is being processed, but would also flush the event queue,
    // which would kill any orders placed in parallel. We have to honor the
    // event queue, so... do things as fast and efficiently as we can
    money( key buyerId , integer lindensReceived ) {
        HandoutQueue = HandoutQueue + buyerId; // Voodoo for better memory usage
        HandoutQueue = HandoutQueue + lindensReceived; // Voodoo for better memory usage
        HandoutQueueCount += 2;
        StatusMask = StatusMask | 4/*STATUS_MASK_HANDOUT_NEEDED*/;
        llSetTimerEvent( 0.0 ); // Take timer event off stack
        llSetTimerEvent( 0.01 ); // Add it to end of stack
    }

    timer() {
        llSetTimerEvent( 0.0 );

        if( 4/*STATUS_MASK_HANDOUT_NEEDED*/ & StatusMask ) {
            state handout;
        }

        if( 1/*STATUS_MASK_CHECK_BASE_ASSUMPTIONS*/ & StatusMask ) {
            CheckBaseAssumptions();
        }

        if( 2/*STATUS_MASK_INVENTORY_CHANGED*/ & StatusMask ) {
            state setup;
        }
    }
}

// Note: State has neither touch events nor pay events, preventing further
// additions to the queue
state handout {
    state_entry() {
        StatusMask -= 4/*STATUS_MASK_HANDOUT_NEEDED*/; // Remove bit

        while( 0 <= ( HandoutQueueCount -= 2 ) ) {
            key buyerId = llList2Key( HandoutQueue , HandoutQueueCount );
            integer lindensReceived = llList2Integer( HandoutQueue , HandoutQueueCount + 1 );

            string displayName = llGetDisplayName( buyerId );

            // Let them know we're thinking
            Message( 1 , "Please wait, getting random items for " + displayName );

            // If not enough money
            if( lindensReceived < Price ) {
                // Send statistics to server if server is configured
                //if( AllowStatSend ) {
                    //HttpRequest( ""/*SERVER_URL_PURCHASE*/ , [
                        //RuntimeId
                        //, buyerId
                        //, displayName
                    //] );
                //}

                // Give money back
                if( lindensReceived ) {
                    llGiveMoney( buyerId , lindensReceived );
                }

                // Tell them why
                Message( 4 , "Sorry " + displayName + ", the price is L$" + (string)Price );

                // Continue
                jump break2;
            }

            // While there's still enough money for another item
            integer countItemsToSend = 0;
            list itemsToSend = [];
            while( lindensReceived >= Price && countItemsToSend < MaxPerPurchase && ItemsCount ) {
                float random = Rarity - llFrand( Rarity ); // Generate a random number which is between [ Rarity , 0.0 )
                integer selected = -2; // Start below the first object because the first iteration will definitely run once

                // While the random number is at or above zero, we haven't hit our
                // target object. Exiting the while loop will result in a random number
                // at or below zero, indicating the selected index matches an object.
                while( 0 <= random ) {
                    // Increment to the next item (or first if first iteration)
                    selected += 2;

                    // If the Rarity of the Item is zero, this cannot cause
                    // random to satisfy the exit criteria for the loop,
                    // guranteeing that items with a zero are always skipped
                    random -= llList2Float( Items , selected + 1 );
                }

                string inventoryName = llList2String( Items , selected );

                // If item is no-copy, then we know we can only hand out one at
                // a time anyway, so no need to shorten the list or worry about
                // inventory being missing on the next iteration. There won't
                // be another iteration, and after handing out, we'll rescan
                // inventory anyway.
                if( ! ( PERM_COPY & llGetInventoryPermMask( inventoryName , MASK_OWNER ) ) ) {
                    // Note that the next inventory action should not report to the
                    // owner and queue up a re-scan of inventory
                    SuppressOwnerMessages = TRUE;
                }

                // Schedule to give inventory, increment counter, decrement money
                itemsToSend = itemsToSend + inventoryName; // Voodoo for better memory usage
                countItemsToSend += 1;
                lindensReceived -= Price;
            }

            // Distribute the money
            if( lindensReceived ) {
                integer x;
                for( x = 0 ; x < PayoutsCount ; x += 2 ) {
                    if( Owner != llList2Key( Payouts , x ) ) {
                        llGiveMoney( llList2Key( Payouts , x ) , llList2Integer( Payouts , x + 1 ) * countItemsToSend );
                    }
                }
            }

            // If too much money was given
            string change = "";
            if( lindensReceived ) {
                // Give back the excess
                llGiveMoney( buyerId , lindensReceived );
                change = " Your change is L$" + (string)lindensReceived;
            }

            // If only one item was given, fix the wording
            string itemPlural = " items ";
            string hasHave = "have ";
            if( 1 == countItemsToSend ) {
                itemPlural = " item ";
                hasHave = "has ";
            }

            // Thank them for their purchase
            Message( 4 , "Thank you for your purchase, " + displayName + "! Your " + (string)countItemsToSend + itemPlural + hasHave + "been sent." + change );

            // Build the name of the folder to give
            string objectName = llGetObjectName();
            string folderSuffix = ( " (Easy Gacha " + (string)countItemsToSend + itemPlural + llGetDate() + ")" );
            if( llStringLength( objectName ) + llStringLength( folderSuffix ) > 63/*MAX_FOLDER_NAME_LENGTH*/ ) {
                objectName = ( llGetSubString( objectName , 0 , 63/*MAX_FOLDER_NAME_LENGTH*/ - llStringLength( folderSuffix ) - 4 /* 3 for ellipses, 1 because this is end index, not count */ ) + "..." );
            }

            // Give the inventory
            if( 1 < countItemsToSend || FolderForOne ) {
                llGiveInventoryList( buyerId , objectName + folderSuffix , itemsToSend ); // FORCED_DELAY 3.0 seconds
            } else {
                llGiveInventory( buyerId , llList2String( itemsToSend , 0 ) ); // FORCED_DELAY 2.0 seconds
            }

            // Send statistics to server if server is configured
            //if( AllowStatSend ) {
                //HttpRequest( ""/*SERVER_URL_PURCHASE*/ , [
                    //RuntimeId
                    //, buyerId
                    //, displayName
                    //] + itemsToSend
                //);
            //}

            @break2;
        }

        // Clear the thinkin' text
        llSetText( "" , ZERO_VECTOR , 0.0 );

        // If we know we need to re-scan, do so
        if( SuppressOwnerMessages ) {
            state setup;
        }

        state ready;
    }
}
