#start globalfunctions

    // Expected formats: "L$#" "$#" "#" "#L"
    integer ParseLindensConfig( string value ) {
        // Remove valid prefixes and suffixes
        value = llDumpList2String( llParseString2List( ( value = "" ) + value , [ "l" , "L" , "$" ] , [ ] ) , "" );

        // Strip leading zeroes
        while( 1 < llStringLength( value ) && "0" == llGetSubString( value ) ) {
            value = llGetSubString( value , 1 , -1 );
        }

        // There shouldn't be anything else in the string now except the raw
        // number which should convert cleanly back and forth between string
        // and integer
        if( (string)((integer)value) != value ) {
            return -1;
        }

        return (integer)value;
    }

#end globalfunctions
