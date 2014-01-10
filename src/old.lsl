default {
    ///////////////////
    // state default //
    ///////////////////

    dataserver( key queryId , string data ) {
            // Now that we're done processing the config notecard
            if( EOF == data ) {
                // Check that at least one was configured
                if( 0 == CountInventory ) {
                    // Attempt to populate inventory evenly - last ditch effort
                    // here, probably not what someone really wants, but just
                    // in case we'll try it
                    i1 = llGetInventoryNumber( INVENTORY_ALL );
                    for( i0 = 0 ; i0 < i1 ; i0 += 1 ) {
                        s0 = llGetInventoryName( INVENTORY_ALL , i0 );
                        if( ScriptName != s0 && CONFIG != s0 ) {
                            SumProbability += 1.0;
                            Inventory = ( Inventory = [] ) + Inventory + [ s0 , 1.0 ]; // Voodoo for better memory usage
                            CountInventory += 2;
                        }
                    }

                    // If we still don't have anything
                    if( 0 == CountInventory ) {
                        ShowError( "Bad configuration: No items were listed!" );
                        return;
                    }

                    // Give a hint as to why no items configured works
                    llOwnerSay( ScriptName + ": WARNING: No items configured, using entire inventory of object with even probabilities" );
                }

                // Check details of inventory
                for( i0 = 0 ; i0 < CountInventory ; i0 += 2 ) {
                    // Get name
                    s0 = llList2String( Inventory , i0 );

                    // Inventory must be copyable
                    if( ! ( PERM_COPY & llGetInventoryPermMask( s0 , MASK_OWNER ) ) ) {
                        ShowError( "\"" + s0 + "\" is not copyable. If given, it would disappear from inventory, so it cannot be used. " );
                        return;
                    }

                    // Inventory must be transferable
                    if( ! ( PERM_TRANSFER & llGetInventoryPermMask( s0 , MASK_OWNER ) ) ) {
                        ShowError( "\"" + s0 + "\" is not transferable. So how can I give it out? " );
                        return;
                    }
                }

                // Check that at least one was configured. If none were
                // configured, we can't even attempt a last-ditch auto-config
                // here because we wouldn't know the right L$ to charge.
                if( 0 == CountPayees ) {
                    ShowError( "Bad configuration: No payouts were listed!" );
                    return;
                }

                // Check that pay buttons aren't out of bounds
                if( PayButton1 && PayButton1 > MaxPerPurchase ) {
                    ShowError( "Bad configuration: buy_button 1 exceeds maximum of " + (string)MaxPerPurchase );
                    return;
                }
                if( PayButton2 && PayButton2 > MaxPerPurchase ) {
                    ShowError( "Bad configuration: buy_button 2 exceeds maximum of " + (string)MaxPerPurchase );
                    return;
                }
                if( PayButton3 && PayButton3 > MaxPerPurchase ) {
                    ShowError( "Bad configuration: buy_button 3 exceeds maximum of " + (string)MaxPerPurchase );
                    return;
                }

                // Check that duplicate buttons weren't provided
                if( PayButton1 && PayButton1 == PayButton2 ) {
                    ShowError( "Bad configuration: buy_button 1 and buy_button 2 are the same" );
                    return;
                }
                if( PayButton1 && PayButton1 == PayButton3 ) {
                    ShowError( "Bad configuration: buy_button 1 and buy_button 3 are the same" );
                    return;
                }
                if( PayButton2 && PayButton2 == PayButton3 ) {
                    ShowError( "Bad configuration: buy_button 2 and buy_button 3 are the same" );
                    return;
                }

                // If we shouldn't allow the root prim in a linked set
                if( !AllowRootPrim && LINK_ROOT == llGetLinkNumber() ) {
                    ShowError( "This script is in the root prim of a linked set. It will override the default click action for the ENTIRE OBJECT, setting it to click-to-pay. If this is really what you want, change the config to: allow_root_prim yes" );
                    return;
                }

                // Report percentages now that we know the totals
                for( i0 = 0 ; i0 < CountInventory ; i0 += 2 ) {
                    f0 = ( llList2Float( Inventory , i0 + 1 ) / SumProbability );
                    llOwnerSay( ScriptName + ": \"" + llList2String( Inventory , i0 ) + "\" has a probability of " + (string)( f0 * 100 ) + "%" );
                }

                // Set payment option
                if( 0 == PayAnyAmount ) { PayAnyAmount = PAY_HIDE; } else { PayAnyAmount  = Price; }
                if( 0 == PayButton1   ) { PayButton1   = PAY_HIDE; } else { PayButton1   *= Price; }
                if( 0 == PayButton2   ) { PayButton2   = PAY_HIDE; } else { PayButton2   *= Price; }
                if( 0 == PayButton3   ) { PayButton3   = PAY_HIDE; } else { PayButton3   *= Price; }

                // Load first line of config
                SetText( "Checking payouts 0%, please wait..." );
                InitState = 3;
                DataServerRequest = llRequestUsername( llList2Key( Payees , DataServerRequestIndex = 0 ) );
                llSetTimerEvent( 30.0 );
                return;
            }

            // Handle an item entry
            if( "item" == s1 ) {
                // Pull the probability number off the front of the string
                f0 = (float)llGetSubString( s0 , 0 , i0 );

                // If the probability is out of bounds
                if( 0.0 >= f0 ) {
                    BadConfig( "Number must be greater than zero. " , data );
                    return;
                }

                // Name must be provided
                if( llStringLength( s0 ) - 1 == i0 ) {
                    BadConfig( "Inventory name must be provided. " , data );
                    return;
                }

                // Grab inventory name off string
                s0 = llGetSubString( s0 , i0 + 1 , -1 );

                // Inventory must exist
                if( INVENTORY_NONE == llGetInventoryType( s0 ) ) {
                    BadConfig( "Cannot find \"" + s0 + "\" in inventory. " , data );
                    return;
                }

                // If they put the same item in twice
                if( -1 != llListFindList( Inventory , [ s0 ] ) ) {
                    BadConfig( "\"" + s0 + "\" was listed twice. Did you mean to list it once with a rarity of " + (string)( llList2Float( Inventory , llListFindList( Inventory , [ s0 ] ) + 1 ) + f0 ) + "? " , data );
                    return;
                }

                // Store the configuration and add probably to the sum
                SumProbability += f0;
                Inventory = ( Inventory = [] ) + Inventory + [ s0 , f0 ]; // Voodoo for better memory usage
                CountInventory += 2;

                // Load next line of config
                NextConfigLine();
                return;
            } // end if( "item" ... )

            // Handle a payout entry
            // Valid money formats: L$#, $#, #, #L
            if( "payout" == s1 ) {
                // Strip "L" off the front
                if( "l" == llToLower( llGetSubString( s0 , 0 , 0 ) ) ) {
                    s0 = llGetSubString( s0 , 1 , -1 );
                }

                // Strip "$" off the front
                if( "$" == llGetSubString( s0 , 0 , 0 ) ) {
                    s0 = llGetSubString( s0 , 1 , -1 );
                }

                // Find second space
                i0 = llSubStringIndex( s0 , " " );

                // If there's not another space on the line, it's invalid
                if( 0 >= i0 ) {
                    BadConfig( "" , data );
                    return;
                }

                // Pull the payment number off the front of the string
                i1 = (integer)llGetSubString( s0 , 0 , i0 );

                // If the payment is out of bounds
                if( 0 >= i1 ) {
                    BadConfig( "L$ to give must be greater than zero. " , data );
                    return;
                }

                // Name must be provided
                if( llStringLength( s0 ) - 1 == i0 ) {
                    BadConfig( "User key must be provided. " , data );
                    return;
                }

                // Grab agent key off the string
                s0 = llGetSubString( s0 , i0 + 1 , -1 );

                // Convert to key
                k0 = (key)s0;
                if( "owner" == s0 ) {
                    k0 = Owner;
                }
                if( "creator" == s0 ) {
                    k0 = llGetCreator();
                }
                if( "scriptor" == s0 ) {
                    k0 = llGetInventoryCreator( ScriptName );
                }

                // If they put the same item in twice
                if( -1 != llListFindList( Payees , [ k0 ] ) ) {
                    if( Owner == k0 ) {
                        s0 = "owner";
                    }
                    if( llGetCreator() == k0 ) {
                        s0 = "creator";
                    }
                    if( llGetInventoryCreator( ScriptName ) == k0 ) {
                        s0 = "scriptor";
                    }

                    BadConfig( s0 + " was listed twice. Did you mean to list them once with a payout of " + (string)( llList2Integer( Payees , llListFindList( Payees , [ k0 ] ) + 1 ) + i1 ) + "? " , data );
                    return;
                }

                // Store the configuration
                Price += i1;
                Payees = ( Payees = [] ) + Payees + [ k0 , i1 ]; // Voodoo for better memory usage
                CountPayees += 2;

                // Load next line of config
                NextConfigLine();
                return;
            }

            // Advanced option
            if( "buy_button" == s1 ) {
                // Find second space
                i0 = llSubStringIndex( s0 , " " );

                // If there's not another space on the line, it's invalid
                if( 0 >= i0 ) {
                    BadConfig( "" , data );
                    return;
                }

                // Get the number off the end first (number of items)
                if( "off" == llGetSubString( s0 , i0 + 1 , -1 ) ) {
                    i1 = 0;
                } else {
                    i1 = (integer)llGetSubString( s0 , i0 + 1 , -1 );
                }

                // Then reuse for button number
                i0 = (integer)llGetSubString( s0 , 0 , i0 - 1 );

                // If item count isn't greater than 1 and isn't PAY_HIDE, bad
                // format
                if( 0 != i1 && 1 >= i1 ) {
                    BadConfig( "buy_button must have an item count greater than one. " , data );
                    return;
                }

                // Store button value
                if( 1 == i0 ) {
                    PayButton1 = i1;
                } else if( 2 == i0 ) {
                    PayButton2 = i1;
                } else if( 3 == i0 ) {
                    PayButton3 = i1;
                } else {
                    BadConfig( "Which button number did you mean to put here? " , data );
                    return;
                }

                // Load next line of config
                NextConfigLine();
                return;
            }

            // Advanced option
            if( "pay_any_amount" == s1 ) {
                if( -1 == ( PayAnyAmount = BooleanConfigOption( s0 ) ) ) {
                    BadConfig( "" , data );
                    return;
                }

                // Load next line of config
                NextConfigLine();
                return;
            }

            // Advanced option
            if( "allow_send_stats" == s1 ) {
                if( -1 == ( AllowStatSend = BooleanConfigOption( s0 ) ) ) {
                    BadConfig( "" , data );
                    return;
                }

                // Load next line of config
                NextConfigLine();
                return;
            }

            // Advanced option
            if( "allow_show_stats" == s1 ) {
                if( -1 == ( AllowShowStats = BooleanConfigOption( s0 ) ) ) {
                    BadConfig( "" , data );
                    return;
                }

                // Load next line of config
                NextConfigLine();
                return;
            }

            // Advanced option
            if( "buy_max_items" == s1 ) {
                // Get config value
                i1 = (integer)s0;

                // If the payment is out of bounds
                if( 0 >= i1 || 100 < i1 ) {
                    BadConfig( "" , data );
                    return;
                }

                // Store the new value
                MaxPerPurchase = i1;

                // Load next line of config
                NextConfigLine();
                return;
            }

            // Advanced option
            if( "allow_root_prim" == s1 ) {
                if( -1 == ( AllowRootPrim = BooleanConfigOption( s0 ) ) ) {
                    BadConfig( "" , data );
                    return;
                }

                // Load next line of config
                NextConfigLine();
                return;
            }

            // Advanced option
            if( "folder_for_one" == s1 ) {
                if( -1 == ( FolderForOne = BooleanConfigOption( s0 ) ) ) {
                    BadConfig( "" , data );
                    return;
                }

                // Load next line of config
                NextConfigLine();
                return;
            }

            // Completely unknown verb
            BadConfig( "" , data );
            return;
        } // end if( 2 == InitState )

        // If the result is the lookup of a user from the Payees
        if( 3 == InitState ) {
            // Note that this user was looked up correctly and report the amount to be given
            llOwnerSay( ScriptName + ": Will give L$" + (string)llList2Integer( Payees , DataServerRequestIndex + 1 ) + " to " + data + " for each item purchased." );

            // Increment to next value
            DataServerRequestIndex += 2;
            SetText( "Checking payouts " + (string)( DataServerRequestIndex * 100 / CountPayees ) + "%, please wait..." );

            // If there are more to look up
            if( DataServerRequestIndex < CountPayees ) {
                // Look up the next one
                DataServerRequest = llRequestUsername( llList2Key( Payees , DataServerRequestIndex ) );
                llSetTimerEvent( 30.0 );
                return;
            }

            // Report total price
            llOwnerSay( ScriptName + ": The total price is L$" + (string)Price );

            // Get permission to give money (so we can give refunds at least)
            llOwnerSay( ScriptName + ": Getting ability to debit, please grant permission..." );
            SetText( "Getting permission..." );
            llRequestPermissions( Owner , PERMISSION_DEBIT );
            llSetTimerEvent( 30.0 );
            InitState = 4;
        }
    }

    timer() {
        // Reset/stop timer
        llSetTimerEvent( 0.0 );

        if( 1 == InitState ) {
            ShowError( "Timed out while trying to get line count for \"" + CONFIG );
        } else if( 2 == InitState ) {
            ShowError( "Timed out while trying to fetch line " + (string)(DataServerRequestIndex + 1) + " from \"" + CONFIG );
        } else if( 3 == InitState ) {
            ShowError( "Timed out while trying to look up user key. The user \"" + llList2String( Payees , DataServerRequestIndex ) + "\" doesn't seem to exist, or the data server is being too slow." );
        } else if( 4 == InitState ) {
            ShowError( "Timed out while trying to get permission. Please touch to reset and make sure to grant the money permission when asked." );
        } else {
            ShowError( "Timed out." );
        }
    }

    run_time_permissions( integer permissionMask ) {
        if( ! ( PERMISSION_DEBIT & permissionMask ) ) {
            llResetScript();
        } else {
            llSetTimerEvent( 0.0 );
            state ready;
        }
    }

    state_exit() {
        if( AllowStatSend && llStringLength( SERVER_URL_CONFIG ) ) {
            llHTTPRequest( SERVER_URL_CONFIG , SERVER_OPTIONS , llList2Json( JSON_ARRAY , [
                RuntimeId
                , RelevantConfig
                ]
            ) );
        }

        llOwnerSay( ScriptName + ": " + SOURCE_CODE_MESSAGE );
    }
}

state ready {
    ////////////
    // Resets //
    ////////////

    // If the object is attached or detached, reset
    attach( key avatarId ){
        llSetTimerEvent( 0.01 );
    }

    // Each time the object is rezzed, reset
    on_rez( integer rezParam ) {
        llSetTimerEvent( 0.01 );
    }

    // If the owner changes, copy permissions may no longer apply for
    // inventory. If the inventory changes, we have to recertify everything
    // anyway.
    changed( integer changeMask ) {
        if( changeMask & ( CHANGED_INVENTORY | CHANGED_OWNER | CHANGED_LINK ) ) {
            llSetTimerEvent( 0.01 );
        }
    }

    // If the money permission gets revoked, start over
    run_time_permissions( integer permissionMask ) {
        if( ! ( PERMISSION_DEBIT & permissionMask ) ) {
            llSetTimerEvent( 0.01 );
        }
    }

    // We use the timer event to prevent the queue from being dumped.
    // See http://wiki.secondlife.com/wiki/State#Notes
    timer() {
        llResetScript();
    }

    /////////////////
    // state ready //
    /////////////////

    state_entry() {
        llSetText( "" , ZERO_VECTOR , 0.0 );
        llSetClickAction( CLICK_ACTION_PAY );
        llSetPayPrice( PayAnyAmount , [ Price , PayButton1 , PayButton2 , PayButton3 ] );
        llSetTouchText( "Info" );
    }

    // Rate limited
    touch_end( integer detected ) {
        while( 0 <= ( detected -= 1 ) ) {
            if( llDetectedKey( detected ) == Owner && AllowStatSend && !AllowShowStats && llStringLength( SERVER_URL_STATS ) ) {
                llOwnerSay( ScriptName + ":\nWant to see some statistics for this object? Click here: " + SERVER_URL_STATS + (string)RuntimeId + "\n" + SOURCE_CODE_MESSAGE );
            } else {
                if( AllowStatSend && AllowShowStats && llStringLength( SERVER_URL_STATS ) ) {
                    llWhisper( 0 , ScriptName + ":\nWant to see some statistics for this object? Click here: " + SERVER_URL_STATS + (string)RuntimeId + "\n" + SOURCE_CODE_MESSAGE );
                } else {
                    llWhisper( 0 , ScriptName + ": " + SOURCE_CODE_MESSAGE );
                }
            }
        }
    }

    // Switching states here would prevent further orders from being placed
    // while this one is being processed, but would also flush the event queue,
    // which would kill any orders placed in parallel. We have to honor the
    // event queue, so... do things as fast and efficiently as we can
    money( key buyerId , integer lindensReceived ) {
        float random;
        integer selected;
        integer countItemsToSend = 0;
        list itemsToSend = [];
        string change = "";
        string itemPlural = " items ";
        string hasHave = "have ";
        string objectName = llGetObjectName();
        string displayName = llGetDisplayName( buyerId );

        // Let them know we're thinking
        SetText( "Please wait, getting random items for " + displayName );

        // If not enough money
        if( lindensReceived < Price ) {
            // Send statistics to server if server is configured
            if( AllowStatSend && llStringLength( SERVER_URL_PURCHASE ) ) {
                llHTTPRequest( SERVER_URL_PURCHASE , SERVER_OPTIONS , llList2Json( JSON_ARRAY , [
                    RuntimeId
                    , buyerId
                    , displayName
                ] ) );
            }

            // Give money back
            llGiveMoney( buyerId , lindensReceived );
            llWhisper( 0 , ScriptName + ": Sorry " + displayName + ", the price is L$" + (string)Price );
            return;
        }

        // While there's still enough money for another item
        while( lindensReceived >= Price && countItemsToSend < MaxPerPurchase ) {
            random = llFrand( SumProbability ); // Generate a random number which is between [ 0.0 , SumProbability )
            selected = -2; // Start below the first object because the first iteration will definitely run once

            // While the random number is at or above zero, we haven't hit our
            // target object. Exiting the while loop will result in a random number
            // at or below zero, indicating the selected index matches an object.
            while( 0 <= random ) {
                selected += 2;
                random -= llList2Float( Inventory , selected + 1 );
            }

            // Schedule to give inventory, increment counter, decrement money
            itemsToSend = ( itemsToSend = [] ) + itemsToSend + [ llList2String( Inventory , selected ) ]; // Voodoo for better memory usage
            countItemsToSend += 1;
            lindensReceived -= Price;
        }

        // Distribute the money
        integer x;
        for( x = 0 ; x < CountPayees ; x += 2 ) {
            if( Owner != llList2Key( Payees , x ) ) {
                llGiveMoney( llList2Key( Payees , x ) , llList2Integer( Payees , x + 1 ) * countItemsToSend );
            }
        }

        // If too much money was given
        if( lindensReceived ) {
            // Give back the excess
            llGiveMoney( buyerId , lindensReceived );
            change = " Your change is L$" + (string)lindensReceived;
        }

        // If only one item was given, fix the wording
        if( 1 == countItemsToSend ) {
            itemPlural = " item ";
            hasHave = "has ";
        }

        // Thank them for their purchase
        llWhisper( 0 , "Thank you for your purchase, " + displayName + "! Your " + (string)countItemsToSend + itemPlural + hasHave + "been sent." + change );

        // Build the name of the folder to give
        string folderSuffix = ( " (Easy Gacha " + (string)countItemsToSend + itemPlural + llGetDate() + ")" );
        if( llStringLength( objectName ) + llStringLength( folderSuffix ) > MAX_FOLDER_NAME_LENGTH ) {
            objectName = ( llGetSubString( objectName , 0 , MAX_FOLDER_NAME_LENGTH - llStringLength( folderSuffix ) - 4 /* 3 for ellipses, 1 because this is end index, not count */ ) + "..." );
        }

        // Give the inventory
        if( 1 < countItemsToSend || FolderForOne ) {
            llGiveInventoryList( buyerId , objectName + folderSuffix , itemsToSend ); // FORCED_DELAY 3.0 seconds
        } else {
            llGiveInventory( buyerId , llList2String( itemsToSend , 0 ) ); // FORCED_DELAY 2.0 seconds
        }

        // Send statistics to server if server is configured
        if( AllowStatSend && llStringLength( SERVER_URL_PURCHASE ) ) {
            llHTTPRequest( SERVER_URL_PURCHASE , SERVER_OPTIONS , llList2Json( JSON_ARRAY , [
                RuntimeId
                , buyerId
                , displayName
                ] + itemsToSend
            ) );
        }

        // Clear the thinkin' text
        llSetText( "" , ZERO_VECTOR , 0.0 );
    }
}
