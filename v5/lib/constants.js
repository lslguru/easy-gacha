define( [ ] , function() { return {

    DANGER_MEMORY_THRESHOLD: 20000
    , WARN_MEMORY_THRESHOLD: 10000

    , INVENTORY_NUMBER_TO_TYPE: {
        '-1': 'INVENTORY_NONE'
        , '0': 'INVENTORY_TEXTURE'
        , '1': 'INVENTORY_SOUND'
        , '3': 'INVENTORY_LANDMARK'
        , '5': 'INVENTORY_CLOTHING'
        , '6': 'INVENTORY_OBJECT'
        , '7': 'INVENTORY_NOTECARD'
        , '10': 'INVENTORY_SCRIPT'
        , '13': 'INVENTORY_BODYPART'
        , '20': 'INVENTORY_ANIMATION'
        , '21': 'INVENTORY_GESTURE'
    }

    , INVENTORY_TYPE_TO_NUMBER: {
        'INVENTORY_NONE': '-1'
        , 'INVENTORY_TEXTURE': '0'
        , 'INVENTORY_SOUND': '1'
        , 'INVENTORY_LANDMARK': '3'
        , 'INVENTORY_CLOTHING': '5'
        , 'INVENTORY_OBJECT': '6'
        , 'INVENTORY_NOTECARD': '7'
        , 'INVENTORY_SCRIPT': '10'
        , 'INVENTORY_BODYPART': '13'
        , 'INVENTORY_ANIMATION': '20'
        , 'INVENTORY_GESTURE': '21'
    }

} ; } );
