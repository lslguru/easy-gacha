#define INVENTORY_COUNT llGetInventoryNumber( INVENTORY_ALL )

#start globalfunctions

    string FindNthInventoryByNormalizedName( integer searchIndex , string searchName ) {
        integer iterate;
        string inventoryName;
        integer foundIndex;

        searchName = llToLower( llStringTrim( searchName , STRING_TRIM ) );

        for( iterate = 0 ; iterate < INVENTORY_COUNT ; iterate += 1 ) {
            // Get the name
            inventoryName = llGetInventoryName( INVENTORY_ALL , iterate );

            // If it's a normalized match
            if( llToLower( llStringTrim( inventoryName , STRING_TRIM ) ) == searchName ) {
                if( foundIndex == searchIndex ) {
                    return inventoryName;
                } else {
                    foundIndex += 1;
                }
            }
        }

        return EOF;
    }

#end globalfunctions
