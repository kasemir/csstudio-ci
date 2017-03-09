### Assumes
# Oracle java is installed
# JAVA_HOME is set and java is in the default path
# Maven is installed and on the default path, M2 and M2_HOME are set

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${SCRIPT_DIR}/env.sh

set -x

function build_in {
    result=1

    if [ -z $3 ]; then
	fname=$2_$1
    else
	fname=$2_$3
    fi

    rm -f $fname
    
    (cd "$1"; time mvn $OPTS) | tee $fname.log
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
	echo "$1 build failed"
	exit
    fi
}

cd $CSS_BUILD_DIR

#rm -rf *.log

export MAVEN_OPTS="-Xmx2048m -XX:-UseGCOverheadLimit"
#BASE_OPTS="-e -X -s $MSET"
BASE_OPTS="-s $MSET -U -up"

OPTS="${BASE_OPTS} clean install"
build_in archive-influxdb a1

OPTS="${BASE_OPTS} clean p2:site"
build_in archive-influxdb/archive.influxdb-repository a1_1 archive-influxdb-p2

OPTS="${BASE_OPTS} clean install -DskipTests=true"
build_in influxdb-java a2

OPTS="${BASE_OPTS} clean p2:site"
build_in influxdb-java/repository a2_1 influxdb-java-p2

ln -s \
   ${CSS_BUILD_DIR}/archive-influxdb/archive.influxdb-repository/target/repository/plugins \
   ${CSS_BUILD_DIR}/archive-influxdb_plugins

ln -s \
   ${CSS_BUILD_DIR}/influxdb-java/repository/target/repository/plugins \
   ${CSS_BUILD_DIR}/influxdb-java_plugins


