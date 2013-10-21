# Immediate work to do #

* Split script up into separate scripts
    * Easy Gacha (REQUIRED)
        * eg_folder_for_one
        * eg_price
        * eg_rarity
        * eg_hover_text
    * Easy Gacha Config Checker (REQUIRED)
        * eg_verbose
        * eg_hover_text
    * Easy Gacha Purchase Buttons (REQUIRED)
        * eg_set_root_prim_click
        * eg_pay_any_amount
        * eg_buy_max_items
        * eg_buy_buttons
    * Easy Gacha Stats (OPTIONAL)
        * eg_allow_send_stats
        * eg_allow_show_stats
    * Easy Gacha Payouts (OPTIONAL)
        * eg_payout
    * Easy Gacha Touch List (OPTIONAL)
        * eg_list_on_touch

    llMessageLinked(...); llSleep( 0.05 ); // Strictly limit rate to prevent queue overflow

# New Features #

* Option to expire inventory item after X copies given
* Option to restrict to group-only (in which case object group must match agent group)
* Option to email or IM sales as they happen
* Option to enable API events
