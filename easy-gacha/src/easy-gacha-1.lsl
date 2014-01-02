// easy-gacha-1: validate-config

#include lib/CONSTANTS.lsl
#include tools/Message.lsl
#include tools/ParseBooleanConfig.lsl
#include tools/ParseLindensConfig.lsl
#include tools/ParseKeyConfig.lsl
#include tools/FindInventoryByName.lsl

#define ASSET_SERVER_TIMEOUT 5.0

#start globalvariables

    // 0: Get config line count
    // 1: Get config line text
    // 2: Lookup report avatar key
    // 3: Lookup payout target
    // 4: Get config line looking for duplicate payouts
    // 5: Get config line looking for duplicate items
    integer Mode;

    // Traversal
    key DataServerRequest;
    integer LineNumber;
    integer DuplicatesLookupLineNumber;
    integer TotalNotecardLines;

    // Config validation
    integer PriceSet;
    integer PricePayout;
    integer CountPayouts;
    float RarityBlock;
    float TotalRarity;
    integer ConfiguredInventory;
    integer PayAnyAmount;
    string VerbsSeen;
    integer MaxPerPurchase;
    integer BuyButton0;
    integer BuyButton1;
    integer BuyButton2;
    integer BuyButton3;
    integer EmailReportEnabled;
    string ImReportTargetConfig;
    key ImReportTarget;
    string PayoutTargetConfig;
    integer PayoutTargetAmount;
    key PayoutTarget;
    string PayoutTargetName;
    integer PayoutTargetLineCount;
    string DuplicateInventoryComparison;

#end globalvariables

#start globalfunctions

    RestartConfig() {
        llSetScriptState( SCRIPT_BOOT , TRUE );
        llResetScript();
    }

    // Return: Early exit needed
    integer GetNextDuplicateItemLookup() {
        ++DuplicatesLookupLineNumber;
        Message( MESSAGE_DEBUG , "llGetFreeMemory(): " + (string)llGetFreeMemory() );

        // If not the last line, get the next line
        if( DuplicatesLookupLineNumber < TotalNotecardLines ) {
            llSetTimerEvent( ASSET_SERVER_TIMEOUT );
            DataServerRequest = llGetNotecardLine( CONFIG_NOTECARD , DuplicatesLookupLineNumber ); // FORCED_DELAY 0.1 seconds
            return TRUE;
        }

        return FALSE;
    }

    // Return: Early exit needed (boolean)
    integer ParseConfigLineItemName( string data ) {
        string inventoryName = FindInventoryByName( data );

        // Item must exist
        if( "" == inventoryName ) {
            Message( MESSAGE_VIA_OWNER , "WARNING: Cannot find item in inventory. Skipping item and not adding to probabilities: " + data );
            return FALSE;
        }

        // Item must be listed after rarity
        if( -1 == RarityBlock ) {
            Message( MESSAGE_ERROR , "Bad config on line " + (string)LineNumber + ": Item listed before any rarity lines. Please put a \"rarity X\" line before this one: " + data );
            RestartConfig();
            return TRUE;
        }

        // Items must be transferable
        if( ! ( PERM_TRANSFER & llGetInventoryPermMask( inventoryName , MASK_OWNER ) ) ) {
            Message( MESSAGE_ERROR , "Bad config on line " + (string)LineNumber + ": Item is not transferrable: " + inventoryName );
            RestartConfig();
            return TRUE;
        }

        TotalRarity += RarityBlock;
        ++ConfiguredInventory;
        Message( MESSAGE_DEBUG , "Configuration line " + (string)LineNumber + " added item with rarity " + (string)RarityBlock + ": " + inventoryName );

        Mode = 5;
        DuplicatesLookupLineNumber = LineNumber;
        DuplicateInventoryComparison = llToLower( llStringTrim( inventoryName , STRING_TRIM ) );
        GetNextDuplicateItemLookup();

        return TRUE;
    }

    // Return: Early exit needed (boolean)
    integer ParseConfigLine( string data ) {
        Message( MESSAGE_DEBUG , "Parsing line " + (string)LineNumber + ": " + data );

        // Internally we'll use lower case for everything and trim
        string configLine = llToLower( llStringTrim( data , STRING_TRIM ) );

        // EOF should not happen, but could happen with an empty notecard in
        // theory
        if( EOF == configLine ) {
            Message( MESSAGE_DEBUG , "Configuration line " + (string)LineNumber + " is EOF, skipped" );
            return FALSE;
        }

        // Skip blank lines
        if( "" == configLine ) {
            Message( MESSAGE_DEBUG , "Configuration line " + (string)LineNumber + " is blank, skipped" );
            return FALSE;
        }

        // Skip comment lines
        if( "#" == llGetSubString( configLine , 0 , 0 ) ) {
            Message( MESSAGE_DEBUG , "Configuration line " + (string)LineNumber + " is a comment, skipped" );
            return FALSE;
        }

        // Handle config verbs
        integer spaceIndex = llSubStringIndex( configLine , " " );
        if( -1 == spaceIndex ) {
            Message( MESSAGE_DEBUG , "Configuration line " + (string)LineNumber + " contains no space, treating as item name: " + data );
            return ParseConfigLineItemName( data );
        }

        string verb = llGetSubString( configLine , 0 , spaceIndex - 1 );
        string value = llStringTrim( llGetSubString( configLine , spaceIndex + 1 , -1 ) , STRING_TRIM );

        // If the verb isn't known, treat it as part of an item name
        if( -1 == llSubStringIndex( "|rarity|price|payout|buy_max_items|buy_button|pay_any_amount|folder_for_one|set_root_prim_click_action|allow_send_stats|allow_show_stats|list_rarity_on_touch|group|email|im|" , "|" + verb + "|" ) ) {
            Message( MESSAGE_DEBUG , "Configuration line " + (string)LineNumber + " verb not recognized, treating as item name: " + verb );
            return ParseConfigLineItemName( data );
        }

        // If the verb may only be used once
        if( -1 != llSubStringIndex( "|price|buy_max_items|pay_any_amount|folder_for_one|set_root_prim_click_action|allow_send_stats|allow_show_stats|list_rarity_on_touch|group|email|im|" , "|" + verb + "|" ) ) {
            if( -1 != llSubStringIndex( VerbsSeen , "|" + verb + "|" ) ) {
                Message( MESSAGE_ERROR , "Bad config on line " + (string)LineNumber + ": \"" + verb + "\" may only be used once" );
                RestartConfig();
                return TRUE;
            }

            Message( MESSAGE_DEBUG , "Configuration line " + (string)LineNumber + ": Adding verb to seen list: " + verb );
            VerbsSeen += verb + "|";
        }

        // Boolean verbs
        if( -1 != llSubStringIndex( "|pay_any_amount|folder_for_one|set_root_prim_click_action|allow_send_stats|allow_show_stats|list_rarity_on_touch|group|" , "|" + verb + "|" ) ) {
            // Parse input
            integer boolean = ParseBooleanConfig( value );

            // If invalid input
            if( -1 == boolean ) {
                Message( MESSAGE_ERROR , "Bad config on line " + (string)LineNumber + ": Setting must be boolean (yes/no): " + data );
                RestartConfig();
                return TRUE;
            }

            // Store values needed for further sanity checks later
            if( "pay_any_amount" == verb ) PayAnyAmount = boolean; // If all buttons turned off AND this is turned off, that's a problem

            // Nothing more to do for a boolean verb
            Message( MESSAGE_DEBUG , "Configuration line " + (string)LineNumber + ": Boolean verb OK: " + data );
            return FALSE;
        }

        // Manually specified price
        if( "price" == verb ) {
            // Parse input
            PriceSet = ParseLindensConfig( value );

            // If the payment is out of bounds
            if( 0 > PriceSet ) {
                Message( MESSAGE_ERROR , "Bad config on line " + (string)LineNumber + ": L$ must be greater than or equal to zero: " + data );
                RestartConfig();
                return TRUE;
            }

            // Nothing more to do for this
            Message( MESSAGE_DEBUG , "Configuration line " + (string)LineNumber + ": Price set to L$" + (string)PriceSet );
            return FALSE;
        }

        // Max number of items at a time
        if( "buy_max_items" == verb ) {
            // Parse and store for later (individual buttons must not exceed this)
            MaxPerPurchase = (integer)value;

            // If the count is out of bounds
            if( 0 >= MaxPerPurchase || MAX_PER_PURCHASE < MaxPerPurchase ) {
                Message( MESSAGE_ERROR , "Bad config on line " + (string)LineNumber + ": Max purchases must be between 1 and MAX_PER_PURCHASE: " + data );
                RestartConfig();
                return TRUE;
            }

            // Nothing more to do for this
            Message( MESSAGE_DEBUG , "Configuration line " + (string)LineNumber + ": Max items bought at a time set to: " + (string)MaxPerPurchase );
            return FALSE;
        }

        // Preset buy buttons
        if( "buy_button" == verb ) {
            spaceIndex = llSubStringIndex( value , " " );
            if( -1 == spaceIndex ) {
                Message( MESSAGE_ERROR , "Bad config on line " + (string)LineNumber + ": Must be in the format \"buy_button LETTER COUNT\": " + data );
                RestartConfig();
                return TRUE;
            }

            string buttonName = llGetSubString( value , 0 , spaceIndex - 1 );
            integer buyButtonValue = (integer)llGetSubString( value , spaceIndex + 1 , -1 );

            if( buyButtonValue < 0 || buyButtonValue > MAX_PER_PURCHASE ) {
                Message( MESSAGE_ERROR , "Bad config on line " + (string)LineNumber + ": Count must be between 0 and MAX_PER_PURCHASE: " + data );
                RestartConfig();
                return TRUE;
            }

            if( "a" == buttonName ) {
                if( -1 != BuyButton0 ) {
                    Message( MESSAGE_ERROR , "Bad config on line " + (string)LineNumber + ": Each buy_button may only be listed once: " + data );
                    RestartConfig();
                    return TRUE;
                }

                BuyButton0 = buyButtonValue;
            } else if( "b" == buttonName ) {
                if( -1 != BuyButton1 ) {
                    Message( MESSAGE_ERROR , "Bad config on line " + (string)LineNumber + ": Each buy_button may only be listed once: " + data );
                    RestartConfig();
                    return TRUE;
                }

                BuyButton1 = buyButtonValue;
            } else if( "c" == buttonName ) {
                if( -1 != BuyButton2 ) {
                    Message( MESSAGE_ERROR , "Bad config on line " + (string)LineNumber + ": Each buy_button may only be listed once: " + data );
                    RestartConfig();
                    return TRUE;
                }

                BuyButton2 = buyButtonValue;
            } else if( "d" == buttonName ) {
                if( -1 != BuyButton3 ) {
                    Message( MESSAGE_ERROR , "Bad config on line " + (string)LineNumber + ": Each buy_button may only be listed once: " + data );
                    RestartConfig();
                    return TRUE;
                }

                BuyButton3 = buyButtonValue;
            } else {
                Message( MESSAGE_ERROR , "Bad config on line " + (string)LineNumber + ": Letter must be one of \"a\", \"b\", \"c\", or \"d\": " + data );
                RestartConfig();
                return TRUE;
            }

            // Nothing more to do for this
            Message( MESSAGE_DEBUG , "Configuration line " + (string)LineNumber + ": Button " + buttonName + " set to " + (string)buyButtonValue );
            return FALSE;
        }

        // Email based purchase reports
        if( "email" == verb ) {
            // Not much we can do with validating email address unfortunately
            EmailReportEnabled = TRUE;

            // Nothing more to do for this
            Message( MESSAGE_VIA_OWNER , "Will send purchase reports to email address: " + value );
            return FALSE;
        }

        // IM based purchase reports
        if( "im" == verb ) {
            ImReportTargetConfig = data;
            ImReportTarget = ParseKeyConfig( value );

            if( NULL_KEY == ImReportTarget ) {
                Message( MESSAGE_ERROR , "Bad config on line " + (string)LineNumber + ": Needs to be an agent key or one of the special values: " + data );
                RestartConfig();
                return TRUE;
            }

            // Switch modes to lookup this agent
            Message( MESSAGE_DEBUG , "Configuration line " + (string)LineNumber + ": Looking up IM Report Target: " + value );
            Mode = 2;
            llSetTimerEvent( ASSET_SERVER_TIMEOUT );
            DataServerRequest = llRequestUsername( ImReportTarget );
            return TRUE;
        }

        // Set rarity for block
        if( "rarity" == verb ) {
            RarityBlock = (float)value;

            if( 0.0 >= RarityBlock ) {
                Message( MESSAGE_ERROR , "Bad config on line " + (string)LineNumber + ": Rarity number needs to be greater than zero: " + data );
                RestartConfig();
                return TRUE;
            }

            // Nothing more to do for this
            Message( MESSAGE_DEBUG , "Configuration line " + (string)LineNumber + ": All following items will have rarity: " + value );
            return FALSE;
        }

        // IM based purchase reports
        if( "payout" == verb ) {
            spaceIndex = llSubStringIndex( value , " " );
            if( -1 == spaceIndex ) {
                Message( MESSAGE_ERROR , "Bad config on line " + (string)LineNumber + ": Must be in the format \"payout MONEY AGENT_KEY\": " + data );
                RestartConfig();
                return TRUE;
            }

            if( -1 == PricePayout ) {
                PricePayout = 0;
            }

            PayoutTargetConfig = data;
            PayoutTargetAmount = ParseLindensConfig( llGetSubString( value , 0 , spaceIndex - 1 ) );
            PayoutTarget = ParseKeyConfig( llGetSubString( value , spaceIndex + 1 , -1 ) );
            PricePayout += PayoutTargetAmount;

            // If the payment is out of bounds
            if( 0 >= PayoutTargetAmount ) {
                Message( MESSAGE_ERROR , "Bad config on line " + (string)LineNumber + ": L$ must be greater than or equal to zero: " + data );
                RestartConfig();
                return TRUE;
            }

            // If the key is invalid
            if( NULL_KEY == PayoutTarget ) {
                Message( MESSAGE_ERROR , "Bad config on line " + (string)LineNumber + ": Needs to be an agent key or one of the special values: " + data );
                RestartConfig();
                return TRUE;
            }

            // Switch modes to lookup this agent
            Message( MESSAGE_DEBUG , "Configuration line " + (string)LineNumber + ": Looking up Payout Target: " + PayoutTarget );
            Mode = 3;
            llSetTimerEvent( ASSET_SERVER_TIMEOUT );
            DataServerRequest = llRequestUsername( PayoutTarget );
            return TRUE;
        }

        // Catch-all for verbs not handled above
        Message( MESSAGE_ERROR , "Bad config on line " + (string)LineNumber + ": The programmer appears to have made a mistake, as this line wasn't handled: " + data );
        RestartConfig();
        return TRUE;
    }

    // Return: Duplicate found
    DetectDuplicatePayoutTarget( string data ) {
        Message( MESSAGE_DEBUG , "Parsing line " + (string)DuplicatesLookupLineNumber + ": " + data );

        // Internally we'll use lower case for everything and trim
        string configLine = llToLower( llStringTrim( data , STRING_TRIM ) );

        // Handle config verbs
        integer spaceIndex = llSubStringIndex( configLine , " " );
        if( -1 == spaceIndex ) {
            Message( MESSAGE_DEBUG , "Configuration line " + (string)DuplicatesLookupLineNumber + " contains no space, skipping: " + data );
            return;
        }

        string verb = llGetSubString( configLine , 0 , spaceIndex - 1 );
        string value = llStringTrim( llGetSubString( configLine , spaceIndex + 1 , -1 ) , STRING_TRIM );

        if( "payout" != verb ) {
            Message( MESSAGE_DEBUG , "Configuration line " + (string)DuplicatesLookupLineNumber + " is not a payout, skipping: " + data );
            return;
        }

        spaceIndex = llSubStringIndex( value , " " );
        if( -1 == spaceIndex ) {
            Message( MESSAGE_ERROR , "Bad config on line " + (string)DuplicatesLookupLineNumber + ": Must be in the format \"payout MONEY AGENT_KEY\": " + data );
            RestartConfig();
            return;
        }

        integer secondAmount = ParseLindensConfig( llGetSubString( value , 0 , spaceIndex - 1 ) );
        key secondTarget = ParseKeyConfig( llGetSubString( value , spaceIndex + 1 , -1 ) );

        if( secondTarget != PayoutTarget ) {
            Message( MESSAGE_DEBUG , "Configuration line " + (string)DuplicatesLookupLineNumber + " goes to a different target, skipping: " + data );
            return;
        }

        ++PayoutTargetLineCount;
        PayoutTargetAmount += secondAmount;
        return;
    }

#end globalfunctions

#start states

    default {

        state_entry() {
            llSetTimerEvent( 1.0 );
            llSetScriptState( llGetScriptName() , FALSE );
        }

        changed( integer changeMask ) {
            if( ( CHANGED_INVENTORY | CHANGED_LINK ) & changeMask ) {
                RestartConfig();
                return;
            }
        }

        timer() {
            #include lib/message-configs.lsl
            Message( MESSAGE_DEBUG , "llGetFreeMemory(): " + (string)llGetFreeMemory() );
            state scan;
        }

    }

    state scan {
        state_entry() {
            Mode = 0;
            Message( MESSAGE_VIA_HOVER , "Initializing, please wait...\nStep 1" );
            llSetTimerEvent( ASSET_SERVER_TIMEOUT );
            DataServerRequest = llGetNumberOfNotecardLines( CONFIG_NOTECARD ); // FORCED_DELAY 0.1 seconds
        }

        changed( integer changeMask ) {
            if( ( CHANGED_INVENTORY | CHANGED_LINK ) & changeMask ) {
                RestartConfig();
                return;
            }
        }

        timer() {
            if( 0 == Mode ) {
                Message( MESSAGE_ERROR , "Timed out while trying to look up number of lines in notecard. The data server may be having problems." );
                RestartConfig();
                return;
            }

            if( 1 == Mode ) {
                Message( MESSAGE_ERROR , "Timed out while trying to get line " +(string)LineNumber + " of " + CONFIG_NOTECARD + ". The data server may be having problems." );
                RestartConfig();
                return;
            }

            if( 2 == Mode ) {
                Message( MESSAGE_ERROR , "Timed out while trying to lookup IM report user from configuration line " + (string)LineNumber + ". Either this user doesn't exist or the data server may be having problems. Configuration line " + (string)LineNumber + ": " + ImReportTargetConfig );
                RestartConfig();
                return;
            }

            if( 3 == Mode ) {
                Message( MESSAGE_ERROR , "Timed out while trying to lookup payout user from configuration line " + (string)LineNumber + ". Either this user doesn't exist or the data server may be having problems. Configuration line " + (string)LineNumber + ": " + ImReportTargetConfig );
                RestartConfig();
                return;
            }

            Message( MESSAGE_ERROR , "Unexpected timeout. Slap the programmer." );
            RestartConfig();
            return;
        }

        dataserver( key queryId , string data ) {
            if( queryId != DataServerRequest )
                return;

            Message( MESSAGE_DEBUG , "dataserver returned data: " + data );

            // Response received in time, reset timer
            llSetTimerEvent( 0.0 );

            // Got number of lines
            if( 0 == Mode ) {
                TotalNotecardLines = (integer)data;

                Mode = 1;
                LineNumber = 0;
                PriceSet = -1;
                PricePayout = -1;
                CountPayouts = 0;
                RarityBlock = -1.0;
                VerbsSeen = "|";
                PayAnyAmount = DEFAULT_PAY_ANY_AMOUNT;
                MaxPerPurchase = MAX_PER_PURCHASE;
                BuyButton0 = -1;
                BuyButton1 = -1;
                BuyButton2 = -1;
                BuyButton3 = -1;
                EmailReportEnabled = FALSE;
                ImReportTargetConfig = "";
                ImReportTarget = NULL_KEY;
                PayoutTargetConfig = "";
                PayoutTarget = NULL_KEY;
                TotalRarity = 0.0;
                ConfiguredInventory = 0;

                Message( MESSAGE_VIA_HOVER , "Initializing, please wait...\nStep 2: 0%" );

                llSetTimerEvent( ASSET_SERVER_TIMEOUT );
                DataServerRequest = llGetNotecardLine( CONFIG_NOTECARD , LineNumber ); // FORCED_DELAY 0.1 seconds
                return;
            }

            // Got IM report target username
            if( 2 == Mode ) {
                Message( MESSAGE_VIA_OWNER , "Will send a notification of each purchase to " + data );

                Mode = 1;
                data = ""; // Empty the line so that Mode1 doesn't parse it
                // Note: Not returning here, so will fall through
            }

            // Got payout target username
            if( 3 == Mode ) {
                PayoutTargetName = data;
                PayoutTargetLineCount = 1;

                Message( MESSAGE_DEBUG , "Starting lookup for duplicate payout targets. PayoutTargetName: " + data );

                Mode = 4;
                DuplicatesLookupLineNumber = LineNumber;
                data = ""; // Empty the line so that Mode4 doesn't parse it
                // Note: Not returning here, so will fall through
            }

            if( 4 == Mode ) {
                DetectDuplicatePayoutTarget( data );

                if( GetNextDuplicateItemLookup() )
                    return;

                // Otherwise we're at the last line and should do followup checks

                if( 1 != PayoutTargetLineCount ) {
                    Message( MESSAGE_ERROR , "Multiple payouts found to the same person. " + PayoutTargetName + " would receive a total of L$" + (string)PayoutTargetAmount + ". Please put only one payout line per person." );
                    RestartConfig();
                    return;
                }

                Message( MESSAGE_VIA_OWNER , "Will give L$" + (string)PayoutTargetAmount + " to " + PayoutTargetName + " for each item purchased." );

                Mode = 1;
                data = ""; // Empty the line so that Mode1 doesn't parse it
                // Note: Not returning here, so will fall through
            }

            if( 5 == Mode ) {
                if( llToLower( llStringTrim( data , STRING_TRIM ) ) == DuplicateInventoryComparison ) {
                    Message( MESSAGE_ERROR , "This item was listed multiple times: " + data );
                    RestartConfig();
                    return;
                }

                if( GetNextDuplicateItemLookup() )
                    return;

                Mode = 1;
                data = ""; // Empty the line so that Mode1 doesn't parse it
                // Note: Not returning here, so will fall through
            }

            // Got a config line
            if( 1 == Mode ) {
                if( ParseConfigLine( data ) )
                    return;

                ++LineNumber;
                Message( MESSAGE_VIA_HOVER , "Initializing, please wait...\nStep 2: " + (string)( LineNumber * 100 / TotalNotecardLines ) + "%" );
                Message( MESSAGE_DEBUG , "llGetFreeMemory(): " + (string)llGetFreeMemory() );

                // If not the last line, get the next line
                if( LineNumber < TotalNotecardLines ) {
                    llSetTimerEvent( ASSET_SERVER_TIMEOUT );
                    DataServerRequest = llGetNotecardLine( CONFIG_NOTECARD , LineNumber ); // FORCED_DELAY 0.1 seconds
                    return;
                }
                // Otherwise we're at the last line and should do followup checks

                // If they didn't manually set the price or any payouts
                if( -1 == PriceSet && -1 == PricePayout ) {
                    Message( MESSAGE_ERROR , "No price was set. Please either use \"price\" or \"payout\" in the config." );
                    RestartConfig();
                    return;
                }

                // Check if they goofed their math
                if( -1 != PriceSet && -1 != PricePayout && PriceSet != PricePayout ) {
                    Message( MESSAGE_ERROR , "You used both \"price\" and \"payout\", but the sum of all \"payout\" lines L$" + (string)PricePayout + " doesn't equal the \"price\" L$" + (string)PriceSet + "! Which one is right?" );
                    RestartConfig();
                    return;
                }

                // Must have PayAnyAmount or at least one PayButton enabled
                if( !PayAnyAmount && 0 >= BuyButton0 && 0 >= BuyButton1 && 0 >= BuyButton2 && 0 >= BuyButton3 ) {
                    Message( MESSAGE_ERROR , "You used both \"price\" and \"payout\", but the sum of all \"payout\" lines L$" + (string)PricePayout + " doesn't equal the \"price\" L$" + (string)PriceSet + "! Which one is right?" );
                    RestartConfig();
                    return;
                }

                // TODO: Post scan checks
                    // TODO: If email report selected, use more heavily restricted max items
                    // TODO: Button counts vs max items
                    // TODO: Warn about slow operation if too many notecard lines
                    // TODO: Warn about slow operation if too many objects
                    // TODO: Warn about slow operation if email report
            }
        }
    }

#end states
