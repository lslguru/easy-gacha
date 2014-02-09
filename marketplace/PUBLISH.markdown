# Steps to publish a new version #

## Repository ##

* Remove warning from README
* Build an HTML copy of README.markdown using "marked" npm package
* Build marketplace/README.pdf using print-to-pdf in browser of README.html
* Commit files
* Tag commit
* Restore warning to README
* Push tag and branch
* Build official version of script (combined with Registry code)

## Items Included ##

* Script
    * Name: Easy Gacha
    * Description: Git Commit ID
    * Permissions: Next Owner -Mod +Copy -Trans, Anyone -Copy, Group -Share
    * Edit script: Paste correct contents
    * Edit script: Paste Registry function for server

* Script Notecard
    * Use my own notecard
    * Name: Easy Gacha Source Code
    * Description: Git Commit ID
    * Permissions: Next Owner -Mod +Copy -Trans, Anyone -Copy, Group -Share
    * Edit card: Paste easy-gacha.lsl contents

* Readme Notecard
    * Use my own notecard
    * Name: ! DIRECTIONS / INSTRUCTIONS / HEY YOU !
    * Description: Git Commit ID
    * Permissions: Next Owner -Mod +Copy -Trans, Anyone -Copy, Group -Share
    * Edit card: Paste contents from top-level README.markdown

* Ready Object
    * Create new Gumball machine object
    * Size such that land-impact is 1 or 2
    * Name: Easy Gacha - Ready to use
    * Description: Git Commit ID
    * Permissions: Next Owner +Mod +Copy -Trans, Anyone -Copy, Group -Share
    * Contents:
        * Script "Easy Gacha" (running)

* Mesh Object Kit
    * Use Rix's original object
    * Texture: Easy Gacha Logo
    * Name: Easy Gacha - Mesh Object Kit
    * Description: Git Commit ID
    * Permissions: Next Owner +Mod +Copy -Trans, Anyone -Copy, Group -Share
    * Default Action: Open
    * Contents: All original inventory from Rix

* Kit Object
    * Create new cube
    * Texture: Easy Gacha Logo
    * Name: Easy Gacha - Kit
    * Description: Git Commit ID
    * Permissions: Next Owner +Mod +Copy -Trans, Anyone -Copy, Group -Share
    * Default Action: Open
    * Contents
        * Readme Notecard
        * Script "Easy Gacha" (not running)
        * Script Notecard
        * Mesh Object Kit
v5.0 (f28627cbf43baf39d00bfb088818efcb00fd9b34)

## Marketplace Listing ##

* SKU: easy-gacha
* Version: {human-readable-number}: {git-commit-id}
* Maturity Level: General
* Mesh: No Mesh
* Permission: +Copy +Mod -Trans
* User Requirements: None
* Item Title: Easy Gacha
* Features:
    1. Easy to configure
    2. Set probability for each inventory item
    3. Share profits with as many people as you like
    4. Free web page based statistics
    5. Free Open Source Software (FOSS)
* Extended Description: Copy from below
* Keywords: easy, gacha, gasha, gashapon, OSS, FOSS, full perm, low lag, no lag
* Category: Business > Vendor Machines
* Item price: L$0
* Prim count: 2
* SLurl: {not entered}
* Video URL: {not entered}
* Available quantity: Unlimited
* Images: {not entered}
* Animated GIF: {not entered}
* Downloadable PDF: README.pdf
* Related Items: None
* Demo Item: N/A

### Extended Description ###

=== DIRECTIONS / INSTRUCTIONS / GETTING STARTED ===

1. Rez the "Easy Gacha" object
2. Put your Gacha items into the object
3. Click the link in your chat window
4. Configure your Easy Gacha using the web page
5. ...
6. Profit!

=== FEATURES ===

User-Friendly Features

* No need to rename any items
* Incredibly easy to configure
* Most configuration done automatically
* Detects and prevents most mistakes
* Can set rarity per item
* Supports 30+ items configured at a time
* Multiple-play option (can buy multiple objects at at a time)
* Can limit number of sales per item
* Can limit total number of sales for entire Gacha
* Can payout to multiple people with each play
* Guaranteed to hand out inventory and refund change correctly
* Can be restricted to group-only play
* Can handle no-copy items
* Can configure payment buttons
* Can send IM reports when people play
* Can send Email reports when people play
* Dashboard can be loaded on a smart-phone (with JavaScript enabled)

Geeky Features

* Only asks for debit permission once if possible
* Ultra low lag (zero when not in use)
* All data stored in-world (except for Gacha registry and single JavaScript file)
* Configuration can be exported
* Configuration can be imported by hand or from notecard
* Automatic self memory management
* Gives statistics about actual sales versus configured rarity
* Protects against modifying existing object configurations (safe to use in any object)
* Has an optional API for writing plugins and addons (doesn't spam object unless requested)
* Guaranteed to only use one system URL at a time
* Shortens URLs to make them easy to use

=== NOTES ===

Easy Gacha configuration is very, very simple. Click the link and follow the instructions on the web page. The web page is produced by the object, so there is no external server to worry about!

Easy Gacha allows people to buy more than one random prize at a time. Really want that 2% rare item? Buy up to 50 items at the same time, all delivered in a handy folder! That doesn't guarantee you'll get the rare item, but why wear out your finger clicking 50 times? Don't want people to be able to do this? It's configurable, so you can turn it off.

This is free, copyable, modifiable, open source software. That means it will never cost anything, and you can change it (or hire someone else to change it) any time you like! All the files that go into creating Easy Gacha are available on the GitHub page.

The script has been thoroughly tested to be absolutely reliable and speedy, and has been designed to have no lag (less than 0.00001 average script time per instance, sometimes registering at 0.000000)!

Easy Gacha collects usage data while it is running to provide you with a simple, easy to use list of statistics for your vendor. Just right-click on your vendor and select "Info" to get a link (if you've set free-play mode, it will say "Play" but also give you the link).

Easy Gacha does contact our server to provide everyone with a list of official Easy Gacha machines. This is a form of free advertising for YOUR gacha! Don't want to be listed? There is a setting on the "Advanced" screen to turn it off.

Works with any type of inventory which can be put inside an object. Note: When dropping scripts into an object's inventory, they try to run automatically.

Not locked in to a specific object: You can use any object you have with modify rights. Only one prim required (to hold the script).

The script and README are +Copy -Mod -Trans to prevent tampering, but you're welcome to copy and paste the code into your own script (if you want a full perm script).

For frequently asked questions, go here:

https://github.com/lslguru/easy-gacha/#frequently-asked-questions

The list of awesome people who contributed can be found at:

https://github.com/lslguru/easy-gacha/#the-awesome-people-contributors

The source code can be found at:

https://github.com/lslguru/easy-gacha/#readme
