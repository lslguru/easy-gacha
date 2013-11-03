#start globalfunctions

string FindConfig_1Part_ByVerb_Value( integer searchIndex , string searchVerb ) {
    integer iterate;
    string inventoryName;
    integer spaceIndex;

    for( iterate = 0 ; iterate < TextureCount ; iterate += 1 ) {
        // Get the name
        inventoryName = llStringTrim( llGetInventoryName( INVENTORY_TEXTURE , iterate ) , STRING_TRIM );

        // If it's a config item
        if( CONFIG_INVENTORY_ID == llGetInventoryKey( inventoryName ) ) {
            // Find the space
            spaceIndex = llSubStringIndex( inventoryName , " " );

            if( llGetSubString( inventoryName , 0 , spaceIndex - 1 ) == searchVerb ) {
                if( foundIndex == searchIndex ) {
                    return llStringTrim( llGetSubString( inventoryName , spaceIndex + 1 , -1 ) , STRING_TRIM );
                } else {
                    foundIndex += 1;
                }
            }
        }
    }

    return EOF;
}

#end globalfunctions
