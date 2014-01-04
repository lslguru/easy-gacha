list Items;
list Rarity;
list Limit;
list Bought;
list Payouts;
integer MaxPerPurchase = 50;
integer PayPrice;
list PayPriceButtons;
integer FolderForSingleItem = TRUE;
integer RootClickAction = FALSE;
integer Stats = TRUE;
key Runtime;
integer Group = FALSE;
string Email;
key Im;
integer Whisper = TRUE;
integer Hovertext = TRUE;
integer Registry = TRUE;
integer MaxBuys = -1;
Debug( string msg ) {
if( INVENTORY_NONE != llGetInventoryType( "eg_debug" ) ) {
llOwnerSay( "/me : " + llGetScriptName() + ": DEBUG: " + msg );
}
}
Whisper( string msg ) {
if( Whisper ) {
llWhisper( 0 , "/me : " + llGetScriptName() + ": " + msg );
}
}
Hover( string msg ) {
if( Hovertext ) {
llSetText( llGetScriptName() + ":\n" + msg + "\n|\n|\n|\n|\n|" , <1,0,0>, 1 );
}
}
HttpRequest( list data ) {
if( "" == "" ) {
return;
}
llHTTPRequest( "" , [ HTTP_METHOD , "POST" , HTTP_MIMETYPE , "text/json;charset=utf-8" , HTTP_BODY_MAXLENGTH , 16384 , HTTP_VERIFY_CERT , FALSE , HTTP_VERBOSE_THROTTLE , FALSE ] , llList2Json( JSON_ARRAY , data ) );
llSleep( 1.0 );
}
default {
state_entry() { }
changed( integer changeMask ) { }
timer() { }
}
state ready {
state_entry() { }
changed( integer changeMask ) { }
timer() { }
}
