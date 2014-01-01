// Message modes (bitmask)
#define MESSAGE_SET_TEXT 1
#define MESSAGE_OWNER_SAY 2
#define MESSAGE_WHISPER 4
#define MESSAGE_DIALOG 8
#define MESSAGE_IS_VERBOSE 16
#define MESSAGE_IS_DEBUG 32

// Convenience modes
#define MESSAGE_TEXT_AND_OWNER 3
#define MESSAGE_ERROR 11
#define MESSAGE_DEBUG 40

// Overrideable parts
#define OWNER llGetOwner()
#define SCRIPT_NAME llGetScriptName()

#start globalvariables

    integer MessageVerbose      = FALSE;
    integer MessageDebug        = FALSE;
    integer MessageHoverText    = TRUE;
    integer MessageOwner        = TRUE;
    integer MessageChat         = TRUE;

#end globalvariables

#start globalfunctions

    Message( integer mode , string msg ) {
        if( MESSAGE_IS_VERBOSE & mode && !MessageVerbose ) {
            // If message is a verbose-mode one and verbose isn't turned on, skip
            return;
        }
        if( MESSAGE_IS_DEBUG & mode && !MessageDebug ) {
            // If message is a verbose-mode one and verbose isn't turned on, skip
            return;
        }
        if( MESSAGE_SET_TEXT & mode && MessageHoverText ) {
            llSetText( SCRIPT_NAME + ":\n" + msg + "\n|\n|\n|\n|\n|" , <1,0,0>, 1 );
        }
        if( MESSAGE_OWNER_SAY & mode && MessageOwner ) {
            llOwnerSay( SCRIPT_NAME + ": " + msg );
        }
        if( MESSAGE_WHISPER & mode && MessageChat ) {
            llWhisper( 0 , "/me : " + SCRIPT_NAME + ": " + msg );
        }
        if( MESSAGE_DIALOG & mode && MessageOwner ) {
            llDialog( OWNER , SCRIPT_NAME + ":\n\n" + msg , [] , -1 ); // FORCED_DELAY 1.0 seconds
        }
    }

#end globalfunctions
