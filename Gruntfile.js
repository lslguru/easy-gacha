module.exports = function( grunt ) {

    grunt.initConfig( {
        pkg: grunt.file.readJSON( 'package.json' ) ,

        requirejs: {
            v5: {
                options: {
                    optimize: 'uglify2' ,
                    generateSourceMaps: true ,
                    name: 'easy-gacha' ,
                    out: 'easy-gacha.min.js' ,
                } ,
            } ,
        } ,
    } );

    grunt.loadNpmTasks( 'grunt-contrib-requirejs' );

    grunt.registerTask( 'default' , [
        'requirejs' ,
    ] );

};
