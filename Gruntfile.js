module.exports = function( grunt ) {

    grunt.initConfig( {
        pkg: grunt.file.readJSON( 'package.json' ) ,

        requirejs: {
            v5: {
                options: {
                    baseUrl: 'v5' , // Script will be loaded directly out of this dir
                    optimize: 'uglify2' , // Compress the heck out of it
                    preserveLicenseComments: false , // Disabled so we can use source-maps
                    generateSourceMaps: true , // But make it possible to debug
                    name: 'main' , // Single-file module
                    out: 'v5/main.min.js' , // Produces a single minified file
                    paths: {
                        'bootstrap': 'bootstrap/js/bootstrap' ,
                    } ,
                    shim: {
                        'bootstrap': {
                            deps: [
                                'jquery' ,
                            ] ,
                        } ,
                    } ,
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
