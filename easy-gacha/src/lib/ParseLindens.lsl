#start globalfunctions

    // Expected formats: "L$#" "$#" "#" "#L"
    // Does not support leading zeroes
    integer ParseLindens( string value ) {
        value = llDumpList2String( llParseString2List( ( value = "" ) + value , [ "l" , "L" , "$" ] , [ ] ) , "" );

        // There shouldn't be anything else in the string now except the raw number
        if( (string)((integer)value) != value ) {
            return -1;
        }

        return (integer)value;
    }

#end globalfunctions
