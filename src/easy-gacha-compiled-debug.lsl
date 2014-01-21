list Items;
list Rarity;
list Limit;
list Bought;
list Payouts;
integer MaxPerPurchase = 50 /*DEFAULT_MAX_PER_PURCHASE*/;
integer PayPrice = PAY_HIDE;
integer PayPriceButton0 = PAY_HIDE;
integer PayPriceButton1 = PAY_HIDE;
integer PayPriceButton2 = PAY_HIDE;
integer PayPriceButton3 = PAY_HIDE;
integer FolderForSingleItem = TRUE;
integer RootClickAction = -1;
integer Group = FALSE;
string Email;
key Im;
integer AllowHover = TRUE;
integer MaxBuys = -1;
integer Configured;
string Extra;
integer ApiPurchasesEnabled;
integer ApiItemsGivenEnabled;
integer Ready;
key AdminKey;
string BaseUrl;
string ShortenedInfoUrl;
string ShortenedAdminUrl;
key Owner;
string ScriptName;
integer HasPermission;
list DataServerRequests;
list DataServerRequestTimes;
list DataServerRequestTypes;
list DataServerResponses;
integer LastPing;
integer TotalPrice;
integer TotalBought;
integer TotalLimit;
integer HasUnlimitedItems;
integer HasNoCopyItemsForSale;
float TotalEffectiveRarity;
integer CountItems;
integer CountPayouts;
integer LastWhisperedUrl;
Debug( string msg ) { if( INVENTORY_NONE != llGetInventoryType( "easy-gacha-debug" /*DEBUG_INVENTORY*/ ) ) { llOwnerSay( "/me : " + llGetScriptName() + ": DEBUG: " + msg ); } }
Whisper( string msg ) {
Debug( "Whisper( \"" + msg + "\" );" );
llWhisper( 0 , llGetScriptName() + ": " + msg );
}
Hover( string msg ) {
Debug( "Hover( \"" + msg + "\" );" );
if( AllowHover ) {
if( msg ) {
llSetText( llGetObjectName() + ": " + llGetScriptName() + ":\n" + msg + "\n|\n|\n|\n|\n|\n_\nV" , <1,0,0>, 1 );
} else {
llSetText( "" , ZERO_VECTOR , 1 );
}
}
}
Registry( list data ) {
Debug( "Registry( [ " + llList2CSV( data ) + " ] );" );
return; /*REGISTRY_DISABLED*/
llHTTPRequest( "" /*REGISTRY_URL*/ , [ HTTP_METHOD , "POST" , HTTP_MIMETYPE , "text/json;charset=utf-8" , HTTP_BODY_MAXLENGTH , 16384 , HTTP_VERIFY_CERT , FALSE , HTTP_VERBOSE_THROTTLE , FALSE , "X-EasyGacha-Version" , "5.0" /*VERSION*/ ] /*REGISTRY_HTTP_OPTIONS*/ , llList2Json( JSON_ARRAY , data ) );
llSleep( 1.0 );
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
Debug( "    PayPriceButton0 = " + (string)PayPriceButton0 );
Debug( "    PayPriceButton1 = " + (string)PayPriceButton1 );
Debug( "    PayPriceButton2 = " + (string)PayPriceButton2 );
Debug( "    PayPriceButton3 = " + (string)PayPriceButton3 );
Debug( "    FolderForSingleItem = " + (string)FolderForSingleItem );
Debug( "    RootClickAction = " + (string)RootClickAction );
Debug( "    Group = " + (string)Group );
Debug( "    Email = " + Email );
Debug( "    Im = " + (string)Im );
Debug( "    AllowHover = " + (string)AllowHover );
Debug( "    MaxBuys = " + (string)MaxBuys );
Debug( "    Configured = " + (string)Configured );
Debug( "    Extra = " + Extra );
Debug( "    ApiPurchasesEnabled = " + (string)ApiPurchasesEnabled );
Debug( "    ApiItemsGivenEnabled = " + (string)ApiItemsGivenEnabled );
Debug( "    Ready = " + (string)Ready );
Debug( "    AdminKey = " + (string)AdminKey );
Debug( "    BaseUrl = " + BaseUrl );
Debug( "    ShortenedInfoUrl = " + ShortenedInfoUrl );
Debug( "    ShortenedAdminUrl = " + ShortenedAdminUrl );
Debug( "    Owner = " + (string)Owner );
Debug( "    ScriptName = " + ScriptName );
Debug( "    HasPermission = " + (string)HasPermission );
Debug( "    DataServerRequests = " + llList2CSV( DataServerRequests ) );
Debug( "    DataServerRequestTimes = " + llList2CSV( DataServerRequestTimes ) );
Debug( "    DataServerRequestTypes = " + llList2CSV( DataServerRequestTypes ) );
Debug( "    DataServerResponses = " + llList2CSV( DataServerResponses ) );
Debug( "    LastPing = " + (string)LastPing );
Debug( "    TotalPrice = " + (string)TotalPrice );
Debug( "    TotalBought = " + (string)TotalBought );
Debug( "    TotalLimit = " + (string)TotalLimit );
Debug( "    HasUnlimitedItems = " + (string)HasUnlimitedItems );
Debug( "    HasNoCopyItemsForSale = " + (string)HasNoCopyItemsForSale );
Debug( "    TotalEffectiveRarity = " + (string)TotalEffectiveRarity );
Debug( "    CountItems = " + (string)CountItems );
Debug( "    CountPayouts = " + (string)CountPayouts );
Debug( "    Last whispered URL unixtime: " + (string)LastWhisperedUrl );
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
integer ItemUsable( integer itemIndex ) {
if( INVENTORY_NONE != llGetInventoryType( llList2String( Items , itemIndex ) ) ) {
if( PERM_TRANSFER & llGetInventoryPermMask( llList2String( Items , itemIndex ) , MASK_OWNER ) ) {
if( -1 == llList2Integer( Limit , itemIndex ) || llList2Integer( Bought , itemIndex ) < llList2Integer( Limit , itemIndex ) ) {
return TRUE;
}
}
}
return FALSE;
}
Update() {
Debug( "Update()" );
Owner = llGetOwner();
ScriptName = llGetScriptName();
HasPermission = ( ( llGetPermissionsKey() == Owner ) && llGetPermissions() & PERMISSION_DEBIT );
TotalPrice = (integer)llListStatistics( LIST_STAT_SUM , Payouts );
TotalBought = (integer)llListStatistics( LIST_STAT_SUM , Bought );
CountItems = llGetListLength( Items );
CountPayouts = llGetListLength( Payouts );
HasUnlimitedItems = ( -1 != llListFindList( Limit , [ -1 ] ) );
integer itemIndex;
TotalLimit = 0;
TotalEffectiveRarity = 0.0;
HasNoCopyItemsForSale = FALSE;
for( itemIndex = 0 ; itemIndex < CountItems ; ++itemIndex ) {
if( 0 < llList2Integer( Limit , itemIndex ) ) {
TotalLimit += llList2Integer( Limit , itemIndex );
}
if( ItemUsable( itemIndex ) ) {
TotalEffectiveRarity += llList2Float( Rarity , itemIndex );
if( ! ( PERM_COPY & llGetInventoryPermMask( llList2String( Items , itemIndex ) , MASK_OWNER ) ) ) {
HasNoCopyItemsForSale = TRUE;
}
}
}
Ready = FALSE;
if( Configured ) {
Ready = TRUE;
if( TotalPrice && !HasPermission ) {
Ready = FALSE;
}
if( TotalBought >= MaxBuys ) {
Ready = FALSE;
}
if( 0.0 == TotalEffectiveRarity ) {
Ready = FALSE;
}
if( Group && llSameGroup( NULL_KEY ) ) {
Ready = FALSE;
}
}
if( Ready && TotalPrice ) {
if( HasNoCopyItemsForSale ) {
llSetPayPrice( PAY_HIDE , [ TotalPrice , PAY_HIDE , PAY_HIDE , PAY_HIDE ] );
} else {
llSetPayPrice( PayPrice , [ PayPriceButton0 , PayPriceButton1 , PayPriceButton2 , PayPriceButton3 ] );
}
} else {
llSetPayPrice( PAY_HIDE , [ PAY_HIDE , PAY_HIDE , PAY_HIDE , PAY_HIDE ] );
}
if( !Ready ) {
llSetTouchText( "Config" );
} else if( TotalPrice ) {
llSetTouchText( "Info" );
} else {
llSetTouchText( "Play" );
}
if( TRUE == RootClickAction || LINK_ROOT != llGetLinkNumber() ) {
if( Ready && TotalPrice ) {
llSetClickAction( CLICK_ACTION_PAY );
} else {
llSetClickAction( CLICK_ACTION_TOUCH );
}
}
if( Ready ) {
if( -1 != llListFindList( DataServerRequestTypes , [ 1 ] ) || -1 != llListFindList( DataServerRequestTypes , [ 2 ] ) ) {
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
Shorten( string url ) {
Debug( "Shorten( \"" + url + "\" )" );
DataServerRequests += [ llHTTPRequest(
"https:\/\/www.googleapis.com/urlshortener/v1/url"
, [
HTTP_METHOD , "POST"
, HTTP_MIMETYPE , "application/json"
, HTTP_BODY_MAXLENGTH , 16384
, HTTP_VERIFY_CERT , TRUE
, HTTP_VERBOSE_THROTTLE , FALSE
]
, llJsonSetValue( "{}" , [ "longUrl" ] , url )
) ];
DataServerRequestTimes += [ llGetUnixTime() ];
DataServerResponses += [ NULL_KEY ];
}
Play( key buyerId , integer lindensReceived ) {
Debug( "Play( " + (string)buyerId + " , " + (string)lindensReceived + " )" );
string displayName = llGetDisplayName( buyerId );
Hover( "Please wait, getting random items for: " + displayName );
integer totalItems;
if( TotalPrice ) {
totalItems = lindensReceived / TotalPrice;
} else {
totalItems = 1;
}
if( HasNoCopyItemsForSale ) {
totalItems = 1;
Debug( "    HasNoCopyItemsForSale, set to: 1" );
}
if( totalItems > MaxPerPurchase ) {
totalItems = MaxPerPurchase;
Debug( "    totalItems > MaxPerPurchase, set to: " + (string)totalItems );
}
if( -1 != MaxBuys && totalItems > MaxBuys - TotalBought ) {
totalItems = MaxBuys - TotalBought;
Debug( "    totalItems > MaxBuysRemaining, set to: " + (string)totalItems );
}
if( !HasUnlimitedItems && totalItems > TotalLimit - TotalBought ) {
totalItems = TotalLimit - TotalBought;
Debug( "    totalItems > RemainingInventory, set to: " + (string)totalItems );
}
if( Group && !llSameGroup( buyerId ) ) {
totalItems = 0;
Debug( "    Not in same group, totalItems = 0" );
}
list itemsToSend = [];
integer countItemsToSend = 0;
float random;
integer itemIndex;
while( countItemsToSend < totalItems ) {
Hover( "Please wait, getting random item " + (string)( countItemsToSend + 1 ) + " of " + (string)totalItems + " for: " + displayName );
random = TotalEffectiveRarity - llFrand( TotalEffectiveRarity );
Debug( "    random = " + (string)random );
for( itemIndex = 0 ; itemIndex < CountItems && random > 0.0 ; ++itemIndex ) {
if( ItemUsable( itemIndex ) ) {
random -= llList2Float( Rarity , itemIndex );
}
}
--itemIndex;
Debug( "    index of item = " + (string)itemIndex );
itemsToSend += [ llList2String( Items , itemIndex ) ];
Debug( "    Item picked: " + llList2String( Items , itemIndex ) );
++countItemsToSend;
Bought = llListReplaceList( Bought , [ llList2Integer( Bought , itemIndex ) + 1 ] , itemIndex , itemIndex );
++TotalBought;
if( ! ItemUsable( itemIndex ) ) {
TotalEffectiveRarity -= llList2Float( Rarity , itemIndex );
Debug( "    Inventory has run out for item! TotalEffectiveRarity = " + (string)TotalEffectiveRarity );
}
}
string itemPlural = " items ";
string hasHave = "have ";
if( 1 == countItemsToSend ) {
itemPlural = " item ";
hasHave = "has ";
}
string objectName = llList2String( llGetLinkPrimitiveParams( LINK_THIS , [ PRIM_NAME ] ) , 0 );
if( "" == objectName || "Object" == objectName ) {
objectName = llGetObjectName();
}
string folderSuffix = ( " (Easy Gacha: " + (string)countItemsToSend + itemPlural + llGetDate() + ")" );
if( llStringLength( objectName ) + llStringLength( folderSuffix ) > 63 /*MAX_FOLDER_NAME_LENGTH*/ ) {
objectName = ( llGetSubString( objectName , 0 , 63 /*MAX_FOLDER_NAME_LENGTH*/ - llStringLength( folderSuffix ) - 4 ) + "..." );
}
Debug( "    Truncated object name: " + objectName );
string change = "";
lindensReceived -= ( totalItems * TotalPrice );
if( lindensReceived ) {
llGiveMoney( buyerId , lindensReceived );
change = " Your change is L$" + (string)lindensReceived;
}
integer payoutIndex;
for( payoutIndex = 0 ; payoutIndex < CountPayouts ; payoutIndex += 2 ) {
if( llList2Key( Payouts , payoutIndex ) != Owner && 0 < llList2Integer( Payouts , payoutIndex + 1 ) ) {
Debug( "    Giving L$" + (string)(llList2Integer( Payouts , payoutIndex + 1 ) * totalItems) + " to " + llList2String( Payouts , payoutIndex ) );
llGiveMoney( llList2Key( Payouts , payoutIndex ) , llList2Integer( Payouts , payoutIndex + 1 ) * totalItems );
}
}
Whisper( "Thank you for your purchase, " + displayName + "! Your " + (string)countItemsToSend + itemPlural + hasHave + "been sent." + change );
Hover( "Please wait, giving items to: " + displayName );
if( 1 < countItemsToSend || ( FolderForSingleItem && !HasNoCopyItemsForSale ) ) {
llGiveInventoryList( buyerId , objectName + folderSuffix , itemsToSend );
} else {
llGiveInventory( buyerId , llList2String( itemsToSend , 0 ) );
}
if( Im ) {
llInstantMessage( Owner , ScriptName + ": User " + displayName + " (" + llGetUsername(buyerId) + ") just received " + (string)countItemsToSend + " items. " + ShortenedInfoUrl );
}
if( Email ) {
llEmail( Email , llGetObjectName() + " - Easy Gacha Played" , displayName + " (" + llGetUsername(buyerId) + ") just received the following items:\n\n" + llDumpList2String( itemsToSend , "\n" ) );
}
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
if( ( CHANGED_OWNER | CHANGED_REGION_START | CHANGED_REGION | CHANGED_TELEPORT ) & changeMask ) {
RequestUrl();
}
Update();
DebugGlobals();
}
money( key buyerId , integer lindensReceived ) {
Debug( "default::money( " + (string)buyerId + ", " + (string)lindensReceived + " )" );
llSetPayPrice( PAY_HIDE , [ PAY_HIDE , PAY_HIDE , PAY_HIDE , PAY_HIDE ] );
Play( buyerId , lindensReceived );
Update();
DebugGlobals();
}
timer() {
Debug( "default::timer()" );
llSetTimerEvent( 0.0 );
DebugGlobals();
integer requestIndex;
for( requestIndex = 0 ; requestIndex < llGetListLength( DataServerRequests ) ; ++requestIndex ) {
if( llList2Integer( DataServerRequestTimes , requestIndex ) + 15.0 /*ASSET_SERVER_TIMEOUT*/ < llGetUnixTime() ) {
if( NULL_KEY != llList2Key( DataServerResponses , requestIndex ) ) {
llHTTPResponse( llList2Key( DataServerResponses , requestIndex ) , 200 , "null" );
}
DataServerRequests = llDeleteSubList( DataServerRequests , requestIndex , requestIndex );
DataServerRequestTimes = llDeleteSubList( DataServerRequestTimes , requestIndex , requestIndex );
DataServerRequestTypes = llDeleteSubList( DataServerRequestTypes , requestIndex , requestIndex );
DataServerResponses = llDeleteSubList( DataServerResponses , requestIndex , requestIndex );
}
}
if( llGetListLength( DataServerRequests ) ) {
llSetTimerEvent( 5.0 );
} else {
}
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
Shorten( ShortenedInfoUrl );
DataServerRequestTypes += [ 1 ];
Shorten( ShortenedAdminUrl );
DataServerRequestTypes += [ 2 ];
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
llList2Integer( requestBodyParts , 0 ) ,
llList2Float( Rarity , llList2Integer( requestBodyParts , 0 ) ) ,
llList2Integer( Limit , llList2Integer( requestBodyParts , 0 ) ) ,
llList2Integer( Bought , llList2Integer( requestBodyParts , 0 ) ) ,
inventoryName ,
inventoryType
];
if( INVENTORY_NONE != inventoryType ) {
values += [
llGetInventoryCreator( inventoryName ) ,
llGetInventoryKey( inventoryName ) != NULL_KEY ,
llGetInventoryPermMask( inventoryName , MASK_OWNER ) ,
llGetInventoryPermMask( inventoryName , MASK_GROUP ) ,
llGetInventoryPermMask( inventoryName , MASK_EVERYONE ) ,
llGetInventoryPermMask( inventoryName , MASK_NEXT )
];
} else {
values += [
NULL_KEY ,
FALSE ,
0 ,
0 ,
0 ,
0
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
DataServerResponses += [ requestId ];
DataServerRequestTimes += [ llGetUnixTime() ];
llSetContentType( requestId , responseContentType );
llSetTimerEvent( 5.0 );
if( "username" == subject ) {
DataServerRequests += [ llRequestUsername( llList2Key( requestBodyParts , 0 ) ) ];
DataServerRequestTypes += [ 3 ];
}
if( "displayname" == subject ) {
DataServerRequests += [ llRequestDisplayName( llList2Key( requestBodyParts , 0 ) ) ];
DataServerRequestTypes += [ 4 ];
}
if( "notecard-line-count" == subject ) {
DataServerRequests += [ llGetNumberOfNotecardLines( llList2String( requestBodyParts , 0 ) ) ];
DataServerRequestTypes += [ 5 ];
}
if( "notecard-line" == subject ) {
DataServerRequests += [ llGetNotecardLine( llList2String( requestBodyParts , 0 ) , llList2Integer( requestBodyParts , 1 ) ) ];
DataServerRequestTypes += [ 6 ];
}
return;
}
if( "inv" == subject && isAdmin ) {
if( llList2Integer( requestBodyParts , 0 ) < llGetInventoryNumber( INVENTORY_ALL ) ) {
string inventoryName = llGetInventoryName( INVENTORY_ALL , llList2Integer( requestBodyParts , 0 ) );
list values = [
llList2Integer( requestBodyParts , 0 ) ,
inventoryName ,
llGetInventoryType( inventoryName ) ,
llGetInventoryCreator( inventoryName ) ,
llGetInventoryKey( inventoryName ) ,
llGetInventoryPermMask( inventoryName , MASK_OWNER ) ,
llGetInventoryPermMask( inventoryName , MASK_GROUP ) ,
llGetInventoryPermMask( inventoryName , MASK_EVERYONE ) ,
llGetInventoryPermMask( inventoryName , MASK_NEXT )
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
Debug( "    responseContentType = " + (string)responseContentType );
Debug( "    responseStatus = " + (string)responseStatus );
Debug( "    responseBody = " + (string)responseBody );
llSetContentType( requestId , responseContentType );
llHTTPResponse( requestId , responseStatus , responseBody );
DebugGlobals();
}
dataserver( key queryId , string data ) {
Debug( "default::dataserver( " + (string)queryId + ", " + data + " )" );
integer requestIndex = llListFindList( DataServerRequests , [ queryId ] );
if( -1 == requestIndex ) {
return;
}
if( NULL_KEY != llList2Key( DataServerResponses , requestIndex ) ) {
llHTTPResponse( llList2Key( DataServerResponses , requestIndex ) , 200 , llList2Json( JSON_ARRAY , [ data ] ) );
DataServerRequests = llDeleteSubList( DataServerRequests , requestIndex , requestIndex );
DataServerRequestTimes = llDeleteSubList( DataServerRequestTimes , requestIndex , requestIndex );
DataServerRequestTypes = llDeleteSubList( DataServerRequestTypes , requestIndex , requestIndex );
DataServerResponses = llDeleteSubList( DataServerResponses , requestIndex , requestIndex );
}
llSetTimerEvent( 0.0 );
DebugGlobals();
}
http_response( key requestId , integer responseStatus , list metadata , string responseBody ) {
Debug( "default::http_response( " + llList2CSV( [ requestId , responseStatus ] + metadata + [ responseBody ] )+ " )" );
integer requestIndex = llListFindList( DataServerRequests , [ requestId ] );
if( -1 == requestIndex ) {
return;
}
string shortened = llJsonGetValue( responseBody , [ "id" ] );
if( JSON_INVALID != shortened && JSON_NULL != shortened ) {
if( 1 == llList2Integer( DataServerRequestTypes , requestIndex ) ) {
ShortenedInfoUrl = shortened;
}
if( 2 == llList2Integer( DataServerRequestTypes , requestIndex ) ) {
ShortenedAdminUrl = shortened;
llOwnerSay( "Ready to configure. Here is the configruation link: " + ShortenedAdminUrl + " DO NOT GIVE THIS LINK TO ANYONE ELSE." );
}
} else if( 2 == llList2Integer( DataServerRequestTypes , requestIndex ) ) {
llOwnerSay( "Goo.gl URL shortener failed. Ready to configure. Here is the configruation link: " + ShortenedAdminUrl + " DO NOT GIVE THIS LINK TO ANYONE ELSE." );
}
DataServerRequests = llDeleteSubList( DataServerRequests , requestIndex , requestIndex );
DataServerRequestTimes = llDeleteSubList( DataServerRequestTimes , requestIndex , requestIndex );
DataServerRequestTypes = llDeleteSubList( DataServerRequestTypes , requestIndex , requestIndex );
DataServerResponses = llDeleteSubList( DataServerResponses , requestIndex , requestIndex );
DebugGlobals();
}
touch_end( integer detected ) {
Debug( "default::touch_end( " + (string)detected + " )" );
while( 0 <= ( detected -= 1 ) ) {
key detectedKey = llDetectedKey( detected );
Debug( "    Touched by: " + llDetectedName( detected ) + " (" + (string)detectedKey + ")" );
if( detectedKey == Owner ) {
if( ShortenedAdminUrl ) {
llOwnerSay( "To configure and administer this Easy Gacha, please go here: " + ShortenedAdminUrl + " DO NOT GIVE THIS LINK TO ANYONE ELSE." );
} else if( "" == BaseUrl && llGetFreeURLs() ) {
llOwnerSay( "Trying to get a new URL now... please wait" );
RequestUrl();
} else {
llDialog( Owner , "No URLs are available on this parcel/sim, so the configuration screen cannot be shown. Please slap whoever is consuming all the URLs and try again." , [ ] , -1 );
}
if( TotalPrice && !HasPermission ) {
llRequestPermissions( llGetOwner() , PERMISSION_DEBIT );
}
}
if( Ready && !TotalPrice ) {
Play( detectedKey , 0 );
}
}
if( llGetUnixTime() != LastWhisperedUrl ) {
if( ShortenedInfoUrl ) {
Whisper( "For help, information, and statistics about this Easy Gacha, please go here: " + ShortenedInfoUrl );
} else {
Whisper( "Information about this Easy Gacha is not yet available, please wait a few minutes and try again." );
}
LastWhisperedUrl = llGetUnixTime();
}
Update();
DebugGlobals();
}
}
