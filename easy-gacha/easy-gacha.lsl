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
//  integer LOW_MEMORY_THRESHOLD = 16000;
//  integer MAX_FOLDER_NAME_LENGTH = 63;
//  integer MAX_PER_PURCHASE = 100;
//  integer MAX_PAYOUTS = 10;
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
list Payouts; // Strided list of [ key , amount ]
integer PayoutsCount; // List length of Payouts, not de-strided
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
integer HasNoCopyItems;
string Settings;

// Runtime
key RuntimeId; // Generated each time inventory is scanned
integer StatusMask; // Bitmask
key DataServerRequest;
integer DataServerRequestIndex;
integer SuppressOwnerMessages; // boolean, used when we know inventory will change
integer InventoryCount; // cache this and only update it in setup
integer TextureCount; // cache this and only update it in setup

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
    if( "" == url ) {
        return;
    }

    llHTTPRequest(
        url
        , [
            HTTP_METHOD , "POST"
            , HTTP_MIMETYPE , "text/json;charset=utf-8"
            , HTTP_BODY_MAXLENGTH , 16384
            , HTTP_VERIFY_CERT , FALSE
            , HTTP_VERBOSE_THROTTLE , FALSE
            // Put any custom headers for auth here as: , HTTP_CUSTOM_HEADER , "..." , "..."
        ] // HTTP_OPTIONS
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

/*
// Find the Nth config line
string FindConfigLine( integer requestedIndex ) {
    integer iterate;
    integer foundIndex = 0;
    string inventoryName;

    // For each texture
    for( iterate = 0 ; iterate < TextureCount ; iterate += 1 ) {
        // Get the name
        inventoryName = llGetInventoryName( INVENTORY_TEXTURE , iterate );

        // If it's a config item
        if( "517a121a-e248-ea49-b901-5dbefa4b2285" == llGetInventoryKey( inventoryName ) ) { // CONFIG_INVENTORY_ID
            // And it matches the requested index
            if( foundIndex == requestedIndex ) {
                return inventoryName;
            }

            // Otherwise increment the index because it was a config
            foundIndex += 1;
        }
    }

    // Nope, not that many lines
    return EOF;
}

// Find the Nth config line which begins with this verb
string FindConfigVerb( string verb , integer requestedIndex ) {
    integer iterate;
    integer foundIndex = 0;
    string inventoryName;

    // Pre-add the trailing space
    verb = verb + " ";

    // For each texture
    for( iterate = 0 ; iterate < TextureCount ; iterate += 1 ) {
        // Get the name
        inventoryName = llGetInventoryName( INVENTORY_TEXTURE , iterate );

        // If it's a config item
        if( "517a121a-e248-ea49-b901-5dbefa4b2285" == llGetInventoryKey( inventoryName ) ) { // CONFIG_INVENTORY_ID
            // If the verb is the first part of the inventory name
            if( verb == llGetSubString( inventoryName , 0 , llStringLength( verb ) - 1 ) ) {
                // And it matches the requested index
                if( foundIndex == requestedIndex ) {
                    // If there's nothing after the verb+space, we can't use
                    // llGetSubString
                    if( llStringLength( verb ) == llStringLength( inventoryName ) ) {
                        return "";
                    }

                    // Return the non-verb portion of the line
                    return llGetSubString( inventoryName , llStringLength( verb ) , -1 );
                }

                // Otherwise increment the index because it was a config
                foundIndex += 1;
            }
        }
    }

    // Nope, not that many lines
    return EOF;
}
*/

// Find the Nth config line which begins with this verb
string FindConfigVerbId( string verb , string id , integer requestedIndex ) {
    integer iterate;
    integer foundIndex = 0;
    string inventoryName;

    // Pre-add the trailing space
    verb = verb + " ";

    // Pre-add the leading space
    id = " " + id;

    // For each texture
    for( iterate = 0 ; iterate < TextureCount ; iterate += 1 ) {
        // Get the name
        inventoryName = llGetInventoryName( INVENTORY_TEXTURE , iterate );

        // If it's a config item
        if( "517a121a-e248-ea49-b901-5dbefa4b2285" == llGetInventoryKey( inventoryName ) ) { // CONFIG_INVENTORY_ID
            // If the verb is the first part of the inventory name
            if( verb == llGetSubString( inventoryName , 0 , llStringLength( verb ) - 1 ) ) {
                // Check to see if the end of the line matches the id provided.
                // Should be separated by a space.
                if( id == llGetSubString( inventoryName , -1 * llStringLength( id ) , -1 ) ) {
                    // And it matches the requested index
                    if( foundIndex == requestedIndex ) {
                        // If there's nothing after the verb+space, we can't use
                        // llGetSubString
                        if( llStringLength( verb ) + llStringLength( id ) == llStringLength( inventoryName ) ) {
                            return "";
                        }

                        // Return the non-verb non-id portion of the line
                        return llGetSubString( inventoryName , llStringLength( verb ) , ( -1 * llStringLength( id ) ) - 1 );
                    }

                    // Otherwise increment the index because it was a config
                    foundIndex += 1;
                }
            }
        }
    }

    // Nope, not that many lines
    return EOF;
}

integer ConvertBooleanSetting( string config ) {
    config = llToLower( config );

    if( -1 != llListFindList( [ "no"  , "off" , "false" , "0" , "iie" , "nay" , "nope" , "-" ] , [ config ] ) ) {
        return FALSE;
    }
    if( -1 != llListFindList( [ "yes" , "on"  , "true"  , "1" , "hai" , "yea" , "yep"  , "+" ] , [ config ] ) ) {
        return TRUE;
    }

    // Invalid value
    return -1;
}

////////////////////////////////////////////////////////////////////////////////
//
// STATES
//
////////////////////////////////////////////////////////////////////////////////

default {
    state_entry() {
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
        Payouts = [];
        PayoutsCount = 0;
        AllowNoCopy = TRUE;
        SetPayActionOnRootPrim = FALSE;
        AllowStatSend = TRUE;
        AllowShowStats = TRUE;
        BuyButton1 = 2;
        BuyButton2 = 5;
        BuyButton3 = 10;
        PayAnyAmount = 1;
        MaxPerPurchase = 100; // MAX_PER_PURCHASE
        FolderForOne = TRUE;
        RuntimeId = llGenerateKey();
        StatusMask = 0;
        DataServerRequest = NULL_KEY;
        DataServerRequestIndex = 0;
        LastTouch = 0;
        HasNoCopyItems = FALSE;

        if( AllowStatSend ) {
            Settings = "# version 3.2\n"; // VERSION
        }

        InventoryCount = llGetInventoryNumber( INVENTORY_ALL );
        TextureCount = llGetInventoryNumber( INVENTORY_TEXTURE );

        llSetTimerEvent( 0.0 );

        llSetClickAction( CLICK_ACTION_NONE );
        llSetPayPrice( PAY_DEFAULT , [ PAY_DEFAULT , PAY_DEFAULT , PAY_DEFAULT , PAY_DEFAULT ] );
        llSetTouchText( "" );

        // Temporary variables
        integer iterate;
        integer i0;
        list l0;
        float f0;
        key k0;

        // Config related variables
        string inventoryName;
        string verb;
        string value;

        Message( 2 , "Initializing, please wait..." );
        Message( 1 , "Initializing, please wait...\nStep 1 / 5: 0%" );
        // Check that all config lines have at least one space, something to
        // the left and right of the space, and a known verb (in a single pass)
        for( iterate = 0 ; iterate < TextureCount ; iterate += 1 ) {
            // Get the name
            inventoryName = llGetInventoryName( INVENTORY_TEXTURE , iterate );

            // If it's a config item
            if( "517a121a-e248-ea49-b901-5dbefa4b2285" == llGetInventoryKey( inventoryName ) ) { // CONFIG_INVENTORY_ID

                // Find the space
                i0 = llSubStringIndex( inventoryName , " " );

                // If the first space isn't present, is the first character, or
                // is the last character (meaning no value before/after it)
                if( 0 >= i0 || llStringLength( inventoryName ) - 1 == i0 ) {
                    Message( 11 , "Bad config: " + inventoryName );
                    return;
                }

                // Separate the verb
                verb = llGetSubString( inventoryName , 0 , i0 - 1 );
                value = llGetSubString( inventoryName , i0 + 1 , -1 );

                // If the verb isn't known
                if(
                    -1 == llListFindList( [
                        "eg_pay_any_amount"
                        , "eg_allow_send_stats"
                        , "eg_allow_show_stats"
                        , "eg_set_root_prim_click"
                        , "eg_folder_for_one"
                        , "eg_allow_no_copy"
                        , "eg_buy_max_items"
                        , "eg_buy_buttons"
                        , "eg_price"
                        , "eg_rarity"
                        , "eg_payout"
                    ] , [ verb ] )
                ) {
                    Message( 11 , "Bad config: Unknown option: " + inventoryName );
                    return;
                }

                // If the verb may only be used once
                l0 = [];
                if(
                    -1 != llListFindList( [
                        "eg_pay_any_amount"
                        , "eg_allow_send_stats"
                        , "eg_allow_show_stats"
                        , "eg_set_root_prim_click"
                        , "eg_folder_for_one"
                        , "eg_allow_no_copy"
                        , "eg_buy_max_items"
                        , "eg_buy_buttons"
                        , "eg_price"
                    ] , [ verb ] )
                    && -1 != llListFindList( l0 , [ verb ] )
                ) {
                    Message( 11 , "Bad config: " + verb + " may only be used once" );
                    return;
                } else {
                    l0 += verb;
                }

                // Boolean verbs
                if(
                    -1 != llListFindList( [
                        "eg_pay_any_amount"
                        , "eg_allow_send_stats"
                        , "eg_allow_show_stats"
                        , "eg_set_root_prim_click"
                        , "eg_folder_for_one"
                        , "eg_allow_no_copy"
                    ] , [ verb ] )
                ) {
                    i0 = ConvertBooleanSetting( value );

                    // If invalid input
                    if( -1 == i0 ) {
                        Message( 11 , "Bad config: Setting must be boolean (yes/no): " + inventoryName );
                        return;
                    }

                    if( "eg_pay_any_amount"      == verb ) { PayAnyAmount           = i0; }
                    if( "eg_allow_send_stats"    == verb ) { AllowStatSend          = i0; }
                    if( "eg_allow_show_stats"    == verb ) { AllowShowStats         = i0; }
                    if( "eg_set_root_prim_click" == verb ) { SetPayActionOnRootPrim = i0; }
                    if( "eg_folder_for_one"      == verb ) { FolderForOne           = i0; }
                    if( "eg_allow_no_copy"       == verb ) { AllowNoCopy            = i0; }
                }

                // SetPrice
                if( "eg_price" == verb ) {
                    SetPrice = ParseLindens( value );

                    // If the payment is out of bounds
                    if( 0 > SetPrice ) {
                        Message( 11 , "Bad config: L$ must be greater than or equal to zero: " + inventoryName );
                        return;
                    }
                }

                // SetPrice
                if( "eg_buy_max_items" == verb ) {
                    MaxPerPurchase = (integer)value;

                    // If the count is out of bounds
                    if( 0 >= MaxPerPurchase || 100 < MaxPerPurchase ) { // MAX_PER_PURCHASE
                        Message( 11 , "Bad config: Max purchases must be between 1 and 100: " + inventoryName );
                        return;
                    }
                }

                // BuyButton*
                if( "eg_buy_buttons" == verb ) {
                    l0 = llParseString2List( value , [ " " ] , [ ] );
                    BuyButton1 = llList2Integer( l0 , 0 );
                    BuyButton2 = llList2Integer( l0 , 1 );
                    BuyButton3 = llList2Integer( l0 , 2 );

                    if(
                        llDumpList2String( [ BuyButton1 , BuyButton2 , BuyButton3 ] , " " ) != value
                        || BuyButton1 < 0 || BuyButton1 > 100
                        || BuyButton2 < 0 || BuyButton2 > 100
                        || BuyButton3 < 0 || BuyButton3 > 100
                        || ( BuyButton1 && BuyButton1 == BuyButton2 )
                        || ( BuyButton1 && BuyButton1 == BuyButton3 )
                        || ( BuyButton2 && BuyButton2 == BuyButton3 )
                    ) {
                        Message( 11 , "Bad config: Please see documentation for: " + inventoryName );
                        return;
                    }
                }

                // Check format of multi-part configs
                if( "eg_rarity" == verb || "eg_payout" == verb ) {
                    // Find the space
                    i0 = llSubStringIndex( value , " " );

                    // If the first space isn't present, is the first character, or
                    // is the last character (meaning no value before/after it)
                    if( 0 >= i0 || llStringLength( inventoryName ) - 1 == i0 ) {
                        Message( 11 , "Bad config: " + inventoryName );
                        return;
                    }

                    // Check that inventory exists if it was configured, warn
                    // (but not error) if not
                    if( "eg_rarity" == verb ) {
                        // Convert value to the inventory name
                        value = llGetSubString( value , i0 + 1 , -1 );

                        // Items should exist, if not, skip safely but tell
                        // them about it - chat only
                        if( INVENTORY_NONE == llGetInventoryType( value ) ) {
                            Message( 2 , "WARNING: Cannot find \"" + value + "\" in inventory. Skipping item and not adding to probabilities: " + inventoryName );
                        }
                    }

                    // Add up the configured payouts
                    if( "eg_payout" == verb ) {
                        // Split string - replaces i0 and value
                        i0 = ParseLindens( llGetSubString( value , 0 , llSubStringIndex( value , " " ) - 1 ) );
                        value = llGetSubString( value , llSubStringIndex( value , " " ) + 1 , -1 );

                        // If the payment is out of bounds
                        if( 0 >= i0 ) {
                            Message( 11 , "Bad config: L$ to give must be greater than zero: " + inventoryName );
                            return;
                        }

                        // Convert to key
                        k0 = (key)value;
                        if( "owner"    == value ) { k0 = Owner;                                } // magic override
                        if( "creator"  == value ) { k0 = llGetCreator();                       } // magic override
                        if( "scriptor" == value ) { k0 = llGetInventoryCreator( ScriptName );  } // magic override

                        // If they put the same item in twice
                        if( -1 != llListFindList( Payouts , [ k0 ] ) ) {
                            if( Owner                               == k0 ) { value = "owner";     } // reverse lookup
                            if( llGetCreator()                      == k0 ) { value = "creator";   } // reverse lookup
                            if( llGetInventoryCreator( ScriptName ) == k0 ) { value = "scriptor";  } // reverse lookup

                            Message( 11 , "Bad config: " + value + " was listed more than once. Did you mean to list them once with a payout of " + (string)( llList2Integer( Payouts , llListFindList( Payouts , [ k0 ] ) + 1 ) + i0 ) + "?" );
                            return;
                        }

                        // Store the configuration
                        Price += i0;
                        Payouts = Payouts + k0; // Voodoo for better memory usage
                        Payouts = Payouts + i0; // Voodoo for better memory usage
                        PayoutsCount += 2;

                        if( PayoutsCount > 20 ) { // MAX_PAYOUTS * 2
                            Message( 11 , "Bad config: Trying to pay too many people. Script memory errors are likely to occur." );
                            return;
                        }
                    }
                } // end multi-part config checks

            } // end if is config item

            Message( 1 , "Initializing, please wait...\nStep 1 / 5: " + (string)( ( iterate + 1 ) * 100 / TextureCount ) + "%" );
        } // end texture iteration

        // Scan and verify items
        for( iterate = 0 ; iterate < InventoryCount ; iterate += 1 ) {
            // Get the name
            inventoryName = llGetInventoryName( INVENTORY_ALL , iterate );
            Message( 1 , "Initializing, please wait...\nStep 2 / 5: " + (string)( ( iterate + 1 ) * 100 / InventoryCount ) + "%\nChecking: " + inventoryName );

            // If it's ourself, skip it
            if( ScriptName == inventoryName ) {
                jump break0;
            }

            // If it's a config item, skip it
            if( "517a121a-e248-ea49-b901-5dbefa4b2285" == llGetInventoryKey( inventoryName ) ) { // CONFIG_INVENTORY_ID
                jump break0;
            }

            // Items must be transferable
            if( ! ( PERM_TRANSFER & llGetInventoryPermMask( inventoryName , MASK_OWNER ) ) ) {
                Message( 2 , "WARNING: Not transferable, skipping: " + inventoryName );
                jump break0;
            }

            // Find all config lines for this item: Note, expensive because we
            // have to do sub-iteration here for each config line. Worth it for
            // the output, though.
            i0 = 0;
            f0 = 0.0;
            while( EOF != ( value = FindConfigVerbId( "eg_rarity" , inventoryName , i0 ) ) ) {
                i0 += 1;
                f0 += (float)value;

                // If the probability is out of bounds
                if( 0.0 > (float)value ) {
                    Message( 11 , "Bad config: Number must be greater than or equal to zero: eg_rarity " + value + " " + inventoryName );
                    return;
                }
                if( 0.0 == (float)value && "0" != value && "0.0" != value ) {
                    Message( 11 , "Bad config: eg_rarity " + value + " " + inventoryName );
                    return;
                }
            }

            // If more than one config line was found, use the sum of
            // rarities for error message
            if( 1 < i0 ) {
                Message( 11 , "Bad config: \"" + inventoryName + "\" was listed more than once. Did you mean to list it once like this? eg_rarity " + (string)( f0 ) + " " + inventoryName );
                return;
            }

            // If no config lines were provided, default to a rarity of one
            if( 0 == i0 ) {
                f0 = 1.0;
                Message( 2 , "No rarity listed for \"" + inventoryName + "\", setting to 1.0" );
            }

            // Rarity explicitly set to zero
            if( 0.0 == f0 ) {
                Message( 2 , "Will not hand out: " + inventoryName );
                jump break0;
            }

            // Add to rarity
            Rarity += f0;

            // If item is not copyable
            if( ! ( PERM_COPY & llGetInventoryPermMask( inventoryName , MASK_OWNER ) ) ) {
                Message( 2 , "WARNING: \"" + inventoryName + "\" is is not copyable. When it is given out, it will disappear from inventory. Switching to no-copy-item mode. Stats are being disabled."  );

                HasNoCopyItems = TRUE;
                BuyButton1 = 0;
                BuyButton2 = 0;
                BuyButton3 = 0;
                FolderForOne = FALSE;
                PayAnyAmount = 0;
                MaxPerPurchase = 1;
                AllowStatSend = FALSE;
            }

            @break0;
        } // end inventory iteration

        Message( 1 , "Initializing, please wait...\nStep 3 / 5: Validity checks" );

        // If we still don't have anything (determined by rarity because a
        // rarity of 0 means "do not sell" and default rarity is 1.0 if not
        // specified)
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
                Message( 11 , "You used both eg_price and eg_payout, but the sum of all eg_payout lines L$" + (string)Price + " doesn't equal the eg_price L$" + (string)SetPrice + "! Which one is right?" );
                return;
            }

            // Otherwise accept their stated price
            Price = SetPrice;
            Payouts = [ Owner , Price ];
            PayoutsCount = 2;
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
        for( iterate = 0 ; iterate < InventoryCount ; iterate += 1 ) {
            // Get the name
            inventoryName = llGetInventoryName( INVENTORY_ALL , iterate );
            Message( 1 , "Initializing, please wait...\nStep 4 / 5: " + (string)( ( iterate + 1 ) * 100 / InventoryCount ) + "%" );

            // If it's ourself, skip it
            if( ScriptName == inventoryName ) {
                jump break1;
            }

            // If it's a config item, skip it
            if( "517a121a-e248-ea49-b901-5dbefa4b2285" == llGetInventoryKey( inventoryName ) ) { // CONFIG_INVENTORY_ID
                jump break1;
            }

            // Items must be transferable
            if( ! ( PERM_TRANSFER & llGetInventoryPermMask( inventoryName , MASK_OWNER ) ) ) {
                jump break1;
            }

            f0 = 1.0;
            if( EOF != ( value = FindConfigVerbId( "eg_rarity" , inventoryName , 0 ) ) ) {
                f0 = (float)value;
            }

            if( 0.0 < f0 ) {
                Message( 2 , "\"" + inventoryName + "\" has a probability of " + (string)( f0 / Rarity * 100 ) + "%" );
            }

            @break1;
        }

        // Kick off payout lookups
        Message( 1 , "Initializing, please wait...\nStep 5 / 5: " + (string)( DataServerRequestIndex * 100 / PayoutsCount ) + "%" );
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
            Message( 1 , "Initializing, please wait...\nStep 5 / 5: " + (string)( DataServerRequestIndex * 100 / PayoutsCount ) + "%" );
            DataServerRequest = llRequestUsername( llList2Key( Payouts , DataServerRequestIndex ) );
            llSetTimerEvent( 30.0 );
            return;
        }

        // Report total price
        Message( 2 , "The total price is L$" + (string)Price );

        // Send config to server
        // TODO
        if( AllowStatSend ) {
            HttpRequest( "" , [ // SERVER_URL_CONFIG
                RuntimeId
                , Settings
                ]
            );
        }
        Settings = ""; // Cleanup

        // Allow time for garbage collection to work
        llSleep( 3.0 );

        // Check memory now that we're all done messing around
        if( llGetFreeMemory() < 16000 ) { // LOW_MEMORY_THRESHOLD
            Message( 11 , "Not enough free memory to handle large orders. Too many items? Resetting... (Used: " + (string)llGetUsedMemory() + " Free: " + (string)llGetFreeMemory() + ")" );
            llResetScript();
        }

        // All done!
        Message( 2 , "This is free open source software. The source can be found at: https://github.com/zannalov/opensl" ); // SOURCE_CODE_MESSAGE
        Message( 2 , "Ready! Memory Used: " + (string)llGetUsedMemory() + " Memory Free: " + (string)llGetFreeMemory() );

        state ready;
    } // end dataserver()

    timer() {
        llSetTimerEvent( 0.0 );

        Message( 11 , "Timed out while trying to look up user key. The user \"" + llList2String( Payouts , DataServerRequestIndex ) + "\" doesn't seem to exist, or the data server is being too slow." );
    }
} // end state setup

state setupRestart {
    state_entry() {
        SuppressOwnerMessages = FALSE;
        llSetTimerEvent( 1.0 ); // Wait 1 second in case events are still firing
    }

    timer() {
        llSetTimerEvent( 0.0 );
        state setup;
    }
}

state ready {
    attach( key avatarId ){
        StatusMask = StatusMask | 1; // STATUS_MASK_CHECK_BASE_ASSUMPTIONS
        llSetTimerEvent( 0.0 ); // Take timer event off stack
        llSetTimerEvent( 0.01 ); // Add it to end of stack
    }

    on_rez( integer rezParam ) {
        StatusMask = StatusMask | 1; // STATUS_MASK_CHECK_BASE_ASSUMPTIONS
        llSetTimerEvent( 0.0 ); // Take timer event off stack
        llSetTimerEvent( 0.01 ); // Add it to end of stack
    }

    run_time_permissions( integer permissionMask ) {
        StatusMask = StatusMask | 1; // STATUS_MASK_CHECK_BASE_ASSUMPTIONS
        llSetTimerEvent( 0.0 ); // Take timer event off stack
        llSetTimerEvent( 0.01 ); // Add it to end of stack
    }

    changed( integer changeMask ) {
        StatusMask = StatusMask | 1; // STATUS_MASK_CHECK_BASE_ASSUMPTIONS
        llSetTimerEvent( 0.0 ); // Take timer event off stack
        llSetTimerEvent( 0.01 ); // Add it to end of stack

        if( ( CHANGED_INVENTORY | CHANGED_LINK ) & changeMask ) {
            StatusMask = StatusMask | 2; // STATUS_MASK_INVENTORY_CHANGED
        }
    }

    state_entry() {
        CheckBaseAssumptions();
        SuppressOwnerMessages = FALSE;
        HandoutQueue = [];
        HandoutQueueCount = 0;

        llSetText( "" , ZERO_VECTOR , 1 );

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
                StatusMask = StatusMask | 4; // STATUS_MASK_HANDOUT_NEEDED
                llSetTimerEvent( 0.0 ); // Take timer event off stack
                llSetTimerEvent( 0.01 ); // Add it to end of stack
            }
        }

        // Whisper source code message
        Message( 4 , "This is free open source software. The source can be found at: https://github.com/zannalov/opensl" ); // SOURCE_CODE_MESSAGE

        // Otherwise stats get whispered
        //if( AllowStatSend ) {
            //Message( messageMode , ( "Want to see some statistics for this object? Click this link: " + "" + (string)RuntimeId ) ); // SERVER_URL_STATS
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
        StatusMask = StatusMask | 4; // STATUS_MASK_HANDOUT_NEEDED
        llSetTimerEvent( 0.0 ); // Take timer event off stack
        llSetTimerEvent( 0.01 ); // Add it to end of stack
    }

    timer() {
        llSetTimerEvent( 0.0 );

        if( 4 & StatusMask ) { // STATUS_MASK_HANDOUT_NEEDED
            state handout;
        }

        if( 1 & StatusMask ) { // STATUS_MASK_CHECK_BASE_ASSUMPTIONS
            CheckBaseAssumptions();
        }

        if( 2 & StatusMask ) { // STATUS_MASK_INVENTORY_CHANGED
            state setup;
        }
    }
}

// Note: State has neither touch events nor pay events, preventing further
// additions to the queue
state handout {
    state_entry() {
        StatusMask -= 4; // Remove bit // STATUS_MASK_HANDOUT_NEEDED

        while( 0 <= ( HandoutQueueCount -= 2 ) ) {
            key buyerId = llList2Key( HandoutQueue , HandoutQueueCount );
            integer lindensReceived = llList2Integer( HandoutQueue , HandoutQueueCount + 1 );
            string displayName = llGetDisplayName( buyerId );

            // Let them know we're thinking
            Message( 1 , "Please wait, getting random items for: " + displayName );

            // If not enough money
            if( lindensReceived < Price ) {
                // Send statistics to server if server is configured
                if( AllowStatSend ) {
                    HttpRequest( "" , [ // SERVER_URL_PURCHASE
                        RuntimeId
                        , buyerId
                        , displayName
                    ] );
                }

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
            integer iterate;
            float random;
            string raritySetting;
            float rarity;
            string inventoryName;
            while( lindensReceived >= Price && countItemsToSend < MaxPerPurchase ) {
                // Let them know we're thinking
                Message( 1 , "Please wait, getting random item " + (string)( countItemsToSend + 1 ) + " / " + (string)( countItemsToSend + ( lindensReceived / Price ) ) + " for: " + displayName );

                random = Rarity - llFrand( Rarity ); // Generate a random number which is between [ Rarity , 0.0 )

                // Iterate across all inventory looking for the one in the
                // range specified
                for( iterate = 0 ; iterate < InventoryCount && 0 <= random ; iterate += 1 ) {
                    // Get the name
                    inventoryName = llGetInventoryName( INVENTORY_ALL , iterate );

                    // If it's ourself, skip it
                    if( ScriptName == inventoryName ) {
                        jump break3;
                    }

                    // If it's a config item, skip it
                    if( "517a121a-e248-ea49-b901-5dbefa4b2285" == llGetInventoryKey( inventoryName ) ) { // CONFIG_INVENTORY_ID
                        jump break3;
                    }

                    // Items must be transferable
                    if( ! ( PERM_TRANSFER & llGetInventoryPermMask( inventoryName , MASK_OWNER ) ) ) {
                        jump break3;
                    }

                    // Figure out the configured rarity
                    rarity = 1.0;
                    if( EOF != ( raritySetting = FindConfigVerbId( "eg_rarity" , inventoryName , 0 ) ) ) {
                        rarity = (float)raritySetting;
                    }

                    // Subtract the rarity from the random number. If zero, has
                    // no effect. If greater than zero, can cause random to
                    // become negative. Then we know the random number fell in
                    // the range of the rarity of this item.
                    random -= rarity;

                    @break3;
                }

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
            integer x;
            for( x = 0 ; x < PayoutsCount ; x += 2 ) {
                if( Owner != llList2Key( Payouts , x ) ) {
                    llGiveMoney( llList2Key( Payouts , x ) , llList2Integer( Payouts , x + 1 ) * countItemsToSend );
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
            if( llStringLength( objectName ) + llStringLength( folderSuffix ) > 63 ) { // MAX_FOLDER_NAME_LENGTH
                // MAX_FOLDER_NAME_LENGTH
                // 4 == 3 for ellipses, 1 because this is end index, not count
                objectName = ( llGetSubString( objectName , 0 , 63 - llStringLength( folderSuffix ) - 4 ) + "..." ); // MAX_FOLDER_NAME_LENGTH
            }

            // Give the inventory
            if( 1 < countItemsToSend || FolderForOne ) {
                llGiveInventoryList( buyerId , objectName + folderSuffix , itemsToSend ); // FORCED_DELAY 3.0 seconds
            } else {
                llGiveInventory( buyerId , llList2String( itemsToSend , 0 ) ); // FORCED_DELAY 2.0 seconds
            }

            // Send statistics to server if server is configured
            if( AllowStatSend ) {
                HttpRequest( "" , [ // SERVER_URL_PURCHASE
                    RuntimeId
                    , buyerId
                    , displayName
                    ] + itemsToSend
                );
            }

            @break2;
        }

        // Clear the thinkin' text
        llSetText( "" , ZERO_VECTOR , 1 );

        // If we know we need to re-scan, do so
        if( SuppressOwnerMessages ) {
            state setup;
        }

        state ready;
    }
}
