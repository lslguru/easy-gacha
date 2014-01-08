define( [

    'image!images/inv/folder_trash.png'
    , 'image!images/inv/item_texture.png'
    , 'image!images/inv/item_sound.png'
    , 'image!images/inv/item_landmark.png'
    , 'image!images/inv/item_clothing.png'
    , 'image!images/inv/item_object.png'
    , 'image!images/inv/item_notecard.png'
    , 'image!images/inv/item_script.png'
    , 'image!images/inv/item_shape.png'
    , 'image!images/inv/item_animation.png'
    , 'image!images/inv/item_gesture.png'
    , 'image!images/inv/folder_lostandfound.png'

] , function(

    folder_trash
    , item_texture
    , item_sound
    , item_landmark
    , item_clothing
    , item_object
    , item_notecard
    , item_script
    , item_shape
    , item_animation
    , item_gesture
    , item_lostandfound

) { return {

    NULL_KEY: '00000000-0000-0000-0000-000000000000'

    , DANGER_MEMORY_THRESHOLD: 20000
    , WARN_MEMORY_THRESHOLD: 10000

    , INVENTORY_NUMBER_TO_TYPE: {
        '': 'INVENTORY_UNKNOWN'
        , '-1': 'INVENTORY_NONE'
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
        'INVENTORY_UNKNOWN': ''
        , 'INVENTORY_NONE': '-1'
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

    , INVENTORY_TYPE_ICON: {
        'INVENTORY_UNKNOWN': item_lostandfound
        , 'INVENTORY_NONE': item_lostandfound
        , 'INVENTORY_TEXTURE': item_texture
        , 'INVENTORY_SOUND': item_sound
        , 'INVENTORY_LANDMARK': item_landmark
        , 'INVENTORY_CLOTHING': item_clothing
        , 'INVENTORY_OBJECT': item_object
        , 'INVENTORY_NOTECARD': item_notecard
        , 'INVENTORY_SCRIPT': item_script
        , 'INVENTORY_BODYPART': item_shape
        , 'INVENTORY_ANIMATION': item_animation
        , 'INVENTORY_GESTURE': item_gesture
    }

    , INVENTORY_TYPE_NAME: {
        'INVENTORY_UNKNOWN': 'The inventory type of the item was not understood'
        , 'INVENTORY_NONE': 'This inventory item is currently unavailable (not present in this Gacha)'
        , 'INVENTORY_TEXTURE': 'Texture'
        , 'INVENTORY_SOUND': 'Sound'
        , 'INVENTORY_LANDMARK': 'Landmark'
        , 'INVENTORY_CLOTHING': 'Clothing'
        , 'INVENTORY_OBJECT': 'Object'
        , 'INVENTORY_NOTECARD': 'Notecard'
        , 'INVENTORY_SCRIPT': 'Script'
        , 'INVENTORY_BODYPART': 'Body Part'
        , 'INVENTORY_ANIMATION': 'Animation'
        , 'INVENTORY_GESTURE': 'Gesture'
    }

} ; } );
