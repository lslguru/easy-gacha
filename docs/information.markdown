# Folders #

The script can give people a folder which is the name of the Easy Gacha object
followed by the date.

For example, if you name the object "My Stuff", then someone might receive a
folder that says:

    My Stuff (Easy Gacha: 3 items 2013-10-06)

# Caveats / Assumptions #

## Configuration ##

If the script is deleted or reset, any configurations not exported and saved to
a notecard will be lost.

## URL Resource Limitations ##

The script requires a URL to be available on the parcel/sim.  See the [LSL HTTP
server](http://wiki.secondlife.com/wiki/LSL_http_server) for more details.
Specifically, if it cannot obtain a URL, then it cannot be directly configured.
It can still load its configuration from a notecard, and will still function,
but you will not have access to the configuration interface. This can be
resolved by finding the script(s) which are eating up more than their fair
share of URLs and giving their creators a good slap in the face.

## Agent Identification ##

User/agent identification MUST be provided as UUID because SL has yet to
implement a way of looking up a UUID from a user-name or legacy-name reliably.
It might be possible to reverse engineer the key via site-scraping, but that's
not sustainable/maintainable and plain not worth it. We want llRequestAgentKey!
