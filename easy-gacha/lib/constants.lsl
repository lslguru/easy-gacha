#define SCRIPT_NAME ScriptName
#define OWNER Owner

#define CONFIG_INVENTORY_ID "517a121a-e248-ea49-b901-5dbefa4b2285"
#define VERSION 3.3
#define DEFAULT_STATS_ALLOWED FALSE
#define SOURCE_CODE_MESSAGE "This is free open source software. The source can be found at: https:\/\/github.com/zannalov/opensl"
#define SERVER_URL_CONFIG ""
#define SERVER_URL_PURCHASE ""
#define SERVER_URL_STATS ""
#define HTTP_OPTIONS [ HTTP_METHOD , "POST" , HTTP_MIMETYPE , "text/json;charset=utf-8" , HTTP_BODY_MAXLENGTH , 16384 , HTTP_VERIFY_CERT , FALSE , HTTP_VERBOSE_THROTTLE , FALSE ]

// We use about 8000 bytes during handout stage, so be conservative and reserve 50% more than that
#define LOW_MEMORY_THRESHOLD_SETUP 1
// Above minus expected 8000 and a little padding
#define LOW_MEMORY_THRESHOLD_RUNNING 1
#define MAX_FOLDER_NAME_LENGTH 63
#define MAX_PER_PURCHASE 100
// Set based on wanting 0.5 seconds on average per item randomly selected
#define MANY_ITEMS_WARNING 25

// StatusMask
#define STATUS_MASK_CHECK_BASE_ASSUMPTIONS 1
#define STATUS_MASK_INVENTORY_CHANGED 2
#define STATUS_MASK_HANDOUT_NEEDED 4

// InventoryIterator modes
// [ 7 , verb , id , index ] == Get Nth item matching verb and id (returns [value] from "verb value id")
// [ 8 , multiplier ] == Send money to payouts
// [ 9 , verb , index , split ] == Get Nth item matching verb with two-part configuration (returns [ part1 , part2 ] or [ EOF , EOF ])
#define INVENTORY_ITERATOR_REPORT_PERCENTAGES_TO_OWNER 0
#define INVENTORY_ITERATOR_REPORT_PERCENTAGES_VIA_WHISPER 1
#define INVENTORY_ITERATOR_STARTUP_CONFIGS 2
#define INVENTORY_ITERATOR_SCAN_CONFIGS 3
#define INVENTORY_ITERATOR_SCAN_INVENTORY 4
#define INVENTORY_ITERATOR_SEND_CONFIG 5
#define INVENTORY_ITERATOR_FIND_RANDOM_ITEM 6
#define INVENTORY_ITERATOR_FIND_NTH_VERB_ID 7
#define INVENTORY_ITERATOR_PROCESS_PAYOUTS 8
#define INVENTORY_ITERATOR_FIND_NTH_TWO_PART_VERB 9
