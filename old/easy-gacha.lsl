#start globalvariables

    // Runtime
    key RuntimeId; // Generated each time inventory is scanned
    integer StatusMask; // Bitmask
    key DataServerRequest;
    integer DataServerRequestIndex;
    integer ItemCount; // The number of items which will actually be given away

    // Delivery
    list HandoutQueue; // Strided list of [ Agent Key , Lindens Given ]
    integer HandoutQueueCount; // List length (not stride item length)
    integer HaveHandedOut; // Boolean

#end globalvariables

#start states

state ready {
    attach( key avatarId ){
        StatusMask = StatusMask | STATUS_MASK_CHECK_BASE_ASSUMPTIONS;
        llSetTimerEvent( 0.0 ); // Take timer event off stack
        llSetTimerEvent( 0.01 ); // Add it to end of stack
    }

    on_rez( integer rezParam ) {
        StatusMask = StatusMask | STATUS_MASK_CHECK_BASE_ASSUMPTIONS;
        llSetTimerEvent( 0.0 ); // Take timer event off stack
        llSetTimerEvent( 0.01 ); // Add it to end of stack
    }

    run_time_permissions( integer permissionMask ) {
        StatusMask = StatusMask | STATUS_MASK_CHECK_BASE_ASSUMPTIONS;
        llSetTimerEvent( 0.0 ); // Take timer event off stack
        llSetTimerEvent( 0.01 ); // Add it to end of stack
    }

    changed( integer changeMask ) {
        StatusMask = StatusMask | STATUS_MASK_CHECK_BASE_ASSUMPTIONS;
        llSetTimerEvent( 0.0 ); // Take timer event off stack
        llSetTimerEvent( 0.01 ); // Add it to end of stack

        if( ( CHANGED_INVENTORY | CHANGED_LINK ) & changeMask ) {
            StatusMask = StatusMask | STATUS_MASK_INVENTORY_CHANGED;
        }
    }

    state_entry() {
        MessageOwner = TRUE;
        HandoutQueue = [];
        HandoutQueueCount = 0;

        llSetText( "" , ZERO_VECTOR , 1 );

        if( Price ) {
            llSetPayPrice( PayAnyAmount , [ Price , BuyButton1 , BuyButton2 , BuyButton3 ] );
            llSetTouchText( "Info" );
        } else {
            llSetPayPrice( PAY_HIDE , [ PAY_HIDE , PAY_HIDE , PAY_HIDE , PAY_HIDE ] );
            llSetTouchText( "Play" );
        }

        if( SetPayActionOnRootPrim || LINK_ROOT != llGetLinkNumber() ) {
            if( Price ) {
                llSetClickAction( CLICK_ACTION_PAY );
            } else {
                llSetClickAction( CLICK_ACTION_TOUCH );
            }
        }

llOwnerSay( "Memory Used: " + (string)llGetUsedMemory() + " Memory Free: " + (string)llGetFreeMemory() );
    }

    touch_end( integer detected ) {
        integer messageMode = 0;

        if( AllowStatSend && AllowShowStats ) {
            messageMode = 4;
        }

        // For each person that touched
        while( 0 <= ( detected -= 1 ) ) {
            // This is the exception which will be direct to owner
            if( llDetectedKey( detected ) == Owner ) {
                // Only if we're not going to whisper it
                if( AllowStatSend && !AllowShowStats ) {
                    messageMode = messageMode | 2;
                }

                // Memory will only be shown to owner now
                Message( MESSAGE_DEBUG , "Script Memory Used: " + (string)llGetUsedMemory() + " Memory Free: " + (string)llGetFreeMemory() );
            }

            // If price is zero, has to be touch based
            if( !Price ) {
                HandoutQueue = HandoutQueue + llDetectedKey( detected ); // Voodoo for better memory usage
                HandoutQueue = HandoutQueue + 0; // Voodoo for better memory usage
                HandoutQueueCount += 2;
                StatusMask = StatusMask | STATUS_MASK_HANDOUT_NEEDED;
                llSetTimerEvent( 0.0 ); // Take timer event off stack
                llSetTimerEvent( 0.01 ); // Add it to end of stack
            }
        }

        // Whisper source code message
        Message( MESSAGE_WHISPER , SOURCE_CODE_MESSAGE );
        Message( MESSAGE_WHISPER , "I have " + (string)ItemCount + " items to give out. Of them, the most rare has a " + (string)( MostRare / Rarity * 100 ) + "% chance, and the most common has a " + (string)( MostCommon / Rarity * 100 ) + "% chance." );

        // If stats can be sent at all
        if( AllowStatSend ) {
            Message( messageMode , ( "Want to see some statistics for this object? Click this link: " + SERVER_URL_STATS + (string)RuntimeId ) );
        }

        if( ListOnTouch ) {
            InventoryIterator( [ INVENTORY_ITERATOR_REPORT_PERCENTAGES_VIA_WHISPER ] );
        }
    }

    // Switching states here would prevent further orders from being placed
    // while this one is being processed, but would also flush the event queue,
    // which would kill any orders placed in parallel. We have to honor the
    // event queue, so... do things as fast and efficiently as we can
    money( key buyerId , integer lindensReceived ) {
        HandoutQueue = HandoutQueue + buyerId; // Voodoo for better memory usage
        HandoutQueue = HandoutQueue + lindensReceived; // Voodoo for better memory usage
        HandoutQueueCount += 2;
        StatusMask = StatusMask | STATUS_MASK_HANDOUT_NEEDED;
        llSetTimerEvent( 0.0 ); // Take timer event off stack
        llSetTimerEvent( 0.01 ); // Add it to end of stack
    }

    timer() {
        llSetTimerEvent( 0.0 );

        if( STATUS_MASK_HANDOUT_NEEDED & StatusMask ) {
            state handout;
        }

        if( STATUS_MASK_CHECK_BASE_ASSUMPTIONS & StatusMask ) {
            CheckBaseAssumptions();
        }

        if( STATUS_MASK_INVENTORY_CHANGED & StatusMask ) {
            state setup;
        }
    }
}

// Note: State has neither touch events nor pay events, preventing further
// additions to the queue
state handout {
    attach( key avatarId ){
        StatusMask = StatusMask | STATUS_MASK_CHECK_BASE_ASSUMPTIONS;
        llSetTimerEvent( 0.0 ); // Take timer event off stack
        llSetTimerEvent( 0.01 ); // Add it to end of stack
    }

    on_rez( integer rezParam ) {
        StatusMask = StatusMask | STATUS_MASK_CHECK_BASE_ASSUMPTIONS;
        llSetTimerEvent( 0.0 ); // Take timer event off stack
        llSetTimerEvent( 0.01 ); // Add it to end of stack
    }

    run_time_permissions( integer permissionMask ) {
        StatusMask = StatusMask | STATUS_MASK_CHECK_BASE_ASSUMPTIONS;
        llSetTimerEvent( 0.0 ); // Take timer event off stack
        llSetTimerEvent( 0.01 ); // Add it to end of stack
    }

    changed( integer changeMask ) {
        StatusMask = StatusMask | STATUS_MASK_CHECK_BASE_ASSUMPTIONS;
        llSetTimerEvent( 0.0 ); // Take timer event off stack
        llSetTimerEvent( 0.01 ); // Add it to end of stack

        if( ( CHANGED_INVENTORY | CHANGED_LINK ) & changeMask ) {
            StatusMask = StatusMask | STATUS_MASK_INVENTORY_CHANGED;
        }
    }

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

        // Clear the thinkin' text
        llSetText( "" , ZERO_VECTOR , 1 );

        llSetTimerEvent( 0.01 ); // Add it to end of stack
    }
}

#end states
