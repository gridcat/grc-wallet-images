FROM ubuntu:24.04

ENV TZ=Europe/Berlin

# gridcoinresearchd from the official stable PPA. Pin is explicit so a
# bad upstream release can't silently break the next image build; bump
# the version when a newer release is verified.
ARG GRC_DAEMON_VERSION=5.5.2.0-1~noble1
RUN apt-get update -qq \
    &&  apt-get upgrade -y -qq \
    &&  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y -qq \
          apt-utils software-properties-common wget \
    &&  add-apt-repository -y ppa:gridcoin/gridcoin-stable \
    &&  apt-get update -qq \
    &&  apt-get install --no-install-recommends -y -qq \
          gridcoinresearchd=${GRC_DAEMON_VERSION} \
    &&  apt-get clean -qq \
    &&  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /root
COPY entrypoint.sh /

RUN mkdir -p /root/.GridcoinResearch \
    &&  wget -O /root/nodes.txt https://addnodes.gridcoin.club/

# Pinned gridcoinresearch-tui. CI passes the latest plain vX.Y.Z
# release; a new version changes the ARG and rebuilds this layer. The
# build fails if the binary reports a different version.
ARG TUI_VERSION
RUN test -n "$TUI_VERSION" || { echo "TUI_VERSION build-arg is required (e.g. v1.13.1)"; exit 1; } \
    &&  wget -q https://github.com/gridcat/gridcoinresearch-tui/releases/download/${TUI_VERSION}/gridcoinresearch-tui_linux_amd64.tar.gz \
    &&  tar -xzf gridcoinresearch-tui_linux_amd64.tar.gz -C /bin/ \
    &&  rm gridcoinresearch-tui_linux_amd64.tar.gz \
    &&  /bin/gridcoinresearch-tui --version | grep -qx "gridcoinresearch-tui ${TUI_VERSION#v}"

# Bundled versions, readable with `docker inspect` and logged on start.
LABEL club.gridcoin.daemon.version="${GRC_DAEMON_VERSION}" \
      club.gridcoin.tui.version="${TUI_VERSION}"

EXPOSE 32750/tcp
EXPOSE 47812/tcp

ENV GRC_DATADIR=/root/.GridcoinResearch

# TUI settings (state.json) go on the data mount instead of
# /root/.config, so they survive container recreation.
ENV XDG_CONFIG_HOME=/root/.GridcoinResearch/.config

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
