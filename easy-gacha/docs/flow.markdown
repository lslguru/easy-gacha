# Core #

* Get Debit Permission
* Check for config validator
* Enable config validator, tell it to start, and wait for it to finish
* TODO: Enter ready state
    * TODO: On touch
        * TODO: If Price == 0, Handout
        * TODO: If Price != 0, Wake up info and signal interaction, wait for it to finish
    * TODO: On pay
        * TODO: Handout
    * TODO: On handout
        * TODO: First hand out inventory
        * TODO: Wake up stats and signal
        * TODO: Wake up payouts and signal

# Config Validator #

* TODO: All scripts must be preset
* TODO: All config options must be valid
* TODO: Wake up and signal Payouts to init, wait for return
* TODO: Wake up and signal Purchase Buttons to init, wait for return
* TODO: Wake up and signal Stats to init, wait for return
* TODO: Signal valid
* TODO: At any exit point, go to sleep

# Info #

* TODO

# Payouts #

* On init:
    * TODO: Validate total price versus sum of payouts
    * TODO: Validate no duplicate payouts
    * TODO: Validate each payout
    * TODO: Signal valid
    * TODO: At any exit point, go to sleep
* On purchase:
    * TODO: Process payouts * total number of items purchased
    * TODO: Signal payouts complete
    * TODO: Go to sleep

# Purchase Buttons #

* On init:
    * TODO: Validate configs for payment buttons
    * TODO: Apply settings
    * TODO: Signal valid
    * TODO: Go to sleep

# Stats #

* On init:
    * TODO: Send configs to server
    * TODO: Signal valid
    * TODO: Go to sleep
* On purchase:
    * TODO: Signal purchase to server
    * TODO: Go to sleep
