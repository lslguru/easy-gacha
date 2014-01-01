#include lib/CONSTANTS.lsl
#include lib/Message.lsl
#include lib/ConvertBooleanSetting.lsl
#include lib/FindConfig_1Part_ByVerb_Value.lsl

#start globalfunctions

MessageConfig() {
    // Check up front for opposite of default values
    MessageVerbose = ( TRUE == ConvertBooleanSetting( FindConfig_1Part_ByVerb_Value( 0 , "eg_verbose" ) ) );
    MessageHoverText = !( FALSE == ConvertBooleanSetting( FindConfig_1Part_ByVerb_Value( 0 , "eg_hover_text" ) ) );
}

#end globalfunctions
