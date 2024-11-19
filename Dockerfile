# need buildx

ARG BUILD_IMAGE=registry.altlinux.org/basealt/altsp:c10f1

################################################################################
# Stage 1: Prepare build image
FROM $BUILD_IMAGE as builder

ENV DEBIAN_FRONTEND=noninteractive
ENV BUILD_PACKAGES_DEBIAN=" \
    curl \
    git-core \
    java-11-openjdk-headless \
    fontconfig \
    fonts-ttf-open-sans \
    fonts-console-terminus \
    libswtpm \
    glibc-locales \
    wget \
"

RUN mkdir -p /src
WORKDIR /src/

# install build packages
RUN apt-get update -qq -y && \
    apt-get install -qq -y $BUILD_PACKAGES_DEBIAN && \
    apt-get clean

RUN mkdir -p /opt/ /src
WORKDIR /src/

ARG MAVEN_VERSION=3.6.3

# download maven
RUN ( curl -fsS https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz -o apache-maven-${MAVEN_VERSION}-bin.tar.gz || \
    curl -fsS https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/${MAVEN_VERSION}/apache-maven-${MAVEN_VERSION}-bin.tar.gz -o apache-maven-${MAVEN_VERSION}-bin.tar.gz ) && \
    tar xfz apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
    rm apache-maven-${MAVEN_VERSION}-bin.tar.gz
#COPY apache-maven-${MAVEN_VERSION}-bin.tar.gz .

ENV PATH="$PATH:/src/apache-maven-${MAVEN_VERSION}/bin"
RUN ls -la && mvn --version || exit 1
ENV M2_HOME=/src/apache-maven-${MAVEN_VERSION}

################################################################################
# Stage 2: Build from sources
FROM builder as build

RUN mkdir -p /src
WORKDIR /src/

ARG HOP_VERSION=2.9.0

## Push sources
#ADD https://github.com/apache/hop/archive/refs/tags/${HOP_VERSION}-rc1.tar.gz .
#RUN \
#    git config --global user.email "docker@build.none" && \
#    git config --global user.name "Docker Build" && \
##    git clone --single-branch --depth 1 --branch release/$HOP_VERSION https://github.com/apache/hop.git
RUN mkdir -p /src/hop
COPY ./ /src/hop

RUN mkdir -p /src/hop/.mvn-repo
RUN mkdir -p /src/hop/.mvn-repo/com/splunk/splunk/1.6.5.0 && \
    cd /src/hop/.mvn-repo/com/splunk/splunk/1.6.5.0 && \
    wget https://repository.liferay.com/nexus/content/repositories/public/com/splunk/splunk/1.6.5.0/splunk-1.6.5.0.jar && \
    wget https://repository.liferay.com/nexus/content/repositories/public/com/splunk/splunk/1.6.5.0/splunk-1.6.5.0.jar.sha1 && \
    wget https://repository.liferay.com/nexus/content/repositories/public/com/splunk/splunk/1.6.5.0/splunk-1.6.5.0.pom && \
    wget https://repository.liferay.com/nexus/content/repositories/public/com/splunk/splunk/1.6.5.0/splunk-1.6.5.0.pom.sha1


ENV MAVEN_OPTS="-Dmaven.repo.local=/src/hop/.mvn-repo"

WORKDIR /src/hop

# enable local maven proxy
#COPY settings.xml $M2_HOME/conf/

# download dependencies
RUN mvn clean -T4C dependency:go-offline -Dmaven.test.skip --batch-mode --no-transfer-progress || exit 0

# build offline
RUN mvn clean -T4C install -Dmaven.test.skip --batch-mode --no-transfer-progress # --offline

RUN mkdir /src/dependencies && \
    mvn dependency:tree -Doutput=/src/dependencies/dependency.txt --batch-mode --no-transfer-progress && \
    mvn dependency:tree -DoutputType=graphml -Doutput=/src/dependencies/dependency.graphml --batch-mode --no-transfer-progress && \
    mvn dependency:tree -DoutputType=dot -Doutput=/src/dependencies/dependency.dot --batch-mode --no-transfer-progress

################################################################################
# Stage 3: Run
FROM $BUILD_IMAGE as run

# JSON configs to update with DB_* envs (space separated)
ENV CONFIG_JSON=""
# List of jobs (workflows) to run once and exit
ENV JOBS_RUN_ONCE=""
# List of jobs (workflows) to run every time on startup
ENV JOBS_ON_STARTUP=""
# List of jobs (workflows) to run with cron
#   syntax: JOBS_CRON="<cron_schedule_without_space>@<project_file_name1> <second_cron_schedule>@<project_file_name1> ..."
#   example: JOBS_CRON="*/1_*_*_*_*@repeated/job_every_minute.hwf" - run repeated/job_every_minute.hwf every minute
ENV JOBS_CRON=""

# Writable workpath
ENV WORKING_PATH=/home/hop
# params from https://github.com/apache/hop/blob/release/2.9.0/docker/Dockerfile
# path to where the artifacts should be deployed to
ENV DEPLOYMENT_PATH=/opt/hop
# volume mount point
ENV VOLUME_MOUNT_POINT=/files
# parent directory in which the hop config artifacts live
# ENV HOP_HOME= ...
# specify the hop log level
ENV HOP_LOG_LEVEL=Basic
# path to hop workflow or pipeline e.g. ~/project/main.hwf
ENV HOP_FILE_PATH=
# file path to hop log file, e.g. ~/hop.err.log
ENV HOP_LOG_PATH=$DEPLOYMENT_PATH/hop.err.log
# path to jdbc drivers
ENV HOP_SHARED_JDBC_FOLDERS=
# name of the Hop project to use
ENV HOP_PROJECT_NAME=mappings
# path to the home of the Hop project..
ENV HOP_PROJECT_FOLDER=$DEPLOYMENT_PATH/config/projects/mappings
# name of the project config file including file extension
ENV HOP_PROJECT_CONFIG_FILE_NAME=project-config.json
# environment to use with hop run
ENV HOP_ENVIRONMENT_NAME=prod
# comma separated list of paths to environment config files (including filename and file extension).
ENV HOP_ENVIRONMENT_CONFIG_FILE_NAME_PATHS=
# hop run configuration to use
ENV HOP_RUN_CONFIG=local
# parameters that should be passed on to the hop-run command
# specify as comma separated list, e.g. PARAM_1=aaa,PARAM_2=bbb
ENV HOP_RUN_PARAMETERS=
# An optional export of metadata in JSON format
ENV HOP_RUN_METADATA_EXPORT=
# System properties that should be set
# specify as comma separated list, e.g. PROP1=xxx,PROP2=yyy
ENV HOP_SYSTEM_PROPERTIES=
# any JRE settings you want to pass on
# The “-XX:+AggressiveHeap” tells the container to use all memory assigned to the container.
# this removed the need to calculate the necessary heap Xmx
ENV HOP_OPTIONS=-XX:+AggressiveHeap
# Path to custom entrypoint extension script file - optional
# e.g. to fetch Hop project files from S3 or gitlab
ENV HOP_CUSTOM_ENTRYPOINT_EXTENSION_SHELL_FILE_PATH=
# The server user
ENV HOP_SERVER_USER=cluster
# The server password
ENV HOP_SERVER_PASSWORD=cluster
# The server hostname
ENV HOP_SERVER_HOSTNAME=0.0.0.0
ENV HOP_SERVER_PORT=8080
ENV HOP_SERVER_SHUTDOWNPORT=8079
# Optional metadata folder to be included in the hop server XML
ENV HOP_SERVER_METADATA_FOLDER=
# Optional server SSL configuration variables
ENV HOP_SERVER_KEYSTORE=
ENV HOP_SERVER_KEYSTORE_PASSWORD=
ENV HOP_SERVER_KEY_PASSWORD=
# Memory optimization options for the server
ENV HOP_SERVER_MAX_LOG_LINES=
ENV HOP_SERVER_MAX_LOG_TIMEOUT=
ENV HOP_SERVER_MAX_OBJECT_TIMEOUT=

# Define en_US.
# ENV LANGUAGE en_US.UTF-8
# ENV LANG en_US.UTF-8
# ENV LC_ALL en_US.UTF-8
# ENV LC_CTYPE en_US.UTF-8
# ENV LC_MESSAGES en_US.UTF-8

ENV PACKAGES_DEBIAN=" \
    bash \
    curl \
    procps \
    unzip \
    java-11-openjdk-headless \
    fontconfig \
    fonts-ttf-open-sans \
    fonts-console-terminus \
    libswtpm \
    jq \
    at \
    glibc-locales \
    gosu \
 "

# install run packages
RUN apt-get update -qq -y && \
    apt-get install -qq -y $PACKAGES_DEBIAN && \
    apt-get clean && \
    rm -rf /var/cache/apt && \
    fc-cache -f

## Define locale
#ENV LANGUAGE en_US.UTF-8
#ENV LANG en_US.UTF-8
#ENV LC_ALL en_US.UTF-8
#ENV LC_CTYPE en_US.UTF-8
#ENV LC_MESSAGES en_US.UTF-8


RUN chmod 777 -R /tmp && chmod o+t -R /tmp

RUN \
  groupadd --system --gid 500 hop \
  && adduser --system --no-create-home -d ${WORKING_PATH} --uid 500 --gid 500 hop \
  && mkdir -p ${WORKING_PATH} \
  && mkdir -p ${VOLUME_MOUNT_POINT} \
  && mkdir -p ${DEPLOYMENT_PATH} \
  && chown -R hop:hop ${DEPLOYMENT_PATH} \
  && chown -R hop:hop ${VOLUME_MOUNT_POINT}

WORKDIR ${DEPLOYMENT_PATH}

COPY entrypoint.sh ./
COPY --from=build /src/hop/docker/resources/run.sh ./
COPY --from=build /src/hop/docker/resources/load-and-execute.sh ./



RUN chmod +x *.sh

# expose 8080/8079 for Hop Server
EXPOSE 8080 8079

# make volume available so that hop pipeline and workflow files can be provided easily
VOLUME ["/files"]

WORKDIR /opt
ARG HOP_VERSION=2.9.0
# copy the hop package from build container
COPY --from=build /src/hop/assemblies/client/target/hop-client-${HOP_VERSION}.zip .
RUN unzip hop-client-${HOP_VERSION}.zip \
    && rm hop-client-${HOP_VERSION}.zip

RUN chown hop:hop -R /opt/hop/config

RUN mkdir -p ${HOP_PROJECT_FOLDER}
WORKDIR ${HOP_PROJECT_FOLDER}

RUN mkdir -p datasets metadata \
    && chown -R hop:hop ${HOP_PROJECT_FOLDER}


# entrypoint

# cron needs root, move to sudo
#USER hop
ENV PATH=$PATH:${DEPLOYMENT_PATH}/hop
WORKDIR ${WORKING_PATH}

ENTRYPOINT ["/bin/bash", "-c"]
#CMD ["/opt/hop/run.sh"]
CMD ["/opt/hop/entrypoint.sh"]
