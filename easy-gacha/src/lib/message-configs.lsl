MessageHoverText = MessageChat = TRUE;
MessageVerbose = MessageDebug = FALSE;
if( INVENTORY_NONE != llGetInventoryType( CONFIG_DISABLE_WHISPER ) ) { MessageWhisper = FALSE; }
if( INVENTORY_NONE != llGetInventoryType( CONFIG_DISABLE_HOVERTEXT ) ) { MessageHover = FALSE; }
if( INVENTORY_NONE != llGetInventoryType( CONFIG_ENABLE_VERBOSE ) ) { MessageVerbose = TRUE; }
if( INVENTORY_NONE != llGetInventoryType( CONFIG_ENABLE_DEBUG ) ) { MessageDebug = TRUE; }
