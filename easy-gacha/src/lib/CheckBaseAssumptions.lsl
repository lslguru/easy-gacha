#define SCRIPT_NAME ScriptName
#define OWNER Owner

#start globalvariables

    // Basic object properties - Override included-file settings for these because
    // this script takes care of these
    string ScriptName = ""; // Cached because this shouldn't change
    key Owner = NULL_KEY; // Cached because this shouldn't change

#end globalvariables

#start globalfunctions

    // attach: Could be rezzed from inventory of different user
    // on_rez: Could be rezzed by new owner
    // changed: Change in owner, change in inventory (script name)
    // run_time_permissions: Permissions revoked or denied
    //
    // attach( key avatarId ){ CheckBaseAssumptions(); }
    // on_rez( integer rezParam ) { CheckBaseAssumptions(); }
    // changed( integer changeMask ) { CheckBaseAssumptions(); }
    // run_time_permissions( integer permissionMask ) { CheckBaseAssumptions(); }
    //
    CheckBaseAssumptions() {
        // On first run, expect we won't have permission
        if( NULL_KEY == Owner ) {
            Owner = llGetOwner();
            ScriptName = llGetScriptName();
            return;
        }

        if(
            llGetOwner() != Owner
            || llGetScriptName() != ScriptName
            || llGetPermissionsKey() != Owner
            || ! ( llGetPermissions() & PERMISSION_DEBIT )
        ) {
            llResetScript();
        }
    }

#end globalfunctions
