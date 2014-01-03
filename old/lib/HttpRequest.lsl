#include lib/CONSTANTS.lsl
#start globalfunctions

    HttpRequest( string url , list data ) {
        if( "" == url ) {
            return;
        }

        llHTTPRequest( url , HTTP_OPTIONS , llList2Json( JSON_ARRAY , data ) );

        llSleep( 1.0 ); // FORCED_DELAY 1.0 seconds
    }

#end globalfunctions
