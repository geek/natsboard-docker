FROM node:6-alpine

RUN apk update && \
    apk add bash \
        ca-certificates \
        curl \
        jq \
        tar \
        unzip && \
    rm -rf /var/cache/apk/*

RUN export CONSUL_VERSION=0.7.0 \
    && export CONSUL_CHECKSUM=b350591af10d7d23514ebaa0565638539900cdb3aaa048f077217c4c46653dd8 \
    && curl --retry 7 --fail -vo /tmp/consul.zip "https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip" \
    && echo "${CONSUL_CHECKSUM}  /tmp/consul.zip" | sha256sum -c \
    && unzip /tmp/consul -d /usr/local/bin \
    && rm /tmp/consul.zip \
    && mkdir /config

# Add Consul-CLI
ENV CONSUL_CLI_VER=0.3.1 \
    CONSUL_CLI_SHA256=037150d3d689a0babf4ba64c898b4497546e2fffeb16354e25cef19867e763f1
RUN curl -Lso /tmp/consul-cli.tgz "https://github.com/CiscoCloud/consul-cli/releases/download/v${CONSUL_CLI_VER}/consul-cli_${CONSUL_CLI_VER}_linux_amd64.tar.gz" \
    && echo "${CONSUL_CLI_SHA256}  /tmp/consul-cli.tgz" | sha256sum -c \
    && tar zxf /tmp/consul-cli.tgz -C /usr/local/bin --strip-components 1 \
    && rm /tmp/consul-cli.tgz

# Install ContainerPilot
ENV CONTAINERPILOT_VERSION 3.4.2
RUN export CP_SHA1=5c99ae9ede01e8fcb9b027b5b3cb0cfd8c0b8b88 \
    && curl -Lso /tmp/containerpilot.tar.gz \
         "https://github.com/joyent/containerpilot/releases/download/${CONTAINERPILOT_VERSION}/containerpilot-${CONTAINERPILOT_VERSION}.tar.gz" \
    && echo "${CP_SHA1}  /tmp/containerpilot.tar.gz" | sha1sum -c \
    && tar zxf /tmp/containerpilot.tar.gz -C /bin \
    && rm /tmp/containerpilot.tar.gz

# COPY configuration and scripts
COPY etc/* /etc/
COPY bin/* /usr/local/bin/
RUN chmod 500 /usr/local/bin/manage.sh
ENV CONTAINERPILOT_PATH=/etc/containerpilot.json5
ENV CONTAINERPILOT=file://${CONTAINERPILOT_PATH}

# Install our application
RUN npm install -g natsboard

CMD ["containerpilot"]
