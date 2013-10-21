# Immediate work to do #

## Split script up into separate scripts ##

    * Easy Gacha (REQUIRED)
        * eg_folder_for_one
        * eg_price
        * eg_rarity
        * eg_hover_text
        * eg_buy_max_items

    * Easy Gacha Config Checker (OPTIONAL)
        * eg_verbose
        * eg_hover_text

    * Easy Gacha Purchase Buttons (OPTIONAL)
        * eg_set_root_prim_click
        * eg_pay_any_amount
        * eg_buy_max_items
        * eg_buy_buttons

    * Easy Gacha Stats (OPTIONAL)
        * eg_allow_send_stats
        * eg_allow_show_stats

    * Easy Gacha Payouts (OPTIONAL)
        * eg_payout

    * Easy Gacha List Contents On Touch (OPTIONAL)
        * eg_list_on_touch

    llMessageLinked(...); llSleep( 0.05 ); // Strictly limit rate to prevent queue overflow

## Flow ##

    * Easy Gacha: Get debit permission
    * Easy Gacha: Check for Config Checker, if not found, error and wait for it
    * Easy Gacha: Wake up Config Checker
    * Easy Gacha: Listen for config valid signal
    * Config Checker: Validate all config options
    * Config Checker: If invalid, wait for changes, revalidate
    * Config Checker: Signal valid
    * Config Checker: Go to sleep
    * Easy Gacha: on valid config continue
    * Easy Gacha: Wake up Purchase Buttons (if present)
        * Purchase Buttons: Read config and apply settings
        * Purchase Buttons: Go to sleep
    * Easy Gacha: Wake up Stats (if present)
        * Stats: Scan config
        * Stats: report to server
        * Stats: Go to sleep
    * Easy Gacha: Enter ready state, wait for payments/touch
        * On touch
            * If Price == 0
                * Signal Handout
            * Signal touched
        * On pay
            * Signal Handout
        * On sending signal handout
            * First hand out inventory
            * Wake up stats if present
                * Sends data to server
            * Wake up payouts if present
                * Disburses funds
        * On sending signal touched
            * Wake up stats if present
                * Gives out link
            * Wake up touch list if present
                * List rarities

# New Features #

* Option to expire inventory item after X copies given
* Option to restrict to group-only (in which case object group must match agent group)
* Option to email or IM sales as they happen
