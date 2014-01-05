list Items;
list Rarity;
list Limit;
list Bought;
list Payouts;
integer MaxPerPurchase = 50;
integer PayPrice = PAY_HIDE;
list PayPriceButtons = [ PAY_HIDE , PAY_HIDE , PAY_HIDE , PAY_HIDE ];
integer FolderForSingleItem = TRUE;
integer RootClickAction = FALSE;
integer Group = FALSE;
string Email;
key Im;
integer AllowWhisper = TRUE;
integer AllowHover = TRUE;
integer MaxBuys = -1;
integer Configured;
key AdminKey;
string BaseUrl;
string ShortenedInfoUrl;
string ShortenedAdminUrl;
key Owner;
string ScriptName;
integer HasPermission;
key DataServerRequest;
integer DataServerMode;
integer InventoryChanged;
integer InventoryChangeExpected;
integer NextPing;
integer TotalPrice;
integer TotalBought;
integer TotalLimit;
integer HasUnlimitedItems;
float TotalEffectiveRarity;
integer CountItems;
integer CountPayouts;
Whisper( string msg ) {
if( AllowWhisper ) {
llWhisper( 0 , "/me : " + llGetScriptName() + ": " + msg );
}
}
Hover( string msg ) {
if( AllowHover ) {
if( msg ) {
llSetText( llGetScriptName() + ":\n" + msg + "\n|\n|\n|\n|\n|" , <1,0,0>, 1 );
} else {
llSetText( "" , ZERO_VECTOR , 1 );
}
}
}
HttpRequest( list data ) {
if( "" == "" ) {
return;
}
llHTTPRequest( "" , [ HTTP_METHOD , "POST" , HTTP_MIMETYPE , "text/json;charset=utf-8" , HTTP_BODY_MAXLENGTH , 16384 , HTTP_VERIFY_CERT , FALSE , HTTP_VERBOSE_THROTTLE , FALSE ] , llList2Json( JSON_ARRAY , data ) );
llSleep( 1.0 );
}
RequestUrl() {
llReleaseURL( BaseUrl );
AdminKey = llGenerateKey();
BaseUrl = "";
ShortenedInfoUrl = "";
ShortenedAdminUrl = "";
llRequestURL();
}
Update() {
Owner = llGetOwner();
ScriptName = llGetScriptName();
HasPermission = ( ( llGetPermissionsKey() == Owner ) && llGetPermissions() & PERMISSION_DEBIT );
if( TotalPrice && !HasPermission ) {
Configured = FALSE;
}
if( Configured ) {
llSetPayPrice( PayPrice , PayPriceButtons );
} else {
llSetPayPrice( PAY_HIDE , [ PAY_HIDE , PAY_HIDE , PAY_HIDE , PAY_HIDE ] );
}
if( !Configured ) {
llSetTouchText( "Config" );
} else if( TotalPrice ) {
llSetTouchText( "Info" );
} else {
llSetTouchText( "Play" );
}
if( RootClickAction || LINK_ROOT != llGetLinkNumber() ) {
if( Configured && TotalPrice ) {
llSetClickAction( CLICK_ACTION_PAY );
} else {
llSetClickAction( CLICK_ACTION_TOUCH );
}
}
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
if( Configured ) {
Hover( "" );
} else if( TotalPrice && !HasPermission ) {
Hover( "Need debit permission, please touch this object" );
} else {
Hover( "Configuration needed, please touch this object" );
}
}
Shorten( string url ) {
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
string displayName = llGetDisplayName( buyerId );
Hover( "Please wait, getting random items for: " + displayName );
integer totalItems = lindensReceived / TotalPrice;
if( totalItems > MaxPerPurchase ) {
totalItems = MaxPerPurchase;
}
if( -1 != MaxBuys && totalItems > MaxBuys - TotalBought ) {
totalItems = MaxBuys - TotalBought;
}
if( !HasUnlimitedItems && totalItems > TotalLimit - TotalBought ) {
totalItems = TotalLimit - TotalBought;
}
list itemsToSend = [];
integer countItemsToSend = 0;
float random;
integer itemIndex;
while( countItemsToSend < totalItems ) {
Hover( "Please wait, getting random item " + (string)( countItemsToSend + 1 ) + " of " + (string)totalItems + " for: " + displayName );
random = TotalEffectiveRarity - llFrand( TotalEffectiveRarity );
for( itemIndex = 0 ; itemIndex < CountItems && random > 0.0 ; ++itemIndex ) {
if( -1 == llList2Integer( Limit , itemIndex ) || llList2Integer( Bought , itemIndex ) < llList2Integer( Limit , itemIndex ) ) {
random -= llList2Float( Rarity , itemIndex );
}
}
--itemIndex;
itemsToSend += [ llList2String( Items , itemIndex ) ];
++countItemsToSend;
Bought = llListReplaceList( Bought , [ llList2Integer( Bought , itemIndex ) + 1 ] , itemIndex , itemIndex );
if( -1 != llList2Integer( Limit , itemIndex ) && llList2Integer( Bought , itemIndex ) >= llList2Integer( Limit , itemIndex ) ) {
TotalEffectiveRarity -= llList2Float( Rarity , itemIndex );
InventoryChangeExpected = TRUE;
}
}
string itemPlural = " items ";
string hasHave = "have ";
if( 1 == countItemsToSend ) {
itemPlural = " item ";
hasHave = "has ";
}
string objectName = llGetObjectName();
string folderSuffix = ( " (Easy Gacha: " + (string)countItemsToSend + itemPlural + llGetDate() + ")" );
if( llStringLength( objectName ) + llStringLength( folderSuffix ) > 63 ) {
objectName = ( llGetSubString( objectName , 0 , 63 - llStringLength( folderSuffix ) - 4 ) + "..." );
}
string change = "";
lindensReceived -= ( totalItems * TotalPrice );
if( lindensReceived ) {
llGiveMoney( buyerId , lindensReceived );
change = " Your change is L$" + (string)lindensReceived;
}
integer payoutIndex;
for( payoutIndex = 0 ; payoutIndex < CountPayouts ; payoutIndex += 2 ) {
if( llList2Key( Payouts , payoutIndex ) != Owner ) {
llGiveMoney( llList2Key( Payouts , payoutIndex ) , llList2Integer( Payouts , payoutIndex + 1 ) * totalItems );
}
}
Whisper( "Thank you for your purchase, " + displayName + "! Your " + (string)countItemsToSend + itemPlural + hasHave + "been sent." + change );
Hover( "Please wait, giving items to: " + displayName );
if( 1 < countItemsToSend || FolderForSingleItem ) {
llGiveInventoryList( buyerId , objectName + folderSuffix , itemsToSend );
} else {
llGiveInventory( buyerId , llList2String( itemsToSend , 0 ) );
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
}
money( key buyerId , integer lindensReceived ) {
llSetPayPrice( PAY_HIDE , [ PAY_HIDE , PAY_HIDE , PAY_HIDE , PAY_HIDE ] );
Play( buyerId , lindensReceived );
Update();
}
timer() {
if( NULL_KEY != DataServerRequest ) {
DataServerRequest = NULL_KEY;
DataServerMode = 0;
return;
}
}
http_request( key requestId , string httpMethod , string requestBody ) {
integer responseStatus = 400;
string responseBody = "";
integer responseContentType = CONTENT_TYPE_TEXT;
if( URL_REQUEST_GRANTED == httpMethod ) {
BaseUrl = requestBody;
ShortenedInfoUrl = ( BaseUrl + "/" );
ShortenedAdminUrl = ( BaseUrl + "/#" + (string)AdminKey );
llOwnerSay( "URL obtained, this Easy Gacha can now be configured. Touch to configure." );
DataServerMode = 1;
Shorten( ShortenedInfoUrl );
}
if( URL_REQUEST_DENIED == httpMethod ) {
llOwnerSay( "Unable to get a URL. This Easy Gacha cannot be configured until one becomes available: " + requestBody );
}
if( "get" == llToLower( httpMethod ) ) {
responseStatus = 200;
responseBody = "<!DOCTYPE html PUBLIC \"-\/\/W3C\/\/DTD XHTML 1.0 Transitional\/\/EN\" \"http:\/\/www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n<html xmlns=\"http:\/\/www.w3.org/1999/xhtml\">\n    <head>\n        <script type=\"text/javascript\" src=\"" + "http:\/\/lslguru.github.io/easy-gacha/v5/config.js.min" + "\"></script>\n    </head>\n    <body>\n    </body>\n</html>";
responseContentType = CONTENT_TYPE_XHTML;
}
if( "post" == llToLower( httpMethod ) ) {
responseStatus = 200;
responseContentType = CONTENT_TYPE_JSON;
list path = llParseString2List( llGetHTTPHeader( requestId , "x-path-info" ) , [ "/" ] , [ ] );
integer isAdmin = ( llList2Key( path , 0 ) == AdminKey );
if( isAdmin ) {
path = llList2List( path , 1 , -1 );
}
string verb = llList2String( path , 0 );
string subject = llList2String( path , 1 );
list requestBodyParts = llJson2List( requestBody );
if( "memory" == subject && "get" == verb ) {
responseBody = (string)llGetFreeMemory();
}
if( "inv" == subject ) {
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
}
}
if( "head" == verb ) {
responseBody = llList2Json(
JSON_ARRAY ,
[
llGetListLength( Items )
]
);
} else {
responseBody = llList2Json(
JSON_ARRAY ,
[
llList2Float( Rarity , llList2Integer( requestBodyParts , 0 ) ) ,
llList2Integer( Limit , llList2Integer( requestBodyParts , 0 ) ) ,
llList2Integer( Bought , llList2Integer( requestBodyParts , 0 ) ) ,
llList2String( Items , llList2Integer( requestBodyParts , 0 ) )
]
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
if( "head" == verb ) {
responseBody = llList2Json(
JSON_ARRAY ,
[
llGetListLength( Payouts ) / 2
]
);
} else {
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
if( "delete" == verb ) {
FolderForSingleItem = TRUE;
RootClickAction = FALSE;
Group = FALSE;
AllowWhisper = TRUE;
AllowHover = TRUE;
MaxPerPurchase  = 50;
MaxBuys = -1;
PayPrice = PAY_HIDE;
PayPriceButtons = [ PAY_HIDE , PAY_HIDE , PAY_HIDE , PAY_HIDE ];
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
if( "delete" == verb ) {
Email = "";
}
}
responseBody = llList2Json(
JSON_ARRAY ,
[
Email
]
);
}
if( "im" == subject ) {
if( isAdmin ) {
if( "post" == verb ) {
Im = llList2Key( requestBodyParts , 0 );
}
if( "delete" == verb ) {
Im = NULL_KEY;
}
}
responseBody = llList2Json(
JSON_ARRAY ,
[
Im
]
);
}
if( "configured" == subject ) {
if( isAdmin ) {
if( "post" == verb ) {
Configured = llList2Integer( requestBodyParts , 0 );
}
if( "delete" == verb ) {
Configured = FALSE;
}
}
responseBody = llList2Json(
JSON_ARRAY ,
[
Configured
]
);
}
if( isAdmin ) {
Update();
}
}
llSetContentType( requestId , responseContentType );
llHTTPResponse( requestId , responseStatus , responseBody );
}
dataserver( key queryId , string data ) {
if( queryId != DataServerRequest )
return;
llSetTimerEvent( 0.0 );
DataServerRequest = NULL_KEY;
DataServerMode = 0;
}
http_response( key requestId , integer responseStatus , list metadata , string responseBody ) {
if( DataServerRequest != requestId ) {
return;
}
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
}
touch_end( integer detected ) {
while( 0 <= ( detected -= 1 ) ) {
key detectedKey = llDetectedKey( detected );
if( detectedKey == Owner ) {
if( ShortenedAdminUrl ) {
llOwnerSay( "To configure and administer this Easy Gacha, please go here: " + ShortenedAdminUrl );
} else {
llOwnerSay( "No URLs are available on this parcel/sim, so the configuration screen cannot be shown. Please slap whoever is consuming all the URLs and try again." );
}
if( TotalPrice && !HasPermission ) {
llRequestPermissions( llGetOwner() , PERMISSION_DEBIT );
}
}
if( Configured && !TotalPrice ) {
Play( detectedKey , 0 );
}
}
if( "" == BaseUrl && llGetFreeURLs() ) {
llOwnerSay( "Trying to get a new URL now..." );
RequestUrl();
}
if( ShortenedInfoUrl ) {
llWhisper( 0 , "For help, information, and statistics about this Easy Gacha, please go here: " + ShortenedInfoUrl );
} else {
llWhisper( 0 , "Information about this Easy Gacha is not yet available, please wait a few minutes and try again." );
}
Update();
}
}
