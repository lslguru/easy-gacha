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
integer Whisper = TRUE;
integer Hovertext = TRUE;
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
Debug( string msg ) {
if( INVENTORY_NONE != llGetInventoryType( "easy-gacha-debug" ) ) {
llOwnerSay( "/me : " + llGetScriptName() + ": DEBUG: " + msg );
}
}
Whisper( string msg ) {
Debug( "Whisper( \"" + msg + "\" );" );
if( Whisper ) {
llWhisper( 0 , "/me : " + llGetScriptName() + ": " + msg );
}
}
Hover( string msg ) {
Debug( "Hover( \"" + msg + "\" );" );
if( Hovertext ) {
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
llHTTPRequest( "" , HTTP_OPTIONS , llList2Json( JSON_ARRAY , data ) );
llSleep( 1.0 );
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
Debug( "    Whisper = " + (string)Whisper );
Debug( "    Hovertext = " + (string)Hovertext );
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
}
RequestUrl() {
Debug( "RequestUrl()" );
llReleaseURL( BaseUrl );
BaseUrl = "";
ShortenedInfoUrl = "";
ShortenedAdminUrl = "";
llRequestSecureURL();
}
Update() {
Debug( "Update()" );
Owner = llGetOwner();
ScriptName = llGetScriptName();
HasPermissions = ( ( llGetPermissionsKey() == Owner ) && llGetPermissions() & PERMISSION_DEBIT );
DebugGlobals();
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
Hover( "Configuration Needed / Configuration In Progress / Out of Order" );
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
default {
state_entry() {
if( INVENTORY_NOTECARD != llGetInventoryType( ) ) {
state running;
}
}
dataserver( key queryId , string data ) {
}
timer() {
}
}
state running {
state_entry() {
Debug( "running::state_entry()" );
Update();
RequestUrl();
}
attach( key avatarId ) {
Debug( "running::attach( " + (string)avatarId + " )" );
Update();
}
on_rez( integer rezParam ) {
Debug( "running::on_rez( " + (string)rezParam + " )" );
Update();
RequestUrl();
}
run_time_permissions( integer permissionMask ) {
Debug( "running::run_time_permissions( " + (string)permissionMask + " )" );
Update();
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
}
dataserver( key queryId , string data ) {
Debug( "running::dataserver( " + (string)queryId + ", " + data + " )" );
if( queryId != DataServerRequest )
return;
llSetTimerEvent( 0.0 );
DataServerRequest = NULL_KEY;
DataServerMode = 0;
}
money( key buyerId , integer lindensReceived ) {
Debug( "running::money( " + (string)buyerId + ", " + (string)lindensReceived + " )" );
llSetPayPrice( PAY_HIDE , [ PAY_HIDE , PAY_HIDE , PAY_HIDE , PAY_HIDE ] );
Update();
}
timer() {
Debug( "running::timer()" );
if( NULL_KEY != DataServerRequest ) {
llSetTimerEvent( NextPing - llGetUnixTime() );
DataServerRequest = NULL_KEY;
DataServerMode = 0;
return;
}
}
http_request( key requestId , string httpMethod , string requestBody ) {
Debug( "running::http_request( " + llList2CSV( [ requestId , httpMethod , requestBody ] )+ " )" );
integer responseStatus = 400;
string responseBody = "Bad request";
if( URL_REQUEST_GRANTED == httpMethod ) {
BaseUrl = requestBody;
ShortenedInfoUrl = "http:\/\/lslguru.github.io/easy-gacha/v5/index.html#" + llEscapeURL( BaseUrl );
ShortenedAdminUrl = "http:\/\/lslguru.github.io/easy-gacha/v5/index.html#" + llEscapeURL( BaseUrl + '/' + (string)AdminKey );
DataServerMode = 1;
Shorten( ShortenedInfoUrl );
DebugGlobals();
}
if( URL_REQUEST_DENIED ) {
}
if( "post" == llToLower( httpMethod ) ) {
}
llHTTPResponse( requestId , responseStatus , responseBody );
}
http_response( key requestId , integer responseStatus , list metadata , string responseBody ) {
Debug( "running::http_response( " + llList2CSV( [ requestId , responseStatus ] + metadata + [ responseBody ] )+ " )" );
if( DataServerRequest != requestId ) {
return;
}
var shortened = llJsonGetValue( body , [ "id" ] );
if( JSON_INVALID != shortened && JSON_NULL != shortened ) {
if( 1 == DataServerMode ) {
ShortenedInfoUrl = shortened;
DataServerMode = 2;
Shorten( ShortenedAdminUrl );
}
if( 2 == DataServerMode ) {
ShortenedAdminUrl = shortened;
DataServerMode = 0;
DataServerRequest = NULL_KEY;
}
DebugGlobals();
}
}
touch_end( integer detected ) {
Debug( "running::touch_end( " + (string)detected + " )" );
while( 0 <= ( detected -= 1 ) ) {
}
}
}
