# Work In Progress #

* On touch, llLoadURL
* Process everything from "old" directory, removing as I go
* List final rarity of each item
* If no-copy item is to be handed out
    * Max per purchase = 1
    * Folders turned off
    * No stats
* Check that we have at least one thing to hand out
* Check price == total payouts
* Check buy button configs

    llSetPayPrice( PAY_DEFAULT , [ PAY_DEFAULT , PAY_DEFAULT , PAY_DEFAULT , PAY_DEFAULT ] );
    llSetTouchText( "" );

* Documentation
* Release
* Contact those who have already purchased

# Config Notecard Format #

    inv RARITY LIMIT BOUGHT ITEM
    payout AGENT MONEY
    max_per_purchase COUNT
    pay_price COUNT
    pay_price_buttons COUNT COUNT COUNT COUNT
    folder_for_single_item BOOLEAN
    root_click_action BOOLEAN
    stats BOOLEAN
    group BOOLEAN
    email EMAIL
    im AGENT
    whisper BOOLEAN
    hovertext BOOLEAN

# Future Features #

* Ability to limit number of each item handed out
