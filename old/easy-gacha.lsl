#include lib/CheckBaseAssumptions.lsl

#define STATUS_MASK_CHECK_BASE_ASSUMPTIONS 1
#define STATUS_MASK_INVENTORY_CHANGED 2
#define STATUS_MASK_HANDOUT_NEEDED 4

#define INVENTORY_COUNT InventoryCount
#define TEXTURE_COUNT TextureCount

////////////////////////////////////////////////////////////////////////////////
//
//  SETUP STEPS
//
//  1: Validating configuration
//  2: Validating items and rarity
//  3: Validating consistency
//  4: Reporting percentages
//  5: Validating payouts
//  6: Sending configuration to server for stats tracking
//  7: Allowing time for garbage collection
//
////////////////////////////////////////////////////////////////////////////////

#start globalvariables

    // Config settings
    float Rarity; // Sum
    integer Price; // Sum
    integer PayoutsCount; // Number of payout records
    integer SetPayActionOnRootPrim; // Boolean
    integer AllowStatSend; // Boolean
    integer AllowShowStats; // Boolean
    integer BuyButton1; // Should be item count during config, price after config
    integer BuyButton2; // Should be item count during config, price after config
    integer BuyButton3; // Should be item count during config, price after config
    integer PayAnyAmount; // 0/1 during config ends, price after config
    integer MaxPerPurchase; // Not to exceed MAX_PER_PURCHASE
    integer FolderForOne; // Boolean
    integer ListOnTouch; // Boolean
    integer HasNoCopyItems; // Boolean

    // Runtime
    key RuntimeId; // Generated each time inventory is scanned
    integer StatusMask; // Bitmask
    key DataServerRequest;
    integer DataServerRequestIndex;
    integer ItemCount; // The number of items which will actually be given away
    float MostRare; // The rarity index of the most rare item
    float MostCommon; // The rarity index of the least rare item

    // Delivery
    list HandoutQueue; // Strided list of [ Agent Key , Lindens Given ]
    integer HandoutQueueCount; // List length (not stride item length)
    integer HaveHandedOut; // Boolean

#end globalvariables
#start globalfunctions

list InventoryIterator( list config ) {
    integer mode = llList2Integer( config , 0 );
    integer iterate;
    integer iterateOver = INVENTORY_ALL;
    integer iterateFor = InventoryCount;
    string inventoryName;
    integer skipConfig = FALSE;
    integer skipNonConfig = FALSE;

    integer messageMode;
    float rarity;
    integer setPrice;
    string settings;
    float random;
    integer i0;
    list l0;
    key k0;
    integer foundIndex;

    if( INVENTORY_ITERATOR_SEND_CONFIG == mode ) {
        settings = "# version VERSION\n";
    }
    if( INVENTORY_ITERATOR_FIND_RANDOM_ITEM == mode ) {
        random = Rarity - llFrand( Rarity ); // Generate a random number which is between [ Rarity , 0.0 )
    }

    for( iterate = 0 ; iterate < iterateFor ; iterate += 1 ) {
        // If it's a config item / not a config item, skip it
        if( CONFIG_INVENTORY_ID == llGetInventoryKey( inventoryName ) ) {
            if( INVENTORY_ITERATOR_PROCESS_PAYOUTS == mode && "eg_payout" == verb ) {
                // Find the space
                spaceIndex = llSubStringIndex( value , " " );

                // Split string - replaces i0 and value
                i0 = ParseLindens( llGetSubString( value , 0 , spaceIndex - 1 ) );
                value = llGetSubString( value , spaceIndex + 1 , -1 );

                // Give money
                if( Owner != (key)value ) {
                    llGiveMoney( (key)value , i0 * llList2Integer( config , 1 ) );
                }
            }

        } else { // end if config item, begin else not a config item

            if( INVENTORY_ITERATOR_SCAN_INVENTORY == mode ) {
                // If more than one config line was found, use the sum of
                // rarities for error message
                if( 1 < i0 ) {
                    Message( MESSAGE_ERROR , "Bad config: \"" + inventoryName + "\" was listed more than once. Did you mean to list it once like this? eg_rarity " + (string)( rarity ) + " " + inventoryName );
                    return [1];
                }

                // Some stats
                ItemCount += 1;
                if( rarity > MostCommon ) {
                    MostCommon = rarity;
                }
                if( 0.0 == MostRare || rarity < MostRare ) {
                    MostRare = rarity;
                }

                // If item is not copyable
                if( ! ( PERM_COPY & llGetInventoryPermMask( inventoryName , MASK_OWNER ) ) ) {
                    Message( MESSAGE_OWNER_SAY , "WARNING: \"" + inventoryName + "\" is is not copyable. When it is given out, it will disappear from inventory. Switching to no-copy-item mode. Stats are being disabled."  );

                    HasNoCopyItems = TRUE;
                    BuyButton1 = 0;
                    BuyButton2 = 0;
                    BuyButton3 = 0;
                    FolderForOne = FALSE;
                    PayAnyAmount = 0;
                    MaxPerPurchase = 1;
                    AllowStatSend = FALSE;
                }
            }

            // Calculate rarity
            if( INVENTORY_ITERATOR_REPORT_PERCENTAGES_TO_OWNER == mode || INVENTORY_ITERATOR_REPORT_PERCENTAGES_VIA_WHISPER == mode || INVENTORY_ITERATOR_SEND_CONFIG == mode || INVENTORY_ITERATOR_FIND_RANDOM_ITEM == mode ) {
                rarity = 1.0;
                if( EOF != ( value = llList2String( InventoryIterator( [ INVENTORY_ITERATOR_FIND_NTH_VERB_ID , "eg_rarity" , inventoryName , 0 ] ) , 0 ) ) ) {
                    rarity = (float)value;
                }
            }

            // Listing inventory items
            if( messageMode ) {
                // Only if there is a rarity
                if( 0.0 < rarity ) {
                    // Report percentages now that we know the totals
                    if( INVENTORY_ITERATOR_REPORT_PERCENTAGES_TO_OWNER == mode || INVENTORY_ITERATOR_REPORT_PERCENTAGES_VIA_WHISPER == mode ) {
                        Message( messageMode , "\"" + inventoryName + "\" has a probability of " + (string)( rarity / Rarity * 100 ) + "%" );
                    }
                }
            }

            // If there's no rarity, it's excluded, skip it
            if( INVENTORY_ITERATOR_SEND_CONFIG == mode ) {
                // If it's not to be handed out, skip it
                if( 0.0 == rarity ) {
                    jump break5;
                }

                inventoryName = "item " + (string)rarity + " " + inventoryName;
            }

            if( INVENTORY_ITERATOR_FIND_RANDOM_ITEM == mode ) {
                // Subtract the rarity from the random number. If zero, has
                // no effect. If greater than zero, can cause random to
                // become negative. Then we know the random number fell in
                // the range of the rarity of this item.
                random -= rarity;

                // If we've gone negative, then we have the inventory we want
                if( random < 0.0 ) {
                    return [inventoryName];
                }
            }

        } // end else not config item

        @addToConfig;

        if( INVENTORY_ITERATOR_SEND_CONFIG == mode ) {
            if( ( llStringLength( settings ) * 2 ) + llStringLength( inventoryName ) > 1024 ) {
                HttpRequest( SERVER_URL_CONFIG , [
                    RuntimeId
                    , settings
                    ]
                );
                settings = "";
            }

            settings += inventoryName + "\n";
        }

        @break5;

        if( INVENTORY_ITERATOR_REPORT_PERCENTAGES_TO_OWNER == mode || INVENTORY_ITERATOR_SCAN_INVENTORY == mode || INVENTORY_ITERATOR_SEND_CONFIG == mode ) {
            if( INVENTORY_ITERATOR_SCAN_INVENTORY == mode ) { value = "2"; }
            if( INVENTORY_ITERATOR_REPORT_PERCENTAGES_TO_OWNER == mode ) { value = "4"; }
            if( INVENTORY_ITERATOR_SEND_CONFIG == mode ) { value = "6"; }

            Message( MESSAGE_SET_TEXT , "Initializing, please wait...\nStep " + value + " of 7: " + (string)( ( iterate + 1 ) * 100 / iterateFor ) + "%" );
        }
    }

    if( INVENTORY_ITERATOR_SEND_CONFIG == mode ) {
        if( "" != settings ) {
            HttpRequest( SERVER_URL_CONFIG , [
                RuntimeId
                , settings
                ]
            );
        }

        settings = "";
    }

    if( INVENTORY_ITERATOR_FIND_NTH_VERB_ID == mode ) {
        return [ EOF ];
    }
    if( INVENTORY_ITERATOR_FIND_NTH_TWO_PART_VERB == mode ) {
        return [ EOF , EOF , EOF ];
    }

    return [];
} // end InventoryIterator()

#end globalfunctions
#start states

state setup {
    state_entry() {
        Rarity = 0.0;
        Price = 0;
        PayoutsCount = 0;
        SetPayActionOnRootPrim = FALSE;
        AllowStatSend = DEFAULT_STATS_ALLOWED;
        AllowShowStats = TRUE;
        BuyButton1 = 2;
        BuyButton2 = 5;
        BuyButton3 = 10;
        PayAnyAmount = 1;
        MaxPerPurchase = MAX_PER_PURCHASE;
        FolderForOne = TRUE;
        ListOnTouch = FALSE;
        RuntimeId = llGenerateKey();
        StatusMask = 0;
        DataServerRequest = NULL_KEY;
        DataServerRequestIndex = 0;
        ItemCount = 0;
        MostRare = 0.0;
        MostCommon = 0.0;
        HasNoCopyItems = FALSE;

        llSetTimerEvent( 0.0 );

        llSetPayPrice( PAY_DEFAULT , [ PAY_DEFAULT , PAY_DEFAULT , PAY_DEFAULT , PAY_DEFAULT ] );
        llSetTouchText( "" );

        // Step 1 of 7
        if( llList2Integer( InventoryIterator( [ INVENTORY_ITERATOR_SCAN_CONFIGS ] ) , 0 ) ) {
            return;
        }

        // Step 2 of 7
        if( llList2Integer( InventoryIterator( [ INVENTORY_ITERATOR_SCAN_INVENTORY ] ) , 0 ) ) {
            return;
        }

        Message( MESSAGE_SET_TEXT , "Initializing, please wait...\nStep 3 of 7: Validity checks" );

        // If we still don't have anything (determined by rarity because a
        // rarity of 0 means "do not sell" and default rarity is 1.0 if not
        // specified)
        if( 0.0 == Rarity ) {
            Message( MESSAGE_ERROR , "No items to hand out" );
            return;
        }

        // If price is zero, then there's no way to know how many items someone
        // wants at a time without this
        if( !Price ) {
            MaxPerPurchase = 1;
        }

        // If MaxPerPurchase was lowered and a button exceeds it, just hide the
        // button
        if( BuyButton1 > MaxPerPurchase ) { BuyButton1 = 0; }
        if( BuyButton2 > MaxPerPurchase ) { BuyButton2 = 0; }
        if( BuyButton3 > MaxPerPurchase ) { BuyButton3 = 0; }

        // Now turn settings into actual price
        if( 0 == PayAnyAmount ) { PayAnyAmount = PAY_HIDE; } else { PayAnyAmount  = Price; }
        if( 0 == BuyButton1   ) { BuyButton1   = PAY_HIDE; } else { BuyButton1   *= Price; }
        if( 0 == BuyButton2   ) { BuyButton2   = PAY_HIDE; } else { BuyButton2   *= Price; }
        if( 0 == BuyButton3   ) { BuyButton3   = PAY_HIDE; } else { BuyButton3   *= Price; }

        if( !SetPayActionOnRootPrim && LINK_ROOT == llGetLinkNumber() ) {
            Message( MESSAGE_OWNER_SAY , "WARNING: This script is in the root prim of a set. If it sets the default action to payment, that will override the default action on other prims in the set. To enable this feature, set \"eg_set_root_prim_click yes\""  );
        }

        // Report percentages now that we know the totals
        InventoryIterator( [ INVENTORY_ITERATOR_REPORT_PERCENTAGES_TO_OWNER ] ); // Step 4 of 7

        // Show a warning if there are a lot of items to choose from
        if( MANY_ITEMS_WARNING < ItemCount ) {
            Message( MESSAGE_OWNER_SAY , "WARNING: There are a LOT of items to give out. This will slow things down considerably while handing them out. Consider removing a few, or setting \"eg_buy_max_items 1\""  );
        }

        // Kick off payout lookups
        if( PayoutsCount ) {
            Message( MESSAGE_SET_TEXT , "Initializing, please wait...\nStep 5 of 7: 0%" );
            DataServerRequest = llRequestUsername( llList2Key( InventoryIterator( [ INVENTORY_ITERATOR_FIND_NTH_TWO_PART_VERB , "eg_payout" , DataServerRequestIndex = 0 ] ) , 2 ) );
        } else {
            // Kick off for owner, because we know it will work
            DataServerRequest = llRequestUsername( Owner );
        }
        llSetTimerEvent( 30.0 );
    } // end state_entry()

    dataserver( key queryId , string data ) {
        // Report total price
        Message( MESSAGE_OWNER_SAY , "The total price is L$" + (string)Price );

        // Send config to server
        if( AllowStatSend ) {
            InventoryIterator( [ INVENTORY_ITERATOR_SEND_CONFIG ] ); // Step 6 of 7
        }

        Message( MESSAGE_SET_TEXT , "Initializing, please wait...\nStep 7 of 7" );

        // All done!
        Message( MESSAGE_OWNER_SAY , SOURCE_CODE_MESSAGE );
        Message( MESSAGE_DEBUG , "Memory Used: " + (string)llGetUsedMemory() + " Memory Free: " + (string)llGetFreeMemory() );
        Message( MESSAGE_OWNER_SAY , "Ready!" );

        state ready;
    } // end dataserver()
} // end state setup

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

    timer() {
        llSetTimerEvent( 0.0 );

        // If something more serious has happend
        if( STATUS_MASK_CHECK_BASE_ASSUMPTIONS & StatusMask ) {
            CheckBaseAssumptions();
        }

        // If we know we need to re-scan, do so
        if( !MessageOwner || STATUS_MASK_INVENTORY_CHANGED & StatusMask ) {
            state setup;
        }

        state ready;
    }
}

#end states
