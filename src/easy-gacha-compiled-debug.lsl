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
Debug( string msg ) { if( INVENTORY_NONE != llGetInventoryType( "easy-gacha-debug" ) ) { llOwnerSay( "/me : " + llGetScriptName() + ": DEBUG: " + msg ); } }
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
if( "" == "" ) {
return;
}
llHTTPRequest( "" , [ HTTP_METHOD , "POST" , HTTP_MIMETYPE , "text/json;charset=utf-8" , HTTP_BODY_MAXLENGTH , 16384 , HTTP_VERIFY_CERT , FALSE , HTTP_VERBOSE_THROTTLE , FALSE ] , llList2Json( JSON_ARRAY , data ) );
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
if( Configured ) {
llSetPayPrice( PayPrice , PayPriceButtons );
} else {
llSetPayPrice( PAY_HIDE , [ PAY_HIDE , PAY_HIDE , PAY_HIDE , PAY_HIDE ] );
}
if( !Configured ) {
llSetTouchText( "Config" );
} else if( TotalPrice ) {
llSetTouchText( "Play" );
} else {
llSetTouchText( "Info" );
}
if( RootClickAction || LINK_ROOT != llGetLinkNumber() ) {
if( Configured && TotalPrice ) {
llSetClickAction( CLICK_ACTION_PAY );
} else {
llSetClickAction( CLICK_ACTION_TOUCH );
}
}
if( Configured ) {
Hover( "" );
} else {
Hover( "Configuration needed, please touch this object" );
}
TotalPrice = (integer)llListStatistics( LIST_STAT_SUM , Payouts );
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
}
default {
state_entry() {
Debug( "default::state_entry()" );
if( INVENTORY_NOTECARD != llGetInventoryType( "Easy Gacha Config" ) ) {
state running;
}
if( NULL_KEY == llGetInventoryKey( "Easy Gacha Config" ) ) {
llOwnerSay( "Config notecard is either not full-perm or is new and empty, skipping: " + "Easy Gacha Config" );
state running;
}
llOwnerSay( "Loading previous config from: " + "Easy Gacha Config" );
DataServerMode = 0;
DataServerRequest = llGetNotecardLine( "Easy Gacha Config" , DataServerMode );
llSetTimerEvent( 5.0 );
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
list parts = llParseString2List( data , [ " " ] , [ ] );
if( "inv" == llList2String( parts , 0 ) ) {
Rarity += [ llList2Float( parts , 1 ) ];
Limit += [ llList2Integer( parts , 2 ) ];
Bought += [ llList2Integer( parts , 3 ) ];
Items += [ llDumpList2String( llList2List( parts , 4 , -1 ) , " " ) ];
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
Email = llDumpList2String( llList2List( parts , 1 , -1 ) , " " );
}
if( "im" == llList2String( parts , 0 ) ) {
Im = llList2Key( parts , 1 );
}
if( "configured" == llList2String( parts , 0 ) ) {
Configured = llList2Integer( parts , 1 );
}
++DataServerMode;
DataServerRequest = llGetNotecardLine( "Easy Gacha Config" , DataServerMode );
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
llSetPayPrice( PAY_HIDE , [ PAY_HIDE , PAY_HIDE , PAY_HIDE , PAY_HIDE ] );
Update();
DebugGlobals();
}
timer() {
Debug( "running::timer()" );
if( NULL_KEY != DataServerRequest ) {
llSetTimerEvent( 0.0 );
DataServerRequest = NULL_KEY;
DataServerMode = 0;
DebugGlobals();
return;
}
DebugGlobals();
}
http_request( key requestId , string httpMethod , string requestBody ) {
Debug( "running::http_request( " + llList2CSV( [ requestId , httpMethod , requestBody ] )+ " )" );
integer responseStatus = 400;
string responseBody = "Bad request";
if( URL_REQUEST_GRANTED == httpMethod ) {
BaseUrl = requestBody;
ShortenedInfoUrl = "http:\/\/lslguru.github.io/easy-gacha/v5/index.html#" + llEscapeURL( BaseUrl );
ShortenedAdminUrl = "http:\/\/lslguru.github.io/easy-gacha/v5/index.html#" + llEscapeURL( BaseUrl + "/" + (string)AdminKey );
llOwnerSay( "URL obtained, this Easy Gacha can now be configured. Touch to configure." );
DataServerMode = 1;
Shorten( ShortenedInfoUrl );
}
if( URL_REQUEST_DENIED == httpMethod ) {
llOwnerSay( "Unable to get a URL. This Easy Gacha cannot be configured until one becomes available: " + requestBody );
}
if( "post" == llToLower( httpMethod ) ) {
}
llHTTPResponse( requestId , responseStatus , responseBody );
DebugGlobals();
}
http_response( key requestId , integer responseStatus , list metadata , string responseBody ) {
Debug( "running::http_response( " + llList2CSV( [ requestId , responseStatus ] + metadata + [ responseBody ] )+ " )" );
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
DebugGlobals();
}
touch_end( integer detected ) {
Debug( "running::touch_end( " + (string)detected + " )" );
if( "" == BaseUrl && llGetFreeURLs() ) {
llOwnerSay( "Trying to get a new URL now..." );
RequestUrl();
}
while( 0 <= ( detected -= 1 ) ) {
key detectedKey = llDetectedKey( detected );
Debug( "    Touched by: " + llDetectedName( detected ) + " (" + (string)detectedKey + ")" );
if( detectedKey == Owner ) {
if( ShortenedAdminUrl ) {
llOwnerSay( "To configure and administer this Easy Gacha, please go here: " + ShortenedAdminUrl );
} else {
llOwnerSay( "No URLs are available on this parcel/sim, so the configuration screen cannot be shown. Please slap whoever is consuming all the URLs and try again." );
}
}
if( Configured && !TotalPrice ) {
Play( detectedKey , 0 );
}
}
if( ShortenedInfoUrl ) {
llWhisper( 0 , "For help, information, and statistics about this Easy Gacha, please go here: " + ShortenedInfoUrl );
} else {
llWhisper( 0 , "Information about this Easy Gacha is not yet available, please wait a few minutes and try again." );
}
DebugGlobals();
}
}
