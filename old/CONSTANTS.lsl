// We have to build a list in memory of the items to be given in a folder. To
// prevent out of memory errors and exceedlingly long-running scripts (e.g.
// price is L$1 and gave it L$10,000), a max is enforced. The owner can choose
// a value below this, but not above this.
#define MAX_PER_PURCHASE 100

// When reporting via email, the max email body is effectively 3600 bytes. At
// MAX_INVENTORY_NAME_LENGTH times number of purchases with at least two
// characters of separation and including the name of the purchaser...
#define MAX_PER_PURCHASE_WITH_EMAIL 50
