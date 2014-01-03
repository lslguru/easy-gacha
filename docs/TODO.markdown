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

# Config Parameters #

    rarity RARITY
    item ITEM
    price MONEY
    payout MONEY AGENT_KEY
    buy_max_items COUNT
    buy_button LETTER COUNT
    pay_any_amount BOOLEAN
    folder_for_one BOOLEAN
    set_root_prim_click_action BOOLEAN
    allow_send_stats BOOLEAN
    allow_show_stats BOOLEAN
    list_rarity_on_touch BOOLEAN
    group BOOLEAN
    email EMAIL_ADDRESS
    im AGENT_KEY
    whisper BOOLEAN
    hovertext BOOLEAN

# Future Features #

* Ability to limit number of each item handed out
