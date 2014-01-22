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
//      x+2:    unixtime request was made
//      x+3:    integer type of request that was made

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
//      REGISTRY_DISABLED           return;
//      REGISTRY_URL                ""
//      REGISTRY_HTTP_OPTIONS       [ HTTP_METHOD , "POST" , HTTP_MIMETYPE , "text/json;charset=utf-8" , HTTP_BODY_MAXLENGTH , 16384 , HTTP_VERIFY_CERT , FALSE , HTTP_VERBOSE_THROTTLE , FALSE , "X-EasyGacha-Version" , "5.0" /*VERSION*/ ]
//      MAX_FOLDER_NAME_LENGTH      63
//      DEFAULT_MAX_PER_PURCHASE    50
//      ASSET_SERVER_TIMEOUT        15.0
//      ASSET_SERVER_TIMEOUT_CHECK  5.0
//      PING_INTERVAL               86400
//      DEBUG_INVENTORY             "easy-gacha-debug"

//  DEFAULT_MAX_PER_PURCHASE: We have to build a list in memory of the items to
//      be given in a folder. To prevent out of memory errors and exceedlingly
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
string ScriptName; // More memory efficent to only update when it could be changed
integer HasPermission; // More memory efficent to only update when it could be changed
list DataServerRequests; // List of the requests we have pending
integer LastPing; // UnixTime
integer TotalPrice; // Updated when Payouts is updated, sum
integer TotalBought; // Updated when Bought is updated
integer TotalLimit; // Updated when Limit is updated
integer HasUnlimitedItems; // If ANY Limit is -1
integer HasNoCopyItemsForSale; // If ANY item with no-zero limit and rarity set is no-copy
float TotalEffectiveRarity; // Updated when Rarity or Limit are updated
integer CountItems; // Updated when Items is updated
integer CountPayouts; // Updated when Payouts is updated - total elements, not stride elements
integer LastWhisperedUrl; // When were we last touched

Hover( string msg ) {
    if( AllowHover ) {
        if( msg ) {
            llSetText( llGetObjectName() + ": " + ScriptName + ":\n" + msg + "\n|\n|\n|\n|\n|\n_\nV" , <1,0,0>, 1 );
        } else {
            llSetText( "" , ZERO_VECTOR , 1 );
        }
    }
}

Registry( list data ) {
    return; /*REGISTRY_DISABLED*/

    // Note: Request ID not stored, so response will be safely skipped
    llHTTPRequest( "" /*REGISTRY_URL*/ , [ HTTP_METHOD , "POST" , HTTP_MIMETYPE , "text/json;charset=utf-8" , HTTP_BODY_MAXLENGTH , 16384 , HTTP_VERIFY_CERT , FALSE , HTTP_VERBOSE_THROTTLE , FALSE , "X-EasyGacha-Version" , "5.0" /*VERSION*/ ] /*REGISTRY_HTTP_OPTIONS*/ , llList2Json( JSON_ARRAY , data ) );

    llSleep( 1.0 ); // FORCED_DELAY 1.0 seconds
}

RequestUrl() {
    llReleaseURL( BaseUrl );

    AdminKey = llGenerateKey();
    BaseUrl = "";
    ShortenedInfoUrl = "";
    ShortenedAdminUrl = "";

    llRequestURL();
}

integer ItemUsable( integer itemIndex ) {
    // If inventory exists
    if( INVENTORY_NONE != llGetInventoryType( llList2String( Items , itemIndex ) ) ) {
        // And is transferable
        if( PERM_TRANSFER & llGetInventoryPermMask( llList2String( Items , itemIndex ) , MASK_OWNER ) ) {
            // And isn't sold out
            if( -1 == llList2Integer( Limit , itemIndex ) || llList2Integer( Bought , itemIndex ) < llList2Integer( Limit , itemIndex ) ) {
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

    // Calculated values
    TotalPrice = (integer)llListStatistics( LIST_STAT_SUM , Payouts );
    TotalBought = (integer)llListStatistics( LIST_STAT_SUM , Bought );
    CountItems = llGetListLength( Items );
    CountPayouts = llGetListLength( Payouts );
    HasUnlimitedItems = ( -1 != llListFindList( Limit , [ -1 ] ) );

    // Build total rarity and limit
    integer itemIndex;
    TotalLimit = 0;
    TotalEffectiveRarity = 0.0;
    HasNoCopyItemsForSale = FALSE;
    for( itemIndex = 0 ; itemIndex < CountItems ; ++itemIndex ) {
        // If limit is -1 meaning unlimited, don't add it to the total
        if( 0 < llList2Integer( Limit , itemIndex ) ) {
            TotalLimit += llList2Integer( Limit , itemIndex );
        }

        // If the item is usable, meaning exists and has rarity and is
        // transferable, etc...
        if( ItemUsable( itemIndex ) ) {
            TotalEffectiveRarity += llList2Float( Rarity , itemIndex );

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
        if( TotalBought >= MaxBuys ) {
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
    } else if( TotalPrice && !HasPermission ) {
        Hover( "Need debit permission, please touch this object" );
        llRequestPermissions( Owner , PERMISSION_DEBIT );
    } else if( Group && llSameGroup( NULL_KEY ) ) {
        Hover( "Please set a group for this object" );
    } else if( -1 != MaxBuys && TotalBought >= MaxBuys ) {
        Hover( "No more items to give, sorry" );
    } else {
        Hover( "Configuration needed, please touch this object" );
    }
}

Shorten( string url , integer typeId ) {
    DataServerRequests += [
        llHTTPRequest(
            "https:\/\/www.googleapis.com/urlshortener/v1/url"
            , [
                HTTP_METHOD , "POST"
                , HTTP_MIMETYPE , "application/json"
                , HTTP_BODY_MAXLENGTH , 16384
                , HTTP_VERIFY_CERT , TRUE
                , HTTP_VERBOSE_THROTTLE , FALSE
            ]
            , llJsonSetValue( "{}" , [ "longUrl" ] , url )
        )
        , NULL_KEY
        , llGetUnixTime()
        , typeId
    ];
}

Play( key buyerId , integer lindensReceived ) {
    // Cache this because it's used several times
    string displayName = llGetDisplayName( buyerId );

    // Visually note that we're now in the middle of something
    Hover( "Please wait, getting random items for: " + displayName );

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
    if( !HasUnlimitedItems && totalItems > TotalLimit - TotalBought ) {
        totalItems = TotalLimit - TotalBought;
    }

    // If it's set to group-only play and they're not in the right group
    if( Group && !llSameGroup( buyerId ) ) {
        totalItems = 0;
    }

    // Iterate until we've met our total, because it should now be
    // guaranteed to happen
    list itemsToSend = [];
    integer countItemsToSend = 0;
    float random;
    integer itemIndex;
    while( countItemsToSend < totalItems ) {
        // Indicate our progress
        Hover( "Please wait, getting random item " + (string)( countItemsToSend + 1 ) + " of " + (string)totalItems + " for: " + displayName );

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

        // Mark that we found a valid thing to give, otherwise we'll loop
        // through again until we do find one
        ++countItemsToSend;

        // Mark this item as bought, increasing the count
        Bought = llListReplaceList( Bought , [ llList2Integer( Bought , itemIndex ) + 1 ] , itemIndex , itemIndex );
        ++TotalBought;

        // If it's no longer usable (inventory has run out)
        if( ! ItemUsable( itemIndex ) ) {
            // Reduce rarity total
            TotalEffectiveRarity -= llList2Float( Rarity , itemIndex );
        }
    }

    // Fix verbage, just because it bothers me
    string itemPlural = " items ";
    string hasHave = "have ";
    if( 1 == countItemsToSend ) {
        itemPlural = " item ";
        hasHave = "has ";
    }

    // Build the name of the folder to give. Start by getting the name of
    // the prim, or barring that, the name of the object
    string objectName = llList2String( llGetLinkPrimitiveParams( LINK_THIS , [ PRIM_NAME ] ) , 0 );
    if( "" == objectName || "Object" == objectName ) {
        objectName = llGetObjectName();
    }
    string folderSuffix = ( " (Easy Gacha: " + (string)countItemsToSend + itemPlural + llGetDate() + ")" );
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

    // Thank them for their purchase
    llWhisper( 0 , ScriptName + ": Thank you for your purchase, " + displayName + "! Your " + (string)countItemsToSend + itemPlural + hasHave + "been sent." + change );

    // Give the inventory
    Hover( "Please wait, giving items to: " + displayName );
    if( 1 < countItemsToSend || ( FolderForSingleItem && !HasNoCopyItemsForSale ) ) {
        llGiveInventoryList( buyerId , objectName + folderSuffix , itemsToSend ); // FORCED_DELAY 3.0 seconds
    } else {
        llGiveInventory( buyerId , llList2String( itemsToSend , 0 ) ); // FORCED_DELAY 2.0 seconds
    }

    // Reports
    if( Im ) {
        llInstantMessage( Owner , ScriptName + ": User " + displayName + " (" + llGetUsername(buyerId) + ") just received " + (string)countItemsToSend + " items. " + ShortenedInfoUrl ); // FORCED_DELAY 2.0 seconds
    }
    if( Email ) {
        llEmail( Email , llGetObjectName() + " - Easy Gacha Played" , displayName + " (" + llGetUsername(buyerId) + ") just received the following items:\n\n" + llDumpList2String( itemsToSend , "\n" ) ); // FORCED_DELAY 20.0 seconds
    }
    // TODO: Ping registry

    // API calls
    if( ApiPurchasesEnabled ) {
        llMessageLinked( LINK_SET , 3000168 , (string)countItemsToSend , buyerId );
    }
    if( ApiItemsGivenEnabled ) {
        for( itemIndex = 0 ; itemIndex < countItemsToSend ; ++itemIndex ) {
            llMessageLinked( LINK_SET , 3000169 , llList2String( itemsToSend , itemIndex ) , buyerId );
        }
    }
}

default {
    state_entry() {
        Update();
        RequestUrl();
    }

    attach( key avatarId ) {
        Update();
    }

    on_rez( integer rezParam ) {
        Update();
        RequestUrl();
    }

    run_time_permissions( integer permissionMask ) {
        Update();
    }

    changed( integer changeMask ) {
        // If they change the inventory and remove something that was
        // configured, we'll count that as alright and just recalculate the
        // probabilities
        // if( CHANGED_INVENTORY & changeMask )

        if( ( CHANGED_OWNER | CHANGED_REGION_START | CHANGED_REGION | CHANGED_TELEPORT ) & changeMask ) {
            RequestUrl();
        }

        Update();
    }

    money( key buyerId , integer lindensReceived ) {
        // During handout, there is still a "money" event which can capture
        // any successful transactions (so none are missed), but by setting
        // ALL the pay buttons to PAY_HIDE, which should prevent any new
        // purchases while it is processing.
        llSetPayPrice( PAY_HIDE , [ PAY_HIDE , PAY_HIDE , PAY_HIDE , PAY_HIDE ] );

        Play( buyerId , lindensReceived );

        Update();
    }

    timer() {
        llSetTimerEvent( 0.0 ); // reset

        // For each pending request
        integer requestIndex;
        for( requestIndex = 0 ; requestIndex < llGetListLength( DataServerRequests ) ; requestIndex += 4 ) {
            // If it has expired
            if( llList2Integer( DataServerRequests , requestIndex + 2 ) + 15.0 /*ASSET_SERVER_TIMEOUT*/ < llGetUnixTime() ) {
                if( NULL_KEY != llList2Key( DataServerRequests , requestIndex + 1 ) ) {
                    llHTTPResponse( llList2Key( DataServerRequests , requestIndex + 1 ) , 200 , "null" );
                }

                DataServerRequests = llDeleteSubList( DataServerRequests , requestIndex , requestIndex + 3 );
            }
        }

        if( llGetListLength( DataServerRequests ) ) {
            llSetTimerEvent( 5.0 /*ASSET_SERVER_TIMEOUT_CHECK*/ );
        } else {
            // TODO: llSetTimerEvent( LastPing + 86400 /*PING_INTERVAL*/ - llGetUnixTime() );
        }
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
        }

        if( URL_REQUEST_DENIED == httpMethod ) {
            llOwnerSay( "Unable to get a URL. This Easy Gacha cannot be configured until one becomes available: " + requestBody );
        }

        if( "get" == llToLower( httpMethod ) ) {
            if( "/" == llGetHTTPHeader( requestId , "x-path-info" ) ) {
                responseStatus = 200;
                responseBody = ( 
                    "<!DOCTYPE html PUBLIC \"-\/\/W3C\/\/DTD XHTML 1.0 Transitional\/\/EN\" \"http:\/\/www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n"
                    + "<html xmlns=\"http:\/\/www.w3.org/1999/xhtml\">\n"
                    + "    <head>\n"
                    + "        <script type=\"text/javascript\">document.easyGachaScriptVersion = 5.0; /*VERSION*/</script>\n"
                    + "        <script type=\"text/javascript\" src=\"http:\/\/lslguru.com/gh-pages/v5/easy-gacha.js\"></script>\n" /*CONFIG_SCRIPT_URL*/
                    + "        <script type=\"text/javascript\">\n"
                    + "            if( !window.easyGachaLoaded )\n"
                    + "                alert( 'Error loading scripts, please refresh page' );\n"
                    + "        </script>\n"
                    + "    </head>\n"
                    + "    <body>\n"
                    + "        <noscript>Please load this in your normal web browser with JavaScript enabled.</noscript>\n"
                    + "    </body>\n"
                    + "</html>"
                );
                responseContentType = CONTENT_TYPE_XHTML;
            }
        }

        if( "post" == llToLower( httpMethod ) ) {
            responseStatus = 200;
            responseContentType = CONTENT_TYPE_JSON;
            responseBody = "null";

            list path = llParseString2List( llGetHTTPHeader( requestId , "x-path-info" ) , [ "/" ] , [ ] );

            // Determine if the user is an admin by the presence of the
            // key, and strip it off the front
            integer isAdmin = ( llList2Key( path , 0 ) == AdminKey );
            if( isAdmin ) {
                path = llList2List( path , 1 , -1 );
            }

            string verb = llList2String( path , 0 );
            string subject = llList2String( path , 1 );
            list requestBodyParts = llJson2List( requestBody );

            if( "item" == subject ) {
                if( isAdmin ) {
                    if( "post" == verb ) {
                        Rarity += [ llList2Float( requestBodyParts , 0 ) ];
                        Limit += [ llList2Integer( requestBodyParts , 1 ) ];
                        Bought += [ llList2Integer( requestBodyParts , 2 ) ];
                        Items += [ llList2String( requestBodyParts , 3 ) ];
                    }

                    if( "delete" == verb ) {
                        Rarity = [];
                        Limit = [];
                        Bought = [];
                        Items = [];
                        CountItems = 0;
                    }
                }

                if( llList2Integer( requestBodyParts , 0 ) < CountItems ) {
                    string inventoryName = llList2String( Items , llList2Integer( requestBodyParts , 0 ) );
                    integer inventoryType = llGetInventoryType( inventoryName );
                    list values = [
                        llList2Integer( requestBodyParts , 0 ) , // index
                        llList2Float( Rarity , llList2Integer( requestBodyParts , 0 ) ) , // rarity
                        llList2Integer( Limit , llList2Integer( requestBodyParts , 0 ) ) , // limit
                        llList2Integer( Bought , llList2Integer( requestBodyParts , 0 ) ) , // count bought
                        inventoryName , // name
                        inventoryType // type
                    ];

                    if( INVENTORY_NONE != inventoryType ) {
                        values += [
                            llGetInventoryCreator( inventoryName ) , // creator
                            llGetInventoryKey( inventoryName ) != NULL_KEY , // can get key (key not passed for security)
                            llGetInventoryPermMask( inventoryName , MASK_OWNER ) , // owner permissions mask
                            llGetInventoryPermMask( inventoryName , MASK_GROUP ) , // group permissions mask
                            llGetInventoryPermMask( inventoryName , MASK_EVERYONE ) , // public permissions mask
                            llGetInventoryPermMask( inventoryName , MASK_NEXT ) // next permissions mask
                        ];
                    } else {
                        values += [
                            NULL_KEY , // creator
                            FALSE , // can get key (key not passed for security)
                            0 , // owner permissions mask
                            0 , // group permissions mask
                            0 , // public permissions mask
                            0 // next permissions mask
                        ];
                    }

                    responseBody = llList2Json(
                        JSON_ARRAY
                        , values
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
                    }

                    if( "delete" == verb ) {
                        Payouts = [];
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
                if( isAdmin ) {
                    if( "post" == verb ) {
                        Configured = llList2Integer( requestBodyParts , 0 );
                        Extra = llList2String( requestBodyParts , 1 );
                    }
                }

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
                        , HasPermission
                        , LastPing
                        , llGetInventoryNumber( INVENTORY_ALL )
                        , llGetListLength( Items )
                        , llGetListLength( Payouts ) / 2
                        , llGetRegionName()
                        , llGetPos()
                        , Configured
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
                subject = llList2String( path , 2 );
                llSetContentType( requestId , responseContentType );
                llSetTimerEvent( 5.0 /*ASSET_SERVER_TIMEOUT_CHECK*/ );

                if( "username" == subject ) {
                    DataServerRequests += [
                        llRequestUsername( llList2Key( requestBodyParts , 0 ) )
                        , requestId
                        , llGetUnixTime()
                        , 3
                    ];
                }

                if( "displayname" == subject ) {
                    DataServerRequests += [
                        llRequestDisplayName( llList2Key( requestBodyParts , 0 ) )
                        , requestId
                        , llGetUnixTime()
                        , 4
                    ];
                }

                if( "notecard-line-count" == subject ) {
                    DataServerRequests += [
                        llGetNumberOfNotecardLines( llList2String( requestBodyParts , 0 ) )
                        , requestId
                        , llGetUnixTime()
                        , 5
                    ];
                }

                if( "notecard-line" == subject ) {
                    DataServerRequests += [
                        llGetNotecardLine( llList2String( requestBodyParts , 0 ) , llList2Integer( requestBodyParts , 1 ) )
                        , requestId
                        , llGetUnixTime()
                        , 6
                    ];
                }

                return;
            }

            if( "inv" == subject && isAdmin ) {
                if( llList2Integer( requestBodyParts , 0 ) < llGetInventoryNumber( INVENTORY_ALL ) ) {
                    string inventoryName = llGetInventoryName( INVENTORY_ALL , llList2Integer( requestBodyParts , 0 ) );
                    list values = [
                        llList2Integer( requestBodyParts , 0 ) , // index
                        inventoryName , // name
                        llGetInventoryType( inventoryName ) , // type
                        llGetInventoryCreator( inventoryName ) , // creator
                        llGetInventoryKey( inventoryName ) , // key
                        llGetInventoryPermMask( inventoryName , MASK_OWNER ) , // owner permissions mask
                        llGetInventoryPermMask( inventoryName , MASK_GROUP ) , // group permissions mask
                        llGetInventoryPermMask( inventoryName , MASK_EVERYONE ) , // public permissions mask
                        llGetInventoryPermMask( inventoryName , MASK_NEXT ) // next permissions mask
                    ];

                    responseBody = llList2Json(
                        JSON_ARRAY
                        , values
                    );
                }
            }

            if( isAdmin ) {
                Update();
            }
        }

        llSetContentType( requestId , responseContentType );
        llHTTPResponse( requestId , responseStatus , responseBody );
    }

    dataserver( key queryId , string data ) {
        integer requestIndex = llListFindList( DataServerRequests , [ queryId ] );
        if( -1 == requestIndex || 0 != requestIndex % 4 ) {
            return;
        }

        if( NULL_KEY != llList2Key( DataServerRequests , requestIndex + 1 ) ) {
            llHTTPResponse( llList2Key( DataServerRequests , requestIndex + 1 ) , 200 , llList2Json( JSON_ARRAY , [ data ] ) );

            DataServerRequests = llDeleteSubList( DataServerRequests , requestIndex , requestIndex + 3 );
        }

        llSetTimerEvent( 0.0 );
    }

    http_response( key requestId , integer responseStatus , list metadata , string responseBody ) {
        integer requestIndex = llListFindList( DataServerRequests , [ requestId ] );
        if( -1 == requestIndex || 0 != requestIndex % 4 ) {
            return;
        }

        // goo.gl URL shortener parsing
        string shortened = llJsonGetValue( responseBody , [ "id" ] );
        if( JSON_INVALID != shortened && JSON_NULL != shortened ) {
            if( 1 == llList2Integer( DataServerRequests , requestIndex + 3 ) ) {
                ShortenedInfoUrl = shortened;
                // TODO: Ping registry
            }
            if( 2 == llList2Integer( DataServerRequests , requestIndex + 3 ) ) {
                ShortenedAdminUrl = shortened;
                llOwnerSay( "Ready to configure. Here is the configruation link: " + ShortenedAdminUrl + " DO NOT GIVE THIS LINK TO ANYONE ELSE." );
                // TODO: Ping registry
            }
        } else if( 2 == llList2Integer( DataServerRequests , requestIndex + 3 ) ) {
            llOwnerSay( "Goo.gl URL shortener failed. Ready to configure. Here is the configruation link: " + ShortenedAdminUrl + " DO NOT GIVE THIS LINK TO ANYONE ELSE." );
            // TODO: Ping registry
        }

        DataServerRequests = llDeleteSubList( DataServerRequests , requestIndex , requestIndex + 3 );
    }

    touch_end( integer detected ) {
        // For each person that touched
        while( 0 <= ( detected -= 1 ) ) {
            key detectedKey = llDetectedKey( detected );

            // If admin, send IM with link
            if( detectedKey == Owner ) {
                if( ShortenedAdminUrl ) {
                    llOwnerSay( "To configure and administer this Easy Gacha, please go here: " + ShortenedAdminUrl + " DO NOT GIVE THIS LINK TO ANYONE ELSE." );
                } else if( "" == BaseUrl && llGetFreeURLs() ) {
                    // If URL not set but URLs available, request one
                    llOwnerSay( "Trying to get a new URL now... please wait" );
                    RequestUrl();
                } else {
                    llDialog( Owner , "No URLs are available on this parcel/sim, so the configuration screen cannot be shown. Please slap whoever is consuming all the URLs and try again." , [ ] , -1 ); // FORCED_DELAY 1.0 seconds
                }

                if( TotalPrice && !HasPermission ) {
                    llRequestPermissions( llGetOwner() , PERMISSION_DEBIT );
                }
            }

            if( Ready && !TotalPrice ) {
                Play( detectedKey , 0 );
            }
        }

        // Whisper info link
        if( llGetUnixTime() != LastWhisperedUrl ) {
            if( ShortenedInfoUrl ) {
                llWhisper( 0 , ScriptName + ": For help, information, and statistics about this Easy Gacha, please go here: " + ShortenedInfoUrl );
            } else {
                llWhisper( 0 , ScriptName + ": Information about this Easy Gacha is not yet available, please wait a few minutes and try again." );
            }

            LastWhisperedUrl = llGetUnixTime();
        }

        Update();
    }
}
