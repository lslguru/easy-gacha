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
// Notes
////////////////////////////////////////////////////////////////////////////////

//  DataServerRequests Strided list of:
//      x+0:    request key
//      x+1:    http response key if request was via http server
//      x+2:    integer type of request that was made

//  DataServerRequests Types
//      1   goo.gl for info URL
//      2   goo.gl for admin URL
//      3   user name lookup
//      4   display name lookup
//      5   number of notecard lines
//      6   notecard line

//  CONSTANTS
//      VERSION                     5.0
//      CONFIG_SCRIPT_URL           http:\/\/lslguru.github.io/easy-gacha/v5/easy-gacha.js
//      MAX_FOLDER_NAME_LENGTH      63
//      DEFAULT_MAX_PER_PURCHASE    50
//      ASSET_SERVER_TIMEOUT        15.0
//      ASSET_SERVER_TIMEOUT_CHECK  5.0
//      REQUEST_TIMEOUT             30.0
//      LOW_MEMORY                  4096

//  DEFAULT_MAX_PER_PURCHASE: We have to build a list in memory of the items to
//      be given in a folder. To prevent out of memory errors and exceedingly
//      long-running scripts (e.g.  price is L$1 and gave it L$10,000), a max
//      is enforced. The owner can choose a value below this, but not above
//      this.  Because of an interesting quirk of the Grey Goo Fence,
//      unconfigured notecards handed out in excess of 50 will be counted as
//      bad behavior, so even though we can probably reliably handle 100 here,
//      it is limited to 50.

////////////////////////////////////////////////////////////////////////////
// Configuration Values
////////////////////////////////////////////////////////////////////////////

list Items; // Inventory names, strings <= 63 chars in length
list Rarity; // float
list Limit; // integer, -1 == infinite
list Bought; // stats counter
list Payouts; // strided: [ avatar key , lindens ]
integer MaxPerPurchase = 50 /*DEFAULT_MAX_PER_PURCHASE*/;
integer PayPrice = PAY_HIDE; // Price || PAY_HIDE || PAY_DEFAULT (should be sum of Payouts)
integer PayPriceButton0 = PAY_HIDE; // Price || PAY_HIDE || PAY_DEFAULT (multiple of sum of Payouts)
integer PayPriceButton1 = PAY_HIDE; // Price || PAY_HIDE || PAY_DEFAULT (multiple of sum of Payouts)
integer PayPriceButton2 = PAY_HIDE; // Price || PAY_HIDE || PAY_DEFAULT (multiple of sum of Payouts)
integer PayPriceButton3 = PAY_HIDE; // Price || PAY_HIDE || PAY_DEFAULT (multiple of sum of Payouts)
integer FolderForSingleItem = TRUE;
integer RootClickAction = -1; // -1 = user not asked, FALSE, TRUE
integer Group = FALSE; // If group may administer
string Email; // Who to email after each play
key Im; // Who to IM after each play
integer AllowHover = TRUE; // Whether or not to allow hovertext output
integer MaxBuys = -1; // Infinite
integer Configured; // boolean - web checks only
string Extra; // extra data that the UI wants to store
integer ApiPurchasesEnabled; // If we should send signals on purchases
integer ApiItemsGivenEnabled; // If we should send signals for each item (floods object)

////////////////////////////////////////////////////////////////////////////
// Runtime Values
////////////////////////////////////////////////////////////////////////////

integer Ready; // Passes internal checks as well as web checks
key AdminKey; // Used to indicate if person has rights to modify configs
string BaseUrl; // Requested and hopefully received
string ShortenedInfoUrl; // Hand this out instead of the full URL
string ShortenedAdminUrl; // Hand this out instead of the full URL
key Owner; // More memory efficient to only update when it could be changed
string ScriptName; // More memory efficient to only update when it could be changed
integer HasPermission; // More memory efficient to only update when it could be changed
list DataServerRequests; // List of the requests we have pending
integer TotalPrice; // Updated when Payouts is updated, sum
integer TotalBought; // Updated when Bought is updated
integer TotalLimit; // Updated when Limit is updated
integer HasNoCopyItemsForSale; // If ANY item with no-zero limit and rarity set is no-copy
float TotalEffectiveRarity; // Updated when Rarity or Limit are updated
integer CountItems; // Updated when Items is updated
integer CountPayouts; // Updated when Payouts is updated - total elements, not stride elements

////////////////////////////////////////////////////////////////////////////
// Application
////////////////////////////////////////////////////////////////////////////

Registry( list data ){} // Stub, gets replaced in official copy

string RootObjectName() {
    return llList2String( llGetLinkPrimitiveParams( (!!llGetLinkNumber()) , [ PRIM_NAME ] ) , 0 );
}

Hover( string msg ) {
    if( AllowHover ) {
        if( msg ) {
            llSetText( RootObjectName() + ": " + ScriptName + ":\n" + msg + "\n|\n|\n|\n|\n|\n_\nV" , <1,0,0> , 1 );
        } else {
            llSetText( "" , ZERO_VECTOR , 1 );
        }
    }
}

RequestUrl() {
    llReleaseURL( BaseUrl );

    AdminKey = llGenerateKey();
    BaseUrl = "";
    ShortenedInfoUrl = "";
    ShortenedAdminUrl = "";

    llRequestURL();

    Update();
}

integer ItemUsable( integer itemIndex ) {
    string inventoryName = llList2String( Items , itemIndex );
    integer limit = llList2Integer( Limit , itemIndex );

    // If inventory exists
    if( INVENTORY_NONE != llGetInventoryType( inventoryName ) ) {
        // And is transferable
        if( PERM_TRANSFER & llGetInventoryPermMask( inventoryName , MASK_OWNER ) ) {
            // And isn't sold out
            if( -1 == limit || llList2Integer( Bought , itemIndex ) < limit ) {
                // Then it can be used
                return TRUE;
            }
        }
    }

    // Otherwise it cannot be used
    return FALSE;
}

Update() {
    Owner = llGetOwner();
    ScriptName = llGetScriptName();
    HasPermission = ( ( llGetPermissionsKey() == Owner ) && llGetPermissions() & PERMISSION_DEBIT );

    // Sum of all numbers, which will safely skip agent keys
    TotalPrice = (integer)llListStatistics( LIST_STAT_SUM , Payouts );

    // Build total rarity and limit
    integer itemIndex;
    TotalLimit = 0;
    TotalEffectiveRarity = 0.0;
    HasNoCopyItemsForSale = FALSE;
    for( itemIndex = 0 ; itemIndex < CountItems ; ++itemIndex ) {
        // If the item is usable, meaning exists and has rarity and is
        // transferable, etc...
        if( ItemUsable( itemIndex ) ) {
            // Add to total rarity
            TotalEffectiveRarity += llList2Float( Rarity , itemIndex );

            // If limit is -1 meaning unlimited, don't add it to the total,
            // otherwise add the qty remaining for this item
            if( 0 < llList2Integer( Limit , itemIndex ) ) {
                TotalLimit += llList2Integer( Limit , itemIndex ) - llList2Integer( Bought , itemIndex );
            }

            // Mark if we're in the special no-copy mode (any eligible item causes this)
            if( ! ( PERM_COPY & llGetInventoryPermMask( llList2String( Items , itemIndex ) , MASK_OWNER ) ) ) {
                HasNoCopyItemsForSale = TRUE;
            }
        }
    }

    // Default to false
    Ready = FALSE;

    // If UI thinks we're ready
    if( Configured ) {
        // Default to true
        Ready = TRUE;

        // Conditions which make it go offline. If any of these fail, fall
        // back to false

        if( TotalPrice && !HasPermission ) {
            // If we're collecting any amount of money, we need to get
            // debit permission to be able to give change
            Ready = FALSE;
        }

        if( -1 != MaxBuys && TotalBought >= MaxBuys ) {
            // This can occur even if all items are unlimited in quantity
            Ready = FALSE;
        }

        if( 0.0 == TotalEffectiveRarity ) {
            // If no items are effective, they've either run out of
            // inventory, don't exist, or are not transferable...
            Ready = FALSE;
        }

        if( Group && llSameGroup( NULL_KEY ) ) {
            // If we're in group-only mode but no group was set...
            Ready = FALSE;
        }

        if( llGetFreeMemory() < 4096 /*LOW_MEMORY*/ ) {
            // If we're in imminent danger of running out of memory
            Ready = FALSE;
        }
    }

    // Default values of these variables are to not show pay buttons.
    // This should prevent any new purchases until a price has been
    // set.
    if( Ready && TotalPrice ) {
        if( HasNoCopyItemsForSale ) {
            llSetPayPrice( PAY_HIDE , [ TotalPrice , PAY_HIDE , PAY_HIDE , PAY_HIDE ] );
        } else {
            llSetPayPrice( PayPrice , [ PayPriceButton0 , PayPriceButton1 , PayPriceButton2 , PayPriceButton3 ] );
        }
    } else {
        llSetPayPrice( PAY_HIDE , [ PAY_HIDE , PAY_HIDE , PAY_HIDE , PAY_HIDE ] );
    }

    // Set touch text:
    // If needs config, label "Config"
    // If price is zero and Ready, "Play"
    // If price is !zero, "Info" because Pay button plays
    if( !Ready ) {
        llSetTouchText( "Config" );
    } else if( TotalPrice ) {
        llSetTouchText( "Info" );
    } else {
        llSetTouchText( "Play" );
    }

    // Set object action only if we're not the root prim of a linked set or
    // they've explicitly allowed it
    if( TRUE == RootClickAction || LINK_ROOT != llGetLinkNumber() ) {
        // If we're ready to go and price is not zero, then pay is the
        // default action, otherwise touch will always be the default (for
        // play or info or config)
        if( Ready && TotalPrice ) {
            llSetClickAction( CLICK_ACTION_PAY );
        } else {
            llSetClickAction( CLICK_ACTION_TOUCH );
        }
    }

    // Far more simplistic config statement
    if( Ready ) {
        if( -1 != llListFindList( DataServerRequests , [ 1 ] ) || -1 != llListFindList( DataServerRequests , [ 2 ] ) ) {
            Hover( "Working, please wait..." );
        } else {
            Hover( "" );
        }
    } else if( !Configured ) {
        Hover( "Configuration needed, please touch this object" );
    } else if( llGetFreeMemory() < 4096 /*LOW_MEMORY*/ ) {
        Hover( "Script memory is low, please export configuration and reset script" );
    } else if( TotalPrice && !HasPermission ) {
        Hover( "Need debit permission, please touch this object" );
        llRequestPermissions( Owner , PERMISSION_DEBIT );
    } else if( Group && llSameGroup( NULL_KEY ) ) {
        Hover( "Please set a group for this object" );
    } else if( -1 != MaxBuys && TotalBought >= MaxBuys ) {
        Hover( "No more items to give, sorry" );
    } else if( 0.0 == TotalEffectiveRarity ) {
        Hover( "No more items to give, sorry" );
    } else {
        Hover( "Configuration needed, please touch this object" );
    }

    // Ping registry
    Registry( [
        "update"
        , BaseUrl
        , AdminKey
        , Ready
    ] );
}

Shorten( string url , integer typeId ) {
    DataServerRequests += [
        llHTTPRequest(
            "https:\/\/www.googleapis.com/urlshortener/v1/url"
            , [
                HTTP_METHOD , "POST"
                , HTTP_MIMETYPE , "application/json"
                , HTTP_BODY_MAXLENGTH , 16384
                , HTTP_VERBOSE_THROTTLE , FALSE
            ]
            , llJsonSetValue( "{}" , [ "longUrl" ] , url )
        )
        , NULL_KEY
        , typeId
    ];

    // Reset cleanup timer
    llSetTimerEvent( 0.0 );
    llSetTimerEvent( 30.0 /*REQUEST_TIMEOUT*/ );
}

Play( key buyerId , integer lindensReceived ) {
    // Cache this because it's used several times
    string displayName = llGetDisplayName( buyerId );

    // Visually note that we're now in the middle of something
    Hover( "Please wait, getting random items for: " + displayName );

    // This is only used when playing
    integer hasUnlimitedItems = ( -1 != llListFindList( Limit , [ -1 ] ) );

    // Figure out how many objects we need to give
    integer totalItems;
    if( TotalPrice ) {
        totalItems = lindensReceived / TotalPrice;
    } else {
        totalItems = 1;
    }

    // If we can only hand out one at a time anyway
    if( HasNoCopyItemsForSale ) {
        totalItems = 1;
    }

    // If their order would exceed the hard-coded limit
    if( totalItems > MaxPerPurchase ) {
        totalItems = MaxPerPurchase;
    }

    // If their order would exceed the total allowed purchases
    if( -1 != MaxBuys && totalItems > MaxBuys - TotalBought ) {
        totalItems = MaxBuys - TotalBought;
    }

    // If their order would exceed the total available supply
    if( !hasUnlimitedItems && totalItems > TotalLimit ) {
        totalItems = TotalLimit;
    }

    // If it's set to group-only play and they're not in the right group
    if( Group && !llSameGroup( buyerId ) ) {
        totalItems = 0;
    }

    // Iterate until we've met our total, because it should now be
    // guaranteed to happen
    list itemsToSend = []; // We have to pass a list to llGiveInventoryList... in for a penny, in for a pound!
    float random;
    integer itemIndex;
    while( llGetListLength( itemsToSend ) < totalItems ) {
        // Indicate our progress
        Hover( "Please wait, getting random item " + (string)llGetListLength( itemsToSend ) + " of " + (string)totalItems + " for: " + displayName );

        // Generate a random number which is between [ TotalEffectiveRarity , 0.0 )
        random = TotalEffectiveRarity - llFrand( TotalEffectiveRarity );

        // Find the item's index
        for( itemIndex = 0 ; itemIndex < CountItems && random > 0.0 ; ++itemIndex ) {
            // Only items which are usable are considered
            if( ItemUsable( itemIndex ) ) {
                // Decrement the random number
                random -= llList2Float( Rarity , itemIndex );
            }
        }

        // Last iteration of the loop increments the index past where we want
        --itemIndex;

        // llGiveInventoryList uses the inventory names
        itemsToSend += [ llList2String( Items , itemIndex ) ];

        // Mark this item as bought, increasing the count
        Bought = llListReplaceList( Bought , [ llList2Integer( Bought , itemIndex ) + 1 ] , itemIndex , itemIndex );
        ++TotalBought;

        // If it's no longer usable (inventory has run out)
        if( ! ItemUsable( itemIndex ) ) {
            // Reduce rarity total
            TotalEffectiveRarity -= llList2Float( Rarity , itemIndex );
        }
    }

    // Fix verbiage, just because it bothers me
    string itemPlural = " items ";
    string hasHave = "have ";
    if( 1 == totalItems ) {
        itemPlural = " item ";
        hasHave = "has ";
    }

    // Build the name of the folder to give. Start by getting the name of
    // the prim, or barring that, the name of the object
    string objectName = llList2String( llGetLinkPrimitiveParams( LINK_THIS , [ PRIM_NAME ] ) , 0 );
    if( "" == objectName || "Object" == objectName ) {
        objectName = RootObjectName();
    }
    string folderSuffix = ( " (" + ScriptName + ": " + (string)totalItems + itemPlural + llGetDate() + ")" );
    if( llStringLength( objectName ) + llStringLength( folderSuffix ) > 63 /*MAX_FOLDER_NAME_LENGTH*/ ) {
        // 4 == 3 for ellipses + 1 because this is end index, not count
        objectName = ( llGetSubString( objectName , 0 , 63 /*MAX_FOLDER_NAME_LENGTH*/ - llStringLength( folderSuffix ) - 4 ) + "..." );
    }

    // If too much money was given or they weren't able to play
    string change = "";
    lindensReceived -= ( totalItems * TotalPrice );
    if( lindensReceived ) {
        llGiveMoney( buyerId , lindensReceived );
        change = " Your change is L$" + (string)lindensReceived;
    }

    // Distribute the payouts
    integer payoutIndex;
    for( payoutIndex = 0 ; payoutIndex < CountPayouts ; payoutIndex += 2 ) { // Strided list
        // Only if the payment isn't to the owner and is more than L$0
        if( llList2Key( Payouts , payoutIndex ) != Owner && 0 < llList2Integer( Payouts , payoutIndex + 1 ) ) {
            llGiveMoney( llList2Key( Payouts , payoutIndex ) , llList2Integer( Payouts , payoutIndex + 1 ) * totalItems );
        }
    }

    // Give the inventory
    Hover( "Please wait, giving items to: " + displayName );
    if( 1 < totalItems || ( FolderForSingleItem && !HasNoCopyItemsForSale ) ) {
        llGiveInventoryList( buyerId , objectName + folderSuffix , itemsToSend ); // FORCED_DELAY 3.0 seconds
    } else {
        llGiveInventory( buyerId , llList2String( itemsToSend , 0 ) ); // FORCED_DELAY 2.0 seconds
    }

    // Thank them for their purchase
    llWhisper( 0 , ScriptName + ": Thank you for your purchase, " + displayName + "! Your " + (string)totalItems + itemPlural + hasHave + "been sent." + change );

    // Ping registry with play info
    Registry( [
        "play"
        , buyerId
        , totalItems
    ] + itemsToSend );

    // Reports
    if( Im ) {
        llInstantMessage( Owner , ScriptName + ": User " + displayName + " (" + llGetUsername(buyerId) + ") just received " + (string)totalItems + " items. " + ShortenedInfoUrl ); // FORCED_DELAY 2.0 seconds
    }
    if( Email ) {
        llEmail( Email , "Easy Gacha Played" , displayName + " (" + llGetUsername(buyerId) + ") just received the following items:\n\n" + llDumpList2String( itemsToSend , "\n" ) ); // FORCED_DELAY 20.0 seconds
    }

    // API calls
    if( ApiPurchasesEnabled ) {
        llMessageLinked( LINK_SET , 3000168 , (string)totalItems , buyerId );
    }
    if( ApiItemsGivenEnabled ) {
        for( itemIndex = 0 ; itemIndex < totalItems ; ++itemIndex ) {
            llMessageLinked( LINK_SET , 3000169 , llList2String( itemsToSend , itemIndex ) , buyerId );
        }
    }

    // Double check everything before we allow anyone else to play
    Update();
}

default {
    state_entry() {
        RequestUrl();
    }

    attach( key avatarId ) {
        Update();
    }

    on_rez( integer rezParam ) {
        RequestUrl();
    }

    run_time_permissions( integer permissionMask ) {
        Update();
    }

    changed( integer changeMask ) {
        // If they change the inventory and remove something that was
        // configured, we'll count that as alright and just recalculate the
        // probabilities ( CHANGED_INVENTORY & changeMask )

        // 1920 == ( CHANGED_OWNER | CHANGED_REGION_START | CHANGED_REGION | CHANGED_TELEPORT )
        if( 1920 & changeMask ) {
            RequestUrl(); // This will perform an Update
        } else {
            Update();
        }
    }

    money( key buyerId , integer lindensReceived ) {
        // During handout, there is still a "money" event which can capture
        // any successful transactions (so none are missed), but by setting
        // ALL the pay buttons to PAY_HIDE, which should prevent any new
        // purchases while it is processing.
        llSetPayPrice( PAY_HIDE , [ PAY_HIDE , PAY_HIDE , PAY_HIDE , PAY_HIDE ] );

        Play( buyerId , lindensReceived );
    }

    http_request( key requestId , string httpMethod , string requestBody ) {
        integer responseStatus = 400;
        string responseBody = "Bad request";
        integer responseContentType = CONTENT_TYPE_TEXT;

        if( URL_REQUEST_GRANTED == httpMethod ) {
            BaseUrl = requestBody;
            ShortenedInfoUrl = ( BaseUrl + "/" );
            ShortenedAdminUrl = ( BaseUrl + "/#admin/" + (string)AdminKey );

            Shorten( ShortenedInfoUrl , 1 );
            Shorten( ShortenedAdminUrl , 2 );

            Update();
        }

        if( URL_REQUEST_DENIED == httpMethod ) {
            llOwnerSay( ScriptName + ": Unable to get a URL. This Easy Gacha cannot be configured until one becomes available: " + requestBody );
        }

        if( "get" == llToLower( httpMethod ) ) {
            if( "/" == llGetHTTPHeader( requestId , "x-path-info" ) ) {
                // NOTE: Don't change the xhtml directly here, change it in the HTML file first then remove leading whitespace, convert newlines, and copy it to here
                responseStatus = 200;
                responseBody = "<!DOCTYPE html PUBLIC \"-\/\/W3C\/\/DTD XHTML 1.0 Transitional\/\/EN\" \"http:\/\/www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n<html xmlns=\"http:\/\/www.w3.org/1999/xhtml\">\n<head>\n<script type=\"text/javascript\">document.easyGachaScriptVersion = 5.0; // VERSION</script>\n<script type=\"text/javascript\" src=\"http:\/\/lslguru.com/gh-pages/v5/easy-gacha.js\"></script><!-- CONFIG_SCRIPT_URL -->\n<script type=\"text/javascript\">\nif( !window.easyGachaLoaded )\nalert( 'Error loading scripts, please refresh page' );\n</script>\n</head>\n<body>\n<noscript>Please load this in your normal web browser with JavaScript enabled.</noscript>\n</body>\n</html>\n";
                responseContentType = CONTENT_TYPE_XHTML;
            }
        }

        if( "post" == llToLower( httpMethod ) ) {
            responseStatus = 200;
            responseContentType = CONTENT_TYPE_JSON;
            responseBody = "null";

            integer isAdmin = FALSE;

            // Get input
            string verb = llGetHTTPHeader( requestId , "x-path-info" );
            list requestBodyParts = llJson2List( requestBody );

            // Determine if the user is an admin by the presence of the
            // key, and strip it off the front
            if( "/" + (string)AdminKey + "/" == llGetSubString( verb , 0 , 37 ) ) {
                isAdmin = TRUE;
                verb = llDeleteSubString( verb , 0 , 37 );
                Configured = FALSE;
            }

            // Separate the verb and subject on input
            string subject = llGetSubString( verb , llSubStringIndex( verb , "/" ) + 1 , -1 );
            verb = llGetSubString( verb , 0 , llSubStringIndex( verb , "/" ) - 1 );

            // Strip trailing slash
            if( -1 != llSubStringIndex( subject , "/" ) ) {
                subject = llDeleteSubString( subject , llSubStringIndex( subject , "/" ) , -1 );
            }

            if( "item" == subject ) {
                if( isAdmin ) {
                    if( "post" == verb ) {
                        Items += [ llList2String( requestBodyParts , 0 ) ];
                        Rarity += [ llList2Float( requestBodyParts , 1 ) ];
                        Limit += [ llList2Integer( requestBodyParts , 2 ) ];
                        Bought += [ 0 ]; // Placeholder for counter
                        ++CountItems;
                        requestBodyParts = [ CountItems - 1 ];
                    }

                    if( "delete" == verb ) {
                        Items = [];
                        Rarity = [];
                        Limit = [];
                        Bought = [];
                        CountItems = 0;
                        responseBody = "true";
                    }
                }

                if( llList2Integer( requestBodyParts , 0 ) < CountItems ) {
                    string inventoryName = llList2String( Items , llList2Integer( requestBodyParts , 0 ) );

                    responseBody = llList2Json(
                        JSON_ARRAY
                        , [
                            llList2Integer( requestBodyParts , 0 ) , // index
                            llList2Float( Rarity , llList2Integer( requestBodyParts , 0 ) ) , // rarity
                            llList2Integer( Limit , llList2Integer( requestBodyParts , 0 ) ) , // limit
                            llList2Integer( Bought , llList2Integer( requestBodyParts , 0 ) ) , // count bought
                            inventoryName , // name
                            llGetInventoryType( inventoryName ) // type
                        ]
                    );
                }
            }

            if( "payout" == subject ) {
                if( isAdmin ) {
                    if( "post" == verb ) {
                        Payouts += [
                            llList2Key( requestBodyParts , 0 )
                            , llList2Integer( requestBodyParts , 1 )
                        ];

                        CountPayouts += 2;
                        requestBodyParts = [ ( CountPayouts / 2 ) - 1 ];
                    }

                    if( "delete" == verb ) {
                        Payouts = [];
                        CountPayouts = 0;
                        responseBody = "true";
                    }
                }

                if( llList2Integer( requestBodyParts , 0 ) < CountPayouts / 2 ) {
                    responseBody = llList2Json(
                        JSON_ARRAY
                        , llList2List( Payouts , ( llList2Integer( requestBodyParts , 0 ) * 2 ) , ( llList2Integer( requestBodyParts , 0 ) * 2 ) + 1 )
                    );
                }
            }

            if( "configs" == subject ) {
                if( isAdmin ) {
                    if( "post" == verb ) {
                        FolderForSingleItem = llList2Integer( requestBodyParts , 0 );
                        RootClickAction = llList2Integer( requestBodyParts , 1 );
                        Group = llList2Integer( requestBodyParts , 2 );
                        AllowHover = llList2Integer( requestBodyParts , 3 );
                        MaxPerPurchase  = llList2Integer( requestBodyParts , 4 );
                        MaxBuys = llList2Integer( requestBodyParts , 5 );
                        PayPrice = llList2Integer( requestBodyParts , 6 );
                        PayPriceButton0 = llList2Integer( requestBodyParts , 7 );
                        PayPriceButton1 = llList2Integer( requestBodyParts , 8 );
                        PayPriceButton2 = llList2Integer( requestBodyParts , 9 );
                        PayPriceButton3 = llList2Integer( requestBodyParts , 10 );
                        ApiPurchasesEnabled = llList2Integer( requestBodyParts , 11 );
                        ApiItemsGivenEnabled = llList2Integer( requestBodyParts , 12 );
                        Extra = llList2String( requestBodyParts , 13 );
                        TotalBought = 0;
                    }
                }

                responseBody = llList2Json(
                    JSON_ARRAY
                    , [
                        FolderForSingleItem
                        , RootClickAction
                        , Group
                        , AllowHover
                        , MaxPerPurchase 
                        , MaxBuys
                        , PayPrice
                        , PayPriceButton0
                        , PayPriceButton1
                        , PayPriceButton2
                        , PayPriceButton3
                        , ApiPurchasesEnabled
                        , ApiItemsGivenEnabled
                    ]
                );
            }

            if( "email" == subject ) {
                if( isAdmin ) {
                    if( "post" == verb ) {
                        Email = llList2String( requestBodyParts , 0 );
                    }

                    responseBody = llList2Json(
                        JSON_ARRAY
                        , [
                            Email
                        ]
                    );
                }
            }

            if( "im" == subject ) {
                if( isAdmin ) {
                    if( "post" == verb ) {
                        Im = llList2Key( requestBodyParts , 0 );
                    }

                    responseBody = llList2Json(
                        JSON_ARRAY
                        , [
                            Im
                        ]
                    );
                }
            }

            if( "info" == subject ) {
                responseBody = llList2Json(
                    JSON_ARRAY
                    , [
                        isAdmin
                        , Owner
                    ] + llGetLinkPrimitiveParams( (!!llGetLinkNumber()) , [
                        PRIM_NAME
                        , PRIM_DESC
                    ] ) + [
                        ScriptName
                        , llGetFreeMemory()
                        , llGetUsedMemory()
                        , HasPermission
                        , llGetInventoryNumber( INVENTORY_ALL )
                        , llGetListLength( Items )
                        , llGetListLength( Payouts ) / 2
                        , llGetRegionName()
                        , llGetPos()
                        , TotalPrice
                        , Extra
                        , llGetNumberOfPrims()
                        , llGetLinkNumber()
                        , llGetCreator()
                    ] + llGetObjectDetails( llGetKey() , [
                        OBJECT_GROUP
                        , OBJECT_TOTAL_SCRIPT_COUNT
                        , OBJECT_SCRIPT_TIME
                    ] )
                );
            }

            if( "prim" == subject ) {
                responseBody = llList2Json(
                    JSON_ARRAY
                    , llGetLinkPrimitiveParams( llList2Integer( requestBodyParts , 0 ) , [
                        PRIM_NAME
                        , PRIM_DESC
                        , PRIM_TYPE
                        , PRIM_SLICE
                        , PRIM_PHYSICS_SHAPE_TYPE
                        , PRIM_MATERIAL
                        , PRIM_PHYSICS
                        , PRIM_TEMP_ON_REZ
                        , PRIM_PHANTOM
                        , PRIM_POSITION
                        , PRIM_POS_LOCAL
                        , PRIM_ROTATION
                        , PRIM_ROT_LOCAL
                        , PRIM_SIZE
                        , PRIM_TEXT
                        , PRIM_FLEXIBLE
                        , PRIM_POINT_LIGHT
                        , PRIM_OMEGA
                    ] )
                );
            }

            if( "face" == subject ) {
                responseBody = llList2Json(
                    JSON_ARRAY
                    , llGetLinkPrimitiveParams( llList2Integer( requestBodyParts , 0 ) , [
                        PRIM_TEXTURE , llList2Integer( requestBodyParts , 1 )
                        , PRIM_COLOR , llList2Integer( requestBodyParts , 1 )
                        , PRIM_BUMP_SHINY , llList2Integer( requestBodyParts , 1 )
                        , PRIM_FULLBRIGHT , llList2Integer( requestBodyParts , 1 )
                        , PRIM_TEXGEN , llList2Integer( requestBodyParts , 1 )
                        , PRIM_GLOW , llList2Integer( requestBodyParts , 1 )
                    ] )
                );
            }

            if( "lookup" == subject ) {
                subject = llList2String( requestBodyParts , 0 );
                llSetContentType( requestId , responseContentType );

                // Reset cleanup timer
                llSetTimerEvent( 0.0 );
                llSetTimerEvent( 30.0 /*REQUEST_TIMEOUT*/ );

                if( "username" == subject ) {
                    DataServerRequests += [
                        llRequestUsername( llList2Key( requestBodyParts , 1 ) )
                        , requestId
                        , 3
                    ];
                }

                if( "displayname" == subject ) {
                    DataServerRequests += [
                        llRequestDisplayName( llList2Key( requestBodyParts , 1 ) )
                        , requestId
                        , 4
                    ];
                }

                if( "notecard-line-count" == subject ) {
                    DataServerRequests += [
                        llGetNumberOfNotecardLines( llList2String( requestBodyParts , 1 ) )
                        , requestId
                        , 5
                    ];
                }

                if( "notecard-line" == subject ) {
                    DataServerRequests += [
                        llGetNotecardLine( llList2String( requestBodyParts , 1 ) , llList2Integer( requestBodyParts , 2 ) )
                        , requestId
                        , 6
                    ];
                }

                return;
            }

            if( "inv" == subject && isAdmin ) {
                if( llList2Integer( requestBodyParts , 0 ) < llGetInventoryNumber( INVENTORY_ALL ) ) {
                    string inventoryName = llGetInventoryName( INVENTORY_ALL , llList2Integer( requestBodyParts , 0 ) );

                    responseBody = llList2Json(
                        JSON_ARRAY
                        , [
                            llList2Integer( requestBodyParts , 0 ) , // index
                            inventoryName , // name
                            llGetInventoryType( inventoryName ) , // type
                            llGetInventoryCreator( inventoryName ) , // creator
                            llGetInventoryKey( inventoryName ) , // key
                            llGetInventoryPermMask( inventoryName , MASK_OWNER ) , // owner permissions mask
                            llGetInventoryPermMask( inventoryName , MASK_GROUP ) , // group permissions mask
                            llGetInventoryPermMask( inventoryName , MASK_EVERYONE ) , // public permissions mask
                            llGetInventoryPermMask( inventoryName , MASK_NEXT ) // next permissions mask
                        ]
                    );
                }
            }

            if( "reset" == subject && isAdmin ) {
                llResetScript();
            }

            if( "configured" == subject && isAdmin ) {
                if( "post" == verb ) {
                    Configured = llList2Integer( requestBodyParts , 0 );
                }

                responseBody = llList2Json( JSON_ARRAY , [ Configured ] );
            }

            if( isAdmin ) {
                Update();
            }
        }

        llSetContentType( requestId , responseContentType );
        llHTTPResponse( requestId , responseStatus , responseBody );
    }

    timer() {
        // Don't let timer recur
        llSetTimerEvent( 0.0 );

        // Lazy request cleanup. HTTP requests will time out after 30 seconds
        // and automatically fail, so there's no need to do careful list
        // management here. Just cache them until they should have failed
        // already.
        DataServerRequests = [];
    }

    dataserver( key queryId , string data ) {
        integer requestIndex = llListFindList( DataServerRequests , [ queryId ] );
        if( -1 == requestIndex ) {
            return;
        }

        if( NULL_KEY != llList2Key( DataServerRequests , requestIndex + 1 ) ) {
            llHTTPResponse( llList2Key( DataServerRequests , requestIndex + 1 ) , 200 , llList2Json( JSON_ARRAY , [ data ] ) );
        }
    }

    http_response( key requestId , integer responseStatus , list metadata , string responseBody ) {
        integer requestIndex = llListFindList( DataServerRequests , [ requestId ] );
        if( -1 == requestIndex ) {
            return;
        }

        // goo.gl URL shortener parsing
        integer mode = llList2Integer( DataServerRequests , requestIndex + 2 );
        string shortened = llJsonGetValue( responseBody , [ "id" ] );
        if( JSON_INVALID != shortened && JSON_NULL != shortened ) {
            if( 1 == mode ) {
                ShortenedInfoUrl = shortened;
            }
            if( 2 == mode ) {
                ShortenedAdminUrl = shortened;
                llOwnerSay( ScriptName + ": Ready to configure. Here is the configruation link: " + ShortenedAdminUrl + " DO NOT GIVE THIS LINK TO ANYONE ELSE." );
            }
        } else if( 2 == mode ) {
            llOwnerSay( ScriptName + ": Goo.gl URL shortener failed. Ready to configure. Here is the configruation link: " + ShortenedAdminUrl + " DO NOT GIVE THIS LINK TO ANYONE ELSE." );
        }
    }

    touch_end( integer detected ) {
        integer nonOwnerTouched = FALSE;

        // For each person that touched
        while( 0 <= ( detected -= 1 ) ) {
            // If admin, send IM with link
            if( llDetectedKey( detected ) == Owner ) {
                if( ShortenedAdminUrl ) {
                    llOwnerSay( ScriptName + ": To configure and administer this Easy Gacha, please go here: " + ShortenedAdminUrl + " DO NOT GIVE THIS LINK TO ANYONE ELSE." );
                } else if( "" == BaseUrl && llGetFreeURLs() ) {
                    // If URL not set but URLs available, request one
                    llOwnerSay( ScriptName + ": Retrying to get a new URL now... please wait" );
                    RequestUrl();
                } else {
                    llDialog( Owner , "No URLs are available on this parcel/sim, so the configuration screen cannot be shown. Please slap whoever is consuming all the URLs and try again." , [ ] , -1 ); // FORCED_DELAY 1.0 seconds
                }

                // If the owner accidentally ignored the permissions request
                // (not denied) and touches the object again, then re-ask for
                // permission
                if( TotalPrice && !HasPermission ) {
                    Update(); // Will request permission from owner
                }
            } else {
                nonOwnerTouched = TRUE;
            }

            // If we're up and running and free-to-play, then call play
            if( Ready && !TotalPrice ) {
                Play( llDetectedKey( detected ) , 0 );
            }
        }

        // Owner can get to dashboard from admin screen, so don't spam them
        // with two links
        if( nonOwnerTouched || Ready ) {
            // Whisper info link
            if( "" != ShortenedInfoUrl && Ready ) {
                llWhisper( 0 , ScriptName + ": For help, information, and statistics about this Easy Gacha, please go here: " + ShortenedInfoUrl );
            } else {
                llWhisper( 0 , ScriptName + ": Information about this Easy Gacha is not currently available, please wait a few minutes and try again." );
            }
        }
    }
}
