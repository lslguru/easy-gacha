# Immediate work to do #

## easy-gacha-boot

* Set timer to 1 second
* On inventory change, reset timer
* On timer check that all required parts are present (scripts, notecard)
* If anything is missing, report it
* If everything is present
    * Reset (just in case) all except first setup script and memory script
    * Un-pause first setup script
    * Pause self

## easy-gacha setup steps

    llSetPayPrice( PAY_DEFAULT , [ PAY_DEFAULT , PAY_DEFAULT , PAY_DEFAULT , PAY_DEFAULT ] );
    llSetTouchText( "" );

* Special checks for "verbose" and "hover\_text" configs
* Check basic config format
    * Blank lines
    * Comment lines
    * Line has at least one space
    * Known verbs
    * Single-use verbs
    * Boolean verbs
    * Linden verbs
    * Buy buttons
    * Rarity/Limit/Payout lines
    * Check for "duplicate" items (differing only in leading/trailing whitespace or case)
    * Scan inventory items
        * Zero or One rarity entries per item
        * Zero or One limit entries per item
    * List final rarity of each item
    * Scan payout configs
        * Zero or One payout entries per target
    * If no-copy item is to be handed out
        * Max per purchase = 1
        * Folders turned off
        * No stats
    * Check that we have at least one thing to hand out
    * Check price == total payouts
    * Check buy button configs
    * Test run-time for selecting an item, assuming last item would be selected
        * If run-time * button-count > threshold, disable button
        * If run-time > threshold, warn of too many items
    * At least one of Whisper or Hover-text must be turned on

## Miscellaneous

* Write detailed documentation
* Cleanup and organize
* Release
* Contact those who have already purchased
