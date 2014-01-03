# Work In Progress #

* Process everything from "old" directory, removing as I go

Setup Steps
0. easy-gacha-0 (no number shown)
1. easy-gacha-1 Fetching number of lines from notecard
2. easy-gacha-2 Fetching lines from notecard

* Preserve original strings
* Case-insensitive
* Leading/trailing white-space insensitive

* Blank lines
* Comment lines
* If line doesn't begin with known verb followed by space, it's an item name
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

    llSetPayPrice( PAY_DEFAULT , [ PAY_DEFAULT , PAY_DEFAULT , PAY_DEFAULT , PAY_DEFAULT ] );
    llSetTouchText( "" );

* Documentation
* Release
* Contact those who have already purchased

# Future Features #

* Ability to limit number of each item handed out
