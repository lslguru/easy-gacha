#start globalfunctions

    string FindInventoryByName( string seeking ) {
        if( INVENTORY_NONE != llGetInventoryType( seeking ) ) {
            return seeking;
        }

        seeking = llToLower( llStringTrim( seeking , STRING_TRIM ) );

        if( INVENTORY_NONE != llGetInventoryType( seeking ) ) {
            return seeking;
        }

        integer inventoryCount = llGetInventoryNumber( INVENTORY_ALL );
        integer inventoryIndex;
        string inventoryName;

        // Scan inventory for a match - we have to do it this way to support
        // case insensitivity and string trimming
        for( inventoryIndex = 0 ; inventoryIndex < inventoryCount ; ++inventoryIndex ) {
            inventoryName = llGetInventoryName( INVENTORY_ALL , inventoryIndex );

            if( llToLower( llStringTrim( inventoryName , STRING_TRIM ) ) == seeking ) {
                return inventoryName;
            }
        }

        return "";
    }

#end globalfunctions
