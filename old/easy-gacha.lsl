#start states

// Note: State has neither touch events nor pay events, preventing further
// additions to the queue
state handout {
    state_entry() {
        HaveHandedOut = TRUE; // Mark that we've entered this state (affects memory comparisons)

        while( HandoutQueueCount ) {
            HandoutQueueCount -= 2; // Work backward through the list

            key buyerId = llList2Key( HandoutQueue , HandoutQueueCount );
            integer lindensReceived = llList2Integer( HandoutQueue , HandoutQueueCount + 1 );
            string displayName = llGetDisplayName( buyerId );

            // Let them know we're thinking
            Message( MESSAGE_SET_TEXT , "Please wait, getting random items for: " + displayName );

            // For reporting purposes, and to simplify the while condition
            integer totalItems = lindensReceived / Price; // Integer, so whole values rounded down
            if( totalItems > MaxPerPurchase ) {
                totalItems = MaxPerPurchase;
            }

            // While there's still enough money for another item
            integer countItemsToSend = 0;
            list itemsToSend = [];
            while( countItemsToSend < totalItems ) {
                // Let them know we're thinking
                Message( MESSAGE_SET_TEXT , "Please wait, getting random item " + (string)( countItemsToSend + 1 ) + " of " + (string)totalItems + " for: " + displayName );

                // Get random item
                string inventoryName = llList2String( InventoryIterator( [ INVENTORY_ITERATOR_FIND_RANDOM_ITEM ] ) , 0 );

                // If item is no-copy, then we know we can only hand out one at
                // a time anyway, so no need to shorten the list or worry about
                // inventory being missing on the next iteration. There won't
                // be another iteration, and after handing out, we'll rescan
                // inventory anyway.
                if( ! ( PERM_COPY & llGetInventoryPermMask( inventoryName , MASK_OWNER ) ) ) {
                    // Note that the next inventory action should not report to the
                    // owner and queue up a re-scan of inventory
                    MessageOwner = FALSE;
                }

                // Schedule to give inventory, increment counter, decrement money
                itemsToSend = itemsToSend + inventoryName; // Voodoo for better memory usage
                countItemsToSend += 1;
            }

            // If only one item was given, fix the wording
            string itemPlural = " items ";
            string hasHave = "have ";
            if( 1 == countItemsToSend ) {
                itemPlural = " item ";
                hasHave = "has ";
            }

            // Build the name of the folder to give
            string objectName = llGetObjectName();
            string folderSuffix = ( " (Easy Gacha " + (string)countItemsToSend + itemPlural + llGetDate() + ")" );
            if( llStringLength( objectName ) + llStringLength( folderSuffix ) > MAX_FOLDER_NAME_LENGTH ) {
                // 4 == 3 for ellipses, 1 because this is end index, not count
                objectName = ( llGetSubString( objectName , 0 , MAX_FOLDER_NAME_LENGTH - llStringLength( folderSuffix ) - 4 ) + "..." );
            }

            // If too much money was given
            string change = "";
            lindensReceived -= ( totalItems * Price );
            if( lindensReceived ) {
                // Give back the excess
                llGiveMoney( buyerId , lindensReceived );
                change = " Your change is L$" + (string)lindensReceived;
            }

            // Thank them for their purchase
            Message( MESSAGE_WHISPER , "Thank you for your purchase, " + displayName + "! Your " + (string)countItemsToSend + itemPlural + hasHave + "been sent." + change );

            // Give the inventory
            Message( MESSAGE_SET_TEXT , "Please wait, giving items to: " + displayName );
            if( 1 < countItemsToSend || FolderForOne ) {
                llGiveInventoryList( buyerId , objectName + folderSuffix , itemsToSend ); // FORCED_DELAY 3.0 seconds
            } else {
                llGiveInventory( buyerId , llList2String( itemsToSend , 0 ) ); // FORCED_DELAY 2.0 seconds
            }

            // Distribute the money
            InventoryIterator( [ INVENTORY_ITERATOR_PROCESS_PAYOUTS , countItemsToSend ] );

            // Send statistics to server if server is configured
            if( AllowStatSend ) {
                HttpRequest( SERVER_URL_PURCHASE , [
                    RuntimeId
                    , buyerId
                    , displayName
                    ] + itemsToSend
                );
            }
        }

        Hover( "" );
    }
}

#end states
