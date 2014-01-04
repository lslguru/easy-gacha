# Easy Gacha #

This is a very easy, configurable implementation of a
[Gashapon](http://en.wikipedia.org/wiki/Gashapon)-style device.

--------------------------------------------------------------------------------

# Getting Started #

Drop all of the scripts in an object!

You'll see the following things happen:

TODO

--------------------------------------------------------------------------------

# Features #

* Most configuration done automatically
* Incredibly easy to configure
* Detects and prevents most mistakes
* Can set rarity per item
* Supports 30+ items at a time
* Can limit sales per item
* Can limit total number of sales
* Can payout to multiple people with each sale
* Only asks for debit permission once if possible
* Ultra low lag (zero when not in use)
* All data except Gacha registry stored in-world
* Configuration can be exported and loaded via notecard
* Multiple-play option (can buy multiple objects at once)
* Automatic self memory management
* Guaranteed to hand out inventory and refund change correctly
* Can be restricted to group-only play
* Gives statistics about actual sales versus configured rarity
* Can handle no-copy items

--------------------------------------------------------------------------------

# Frequently Asked Questions #

## What happens if someone pays too much? ##

Easy Gacha will give them change.

## What happens if someone pays too little? ##

Easy Gacha will refund the whole amount given and remind them of the price.

## Why aren't the permissions more open? ##

Because otherwise I cannot vouch for its safety. If I made the script
modifiable, someone with ill intent could make it steal money, then give it
away. It would still list me as the creator, but would be malicious.

The script you have should have been created by:
[Zan Lightfoot](secondlife:///app/agent/d393638e-be6e-4f81-a44d-072e344828c4/about)

Also, if I made the objects modifiable and transferable, someone could put
something malicious inside them and they'd still list me as the creator.
Because the kit is free and the source code is open, there should be no problem
with each person that wants one ordering a free copy from the marketplace.

If you want your notecards and your gacha-box to be transferable, simply create
your own objects and notecards (copy the contents from mine) and set the
permissions how you please. The script is transferable because it is no-mod.

## Where do I go for help? ##

You may contact me and I will probably help out, but I cannot guarantee a quick
(or any) response. This was a labor of love. There is no official support, and
Second Life comes... second.  Please read the license.

--------------------------------------------------------------------------------

# Folders #

The script can give people a folder which is the name of the Easy Gacha object
followed by the date.

For example, if you name the object "My Stuff", then someone might receive a
folder that says:

    My Stuff (Easy Gacha: 3 items 2013-10-06)

--------------------------------------------------------------------------------

# Caveats / Assumptions #

## Configuration ##

If the script is deleted or reset, any configurations not exported and saved to
a notecard will be lost.

## URL Resource Limitations ##

The script requires one available URL on the parcel/sim.  See the [LSL HTTP
server](http://wiki.secondlife.com/wiki/LSL_http_server) for more details.
Specifically, if it cannot obtain a URL, then it cannot be configured. As long
as the ownership and inventory haven't changed, it can be stored and re-rezzed,
but the URL is required for initial configuration. This can be resolved by
finding the script(s) which are eating up more than their fair share of URLs
and giving their creators a good slap in the face.

## Agent Identification ##

User/agent identification MUST be provided as UUID because SL has yet to
implement a way of looking up a UUID from a user-name or legacy-name reliably.
It might be possible to reverse engineer the key via site-scraping, but that's
not sustainable/maintainable and plain not worth it. We want llRequestAgentKey!

--------------------------------------------------------------------------------

# Safety Warning #

If the script you have wasn't created by
[Zan Lightfoot](secondlife:///app/agent/d393638e-be6e-4f81-a44d-072e344828c4/about),
then I cannot vouch for its safety. Whoever created it may have altered it. You
have been warned.

--------------------------------------------------------------------------------

# Protocol #

## Overview ##

Use the [LSL HTTP server](http://wiki.secondlife.com/wiki/LSL_http_server) to
simplify configuration and control by putting advanced controls on the hosted
pages of GitHub, then making browser-to-object calls. This prevents needing any
parsing engine within the script, and greatly simplifies the "server-client"
type interactions within the script. It means the only third party server
needed is the host for the admin/stats interface. It also greatly reduces the
memory impact of the script, freeing up space for further configuration.

## CORS ##

Cross-Origin Resource Sharing has a number of security implications within
browsers, and not all browsers handle it the same way. Thus the following rules
have been adopted:

* Blanket approval of all verbs from all hosts
* Always request/use an SSL URL
* Only use the POST verb
* No custom headers
* Only use the "text/plain" mime-type
* Expect no cookies

See [this](http://blogs.msdn.com/b/ieinternals/archive/2010/05/13/xdomainrequest-restrictions-limitations-and-workarounds.aspx)
for some more detail on why.

Unfortunately IE prior to version 10 (9 and below) will not support
cross-protocol requests, so the HTTP-to-HTTPS nature of the requests from
GitHub's project-pages will not work, but that's a small price to pay to work
pretty much everywhere else and get free hosting ;-)

## Structure ##

lslguru.github.io/easy-gacha/<version>/#callbackURL[/adminkey]
callbackURL[/adminkey]/<command>[/parameters]

### version ###

Baked in to prevent breaking existing scripts in the future.

### callbackURL ###

This is the result of using llEscapeURL on the URL generated by the sim.

### adminkey ###

A UUID automatically generated by the script, to prevent spoofing by
non-owners. Needs to be regenerated every time the context changes.

### command ###

The primary operation being performed. Generally speaking it will be one of three things:

* Get information
* Set a value / replace list with single value
* Append to an existing value (string or list)

This keeps the protocol ridiculously simple, and puts the onus of complex
display and understanding on the JavaScript UI. That way the LSL script is
freed to perform the more in-world specific tasks. Modifying values would
require passing more information than the new value, which would be cumbersome,
and also consume far more in-script memory as duplicates of the list would be
made temporarily. This does slow the process down a bit, as the script has to
make multiple sequential calls, but that's an acceptable trade-off.

### parameters ###

Technically these will be part of the command (baked in), but are a logical
separation for the source code. Best to avoid doing any complex string parsing
if possible.

## Content Format ##

This will depend on the specific variable/command, but generally speaking the
type of a variable will be known ahead of time, so variables should be
transferred as a raw cast (string) and parsed on both ends.

Lists should be JSON encoded using

    string llList2Json( JSON\_ARRAY , list values )
    list llJson2List( string src )

VERY IMPORTANT NOTE: In the http\_request event, body is limited to 2048 bytes;
anything longer will be truncated to 2048 bytes.

--------------------------------------------------------------------------------

# TO DO List #

## Work In Progress ##

* Process everything from "old" directory, removing as I go
* New scripting approach
* Documentation
* Release
* Contact those who have already purchased

### SL Script ###

* On touch, llLoadURL
* Report once every 24 hours and on each significant event
* Memory checks

    llSetPayPrice( PAY_DEFAULT , [ PAY_DEFAULT , PAY_DEFAULT , PAY_DEFAULT , PAY_DEFAULT ] );
    llSetTouchText( "" );

    !( llGetOwner() == Owner )
    !( llGetScriptName() == ScriptName )
    !( llGetPermissionsKey() == Owner )
    !( llGetPermissions() & PERMISSION_DEBIT )

### Configuration Page ###

* Check that we have at least one thing to hand out
* Check price == total payouts
* Check buy button configs
* List final rarity of each item
* Root prim detection
* If no-copy item is to be handed out
    * Max per purchase = 1
    * Folders turned off
* Memory checks
* Progress bars during operations
* Serialized background operations
* Style divs after Firestorm windows
* Configured inventory not found
* Auto-configure new inventory
* Save data in localStorage, export/import JSON
* Stats display with auto-reload

    // We have to build a list in memory of the items to be given in a folder. To
    // prevent out of memory errors and exceedlingly long-running scripts (e.g.
    // price is L$1 and gave it L$10,000), a max is enforced. The owner can choose
    // a value below this, but not above this.
    #define MAX_PER_PURCHASE 100

    // When reporting via email, the max email body is effectively 3600 bytes. At
    // MAX_INVENTORY_NAME_LENGTH times number of purchases with at least two
    // characters of separation and including the name of the purchaser...
    #define MAX_PER_PURCHASE_WITH_EMAIL 50

#### Config Notecard Format ####

    inv RARITY LIMIT BOUGHT ITEM
    payout AGENT MONEY
    max_per_purchase COUNT
    pay_price COUNT
    pay_price_buttons COUNT COUNT COUNT COUNT
    folder_for_single_item BOOLEAN
    root_click_action BOOLEAN
    stats BOOLEAN
    group BOOLEAN
    email EMAIL
    im AGENT
    whisper BOOLEAN
    hovertext BOOLEAN
    registry BOOLEAN
    max_buys COUNT

### Registry ###

* Record all reports
* Display paginated sortable list of Gacha boxes

