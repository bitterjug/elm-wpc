DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

TEST_SERVER="curl -s http://localhost:4444/wd/hub/status"

GECKODRIVER="$DIR/bin/geckodriver"

SELENIUM_JAR="$DIR/jar/selenium-server-standalone-3.1.0.jar"

START_SERVER="java -Dwebdriver.gecko.driver=$GECKODRIVER -jar $SELENIUM_JAR"

$TEST_SERVER > /dev/null || ($START_SERVER &)

cd $DIR/webdriver-tests

$DIR/node_modules/.bin/elm-webdriver $*
