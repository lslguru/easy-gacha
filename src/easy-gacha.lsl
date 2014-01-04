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
#define DEFAULT_CONFIG_URL_BASE "http:\/\/lslguru.github.io/easy-gacha/v5/index.html#"
#define HTTP_OPTIONS [ HTTP_METHOD , "POST" , HTTP_MIMETYPE , "text/json;charset=utf-8" , HTTP_BODY_MAXLENGTH , 16384 , HTTP_VERIFY_CERT , FALSE , HTTP_VERBOSE_THROTTLE , FALSE ]
#define REGISTRY_URL ""
#define PERMANENT_KEY ""

// System constraints
// TODO: #define MAX_FOLDER_NAME_LENGTH 63

// Tweaks
#define ASSET_SERVER_TIMEOUT 5.0

// Inventory
#define CONFIG_NOTECARD "Easy Gacha Config"
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
    integer DataServerMode; // Which kind of request is happening, 0 = none, 1 = goo.gl for info, 2 = goo.gl for admin
    integer InventoryChanged; // Indicates the inventory changed since last check
    integer InventoryChangeExpected; // When we give out no-copy items...
    integer NextPing; // UnixTime
    integer TotalPrice; // Updated when Payouts is updated, sum

#end globalvariables

#start globalfunctions

    Debug( string msg ) {
        if( INVENTORY_NONE != llGetInventoryType( DEBUG_INVENTORY ) ) {
            llOwnerSay( "/me : " + llGetScriptName() + ": DEBUG: " + msg );
        }
    }

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

    HttpRequest( list data ) {
        Debug( "HttpRequest( [ " + llList2CSV( data ) + " ] );" );

        if( "" == REGISTRY_URL ) {
            return;
        }

        llHTTPRequest( REGISTRY_URL , HTTP_OPTIONS , llList2Json( JSON_ARRAY , data ) );

        llSleep( 1.0 ); // FORCED_DELAY 1.0 seconds
    }

    DebugGlobals() {
        Debug( "DebugGlobals()" );
        Debug( "    Items = " + llList2CSV( Items ) );
        Debug( "    Rarity = " + llList2CSV( Rarity ) );
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
        Debug( "    NextPing = " + (string)NextPing );
        Debug( "    TotalPrice = " + (string)TotalPrice );
        Debug( "    Free memory: " + (string)llGetFreeMemory() );
    }

    RequestUrl() {
        Debug( "RequestUrl()" );
        llReleaseURL( BaseUrl );

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
            llSetTouchText( "Play" );
        } else {
            llSetTouchText( "Info" );
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

        // Far more simplistic config statement
        if( Configured ) {
            Hover( "" );
        } else {
            // TODO: Be more descriptive here
            Hover( "Configuration needed, please touch this object" );
        }

        // Calculate total price from payouts
        TotalPrice = (integer)llListStatistics( LIST_STAT_SUM , Payouts );

        // TODO
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

#end globalfunctions

#start states

    default {
        state_entry() {
            Debug( "default::state_entry()" );

            // If the notecard isn't there, we'll auto-configure
            if( INVENTORY_NOTECARD != llGetInventoryType( CONFIG_NOTECARD ) ) {
                state running;
            }

            // If the notecard is brand new or doesn't have full-perm, we
            // cannot read it
            if( NULL_KEY == llGetInventoryKey( CONFIG_NOTECARD ) ) {
                llOwnerSay( "Config notecard is either not full-perm or is new and empty, skipping: " + CONFIG_NOTECARD );

                state running;
            }

            llOwnerSay( "Loading previous config from: " + CONFIG_NOTECARD );

            // Co-opt this value for now
            DataServerMode = 0;
            DataServerRequest = llGetNotecardLine( CONFIG_NOTECARD , DataServerMode );
            llSetTimerEvent( ASSET_SERVER_TIMEOUT );

            DebugGlobals();
        }

        dataserver( key queryId , string data ) {
            Debug( "default::dataserver( " + (string)queryId + ", " + data + " )" );

            if( EOF == data ) {
                llOwnerSay( "Previous config loaded. Starting up..." );

                DataServerMode = 0;
                DebugGlobals();
                state running;
            }

            list parts = llParseString2List( data , [ "\t" ] , [ ] );
            if( "inv" == llList2String( parts , 0 ) ) {
                Rarity += [ llList2Float( parts , 1 ) ];
                Limit += [ llList2Integer( parts , 2 ) ];
                Bought += [ llList2Integer( parts , 3 ) ];
                Items += [ llDumpList2String( llList2List( parts , 4 , -1 ) , "\t" ) ];
            }
            if( "payout" == llList2String( parts , 0 ) ) {
                Payouts += [ llList2Key( parts , 1 ) , llList2Integer( parts , 2 ) ];
            }
            if( "configs" == llList2String( parts , 0 ) ) {
                FolderForSingleItem = llList2Integer( parts , 1 );
                RootClickAction = llList2Integer( parts , 2 );
                Group = llList2Integer( parts , 3 );
                AllowWhisper = llList2Integer( parts , 4 );
                AllowHover = llList2Integer( parts , 5 );
                MaxPerPurchase = llList2Integer( parts , 6 );
                MaxBuys = llList2Integer( parts , 7 );
                PayPrice = llList2Integer( parts , 8 );
                PayPriceButtons = [
                    llList2Integer( parts , 9 ) ,
                    llList2Integer( parts , 10 ) ,
                    llList2Integer( parts , 11 ) ,
                    llList2Integer( parts , 12 )
                ];
            }
            if( "email" == llList2String( parts , 0 ) ) {
                Email = llDumpList2String( llList2List( parts , 1 , -1 ) , "\t" );
            }
            if( "im" == llList2String( parts , 0 ) ) {
                Im = llList2Key( parts , 1 );
            }
            if( "configured" == llList2String( parts , 0 ) ) {
                Configured = llList2Integer( parts , 1 );
            }

            ++DataServerMode;
            DataServerRequest = llGetNotecardLine( CONFIG_NOTECARD , DataServerMode );

            DebugGlobals();
        }

        timer() {
            Debug( "default::timer()" );

            llSetTimerEvent( 0.0 );

            llOwnerSay( "Timed out while reading notecard. Config has NOT been fully loaded, but proceeding to runtime. The dataserver may be having problems. Please touch this object and check the config." );

            DataServerMode = 0;
            DebugGlobals();
            state running;
        }
    }

    state running {
        state_entry() {
            Debug( "running::state_entry()" );

            Update();
            RequestUrl();

            DebugGlobals();
        }

        attach( key avatarId ) {
            Debug( "running::attach( " + (string)avatarId + " )" );

            Update();

            DebugGlobals();
        }

        on_rez( integer rezParam ) {
            Debug( "running::on_rez( " + (string)rezParam + " )" );

            Update();
            RequestUrl();

            DebugGlobals();
        }

        run_time_permissions( integer permissionMask ) {
            Debug( "running::run_time_permissions( " + (string)permissionMask + " )" );

            Update();

            DebugGlobals();
        }

        changed( integer changeMask ) {
            Debug( "running::changed( " + (string)changeMask + " )" );

            if( CHANGED_INVENTORY & changeMask ) {
                InventoryChanged = TRUE;
            }

            if( ( CHANGED_REGION_START | CHANGED_REGION | CHANGED_TELEPORT ) & changeMask ) {
                RequestUrl();
            }

            Update();

            DebugGlobals();
        }

        dataserver( key queryId , string data ) {
            Debug( "running::dataserver( " + (string)queryId + ", " + data + " )" );

            if( queryId != DataServerRequest )
                return;

            llSetTimerEvent( 0.0 );
            DataServerRequest = NULL_KEY;
            DataServerMode = 0;

            DebugGlobals();
        }

        money( key buyerId , integer lindensReceived ) {
            Debug( "running::money( " + (string)buyerId + ", " + (string)lindensReceived + " )" );

            // During handout, there is still a "money" event which can capture
            // any successful transactions (so none are missed), but by setting
            // ALL the pay buttons to PAY_HIDE, which should prevent any new
            // purchases while it is processing.
            llSetPayPrice( PAY_HIDE , [ PAY_HIDE , PAY_HIDE , PAY_HIDE , PAY_HIDE ] );

            // TODO

            Update();

            DebugGlobals();
        }

        timer() {
            Debug( "running::timer()" );

            // If we're waiting on a dataserver event
            if( NULL_KEY != DataServerRequest ) {
                llSetTimerEvent( NextPing - llGetUnixTime() );

                // TODO: Handle dataserver or http_response timeout

                DataServerRequest = NULL_KEY;
                DataServerMode = 0;

                DebugGlobals();
                return;
            }

            // TODO

            DebugGlobals();
        }

        http_request( key requestId , string httpMethod , string requestBody ) {
            Debug( "running::http_request( " + llList2CSV( [ requestId , httpMethod , requestBody ] )+ " )" );

            integer responseStatus = 400;
            string responseBody = "Bad request";

            if( URL_REQUEST_GRANTED == httpMethod ) {
                BaseUrl = requestBody;
                ShortenedInfoUrl = DEFAULT_CONFIG_URL_BASE + llEscapeURL( BaseUrl );
                ShortenedAdminUrl = DEFAULT_CONFIG_URL_BASE + llEscapeURL( BaseUrl + "/" + (string)AdminKey );

                llOwnerSay( "URL obtained, this Easy Gacha can now be configured. Touch to configure." );

                DataServerMode = 1;
                Shorten( ShortenedInfoUrl );
            }

            if( URL_REQUEST_DENIED ) {
                // TODO
            }

            if( "post" == llToLower( httpMethod ) ) {
                // TODO: llGetFreeMemory()
            }

            llHTTPResponse( requestId , responseStatus , responseBody );

            DebugGlobals();
        }

        http_response( key requestId , integer responseStatus , list metadata , string responseBody ) {
            Debug( "running::http_response( " + llList2CSV( [ requestId , responseStatus ] + metadata + [ responseBody ] )+ " )" );

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
                }
                if( 1 == DataServerMode ) {
                    ShortenedInfoUrl = shortened;

                    DataServerMode = 2;
                    Shorten( ShortenedAdminUrl );
                }
            }

            DebugGlobals();
        }

        touch_end( integer detected ) {
            Debug( "running::touch_end( " + (string)detected + " )" );

            // If URL not set but URLs available, request one
            if( "" == BaseUrl && llGetFreeURLs() ) {
                llOwnerSay( "Trying to get a new URL now..." );
                RequestUrl();
            }

            // For each person that touched
            while( 0 <= ( detected -= 1 ) ) {
                key detectedKey = llDetectedKey( detected );
                string detectedName = llDetectedName( detected );

                Debug( "    Touched by: " + detectedName + " (" + (string)detectedKey + ")" );

                // If admin, send IM with link
                if( detectedKey == Owner ) {
                    if( ShortenedAdminUrl ) {
                        llOwnerSay( "To configure and administer this Easy Gacha, please go here: " + ShortenedAdminUrl );
                    } else {
                        llOwnerSay( "No URLs are available on this parcel/sim, so the configuration screen cannot be shown. Please slap whoever is consuming all the URLs and try again." );
                    }
                }

                // TODO: Play if Configured and !price
            }

            // Whisper info link
            if( ShortenedInfoUrl ) {
                llWhisper( 0 , "For help, information, and statistics about this Easy Gacha, please go here: " + ShortenedInfoUrl );
            } else {
                llWhisper( 0 , "Information about this Easy Gacha is not yet available, please wait a few minutes and try again." );
            }

            DebugGlobals();
        }
    }

#end states
