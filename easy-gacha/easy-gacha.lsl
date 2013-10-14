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
// StateStatus
//     default
//         0: default::state_entry()
//         1: Getting notecard line count
//         2: Lookup inventory notecard line
//         3: Lookup user name
//         4: Getting permission
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//
// Constants
//
////////////////////////////////////////////////////////////////////////////////

string SOURCE_CODE_MESSAGE = "This is free open source software. The source can be found at: https://github.com/zannalov/opensl";
list SERVER_OPTIONS = [
    HTTP_METHOD , "POST"
    , HTTP_MIMETYPE , "text/json;charset=utf-8"
    , HTTP_BODY_MAXLENGTH , 16384
    , HTTP_VERIFY_CERT , FALSE
    , HTTP_VERBOSE_THROTTLE , FALSE
    // Put any custom headers for auth here as: , HTTP_CUSTOM_HEADER , "..." , "..."
];
string SERVER_URL_CONFIG = ""; // Sent when object gets configured
string SERVER_URL_PURCHASE = ""; // Sent with each purchase
string SERVER_URL_STATS = ""; // The runtime ID gets appended to the end!

string CONFIG = "Easy Gacha Config";
integer LOW_MEMORY_THRESHOLD = 16000;
integer MAX_FOLDER_NAME_LENGTH = 63;
integer DEFAULT_PRICE = 25;

////////////////////////////////////////////////////////////////////////////////
//
// GLOBAL VARIABLES
//
////////////////////////////////////////////////////////////////////////////////

string ScriptName;
key Owner;
integer StateStatus = 0;
key DataServerRequest;
integer DataServerRequestIndex = 0;
key RuntimeId;
string RelevantConfig;

integer AllowRootPrim = FALSE;
integer AllowStatSend = TRUE;
integer AllowShowStats = TRUE;
integer CountConfigLines = 0;
integer FolderForOne = TRUE;

list Inventory = []; // Strided list of [ Inventory Name , Non Zero Positive Probability Number ]
integer CountInventory = 0; // List length (not strided item length)
float SumProbability = 0.0; // Sum

list Payees = []; // Strided list of [ Agent Key , Number of Lindens ]
integer CountPayees = 0; // List length (not strided item length)
integer Price = 0; // Sum

integer PayButton1 = 2; // Item count during config, price after config
integer PayButton2 = 5; // Item count during config, price after config
integer PayButton3 = 10; // Item count during config, price after config
integer PayAnyAmount = 1; // 0/1 during config ends, price after config

integer MaxPerPurchase = 100; // Not to exceed 100

integer LastTouch = 0;

////////////////////////////////////////////////////////////////////////////////
//
// GLOBAL METHODS
//
////////////////////////////////////////////////////////////////////////////////

Message( string msg , integer hoverText , integer ownerSay , integer whisper , integer ownerDialog ) {
    if( hoverText ) {
        llSetText( ScriptName + ":\n" + msg + "\n|\n|\n|\n|\n|" , <1,0,0>, 1 );
    }
    if( ownerSay ) {
        llOwnerSay( ScriptName + ": " + msg );
    }
    if( whisper ) {
        llWhisper( 0 , ScriptName + ": " + msg );
    }
    if( ownerDialog ) {
        llDialog( Owner , ScriptName + ":\n" + msg , [] , -1 ); // FORCED_DELAY 1.0 seconds
    }
}

ShowError( string msg ) {
    Message( "ERROR: " + msg , TRUE , TRUE , FALSE , TRUE );
}

BadConfig( string reason , string data ) {
    ShowError( reason + "Bad configuration on line " + (string)(DataServerRequestIndex + 1) + ": " + data );
}

NextConfigLine() {
    DataServerRequest = llGetNotecardLine( CONFIG , DataServerRequestIndex += 1 );
    Message( "Checking config " + (string)( DataServerRequestIndex * 100 / CountConfigLines ) + "%, please wait..." , TRUE , FALSE , FALSE , FALSE );
    llSetTimerEvent( 30.0 );
}

Give( key buyerId , integer lindensReceived ) {
    float random;
    integer selected;
    integer countItemsToSend = 0;
    list itemsToSend = [];
    string change = "";
    string itemPlural = " items ";
    string hasHave = "have ";
    string objectName = llGetObjectName();
    string displayName = llGetDisplayName( buyerId );

    // Let them know we're thinking
    Message( "Please wait, getting random items for " + displayName , TRUE , FALSE , FALSE , FALSE );

    // If not enough money
    if( lindensReceived < Price ) {
        // Send statistics to server if server is configured
        if( AllowStatSend && llStringLength( SERVER_URL_PURCHASE ) ) {
            llHTTPRequest( SERVER_URL_PURCHASE , SERVER_OPTIONS , llList2Json( JSON_ARRAY , [
                RuntimeId
                , buyerId
                , displayName
            ] ) );
        }

        // Give money back
        if( lindensReceived ) {
            llGiveMoney( buyerId , lindensReceived );
        }
        Message( "Sorry " + displayName + ", the price is L$" + (string)Price , FALSE , FALSE , TRUE , FALSE );
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
    if( lindensReceived ) {
        integer x;
        for( x = 0 ; x < CountPayees ; x += 2 ) {
            if( Owner != llList2Key( Payees , x ) ) {
                llGiveMoney( llList2Key( Payees , x ) , llList2Integer( Payees , x + 1 ) * countItemsToSend );
            }
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
    Message( "Thank you for your purchase, " + displayName + "! Your " + (string)countItemsToSend + itemPlural + hasHave + "been sent." + change , FALSE , FALSE , TRUE , FALSE );

    // Build the name of the folder to give
    string folderSuffix = ( " (Easy Gacha " + (string)countItemsToSend + itemPlural + llGetDate() + ")" );
    if( llStringLength( objectName ) + llStringLength( folderSuffix ) > MAX_FOLDER_NAME_LENGTH ) {
        objectName = ( llGetSubString( objectName , 0 , MAX_FOLDER_NAME_LENGTH - llStringLength( folderSuffix ) - 4 /* 3 for ellipses, 1 because this is end index, not count */ ) + "..." );
    }

    // Give the inventory
    if( 1 < countItemsToSend || FolderForOne ) {
        llGiveInventoryList( buyerId , objectName + folderSuffix , itemsToSend ); // FORCED_DELAY 3.0 seconds
    } else {
        llGiveInventory( buyerId , llList2String( itemsToSend , 0 ) ); // FORCED_DELAY 2.0 seconds
    }

    // Send statistics to server if server is configured
    if( AllowStatSend && llStringLength( SERVER_URL_PURCHASE ) ) {
        llHTTPRequest( SERVER_URL_PURCHASE , SERVER_OPTIONS , llList2Json( JSON_ARRAY , [
            RuntimeId
            , buyerId
            , displayName
            ] + itemsToSend
        ) );
    }

    // Clear the thinkin' text
    llSetText( "" , ZERO_VECTOR , 0.0 );
}

integer BooleanConfigOption( string s0 ) {
    s0 = llToLower( s0 );

    if( -1 != llListFindList( [ "yes" , "on" , "true" , "1" , "hai" , "yea" , "yep" , "+" ] , [ s0 ] ) ) {
        return TRUE;
    }

    if( -1 != llListFindList( [ "no" , "off" , "false" , "0" , "iie" , "nay" , "nope" , "-" ] , [ s0 ] ) ) {
        return FALSE;
    }

    return -1;
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
        RuntimeId = llGenerateKey();
        RelevantConfig = "";

        Message( "Initializing, please wait..." , TRUE , TRUE , FALSE , FALSE );

        // Config notecard not found at all
        if( INVENTORY_NOTECARD != llGetInventoryType( CONFIG ) ) {
            ShowError( "\"" + CONFIG + "\" is missing from inventory" );
            return;
        }

        // Full perm required to use llGetInventoryKey() successfully
        integer mask = llGetInventoryPermMask( CONFIG , MASK_OWNER );
        if( ! ( PERM_COPY     & mask ) ) {
            ShowError( "\"" + CONFIG + "\" is not copyable"     );
            return;
        }
        if( ! ( PERM_MODIFY   & mask ) ) {
            ShowError( "\"" + CONFIG + "\" is not modifiable"   );
            return;
        }
        if( ! ( PERM_TRANSFER & mask ) ) {
            ShowError( "\"" + CONFIG + "\" is not transferable" );
            return;
        }

        // No key returned despite permissions == no contents (which would blow
        // up llGetNotecardLine)
        if( NULL_KEY == llGetInventoryKey( CONFIG ) ) {
            ShowError( "\"" + CONFIG + "\" is new and has not yet been saved" );
            return;
        }

        StateStatus = 1;
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
        string s1;
        key k0;

        // Stop/reset timeout timer
        llSetTimerEvent( 0.0 );

        // Memory check before proceeding, having just gotten a new string
        if( MemoryError() ) {
            return;
        }

        if( 1 == StateStatus ) {
            CountConfigLines = (integer)data;
            StateStatus = 2;
            DataServerRequestIndex = -1; // Next method increments to zero
            NextConfigLine();
            return;
        }

        // If the result is the lookup of a line from the CONFIG
        if( 2 == StateStatus ) {
            // If the line is blank, skip it
            if( "" == data ) {
                NextConfigLine();
                return;
            }

            // If the line starts with a hash, skip it
            if( "#" == llGetSubString( data , 0 , 0 ) ) {
                NextConfigLine();
                return;
            }

            // Now that we're done processing the config notecard
            if( EOF == data ) {
                // Check that at least one was configured
                if( 0 == CountInventory ) {
                    // Attempt to populate inventory evenly - last ditch effort
                    // here, probably not what someone really wants, but just
                    // in case we'll try it
                    i1 = llGetInventoryNumber( INVENTORY_ALL );
                    for( i0 = 0 ; i0 < i1 ; i0 += 1 ) {
                        // Get inventory name
                        s0 = llGetInventoryName( INVENTORY_ALL , i0 );

                        // If the inventory is ourself or our config, skip it
                        if( ScriptName != s0 && CONFIG != s0 ) {
                            // Add inventory to list
                            SumProbability += 1.0;
                            Inventory = ( Inventory = [] ) + Inventory + [ s0 , 1.0 ]; // Voodoo for better memory usage
                            CountInventory += 2;

                            // Memory check before proceeding, having just changed a list
                            if( MemoryError() ) {
                                return;
                            }
                        }
                    }

                    // If we still don't have anything
                    if( 0 == CountInventory ) {
                        ShowError( "Bad configuration: No items were listed!" );
                        return;
                    }

                    // Give a hint as to why no items configured works
                    Message( ScriptName + ": WARNING: No items configured, using entire inventory of object with equal probabilities" , FALSE , TRUE , FALSE , TRUE );
                }

                // Check details of inventory
                for( i0 = 0 ; i0 < CountInventory ; i0 += 2 ) {
                    // Get name
                    s0 = llList2String( Inventory , i0 );

                    // Inventory must be copyable
                    if( ! ( PERM_COPY & llGetInventoryPermMask( s0 , MASK_OWNER ) ) ) {
                        ShowError( "\"" + s0 + "\" is not copyable. If given, it would disappear from inventory, so it cannot be used. " );
                        return;
                    }

                    // Inventory must be transferable
                    if( ! ( PERM_TRANSFER & llGetInventoryPermMask( s0 , MASK_OWNER ) ) ) {
                        ShowError( "\"" + s0 + "\" is not transferable. So how can I give it out? " );
                        return;
                    }
                }

                // If no payees were configured
                if( 0 == CountPayees ) {
                    // First attempt to get a number from the object description
                    i0 = (integer)llGetObjectDesc();
                    if( 0 == i0 && "0" != llGetObjectDesc() ) {
                        i0 = -1;
                    }

                    // If they entered a number less than zero (or didn't enter
                    // any number) in the description
                    if( 0 > i0 ) {
                        // Give a hint as to why no-payout is allowed
                        Message( "WARNING: No payouts configured, defaulting to L$" + (string)DEFAULT_PRICE + " to you." , FALSE , TRUE , FALSE , TRUE );

                        // Default to paying the owner
                        Payees = [ Owner , DEFAULT_PRICE ];
                        CountPayees = 2;
                    } else {
                        // Give a hint that we used the fallback
                        Message( "Will give L$" + (string)i0 + " to you for each item purchased. (Price taken from object description)" , FALSE , TRUE , FALSE , FALSE );
                    }
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
                    Message( "\"" + llList2String( Inventory , i0 ) + "\" has a probability of " + (string)( f0 * 100 ) + "%" , FALSE , TRUE , FALSE , FALSE );
                }

                // Set payment option
                if( 0 == PayAnyAmount ) { PayAnyAmount = PAY_HIDE; } else { PayAnyAmount  = Price; }
                if( 0 == PayButton1   ) { PayButton1   = PAY_HIDE; } else { PayButton1   *= Price; }
                if( 0 == PayButton2   ) { PayButton2   = PAY_HIDE; } else { PayButton2   *= Price; }
                if( 0 == PayButton3   ) { PayButton3   = PAY_HIDE; } else { PayButton3   *= Price; }

                // If price is zero, then there's no way to know how many items
                // someone wants at a time without this
                if( !Price ) {
                    MaxPerPurchase = 1;
                }

                // Memory check before proceeding, having just tested a bunch of things and potentially changed things
                if( MemoryError() ) {
                    return;
                }

                // Load first line of config
                Message( "Checking payouts 0%, please wait..." , TRUE , FALSE , FALSE , FALSE );
                StateStatus = 3;
                DataServerRequest = llRequestUsername( llList2Key( Payees , DataServerRequestIndex = 0 ) );
                llSetTimerEvent( 30.0 );
                return;
            }

            // Add line to relevant config
            RelevantConfig += data + "\n";

            // Process new line
            i0 = llSubStringIndex( data , " " );

            // If there's no space on the line, it's invalid
            if( 0 >= i0 ) {
                BadConfig( "" , data );
                return;
            }

            // If there's nothing after the space, it's invalid
            if( llStringLength( data ) - 1 == i0 ) {
                BadConfig( "" , data );
                return;
            }

            // Split the verb from the config value
            s1 = llToLower( llGetSubString( data , 0 , i0 - 1 ) );
            s0 = llGetSubString( data , i0 + 1 , -1 );

            // Handle an item entry
            if( "item" == s1 ) {
                // Find second space
                i0 = llSubStringIndex( s0 , " " );

                // If there's not another space on the line, it's invalid
                if( 0 >= i0 ) {
                    BadConfig( "" , data );
                    return;
                }

                // Pull the probability number off the front of the string
                f0 = (float)llGetSubString( s0 , 0 , i0 );

                // If the probability is out of bounds
                if( 0.0 >= f0 ) {
                    BadConfig( "Number must be greater than zero. " , data );
                    return;
                }

                // Name must be provided
                if( llStringLength( s0 ) - 1 == i0 ) {
                    BadConfig( "Inventory name must be provided. " , data );
                    return;
                }

                // Grab inventory name off string
                s0 = llGetSubString( s0 , i0 + 1 , -1 );

                // Inventory must exist
                if( INVENTORY_NONE == llGetInventoryType( s0 ) ) {
                    BadConfig( "Cannot find \"" + s0 + "\" in inventory. " , data );
                    return;
                }

                // If they put the same item in twice
                if( -1 != llListFindList( Inventory , [ s0 ] ) ) {
                    BadConfig( "\"" + s0 + "\" was listed twice. Did you mean to list it once with a rarity of " + (string)( llList2Float( Inventory , llListFindList( Inventory , [ s0 ] ) + 1 ) + f0 ) + "? " , data );
                    return;
                }

                // Store the configuration and add probably to the sum
                SumProbability += f0;
                Inventory = ( Inventory = [] ) + Inventory + [ s0 , f0 ]; // Voodoo for better memory usage
                CountInventory += 2;

                // Memory check before proceeding, having just messed with a list
                if( MemoryError() ) {
                    return;
                }

                // Load next line of config
                NextConfigLine();
                return;
            } // end if( "item" ... )

            // Handle a payout entry
            // Valid money formats: L$#, $#, #, #L
            if( "payout" == s1 ) {
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
                    BadConfig( "" , data );
                    return;
                }

                // Pull the payment number off the front of the string
                i1 = (integer)llGetSubString( s0 , 0 , i0 - 1 );

                // If the payment is out of bounds
                if( 0 > i1 ) {
                    BadConfig( "L$ to give must be greater than or equal to zero. " , data );
                    return;
                }
                if( 0 == i1 && "0" != llGetSubString( s0 , 0 , i0 - 1 ) ) {
                    BadConfig( "L$ to give must be greater than or equal to zero. " , data );
                    return;
                }

                // Name must be provided
                if( llStringLength( s0 ) - 1 == i0 ) {
                    BadConfig( "User key must be provided. " , data );
                    return;
                }

                // Grab agent key off the string
                s0 = llGetSubString( s0 , i0 + 1 , -1 );

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

                    BadConfig( s0 + " was listed twice. Did you mean to list them once with a payout of " + (string)( llList2Integer( Payees , llListFindList( Payees , [ k0 ] ) + 1 ) + i1 ) + "? " , data );
                    return;
                }

                // Store the configuration
                Price += i1;
                Payees = ( Payees = [] ) + Payees + [ k0 , i1 ]; // Voodoo for better memory usage
                CountPayees += 2;

                // Memory check before proceeding, having just messed with a list
                if( MemoryError() ) {
                    return;
                }

                // Load next line of config
                NextConfigLine();
                return;
            }

            // Advanced option
            if( "buy_button" == s1 ) {
                // Find second space
                i0 = llSubStringIndex( s0 , " " );

                // If there's not another space on the line, it's invalid
                if( 0 >= i0 ) {
                    BadConfig( "" , data );
                    return;
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
                    BadConfig( "buy_button must have an item count greater than one. " , data );
                    return;
                }

                // Store button value
                if( 1 == i0 ) {
                    PayButton1 = i1;
                } else if( 2 == i0 ) {
                    PayButton2 = i1;
                } else if( 3 == i0 ) {
                    PayButton3 = i1;
                } else {
                    BadConfig( "Which button number did you mean to put here? " , data );
                    return;
                }

                // Memory check before proceeding, having just completed this line
                if( MemoryError() ) {
                    return;
                }

                // Load next line of config
                NextConfigLine();
                return;
            }

            // Advanced option
            if( "pay_any_amount" == s1 ) {
                if( -1 == ( PayAnyAmount = BooleanConfigOption( s0 ) ) ) {
                    BadConfig( "" , data );
                    return;
                }

                // Memory check before proceeding, having just completed this line
                if( MemoryError() ) {
                    return;
                }

                // Load next line of config
                NextConfigLine();
                return;
            }

            // Advanced option
            if( "allow_send_stats" == s1 ) {
                if( -1 == ( AllowStatSend = BooleanConfigOption( s0 ) ) ) {
                    BadConfig( "" , data );
                    return;
                }

                // Memory check before proceeding, having just completed this line
                if( MemoryError() ) {
                    return;
                }

                // Load next line of config
                NextConfigLine();
                return;
            }

            // Advanced option
            if( "allow_show_stats" == s1 ) {
                if( -1 == ( AllowShowStats = BooleanConfigOption( s0 ) ) ) {
                    BadConfig( "" , data );
                    return;
                }

                // Memory check before proceeding, having just completed this line
                if( MemoryError() ) {
                    return;
                }

                // Load next line of config
                NextConfigLine();
                return;
            }

            // Advanced option
            if( "buy_max_items" == s1 ) {
                // Get config value
                i1 = (integer)s0;

                // If the payment is out of bounds
                if( 0 >= i1 || 100 < i1 ) {
                    BadConfig( "" , data );
                    return;
                }

                // Store the new value
                MaxPerPurchase = i1;

                // Memory check before proceeding, having just completed this line
                if( MemoryError() ) {
                    return;
                }

                // Load next line of config
                NextConfigLine();
                return;
            }

            // Advanced option
            if( "allow_root_prim" == s1 ) {
                if( -1 == ( AllowRootPrim = BooleanConfigOption( s0 ) ) ) {
                    BadConfig( "" , data );
                    return;
                }

                // Memory check before proceeding, having just completed this line
                if( MemoryError() ) {
                    return;
                }

                // Load next line of config
                NextConfigLine();
                return;
            }

            // Advanced option
            if( "folder_for_one" == s1 ) {
                if( -1 == ( FolderForOne = BooleanConfigOption( s0 ) ) ) {
                    BadConfig( "" , data );
                    return;
                }

                // Memory check before proceeding, having just completed this line
                if( MemoryError() ) {
                    return;
                }

                // Load next line of config
                NextConfigLine();
                return;
            }

            // Completely unknown verb
            BadConfig( "" , data );
            return;
        } // end if( 2 == StateStatus )

        // If the result is the lookup of a user from the Payees
        if( 3 == StateStatus ) {
            // Note that this user was looked up correctly and report the amount to be given
            Message( "Will give L$" + (string)llList2Integer( Payees , DataServerRequestIndex + 1 ) + " to " + data + " for each item purchased." , FALSE , TRUE , FALSE , FALSE );

            // Increment to next value
            DataServerRequestIndex += 2;
            Message( "Checking payouts " + (string)( DataServerRequestIndex * 100 / CountPayees ) + "%, please wait..." , TRUE , FALSE , FALSE , FALSE );

            // Memory check before proceeding, having just completed this check
            if( MemoryError() ) {
                return;
            }

            // If there are more to look up
            if( DataServerRequestIndex < CountPayees ) {
                // Look up the next one
                DataServerRequest = llRequestUsername( llList2Key( Payees , DataServerRequestIndex ) );
                llSetTimerEvent( 30.0 );
                return;
            }

            // Report total price
            Message( "The total price is L$" + (string)Price , FALSE , TRUE , FALSE , FALSE );

            // Get permission to give money (so we can give refunds at least)
            Message( "Getting permission..." , TRUE , TRUE , FALSE , FALSE );
            llRequestPermissions( Owner , PERMISSION_DEBIT );
            llSetTimerEvent( 30.0 );
            StateStatus = 4;
        }
    }

    timer() {
        // Reset/stop timer
        llSetTimerEvent( 0.0 );

        if( 1 == StateStatus ) {
            ShowError( "Timed out while trying to get line count for \"" + CONFIG );
        } else if( 2 == StateStatus ) {
            ShowError( "Timed out while trying to fetch line " + (string)(DataServerRequestIndex + 1) + " from \"" + CONFIG );
        } else if( 3 == StateStatus ) {
            ShowError( "Timed out while trying to look up user key. The user \"" + llList2String( Payees , DataServerRequestIndex ) + "\" doesn't seem to exist, or the data server is being too slow." );
        } else if( 4 == StateStatus ) {
            ShowError( "Timed out while trying to get permission. Please touch to reset and make sure to grant the money permission when asked." );
        } else {
            ShowError( "Timed out." );
        }
    }

    run_time_permissions( integer permissionMask ) {
        if( ! ( PERMISSION_DEBIT & permissionMask ) ) {
            llResetScript();
        } else {
            llSetTimerEvent( 0.0 );
            state ready;
        }
    }

    state_exit() {
        if( AllowStatSend && llStringLength( SERVER_URL_CONFIG ) ) {
            llHTTPRequest( SERVER_URL_CONFIG , SERVER_OPTIONS , llList2Json( JSON_ARRAY , [
                RuntimeId
                , RelevantConfig
                ]
            ) );
        }

        Message( ScriptName + ": " + SOURCE_CODE_MESSAGE , FALSE , TRUE , FALSE , FALSE );
        Message( ScriptName + ": Ready! Free memory: " + (string)llGetFreeMemory() , FALSE , TRUE , TRUE , FALSE );
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

        if( Price ) {
            llSetClickAction( CLICK_ACTION_PAY );
            llSetPayPrice( PayAnyAmount , [ Price , PayButton1 , PayButton2 , PayButton3 ] );
            llSetTouchText( "Info" );
        } else {
            llSetClickAction( CLICK_ACTION_TOUCH );
            llSetPayPrice( PAY_HIDE , [ PAY_HIDE , PAY_HIDE , PAY_HIDE , PAY_HIDE ] );
            llSetTouchText( "Play" );
        }
    }

    // Rate limited
    touch_end( integer detected ) {
        integer statsPossible = ( AllowStatSend && llStringLength( SERVER_URL_STATS ) );
        integer whisperStats = ( statsPossible && AllowShowStats && LastTouch != llGetUnixTime() );
        integer ownerSayStats = FALSE;

        // For each person that touched
        while( 0 <= ( detected -= 1 ) ) {
            // This is the exception which will be direct to owner
            if( llDetectedKey( detected ) == Owner ) {
                // Only if we're not going to whisper it
                if( statsPossible && !AllowShowStats ) {
                    ownerSayStats = TRUE;
                }

                // Memory will only be shown to owner now
                Message( "Script free memory is: " + (string)llGetFreeMemory() , FALSE , TRUE , FALSE , FALSE );
            }

            // If price is zero, has to be touch based
            if( !Price ) {
                Give( llDetectedKey( detected ) , 0 );
            }
        }

        // Whisper source code message
        Message( SOURCE_CODE_MESSAGE , FALSE , FALSE , TRUE , FALSE );

        // Otherwise stats get whispered
        if( whisperStats || ownerSayStats ) {
            Message( ( "Want to see some statistics for this object? Click this link: " + SERVER_URL_STATS + (string)RuntimeId ) , FALSE , ownerSayStats , whisperStats , FALSE );
        }

        LastTouch = llGetUnixTime();
    }

    // Switching states here would prevent further orders from being placed
    // while this one is being processed, but would also flush the event queue,
    // which would kill any orders placed in parallel. We have to honor the
    // event queue, so... do things as fast and efficiently as we can
    money( key buyerId , integer lindensReceived ) {
        Give( buyerId , lindensReceived );
    }
}
