// Message modes (bitmask)
#define MESSAGE_VIA_HOVER 1
#define MESSAGE_VIA_OWNER 2
#define MESSAGE_VIA_WHISPER 4
#define MESSAGE_VIA_DIALOG 8
#define MESSAGE_TYPE_VERBOSE 16
#define MESSAGE_TYPE_DEBUG 32

// Convenience modes
#define MESSAGE_ERROR 11
#define MESSAGE_WARNING 2
#define MESSAGE_DEBUG 34

// Overrideable parts
#define OWNER llGetOwner()
#define SCRIPT_NAME llGetScriptName()

#start globalvariables

    integer MessageVerbose  = FALSE;
    integer MessageDebug    = FALSE;
    integer MessageHover    = TRUE;
    integer MessageWhisper  = TRUE;

#end globalvariables

#start globalfunctions

    Message( integer mode , string msg ) {

        if( MessageDebug ) {
            mode = mode | MESSAGE_VIA_OWNER;
        }

        if( MESSAGE_TYPE_VERBOSE & mode ) {
            if( !MessageVerbose ) {
                // If message is a verbose-mode one and verbose isn't turned on,
                // skip message altogether
                return;
            }

            msg = "VERBOSE: " + msg;
        }

        if( MESSAGE_TYPE_DEBUG & mode ) {
            if( !MessageDebug ) {
                // If message is debug and debug isn't turned on, skip message
                // altogether
                return;
            }

            msg = "DEBUG: " + msg;
        }

        if( MESSAGE_VIA_HOVER & mode && MessageHover ) {
            llSetText( SCRIPT_NAME + ":\n" + msg + "\n|\n|\n|\n|\n|" , <1,0,0>, 1 );
        }

        if( MESSAGE_VIA_WHISPER & mode && MessageWhisper ) {
            llWhisper( 0 , "/me : " + SCRIPT_NAME + ": " + msg );
        } else if( MESSAGE_VIA_OWNER & mode ) {
            llOwnerSay( SCRIPT_NAME + ": " + msg );
        }

        if( MESSAGE_VIA_DIALOG & mode ) {
            llDialog( OWNER , SCRIPT_NAME + ":\n\n" + msg , [] , -1 ); // FORCED_DELAY 1.0 seconds
        }

    }

#end globalfunctions
