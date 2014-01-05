module.exports = function( grunt ) {

    grunt.initConfig( {
        pkg: grunt.file.readJSON( 'package.json' ) ,

        requirejs: {
            v5: {
                options: {
                    mainConfigFile: 'v5/init.js' ,
                    optimize: 'uglify2' , // Compress the heck out of it
                    preserveLicenseComments: false , // Disabled so we can use source-maps
                    generateSourceMaps: true , // But make it possible to debug
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
