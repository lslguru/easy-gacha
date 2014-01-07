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
// Application
////////////////////////////////////////////////////////////////////////////////

// This is the version I'm working on now
#define VERSION 5.0

// Specific to scriptor
#define CONFIG_SCRIPT_URL "http:\/\/lslguru.github.io/easy-gacha/v5/easy-gacha.js"
#define CONFIG_SCRIPT_URL "http:\/\/lslguru.com/gh-pages/v5/easy-gacha.js"
#define REGISTRY_URL ""
#define REGISTRY_HTTP_OPTIONS [ HTTP_METHOD , "POST" , HTTP_MIMETYPE , "text/json;charset=utf-8" , HTTP_BODY_MAXLENGTH , 16384 , HTTP_VERIFY_CERT , FALSE , HTTP_VERBOSE_THROTTLE , FALSE ]
#define PERMANENT_ADMIN_KEY ""

// System constraints
#define MAX_FOLDER_NAME_LENGTH 63

// Tweaks
#define ASSET_SERVER_TIMEOUT 5.0
#define PING_INTERVAL 86400

// Inventory
#define DEBUG_INVENTORY "easy-gacha-debug"

#start globalvariables

    ////////////////////////////////////////////////////////////////////////////
    // Configuration Values
    ////////////////////////////////////////////////////////////////////////////

    list Items; // Inventory names, strings <= 63 chars in length
    list Rarity; // float
    list Limit; // integer, -1 == infinite
    list Bought; // stats counter
    list Payouts; // strided: [ avatar key , lindens ]
    integer MaxPerPurchase = 50;
    integer PayPrice = PAY_HIDE; // Price || PAY_HIDE || PAY_DEFAULT (should be sum of Payouts)
    list PayPriceButtons = [ PAY_HIDE , PAY_HIDE , PAY_HIDE , PAY_HIDE ]; // [ 4x ( Price || PAY_HIDE || PAY_DEFAULT ) ]
    integer FolderForSingleItem = TRUE;
    integer RootClickAction = FALSE;
    integer Group = FALSE; // If group may administer
    string Email; // Who to email after each play
    key Im; // Who to IM after each play
    integer AllowWhisper = TRUE; // Whether or not to allow whisper
    integer AllowHover = TRUE; // Whether or not to allow hovertext output
    integer MaxBuys = -1; // Infinite
    integer Configured; // boolean

    ////////////////////////////////////////////////////////////////////////////
    // Runtime Values
    ////////////////////////////////////////////////////////////////////////////

    key AdminKey; // Used to indicate if person has rights to modify configs
    string BaseUrl; // Requested and hopefully received
    string ShortenedInfoUrl; // Hand this out instead of the full URL
    string ShortenedAdminUrl; // Hand this out instead of the full URL
    key Owner; // More memory efficient to only update when it could be changed
    string ScriptName; // More memory efficent to only update when it could be changed
    integer HasPermission; // More memory efficent to only update when it could be changed
    key DataServerRequest; // Should only allow one at a time
    integer DataServerMode; // Which kind of request is happening, 0 = none, 1 = goo.gl for info, 2 = goo.gl for admin, 3 = user name lookup, 4 = display name lookup
    key DataServerResponse; // Only present with certain DataServerModes
    integer InventoryChanged; // Indicates the inventory changed since last check
    integer InventoryChangeExpected; // When we give out no-copy items...
    integer LastPing; // UnixTime
    integer TotalPrice; // Updated when Payouts is updated, sum
    integer TotalBought; // Updated when Bought is updated
    integer TotalLimit; // Updated when Limit is updated
    integer HasUnlimitedItems; // If ANY Limit is -1
    float TotalEffectiveRarity; // Updated when Rarity or Limit are updated
    integer CountItems; // Updated when Items is updated
    integer CountPayouts; // Updated when Payouts is updated - total elements, not stride elements
    integer TestMode; // Boolean - Used to test execution without accepting or sending money

#end globalvariables

#start globalfunctions

    Debug( string msg ) { if( INVENTORY_NONE != llGetInventoryType( DEBUG_INVENTORY ) ) { llOwnerSay( "/me : " + llGetScriptName() + ": DEBUG: " + msg ); } }

    Whisper( string msg ) {
        Debug( "Whisper( \"" + msg + "\" );" );

        if( AllowWhisper ) {
            llWhisper( 0 , "/me : " + llGetScriptName() + ": " + msg );
        }
    }

    Hover( string msg ) {
        Debug( "Hover( \"" + msg + "\" );" );

        if( AllowHover ) {
            if( msg ) {
                llSetText( llGetScriptName() + ":\n" + msg + "\n|\n|\n|\n|\n|" , <1,0,0>, 1 );
            } else {
                llSetText( "" , ZERO_VECTOR , 1 );
            }
        }
    }

    Registry( list data ) {
        Debug( "Registry( [ " + llList2CSV( data ) + " ] );" );

        if( "" == REGISTRY_URL ) {
            return;
        }

        llHTTPRequest( REGISTRY_URL , REGISTRY_HTTP_OPTIONS , llList2Json( JSON_ARRAY , data ) );

        llSleep( 1.0 ); // FORCED_DELAY 1.0 seconds
    }

    DebugGlobals() {
        Debug( "DebugGlobals()" );
        Debug( "    Items = " + llList2CSV( Items ) );
        Debug( "    Rarity = " + llList2CSV( Rarity ) );
        Debug( "    Limit = " + llList2CSV( Limit ) );
        Debug( "    Bought = " + llList2CSV( Bought ) );
        Debug( "    Payouts = " + llList2CSV( Payouts ) );
        Debug( "    MaxPerPurchase = " + (string)MaxPerPurchase );
        Debug( "    PayPrice = " + (string)PayPrice );
        Debug( "    PayPriceButtons = " + llList2CSV( PayPriceButtons ) );
        Debug( "    FolderForSingleItem = " + (string)FolderForSingleItem );
        Debug( "    RootClickAction = " + (string)RootClickAction );
        Debug( "    Group = " + (string)Group );
        Debug( "    Email = " + Email );
        Debug( "    Im = " + (string)Im );
        Debug( "    AllowWhisper = " + (string)AllowWhisper );
        Debug( "    AllowHover = " + (string)AllowHover );
        Debug( "    MaxBuys = " + (string)MaxBuys );
        Debug( "    Configured = " + (string)Configured );
        Debug( "    AdminKey = " + (string)AdminKey );
        Debug( "    BaseUrl = " + BaseUrl );
        Debug( "    ShortenedInfoUrl = " + ShortenedInfoUrl );
        Debug( "    ShortenedAdminUrl = " + ShortenedAdminUrl );
        Debug( "    Owner = " + (string)Owner );
        Debug( "    ScriptName = " + ScriptName );
        Debug( "    HasPermission = " + (string)HasPermission );
        Debug( "    DataServerRequest = " + (string)DataServerRequest );
        Debug( "    DataServerMode = " + (string)DataServerMode );
        Debug( "    InventoryChanged = " + (string)InventoryChanged );
        Debug( "    InventoryChangeExpected = " + (string)InventoryChangeExpected );
        Debug( "    LastPing = " + (string)LastPing );
        Debug( "    TotalPrice = " + (string)TotalPrice );
        Debug( "    TotalBought = " + (string)TotalBought );
        Debug( "    TotalLimit = " + (string)TotalLimit );
        Debug( "    HasUnlimitedItems = " + (string)HasUnlimitedItems );
        Debug( "    TotalEffectiveRarity = " + (string)TotalEffectiveRarity );
        Debug( "    CountItems = " + (string)CountItems );
        Debug( "    CountPayouts = " + (string)CountPayouts );
        Debug( "    TestMode = " + (string)TestMode );
        Debug( "    Free memory: " + (string)llGetFreeMemory() );
    "Debug";}

    RequestUrl() {
        Debug( "RequestUrl()" );
        llReleaseURL( BaseUrl );

        AdminKey = llGenerateKey();
        BaseUrl = "";
        ShortenedInfoUrl = "";
        ShortenedAdminUrl = "";

        llRequestURL();
    }

    Update() {
        Debug( "Update()" );

        Owner = llGetOwner();
        ScriptName = llGetScriptName();
        HasPermission = ( ( llGetPermissionsKey() == Owner ) && llGetPermissions() & PERMISSION_DEBIT );

        if( TotalPrice && !HasPermission ) {
            Configured = FALSE;
        }

        // Default values of these variables are to not show pay buttons.
        // This should prevent any new purchases until a price has been
        // set.
        if( Configured ) {
            llSetPayPrice( PayPrice , PayPriceButtons );
        } else {
            llSetPayPrice( PAY_HIDE , [ PAY_HIDE , PAY_HIDE , PAY_HIDE , PAY_HIDE ] );
        }

        // Set touch text:
        // If needs config, label "Config"
        // If price is zero and Configured, "Play"
        // If price is !zero, "Info" because Pay button plays
        if( !Configured ) {
            llSetTouchText( "Config" );
        } else if( TotalPrice ) {
            llSetTouchText( "Info" );
        } else {
            llSetTouchText( "Play" );
        }

        // Set object action only if we're not the root prim of a linked set or
        // they've explicitly allowed it
        if( RootClickAction || LINK_ROOT != llGetLinkNumber() ) {
            // If we're ready to go and price is not zero, then pay is the
            // default action, otherwise touch will always be the default (for
            // play or info or config)
            if( Configured && TotalPrice ) {
                llSetClickAction( CLICK_ACTION_PAY );
            } else {
                llSetClickAction( CLICK_ACTION_TOUCH );
            }
        }

        // Calculated values
        TotalPrice = (integer)llListStatistics( LIST_STAT_SUM , Payouts );
        TotalBought = (integer)llListStatistics( LIST_STAT_SUM , Bought );
        TotalLimit = (integer)llListStatistics( LIST_STAT_SUM , Limit );
        CountItems = llGetListLength( Items );
        CountPayouts = llGetListLength( Payouts );
        HasUnlimitedItems = ( -1 != llListFindList( Limit , [ -1 ] ) );

        integer itemIndex;
        TotalEffectiveRarity = 0.0;
        for( itemIndex = 0 ; itemIndex < CountItems ; ++itemIndex ) {
            if( -1 == llList2Integer( Limit , itemIndex ) || llList2Integer( Bought , itemIndex ) < llList2Integer( Limit , itemIndex ) ) {
                TotalEffectiveRarity += llList2Float( Rarity , itemIndex );
            }
        }

        // Far more simplistic config statement
        if( Configured ) {
            if( 1 == DataServerMode || 2 == DataServerMode ) {
                Hover( "Working, please wait..." );
            } else {
                Hover( "" );
            }
        } else if( TotalPrice && !HasPermission ) {
            Hover( "Need debit permission, please touch this object" );
        } else {
            Hover( "Configuration needed, please touch this object" );
        }
    }

    Shorten( string url ) {
        Debug( "Shorten( \"" + url + "\" )" );

        DataServerRequest = llHTTPRequest(
            "https:\/\/www.googleapis.com/urlshortener/v1/url" ,
            [
                HTTP_METHOD , "POST" ,
                HTTP_MIMETYPE , "application/json" ,
                HTTP_BODY_MAXLENGTH , 16384 ,
                HTTP_VERIFY_CERT , TRUE ,
                HTTP_VERBOSE_THROTTLE , FALSE
            ] ,
            llJsonSetValue( "{}" , [ "longUrl" ] , url )
        );
    }

    Play( key buyerId , integer lindensReceived ) {
        Debug( "Play( " + (string)buyerId + " , " + (string)lindensReceived + " )" );

        // Iterator

        // Cache this because it's used several times
        string displayName = llGetDisplayName( buyerId );

        // Visually note that we're now in the middle of something
        Hover( "Please wait, getting random items for: " + displayName );

        // Figure out how many objects we need to give
        integer totalItems = lindensReceived / TotalPrice;

        // If their order would exceed the hard-coded limit
        if( totalItems > MaxPerPurchase ) {
            totalItems = MaxPerPurchase;
            Debug( "    totalItems > MaxPerPurchase, set to: " + (string)totalItems );
        }

        // If their order would exceed the total allowed purchases
        if( -1 != MaxBuys && totalItems > MaxBuys - TotalBought ) {
            totalItems = MaxBuys - TotalBought;
            Debug( "    totalItems > MaxBuysRemaining, set to: " + (string)totalItems );
        }

        // If their order would exceed the total available supply
        if( !HasUnlimitedItems && totalItems > TotalLimit - TotalBought ) {
            totalItems = TotalLimit - TotalBought;
            Debug( "    totalItems > RemainingInventory, set to: " + (string)totalItems );
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
            Debug( "    random = " + (string)random );

            // Find the item's index
            for( itemIndex = 0 ; itemIndex < CountItems && random > 0.0 ; ++itemIndex ) {
                // Skip over sold-out items
                if( -1 == llList2Integer( Limit , itemIndex ) || llList2Integer( Bought , itemIndex ) < llList2Integer( Limit , itemIndex ) ) {
                    // Otherwise decrement the random number
                    random -= llList2Float( Rarity , itemIndex );
                }
            }

            // Last iteration of the loop increments the index past where we want
            --itemIndex;
            Debug( "    index of item = " + (string)itemIndex );

            // llGiveInventoryList uses the inventory names
            itemsToSend += [ llList2String( Items , itemIndex ) ];
            Debug( "    Item picked: " + llList2String( Items , itemIndex ) );

            // Mark that we found a valid thing to give, otherwise we'll loop
            // through again until we do find one
            ++countItemsToSend;

            // Mark this item as bought, increasing the count
            Bought = llListReplaceList( Bought , [ llList2Integer( Bought , itemIndex ) + 1 ] , itemIndex , itemIndex );
            ++TotalBought;

            // If the inventory has run out
            if( -1 != llList2Integer( Limit , itemIndex ) && llList2Integer( Bought , itemIndex ) >= llList2Integer( Limit , itemIndex ) ) {
                Debug( "    Inventory has run out for item!" );

                // Reduce rarity total
                TotalEffectiveRarity -= llList2Float( Rarity , itemIndex );
                Debug( "    TotalEffectiveRarity = " + (string)TotalEffectiveRarity );

                // And assume inventory will change
                InventoryChangeExpected = TRUE;
            }
        }

        // Fix verbage, just because it bothers me
        string itemPlural = " items ";
        string hasHave = "have ";
        if( 1 == countItemsToSend ) {
            itemPlural = " item ";
            hasHave = "has ";
        }

        // Build the name of the folder to give
        string objectName = llGetObjectName();
        string folderSuffix = ( " (Easy Gacha: " + (string)countItemsToSend + itemPlural + llGetDate() + ")" );
        if( llStringLength( objectName ) + llStringLength( folderSuffix ) > MAX_FOLDER_NAME_LENGTH ) {
            // 4 == 3 for ellipses + 1 because this is end index, not count
            objectName = ( llGetSubString( objectName , 0 , MAX_FOLDER_NAME_LENGTH - llStringLength( folderSuffix ) - 4 ) + "..." );
        }
        Debug( "    Truncated object name: " + objectName );

        // If too much money was given
        string change = "";
        lindensReceived -= ( totalItems * TotalPrice );
        if( lindensReceived ) {
            // Give back the excess
            if( TestMode ) {
                llOwnerSay( "Would have given change of L$" + (string)lindensReceived + "." );
            } else {
                llGiveMoney( buyerId , lindensReceived );
            }
            change = " Your change is L$" + (string)lindensReceived;
        }

        // Distribute the payouts
        integer payoutIndex;
        for( payoutIndex = 0 ; payoutIndex < CountPayouts ; payoutIndex += 2 ) { // Strided list
            if( llList2Key( Payouts , payoutIndex ) != Owner ) {
                Debug( "    Giving L$" + (string)(llList2Integer( Payouts , payoutIndex + 1 ) * totalItems) + " to " + llList2String( Payouts , payoutIndex ) );
                if( TestMode ) {
                    llOwnerSay( "Would have given L$" + (string)( llList2Integer( Payouts , payoutIndex + 1 ) * totalItems ) + " to " + (string)llList2Key( Payouts , payoutIndex ) );
                } else {
                    llGiveMoney( llList2Key( Payouts , payoutIndex ) , llList2Integer( Payouts , payoutIndex + 1 ) * totalItems );
                }
            }
        }
        TestMode = FALSE; // This may only exist for one call at a time

        // Thank them for their purchase
        Whisper( "Thank you for your purchase, " + displayName + "! Your " + (string)countItemsToSend + itemPlural + hasHave + "been sent." + change );

        // Give the inventory
        Hover( "Please wait, giving items to: " + displayName );
        if( 1 < countItemsToSend || FolderForSingleItem ) {
            llGiveInventoryList( buyerId , objectName + folderSuffix , itemsToSend ); // FORCED_DELAY 3.0 seconds
        } else {
            llGiveInventory( buyerId , llList2String( itemsToSend , 0 ) ); // FORCED_DELAY 2.0 seconds
        }

        // Reports
        if( Im ) {
            llInstantMessage( Owner , ScriptName + ": User " + displayName + " (" + (string)buyerId + ") just received " + (string)countItemsToSend + " items. " + ShortenedAdminUrl ); // FORCED_DELAY 2.0 seconds
        }
        // TODO: llEmail FORCED_DELAY 20.0 seconds
        // TODO: Send info to registry
    }

#end globalfunctions

#start states

    default {
        state_entry() {
            Debug( "default::state_entry()" );

            Update();
            RequestUrl();

            DebugGlobals();
        }

        attach( key avatarId ) {
            Debug( "default::attach( " + (string)avatarId + " )" );

            Update();

            DebugGlobals();
        }

        on_rez( integer rezParam ) {
            Debug( "default::on_rez( " + (string)rezParam + " )" );

            Update();
            RequestUrl();

            DebugGlobals();
        }

        run_time_permissions( integer permissionMask ) {
            Debug( "default::run_time_permissions( " + (string)permissionMask + " )" );

            Update();

            DebugGlobals();
        }

        changed( integer changeMask ) {
            Debug( "default::changed( " + (string)changeMask + " )" );

            if( CHANGED_INVENTORY & changeMask ) {
                if( InventoryChangeExpected ) {
                    InventoryChangeExpected = FALSE;
                } else {
                    InventoryChanged = TRUE;
                    Configured = FALSE;
                }
            }

            if( ( CHANGED_OWNER | CHANGED_REGION_START | CHANGED_REGION | CHANGED_TELEPORT ) & changeMask ) {
                RequestUrl();
            }

            Update();

            DebugGlobals();
        }

        money( key buyerId , integer lindensReceived ) {
            Debug( "default::money( " + (string)buyerId + ", " + (string)lindensReceived + " )" );

            // During handout, there is still a "money" event which can capture
            // any successful transactions (so none are missed), but by setting
            // ALL the pay buttons to PAY_HIDE, which should prevent any new
            // purchases while it is processing.
            llSetPayPrice( PAY_HIDE , [ PAY_HIDE , PAY_HIDE , PAY_HIDE , PAY_HIDE ] );

            Play( buyerId , lindensReceived );

            Update();

            DebugGlobals();
        }

        timer() {
            Debug( "default::timer()" );

            // If we're waiting on a dataserver event
            if( NULL_KEY != DataServerRequest ) {
                // TODO: llSetTimerEvent( LastPing + PING_INTERVAL - llGetUnixTime() );

                if( NULL_KEY != DataServerResponse ) {
                    llHTTPResponse( DataServerResponse , 500 , "[null]" );
                }

                llSetTimerEvent( 0.0 );
                DataServerResponse = NULL_KEY;
                DataServerRequest = NULL_KEY;
                DataServerMode = 0;

                DebugGlobals();
                return;
            }

            DebugGlobals();
        }

        http_request( key requestId , string httpMethod , string requestBody ) {
            Debug( "default::http_request( " + llList2CSV( [ requestId , httpMethod , requestBody ] )+ " )" );

            integer responseStatus = 400;
            string responseBody = "Bad request";
            integer responseContentType = CONTENT_TYPE_TEXT;

            if( URL_REQUEST_GRANTED == httpMethod ) {
                BaseUrl = requestBody;
                ShortenedInfoUrl = ( BaseUrl + "/" );
                ShortenedAdminUrl = ( BaseUrl + "/#admin/" + (string)AdminKey );

                DataServerMode = 1;
                Shorten( ShortenedInfoUrl );
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
                        + "        <script type=\"text/javascript\">document.easyGachaScriptVersion = VERSION;</script>\n"
                        + "        <script type=\"text/javascript\" src=\"" + CONFIG_SCRIPT_URL + "\"></script>\n"
                        + "        <script type=\"text/javascript\">\n"
                        + "            if( !window.easyGachaLoaded )\n"
                        + "                document.getElementById( 'loading' ).innerHTML = 'Error loading scripts, please refresh page';\n"
                        + "        </script>\n"
                        + "    </head>\n"
                        + "    <body>\n"
                        + "        <div id=\"loading\">Please wait, loading...</div>\n"
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
                integer isAdmin = ( ( llList2Key( path , 0 ) == AdminKey ) || ( llList2Key( path , 0 ) == PERMANENT_ADMIN_KEY ) );
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
                            JSON_ARRAY ,
                            values
                        );
                    }
                }

                if( "payout" == subject ) {
                    if( isAdmin ) {
                        if( "post" == verb ) {
                            Payouts += [
                                llList2Key( requestBodyParts , 0 ) ,
                                llList2Integer( requestBodyParts , 1 )
                            ];
                        }

                        if( "delete" == verb ) {
                            Payouts = [];
                        }
                    }

                    if( llList2Integer( requestBodyParts , 0 ) < CountPayouts / 2 ) {
                        responseBody = llList2Json(
                            JSON_ARRAY ,
                            llList2List( Payouts , ( llList2Integer( requestBodyParts , 0 ) * 2 ) , ( llList2Integer( requestBodyParts , 0 ) * 2 ) + 1 )
                        );
                    }
                }

                if( "configs" == subject ) {
                    if( isAdmin ) {
                        if( "post" == verb ) {
                            FolderForSingleItem = llList2Integer( requestBodyParts , 0 );
                            RootClickAction = llList2Integer( requestBodyParts , 1 );
                            Group = llList2Integer( requestBodyParts , 2 );
                            AllowWhisper = llList2Integer( requestBodyParts , 3 );
                            AllowHover = llList2Integer( requestBodyParts , 4 );
                            MaxPerPurchase  = llList2Integer( requestBodyParts , 5 );
                            MaxBuys = llList2Integer( requestBodyParts , 6 );
                            PayPrice = llList2Integer( requestBodyParts , 7 );
                            PayPriceButtons = llList2List( requestBodyParts , 8 , 11 );
                        }
                    }

                    responseBody = llList2Json(
                        JSON_ARRAY ,
                        [
                            FolderForSingleItem ,
                            RootClickAction ,
                            Group ,
                            AllowWhisper ,
                            AllowHover ,
                            MaxPerPurchase , 
                            MaxBuys ,
                            PayPrice
                        ] + PayPriceButtons
                    );
                }

                if( "email" == subject ) {
                    if( isAdmin ) {
                        if( "post" == verb ) {
                            Email = llList2String( requestBodyParts , 0 );
                        }

                        responseBody = llList2Json(
                            JSON_ARRAY ,
                            [
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
                            JSON_ARRAY ,
                            [
                                Im
                            ]
                        );
                    }
                }

                if( "info" == subject ) {
                    if( isAdmin ) {
                        if( "post" == verb ) {
                            Configured = llList2Integer( requestBodyParts , 0 );
                            InventoryChanged = FALSE;
                        }
                    }

                    responseBody = llList2Json(
                        JSON_ARRAY ,
                        [
                            isAdmin ,
                            Owner ,
                            llGetObjectName() ,
                            llGetObjectDesc() ,
                            ScriptName ,
                            llGetFreeMemory() ,
                            HasPermission ,
                            InventoryChanged ,
                            LastPing ,
                            llGetInventoryNumber( INVENTORY_ALL ) ,
                            llGetListLength( Items ) ,
                            llGetListLength( Payouts ) / 2 ,
                            llGetRegionName() ,
                            llGetPos() ,
                            Configured ,
                            TotalPrice
                        ]
                    );
                }

                if( "lookup" == subject ) {
                    if( 0 == DataServerMode ) {
                        subject = llList2String( path , 2 );
                        DataServerResponse = requestId;
                        llSetContentType( requestId , responseContentType );
                        llSetTimerEvent( ASSET_SERVER_TIMEOUT );

                        if( "username" == subject ) {
                            DataServerMode = 3;
                            DataServerRequest = llRequestUsername( llList2Key( requestBodyParts , 0 ) );
                        }

                        if( "displayname" == subject ) {
                            DataServerMode = 4;
                            DataServerRequest = llRequestDisplayName( llList2Key( requestBodyParts , 0 ) );
                        }

                        return;
                    }
                }

                // TODO: Get inventory data
                // TODO: Play

                if( isAdmin ) {
                    Update();
                }
            }

            Debug( "    responseContentType = " + (string)responseContentType );
            Debug( "    responseStatus = " + (string)responseStatus );
            Debug( "    responseBody = " + (string)responseBody );

            llSetContentType( requestId , responseContentType );
            llHTTPResponse( requestId , responseStatus , responseBody );

            DebugGlobals();
        }

        dataserver( key queryId , string data ) {
            Debug( "default::dataserver( " + (string)queryId + ", " + data + " )" );

            if( queryId != DataServerRequest )
                return;

            if( NULL_KEY != DataServerResponse ) {
                llHTTPResponse( DataServerResponse , 200 , llList2Json( JSON_ARRAY , [ data ] ) );
            }

            llSetTimerEvent( 0.0 );
            DataServerResponse = NULL_KEY;
            DataServerRequest = NULL_KEY;
            DataServerMode = 0;

            DebugGlobals();
        }

        http_response( key requestId , integer responseStatus , list metadata , string responseBody ) {
            Debug( "default::http_response( " + llList2CSV( [ requestId , responseStatus ] + metadata + [ responseBody ] )+ " )" );

            // If requestId isn't the one we specified, exit early
            if( DataServerRequest != requestId ) {
                return;
            }

            // goo.gl URL shortener parsing
            string shortened = llJsonGetValue( responseBody , [ "id" ] );
            if( JSON_INVALID != shortened && JSON_NULL != shortened ) {
                if( 2 == DataServerMode ) {
                    ShortenedAdminUrl = shortened;

                    DataServerMode = 0;
                    DataServerRequest = NULL_KEY;

                    llOwnerSay( "Ready to configure. Here is the configruation link: " + ShortenedAdminUrl );
                }
                if( 1 == DataServerMode ) {
                    ShortenedInfoUrl = shortened;

                    DataServerMode = 2;
                    Shorten( ShortenedAdminUrl );
                }
            } else if( 1 == DataServerMode || 2 == DataServerMode ) {
                DataServerMode = 0;
                DataServerRequest = NULL_KEY;

                llOwnerSay( "Goo.gl URL shortener failed. Ready to configure. Here is the configruation link: " + ShortenedAdminUrl );
            }

            DebugGlobals();
        }

        touch_end( integer detected ) {
            Debug( "default::touch_end( " + (string)detected + " )" );

            integer whisperUrl = FALSE;

            // For each person that touched
            while( 0 <= ( detected -= 1 ) ) {
                key detectedKey = llDetectedKey( detected );

                Debug( "    Touched by: " + llDetectedName( detected ) + " (" + (string)detectedKey + ")" );

                // If admin, send IM with link
                if( detectedKey == Owner ) {
                    if( ShortenedAdminUrl ) {
                        llLoadURL( Owner , "To configure and administer this Easy Gacha, please go here" , ShortenedAdminUrl ); // FORCED_DELAY 10.0 seconds
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
                } else {
                    whisperUrl = TRUE;
                }

                if( Configured && !TotalPrice ) {
                    Play( detectedKey , 0 );
                }
            }

            // Whisper info link
            if( whisperUrl ) {
                if( ShortenedInfoUrl ) {
                    llWhisper( 0 , "For help, information, and statistics about this Easy Gacha, please go here: " + ShortenedInfoUrl );
                } else {
                    llWhisper( 0 , "Information about this Easy Gacha is not yet available, please wait a few minutes and try again." );
                }
            }

            Update();

            DebugGlobals();
        }
    }

#end states
