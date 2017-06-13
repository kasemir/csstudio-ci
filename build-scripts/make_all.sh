### Assumes
# Oracle java is installed
# JAVA_HOME is set and java is in the default path
# Maven is installed and on the default path, M2 and M2_HOME are set

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${SCRIPT_DIR}/env.sh

${SCRIPT_DIR}/make_comp_repo.sh --with-influxdb

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
BASE_OPTS="-s $MSET"
OPTS="${BASE_OPTS} clean verify"

######## Build Diirt
build_in diirt 0

######## Build Maven OSGI bundles
build_in maven-osgi-bundles 1

######## Build CS Studio third party
build_in cs-studio-thirdparty 2

######## Build CS Studio Core and Applications
OPTS="${BASE_OPTS} clean verify"
build_in cs-studio/core 3 core
build_in cs-studio/applications 4 applications

######## Build the display builder
CSS_REPO=file:${CSS_COMP_REPO}
OPTS="${BASE_OPTS} -Dcss_repo=$CSS_REPO clean verify"
build_in org.csstudio.display.builder 5 display_builder

######## Build SNS product
OPTS="${BASE_OPTS} clean verify"
build_in org.csstudio.sns 6 sns

rm ${CSS_BUILD_DIR}/sns_plugins

ln -s ${CSS_BUILD_DIR}/org.csstudio.sns/repository/target/repository/plugins ${CSS_BUILD_DIR}/sns_plugins
