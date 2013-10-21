#define CONVERT_BOOLEAN_SETTING_FALSE "|no|off|false|0|iie|nay|nope|-|"
#define CONVERT_BOOLEAN_SETTING_TRUE "|yes|on|true|1|hai|yea|yep|+|"
#define CONVERT_BOOLEAN_SETTING_DELIMITER "|"

#startglobalfunctions

    integer ConvertBooleanSetting( string config ) {
        config = llToLower( config );

        if( -1 != llSubStringIndex( CONVERT_BOOLEAN_SETTING_FALSE , CONVERT_BOOLEAN_SETTING_DELIMITER + config + CONVERT_BOOLEAN_SETTING_DELIMITER ) ) {
            return FALSE;
        }
        if( -1 != llSubStringIndex( CONVERT_BOOLEAN_SETTING_TRUE , CONVERT_BOOLEAN_SETTING_DELIMITER + config + CONVERT_BOOLEAN_SETTING_DELIMITER ) ) {
            return TRUE;
        }

        // Invalid value
        return -1;
    }

#endglobalfunctions
