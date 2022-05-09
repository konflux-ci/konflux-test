# Container image that runs your code
FROM registry.access.redhat.com/ubi8/ubi

ARG conftest_version=0.30.0
ARG BATS_VERSION=1.6.0
ARG go_version=1.18.1
ARG gosec_version=2.11.0
ARG MAVEN_VERSION=3.8.5
ARG FINDSECBUGS_VERSION=1.12.0
ARG JAVA_VERSION=18.0.1.1

RUN curl -L https://github.com/open-policy-agent/conftest/releases/download/v"${conftest_version}"/conftest_"${conftest_version}"_Linux_x86_64.tar.gz | tar -xz --no-same-owner -C /usr/bin/ && \
    curl -LO "https://github.com/bats-core/bats-core/archive/refs/tags/v$BATS_VERSION.tar.gz" && \
    tar -xf "v$BATS_VERSION.tar.gz" && \
    cd "bats-core-$BATS_VERSION" && \
    ./install.sh /usr && \
    cd .. | rm -rf "bats-core-$BATS_VERSION" | rm -rf "v$BATS_VERSION.tar.gz" && \
    curl -L https://go.dev/dl/go"${go_version}".linux-amd64.tar.gz | tar -xz --no-same-owner -C /usr/local/ && \
    curl -sfL https://raw.githubusercontent.com/securego/gosec/master/install.sh | sh -s -- -b /usr/local/go/bin v"${gosec_version}" && \
    dnf -y --setopt=tsflags=nodocs install \
    jq \
    skopeo \
    wget \
    unzip && \
    wget https://download.java.net/java/GA/jdk"${JAVA_VERSION}"/65ae32619e2f40f3a9af3af1851d6e19/2/GPL/openjdk-"${JAVA_VERSION}"_linux-x64_bin.tar.gz && \
    tar -xf openjdk-"${JAVA_VERSION}"_linux-x64_bin.tar.gz -C /home/ && \
    rm -fr openjdk-"${JAVA_VERSION}"_linux-x64_bin.tar.gz && \
    wget https://dlcdn.apache.org/maven/maven-3/"${MAVEN_VERSION}"/binaries/apache-maven-"${MAVEN_VERSION}"-bin.zip && \
    unzip apache-maven-"${MAVEN_VERSION}"-bin.zip -d /home/ && \
    rm apache-maven-"${MAVEN_VERSION}"-bin.zip && \
    wget https://github.com/find-sec-bugs/find-sec-bugs/releases/download/version-"${FINDSECBUGS_VERSION}"/findsecbugs-cli-"${FINDSECBUGS_VERSION}".zip && \
    unzip findsecbugs-cli-"${FINDSECBUGS_VERSION}".zip -d /home/findsecbugs-cli/ && \
    chmod 777 /home/findsecbugs-cli/findsecbugs.sh && \
    rm findsecbugs-cli-"${FINDSECBUGS_VERSION}".zip && \
    wget -P /home/findsecbugs-cli/lib/ https://repo1.maven.org/maven2/org/slf4j/slf4j-simple/2.0.0-alpha0/slf4j-simple-2.0.0-alpha0.jar

ENV POLICY_PATH="/project"
ENV JAVA_HOME=/home/jdk-"${JAVA_VERSION}"
ENV PATH=$PATH:$JAVA_HOME/bin:/home/apache-maven-"${MAVEN_VERSION}"/bin
ENV PATH $PATH:/usr/local/go/bin

COPY policies $POLICY_PATH
COPY test/conftest.sh $POLICY_PATH

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY test/entrypoint.sh /entrypoint.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
