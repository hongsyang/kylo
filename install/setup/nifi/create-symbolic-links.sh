#!/bin/bash

while getopts "f" opt; do
  case $opt in
    f) OPT_F=1
       ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
    *)
      echo "unrecognized option -$OPTARG"
      exit 1;
      ;;
  esac
done
shift $((OPTIND-1))

NIFI_HOME=$1
NIFI_USER=$2
NIFI_GROUP=$3

if [ $# -ne 3 ]
then
    echo "Wrong number of arguments. You must pass in the NIFI_HOME location, NIFI_USER, and NIFI_GROUP"
    exit 1
fi

# Determine System's spark version
if [ -z ${SPARK_PROFILE} ]; then
        SPARK_SUBMIT=$(which spark-submit)
        if [ -z ${SPARK_SUBMIT} ]; then
                >&2 echo "ERROR: spark-submit not on path.  Has spark been installed?"
                exit 1
        fi
        if ! [ -x ${SPARK_SUBMIT} ]; then
                >&2 echo "ERROR: spark-submit found but not suitable for execution.  Has spark been installed?"
                exit 1
        fi
        SPARK_PROFILE="spark-v"$(spark-submit --version 2>&1 | grep -o "version [0-9]" | grep -o "[0-9]" | head -1)
else
        if ! [[ $SPARK_PROFILE =~ spark-v[0-9] ]]; then
                >&2 echo "ERROR: variable SPARK_PROFILE not usable, expected it to be like spark-v1 or spark-v2 but found '$SPARK_PROFILE'"
                exit 1
        fi
fi

ln -f -s $NIFI_HOME/data/lib/kylo-nifi-elasticsearch-v1-nar-*.nar $NIFI_HOME/current/lib/kylo-nifi-elasticsearch-nar.nar
ln -f -s $NIFI_HOME/data/lib/kylo-nifi-teradata-tdch-nar-*.nar $NIFI_HOME/current/lib/kylo-nifi-teradata-tdch-nar.nar

##find the nifi version to copy the correct nar versions

framework_name=$(find $NIFI_HOME/current/lib/ -name "nifi-framework-api*.jar")
prefix="$NIFI_HOME/current/lib/nifi-framework-api-"
len=${#prefix}
ver=${framework_name:$len}

if [[ $ver == 1.0* ]] || [[ $ver == 1.1* ]] ;
then

  echo "Creating symlinks for NiFi version $ver compatible nars"
  ln -f -s $NIFI_HOME/data/lib/kylo-nifi-provenance-repo-v1-nar-*.nar $NIFI_HOME/current/lib/kylo-nifi-provenance-repo-nar.nar

  ln -f -s $NIFI_HOME/data/lib/kylo-nifi-core-service-nar-*.nar $NIFI_HOME/current/lib/kylo-nifi-core-service-nar.nar
  ln -f -s $NIFI_HOME/data/lib/kylo-nifi-standard-services-nar-*.nar $NIFI_HOME/current/lib/kylo-nifi-standard-services-nar.nar
  ln -f -s $NIFI_HOME/data/lib/kylo-nifi-core-v1-nar-*.nar $NIFI_HOME/current/lib/kylo-nifi-core-nar.nar
  ln -f -s $NIFI_HOME/data/lib/kylo-nifi-spark-v1-nar-*.nar $NIFI_HOME/current/lib/kylo-nifi-spark-nar.nar
  ln -f -s $NIFI_HOME/data/lib/kylo-nifi-spark-service-v1-nar-*.nar $NIFI_HOME/current/lib/kylo-nifi-spark-service-nar.nar
  ln -f -s $NIFI_HOME/data/lib/kylo-nifi-hadoop-v1-nar-*.nar $NIFI_HOME/current/lib/kylo-nifi-hadoop-nar.nar
  ln -f -s $NIFI_HOME/data/lib/kylo-nifi-hadoop-service-v1-nar-*.nar $NIFI_HOME/current/lib/kylo-nifi-hadoop-service-nar.nar

elif  [[ $ver == 1.* ]] ;
then
   echo "Creating symlinks for NiFi version $ver compatible nars"
  ln -f -s $NIFI_HOME/data/lib/kylo-nifi-provenance-repo-v1.2-nar-*.nar $NIFI_HOME/current/lib/kylo-nifi-provenance-repo-nar.nar

  ln -f -s $NIFI_HOME/data/lib/kylo-nifi-core-service-v1.2-nar-*.nar $NIFI_HOME/current/lib/kylo-nifi-core-service-nar.nar
  ln -f -s $NIFI_HOME/data/lib/kylo-nifi-standard-services-v1.2-nar-*.nar $NIFI_HOME/current/lib/kylo-nifi-standard-services-nar.nar
  ln -f -s $NIFI_HOME/data/lib/kylo-nifi-core-v1.2-nar-*.nar $NIFI_HOME/current/lib/kylo-nifi-core-nar.nar
  ln -f -s $NIFI_HOME/data/lib/kylo-nifi-spark-v1.2-nar-*.nar $NIFI_HOME/current/lib/kylo-nifi-spark-nar.nar
  ln -f -s $NIFI_HOME/data/lib/kylo-nifi-spark-service-v1.2-nar-*.nar $NIFI_HOME/current/lib/kylo-nifi-spark-service-nar.nar
  ln -f -s $NIFI_HOME/data/lib/kylo-nifi-hadoop-v1.2-nar-*.nar $NIFI_HOME/current/lib/kylo-nifi-hadoop-nar.nar
  ln -f -s $NIFI_HOME/data/lib/kylo-nifi-hadoop-service-v1.2-nar-*.nar $NIFI_HOME/current/lib/kylo-nifi-hadoop-service-nar.nar

else
  echo "error: incompatible NiFi version detected: ${ver%.jar}"
  exit 1

fi

##end nars


## Install Kylo's NiFi Spark jars

# check to see if they have been previously installed and if they match the system's current spark default
LINK_CMD="readlink -f"
if [ -f $NIFI_HOME/current/lib/app/kylo-spark-validate-cleanse-jar-with-dependencies.jar ]; then
  VALIDATE=$($LINK_CMD $NIFI_HOME/current/lib/app/kylo-spark-validate-cleanse-jar-with-dependencies.jar)
  if [[ -z "$OPT_F" && $VALIDATE =~ spark-v[0-9]+ ]]; then
     PRIOR_SPARK_PROFILE="$BASH_REMATCH"
     if [ "$SPARK_PROFILE" != "$PRIOR_SPARK_PROFILE" ] ; then
         >&2 echo "ERROR: Kylo's NiFi jars for spark are currently defaulted \
to $PRIOR_SPARK_PROFILE and the default spark is currently $SPARK_PROFILE.  If \
you are sure you want to change the default spark version for the Kylo NiFi jars then \
rerun this script with '-f'. OR.. rerun this script after you've changed spark to $PRIOR_SPARK_PROFILE"
         exit 1
     fi
  fi
fi

ln -f -s $NIFI_HOME/data/lib/app/kylo-spark-validate-cleanse-${SPARK_PROFILE}-*-jar-with-dependencies.jar $NIFI_HOME/current/lib/app/kylo-spark-validate-cleanse-jar-with-dependencies.jar
ln -f -s $NIFI_HOME/data/lib/app/kylo-spark-job-profiler-${SPARK_PROFILE}-*-jar-with-dependencies.jar $NIFI_HOME/current/lib/app/kylo-spark-job-profiler-jar-with-dependencies.jar
ln -f -s $NIFI_HOME/data/lib/app/kylo-spark-interpreter-${SPARK_PROFILE}-*-jar-with-dependencies.jar $NIFI_HOME/current/lib/app/kylo-spark-interpreter-jar-with-dependencies.jar
ln -f -s $NIFI_HOME/data/lib/app/kylo-spark-merge-table-${SPARK_PROFILE}-*-jar-with-dependencies.jar $NIFI_HOME/current/lib/app/kylo-spark-merge-table-jar-with-dependencies.jar
ln -f -s $NIFI_HOME/data/lib/app/kylo-spark-multi-exec-${SPARK_PROFILE}-*-jar-with-dependencies.jar $NIFI_HOME/current/lib/app/kylo-spark-multi-exec-jar-with-dependencies.jar

chown -h $NIFI_USER:$NIFI_GROUP $NIFI_HOME/current/lib/kylo*.nar
chown -h $NIFI_USER:$NIFI_GROUP $NIFI_HOME/current/lib/app/kylo*.jar
