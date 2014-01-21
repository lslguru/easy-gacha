module.exports = function( grunt ) {

    grunt.initConfig( {
        pkg: grunt.file.readJSON( 'package.json' ) ,

        requirejs: {
            v5_require: {
                options: {
                    optimize: 'uglify2' , // Compress the heck out of it
                    preserveLicenseComments: false , // Disabled to save space
                    name: 'v5/vendor/require' , // Single-file module
                    out: 'v5/vendor/require.min.js' , // Produces a single minified file
                } ,
            } ,
            v5: {
                options: {
                    mainConfigFile: 'v5/init.js' ,
                    optimize: 'uglify2' , // Compress the heck out of it
                    preserveLicenseComments: false , // Disabled to save space
                    name: 'init' , // Single-file module
                    out: 'v5/init.min.js' , // Produces a single minified file
                    exclude: [
                        'normalize' ,
                    ] ,
                } ,
            } ,
        } ,
    } );

    grunt.loadNpmTasks( 'grunt-contrib-requirejs' );
    grunt.loadNpmTasks( 'grunt-volo' );

    grunt.registerTask( 'default' , [
        'requirejs' ,
    ] );

};
