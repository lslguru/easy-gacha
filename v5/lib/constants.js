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

    VERSION: 5.0

    , NULL_KEY: '00000000-0000-0000-0000-000000000000'

    , MAX_MEMORY: 65536 // bytes
    , DANGER_MEMORY_THRESHOLD: 4096
    , WARN_MEMORY_THRESHOLD: 8192

    , WARN_SCRIPT_TIME: 0.005

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

    , PERM_ALL: 0x7FFFFFFF
    , PERM_COPY: 0x00008000
    , PERM_MODIFY: 0x00004000
    , PERM_MOVE: 0x00080000
    , PERM_TRANSFER: 0x00002000

    , PAY_HIDE: -1
    , PAY_DEFAULT: -2

    , PRIM_TYPE_BOX: 0
    , PRIM_TYPE_CYLINDER: 1
    , PRIM_TYPE_PRISM: 2
    , PRIM_TYPE_SPHERE: 3
    , PRIM_TYPE_TORUS: 4
    , PRIM_TYPE_TUBE: 5
    , PRIM_TYPE_RING: 6
    , PRIM_TYPE_SCULPT: 7

    , LINK_ALL_CHILDREN: -3
    , LINK_ALL_OTHERS: -2
    , LINK_ROOT: 1
    , LINK_SET: -1
    , LINK_THIS: -4

    , MAX_PER_PURCHASE: 50

    , MAX_NOTECARD_LINE_LENGTH: 255

    , DEFAULT_ITEM_LIMIT_COPY: -1
    , DEFAULT_ITEM_LIMIT_NOCOPY: 1
    , DEFAULT_ITEM_RARITY_INIT: 1
    , DEFAULT_ITEM_RARITY: 0

    , EOF: '\n\n\n'

    , DEFAULT_PRICE: 0
    , DEFAULT_PAY_ANY_COUNT: 1
    , DEFAULT_BUTTON_0_COUNT: 1
    , DEFAULT_BUTTON_1_COUNT: 5
    , DEFAULT_BUTTON_2_COUNT: 10
    , DEFAULT_BUTTON_3_COUNT: 25

} ; } );
