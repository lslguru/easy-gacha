// This is the version I'm working on now
#define VERSION 3.3

// Specific to scriptor
#define DEFAULT_STATS_ALLOWED FALSE
#define SOURCE_CODE_MESSAGE "This is free open source software. The source can be found at: https:\/\/github.com/zannalov/opensl"
#define SERVER_URL_CONFIG ""
#define SERVER_URL_PURCHASE ""
#define SERVER_URL_STATS ""
#define HTTP_OPTIONS [ HTTP_METHOD , "POST" , HTTP_MIMETYPE , "text/json;charset=utf-8" , HTTP_BODY_MAXLENGTH , 16384 , HTTP_VERIFY_CERT , FALSE , HTTP_VERBOSE_THROTTLE , FALSE ]

// System default
#define MAX_FOLDER_NAME_LENGTH 63

// StatusMask
#define STATUS_MASK_CHECK_BASE_ASSUMPTIONS 1
#define STATUS_MASK_INVENTORY_CHANGED 2
#define STATUS_MASK_HANDOUT_NEEDED 4

// Script names (note: you must provide your own quote marks)
#define SCRIPT_BOOT Easy Gacha Boot
#define SCRIPT_

#define SCRIPT_CORE Easy Gacha Core
#define SCRIPT_VALIDATOR Easy Gacha Validator
#define SCRIPT_VALIDATE_CONFIG_FORMATS Easy Gacha Validate Config Formats
#define SCRIPT_PURCHASE_BUTTONS Easy Gacha Buttons
#define SCRIPT_STATS_ENGINE Easy Gacha Stats
#define SCRIPT_PAYOUTS Easy Gacha Payouts
#define SCRIPT_INFO Easy Gacha Info

// Signals
#define SIGNAL_CORE_TO_VALIDATOR_START 3000166
#define SIGNAL_VALIDATOR_TO_CORE_FINISHED 3000167
#define SIGNAL_VALIDATOR_TO_SUB_SCRIPT_START 3000168
#define SIGNAL_SUB_SCRIPT_TO_VALIDATOR_FINISHED 3000169
