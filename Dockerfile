FROM openjdk:8-jdk-alpine

MAINTAINER Stepan Mazurov <smazurov@socialengine.com>

RUN apk add --update \
    # Install bash/curl for the dind setup script:
    curl bash git \
    # Install py-pip as requirement to install docker-compose:
    py-pip \
    # Install the openssh-client (used by CI agents like buildkite):
    openssh-client \
  # Upgrade pip, install tutum cli and supervisor
  && pip install --upgrade \
    pip awscli \
  && rm -rf \
    # Clean up any temporary files:
    /tmp/* \
    # Clean up the pip cache:
    /root/.cache \
    # Clean up the apk cache:
    /var/cache/apk/* \
    # Remove any compiled python files (compile on demand):
    `find / -regex '.*\.py[co]'`

ENV DIND_COMMIT=27afaf3774d7f46028ab72192d4c1b65f8d88b87 DOCKER_VERSION=1.12.5 COMPOSE_VERSION=1.9.0
ADD https://get.docker.com/builds/Linux/x86_64/docker-${DOCKER_VERSION}.tgz /tmp/docker/docker.tgz
RUN tar -xzvf /tmp/docker/docker.tgz -C /tmp && mv /tmp/docker/* /usr/bin/  && rm -r /tmp/docker*
ADD https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind /usr/local/bin/dind
ADD https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-x86_64 /usr/local/bin/docker-compose
RUN chmod +x /usr/bin/docker* /usr/local/bin/dind /usr/local/bin/docker-compose && rm -fr /var/lib/docker/*

# Define additional metadata for our image.
VOLUME /var/lib/docker
VOLUME /var/log/supervisor

ADD *.sh /usr/local/bin/
ADD version_list /etc/docker/

# Install Jenkins Swarm agent
# variable must be named 'HOME' due to swarm client
ENV HOME /root

RUN mkdir -p /usr/share/jenkins && chmod 755 /usr/share/jenkins
ADD https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/2.2/swarm-client-2.2-jar-with-dependencies.jar \
    /usr/share/jenkins/swarm-client-jar-with-dependencies.jar

ENTRYPOINT ["/usr/local/bin/setup.sh"]

