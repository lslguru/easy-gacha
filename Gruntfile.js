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
                    name: 'easy-gacha' , // Single-file module
                    out: 'v5/easy-gacha.min.js' , // Produces a single minified file
                    paths: {
                        'requireLib': 'require' ,
                        'bootstrap': 'bootstrap/js/bootstrap' ,
                    } ,
                    include: [
                        'requireLib' ,
                    ] ,
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
