#define OWNER llGetOwner()
#define CREATOR llGetCreator()
#define SCRIPT_NAME llGetScriptName()
#define SCRIPTOR llGetInventoryCreator( SCRIPT_NAME )
#define OBJECT_KEY llGetKey()
#define PRIM_NUMBER llGetLinkNumber()
#define PRIM_KEY llGetLinkKey( PRIM_NUMBER )

#start globalfunctions

    key ToKey( string value ) {
        value = llToLower( llStringTrim( value , STRING_TRIM ) ); // Be nice and allow upper case letters

        if( "owner"    == value ) { return OWNER;       } // special shorthand
        if( "creator"  == value ) { return CREATOR;     } // special shorthand
        if( "scriptor" == value ) { return SCRIPTOR;    } // special shorthand
        if( "object"   == value ) { return OBJECT_KEY;  } // special shorthand
        if( "prim"     == value ) { return PRIM_KEY;    } // special shorthand

        if( (key)value          ) { return (key)value;  } // valid key
        else                      { return NULL_KEY;    } // invalid key
    }

#end globalfunctions
