DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

cd $DIR
elm-live --open --debug --dir=$DIR/src/static src/elm/Main.elm --output $DIR/src/static/Main.js --pushstate
