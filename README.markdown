# Overview #

This is the branch for the public assets hosted on GitHub for use with Easy Gacha

# Notes #

    $ grunt volo:add:-amd:underscore:exports=_:v5/vendor/underscore
    $ grunt volo:add:-amd:jquery:exports='$':v5/vendor/jquery
    $ grunt volo:add:-amd:backbone:exports=Backbone:depends=v5/jquery,v5/underscore:v5/vendor/backbone
    $ grunt volo:add:-amd:-noprompt:bootstrap:v5/vendor/bootstrap
    $ grunt volo:add:-amd:backbone.wreqr:depends=v5/vendor/backbone:v5/vendor/backbone.wreqr
    $ grunt volo:add:-amd:backbone.babysitter:depends=v5/vendor/backbone:v5/vendor/backbone.babysitter
    $ grunt volo:add:-amd:marionette:exports=Marionette:depends=v5/vendor/underscore,v5/vendor/backbone,v5/vendor/backbone.wreqr,v5/vendor/backbone.babysitter:v5/vendor/marionette
