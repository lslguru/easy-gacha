# Rarity #

    rarity RARITY
    ITEM

Every item listed after the "rarity X" configuration gets the same rarity value.

ITEM is case insensitive and whitespace-trimmed.

RARITY must be an integer or float and greater than or equal to zero.

# Money #

    price MONEY
    payout MONEY AGENT_KEY
    buy_max_items COUNT
    buy_button LETTER COUNT
    pay_any_amount BOOLEAN

MONEY may be represented in any of the following formats: "L$123" "$123" "123" "123L"

AGENT\_KEY must be a UUID

COUNT must be an integer and greater than or equal to zero.

LETTER is the English-alphabet letter indicating the buttons in order, meaning
the first button is "A", the second is "B", etc.

The price must equal the sum of all payout lines. If no payout lines are
specified, a single payout line to the owner is implied. Either price or payout
must be used. The price may be zero.

# Handouts #

    folder_for_one BOOLEAN

Whether or not to use a folder when someone only bought one item.

# Object Confguration #

    set_root_prim_click_action BOOLEAN

If the script is in the root prim of a linked set and changes the default click
action, the change will be applied to ALL prims. This is not true for non-root
prims, and is not applicable to unlinked prims.

# Stats #

    allow_send_stats BOOLEAN
    allow_show_stats BOOLEAN
    list_rarity_on_touch BOOLEAN

Pretty straight forward options here.

# Communication #

    whisper BOOLEAN
    hovertext BOOLEAN
    verbose BOOLEAN
    debug BOOLEAN

One of "whisper" or "hovertext" must be true.

# Access Permissions #

    group BOOLEAN

# Reporting #

    email EMAIL_ADDRESS
    im AGENT_KEY

If provided, sends a report of each purchase/play
