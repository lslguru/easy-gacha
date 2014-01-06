# !!! WARNING !!! #

This is a work-in-progress version, and may contain bugs.

--------------------------------------------------------------------------------

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

* Always request/use a non-SSL URL (nothing here is truly private/important)
* Only use the GET and POST verbs
* No custom headers (sadly that includes CORS, see LSL HTTP Server docs)
* Expect no cookies

See [this](http://blogs.msdn.com/b/ieinternals/archive/2010/05/13/xdomainrequest-restrictions-limitations-and-workarounds.aspx)
for some more detail on why.

See [this](http://wiki.secondlife.com/wiki/LSL_http_server) for a list of
supported features in LSL, which sadly doesn't include setting the CORS headers
on responses.

To get around all this, we officially load the initial page via the script, and
it loads all its libraries, CSS, and images via a single script tag. That way
all AJAX calls are technically to the same domain of the original page.

## Structure ##

    GET secondlifeURL/[?dev=1]#[adminKey/]<page>
        Where the browser is sent
    GET lslguru.github.io/easy-gacha/<version>/easy-gacha.min.js
        Initial library load which takes care of bootstrapping and loading
        everything else
    POST secondLifeURL/[adminKey/]<verb>/<subject>[/options]
        Body should always be JSON-encoded array, though it may be a list with
        only a single item. This overhead is acceptable for gaining simplicitly
        in parsing.

--------------------------------------------------------------------------------

# Config Notecard Format #

Space separated fields

    inv
        rarity
        limit
        bought
        item
    payout
        agent
        money
    configs
        folder_for_single_item (boolean)
        root_click_action (boolean)
        group (boolean)
        allow_whisper (boolean)
        allow_hovertext (boolean)
        max_per_purchase (count)
        max_buys (count)
        pay_price (lindens)
        pay_price_button_0 (lindens)
        pay_price_button_1 (lindens)
        pay_price_button_2 (lindens)
        pay_price_button_3 (lindens)
    email
        email
    im
        agent
    configured
        boolean

--------------------------------------------------------------------------------

# Reference Links #

## SecondLife ##

* [LSL Functions](http://wiki.secondlife.com/wiki/Category:LSL_Functions)
* [LSL HTTP server](http://wiki.secondlife.com/wiki/LSL_http_server)

## UI Libraries/Frameworks ##

* [Bootstrap](http://getbootstrap.com/)
* [Marionette](https://github.com/marionettejs/backbone.marionette)
* [Backbone](http://backbonejs.org/)
* [jQuery](http://api.jquery.com/)
* [Handlebars](http://handlebarsjs.com/)
* [Moment](http://momentjs.com/)
* [Font Awesome](http://fontawesome.io/icons/)

--------------------------------------------------------------------------------

# gh-pages volo #

    $ grunt volo:add:-amd:underscore:exports=_:v5/vendor/underscore
    $ grunt volo:add:-amd:jquery:exports='$':v5/vendor/jquery
    $ grunt volo:add:-amd:backbone:exports=Backbone:depends=v5/jquery,v5/underscore:v5/vendor/backbone
    $ grunt volo:add:-amd:-noprompt:bootstrap:v5/vendor/bootstrap
    $ grunt volo:add:-amd:backbone.wreqr:depends=v5/vendor/backbone:v5/vendor/backbone.wreqr
    $ grunt volo:add:-amd:backbone.babysitter:depends=v5/vendor/backbone:v5/vendor/backbone.babysitter
    $ grunt volo:add:-amd:marionette:exports=Marionette:depends=v5/vendor/underscore,v5/vendor/backbone,v5/vendor/backbone.wreqr,v5/vendor/backbone.babysitter:v5/vendor/marionette

--------------------------------------------------------------------------------

# TO DO List #

## Work In Progress ##

* Process everything from "old" directory, removing as I go
* New scripting approach
* Documentation
* Release
* Contact those who have already purchased

### SL Script ###

* Report once every 24 hours and on each significant event

### Configuration Page ###

* Check that we have at least one thing to hand out
* Check price == total payouts
* Check buy button configs
* List final rarity of each item
* Root prim detection
* If no-copy item is to be handed out
    * Max per purchase = 1 (and update buy buttons)
    * Folders turned off
* Memory checks
* Progress bars during operations
* Serialized background operations
* Style divs after Firestorm windows
* Configured inventory not found
* Auto-configure new inventory
* Save data in localStorage, export/import JSON
* Stats display with auto-reload
* If price is zero
    * Max per purchase = 1 (no way to tell how many times to play, update buy buttons)
* Source code message and link in footer

    // We have to build a list in memory of the items to be given in a folder. To
    // prevent out of memory errors and exceedlingly long-running scripts (e.g.
    // price is L$1 and gave it L$10,000), a max is enforced. The owner can choose
    // a value below this, but not above this.
    #define MAX_PER_PURCHASE 100

    // When reporting via email, the max email body is effectively 3600 bytes. At
    // MAX_INVENTORY_NAME_LENGTH times number of purchases with at least two
    // characters of separation and including the name of the purchaser...
    #define MAX_PER_PURCHASE_WITH_EMAIL 50

### Registry ###

* Record all reports
* Display paginated sortable/searchable list of Gacha boxes
