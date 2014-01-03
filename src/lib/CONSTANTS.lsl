////////////////////////////////////////////////////////////////////////////////
// Application
////////////////////////////////////////////////////////////////////////////////

// This is the version I'm working on now
#define VERSION 4.0

// Specific to scriptor
#define DEFAULT_STATS_ALLOWED FALSE
#define SOURCE_CODE_MESSAGE "This is free open source software. The source can be found at: https:\/\/github.com/zannalov/opensl"
#define SERVER_URL_CONFIG ""
#define SERVER_URL_PURCHASE ""
#define SERVER_URL_STATS ""
#define HTTP_OPTIONS [ HTTP_METHOD , "POST" , HTTP_MIMETYPE , "text/json;charset=utf-8" , HTTP_BODY_MAXLENGTH , 16384 , HTTP_VERIFY_CERT , FALSE , HTTP_VERBOSE_THROTTLE , FALSE ]
#define CONFIG_INVENTORY_KEY "517a121a-e248-ea49-b901-5dbefa4b2285"

// System default
#define MAX_INVENTORY_NAME_LENGTH 63
#define MAX_FOLDER_NAME_LENGTH 63

// Tweaks
#define INVENTORY_SETTLE_TIME 5.0

// Config defaults
#define DEFAULT_PAY_ANY_AMOUNT TRUE
#define DEFAULT_BUY_BUTTON_0 1
#define DEFAULT_BUY_BUTTON_1 3
#define DEFAULT_BUY_BUTTON_2 5
#define DEFAULT_BUY_BUTTON_3 10

// We have to build a list in memory of the items to be given in a folder. To
// prevent out of memory errors and exceedlingly long-running scripts (e.g.
// price is L$1 and gave it L$10,000), a max is enforced
#define MAX_PER_PURCHASE 100

// When reporting via email, the max email body is effectively 3600 bytes. At
// MAX_INVENTORY_NAME_LENGTH times number of purchases with at least two
// characters of separation and including the name of the purchaser...
#define MAX_PER_PURCHASE_WITH_EMAIL 50

// When the config notecard is longer than this many items, things are likely
// to be noticably slow because of the time it takes to scan the notecard.
// Based on the assumption of 0.2 seconds per line in the notecard and an
// acceptable delay of five seconds.
#define WARN_LONG_NOTECARD 25

////////////////////////////////////////////////////////////////////////////////
// Inventory
////////////////////////////////////////////////////////////////////////////////

// Config notecard
#define CONFIG_NOTECARD "Easy Gacha Config"

// Script names (note: you must provide your own quote marks)
#define SCRIPT_BOOT "easy-gacha-0"
#define SCRIPT_VALIDATE_CONFIG "easy-gacha-1"
#define SCRIPT_VALIDATE_INVENTORY "easy-gacha-2"

// Config inventory names
#define CONFIG_DISABLE_WHISPER "whisper_disabled"
#define CONFIG_DISABLE_HOVERTEXT "hovertext_disabled"
#define CONFIG_ENABLE_VERBOSE "verbose_enabled"
#define CONFIG_ENABLE_DEBUG "debug_enabled"

