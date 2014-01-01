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
#define CONFIG_NOTECARD "Easy Gacha Config"
#define CONFIG_INVENTORY_KEY "517a121a-e248-ea49-b901-5dbefa4b2285"

// System default
#define MAX_FOLDER_NAME_LENGTH 63

// Tweaks
#define INVENTORY_SETTLE_TIME 5.0

////////////////////////////////////////////////////////////////////////////////
// Inventory
////////////////////////////////////////////////////////////////////////////////

// Script names (note: you must provide your own quote marks)
#define SCRIPT_BOOT "easy-gacha-0"
#define SCRIPT_VALIDATE_CONFIG "TODO"
#define SCRIPT_VALIDATE_INVENTORY "TODO"

// Config inventory names
#define CONFIG_DISABLE_WHISPER "whisper_disabled"
#define CONFIG_DISABLE_HOVERTEXT "hovertext_disabled"
#define CONFIG_ENABLE_VERBOSE "verbose_enabled"
#define CONFIG_ENABLE_DEBUG "debug_enabled"

