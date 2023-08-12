CWD=`eval pwd`

# Build BirchOutline if needed
cd ./BirchOutline/birch-outline.js/
if [[ ! -e "./min/birchoutline.js" || `find src test -mnewer ./min/birchoutline.js` != "" ]]; then
    ./node_modules/gulp/bin/gulp.js prepublish
    cd "$CWD"
    cd ./BirchEditor/birch-editor.js/
    ./node_modules/gulp/bin/gulp.js prepublish
fi
cd "$CWD"

# Build BirchEditor if needed
cd ./BirchEditor/birch-editor.js/
if [[ ! -e "./min/bircheditor.js" || `find src test -mnewer ./min/bircheditor.js` != "" ]]; then
    ./node_modules/gulp/bin/gulp.js prepublish
fi
cd "$CWD"
