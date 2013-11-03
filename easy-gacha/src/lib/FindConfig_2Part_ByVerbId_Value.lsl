#define TEXTURE_COUNT llGetInventoryNumber( INVENTORY_TEXTURE )

#start globalfunctions

    string FindConfig_2Part_ByVerbId_Value( integer searchIndex , string searchVerb , string searchId ) {
        integer iterate;
        string inventoryName;
        integer spaceIndex;
        integer foundIndex;

        for( iterate = 0 ; iterate < TEXTURE_COUNT ; iterate += 1 ) {
            // Get the name
            inventoryName = llStringTrim( llGetInventoryName( INVENTORY_TEXTURE , iterate ) , STRING_TRIM );

            // If it's a config item
            if( CONFIG_INVENTORY_ID == llGetInventoryKey( inventoryName ) ) {
                // Find the space
                spaceIndex = llSubStringIndex( inventoryName , " " );

                if( llToLower( llGetSubString( inventoryName , 0 , spaceIndex - 1 ) ) == searchVerb ) {
                    // Now just the value and id parts
                    inventoryName = llStringTrim( llGetSubString( inventoryName , spaceIndex + 1 , -1 ) , STRING_TRIM );

                    // Find the space
                    spaceIndex = llSubStringIndex( inventoryName , " " );

                    // Second part of string is value
                    if( llStringTrim( llGetSubString( inventoryName , spaceIndex + 1 , -1 ) , STRING_TRIM ) == searchId ) {
                        if( foundIndex == searchIndex ) {
                            // First part of string is value
                            return llGetSubString( inventoryName , 0 , spaceIndex - 1 );
                        } else {
                            foundIndex += 1;
                        }
                    }
                }
            }
        }

        return EOF;
    }

#end globalfunctions
