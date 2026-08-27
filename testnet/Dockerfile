FROM ubuntu:24.04

ENV TZ=Europe/Berlin

# gridcointestnetd from the official testnet PPA. Pin is explicit so
# a bad upstream release can't silently break the next image build;
# bump the version when a newer release is verified.
RUN apt-get update -qq \
    &&  apt-get upgrade -y -qq \
    &&  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y -qq \
          apt-utils software-properties-common wget \
    &&  add-apt-repository -y ppa:gridcoin/gridcoin-testnet \
    &&  apt-get update -qq \
    &&  apt-get install --no-install-recommends -y -qq \
          gridcointestnetd= 5.5.1.7-1~noble1 \
    &&  apt-get clean -qq \
    &&  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /root
COPY entrypoint.sh /

RUN mkdir -p /root/.GridcoinResearch \
    &&  wget -O /root/nodes.txt https://addnodes.gridcoin.club/testnet

# Always pull the latest gridcoinresearch-tui release. See the mainnet
# Dockerfile for the cache-buster rationale.
ADD https://api.github.com/repos/gridcat/gridcoinresearch-tui/releases/latest /tmp/tui-release.json
RUN wget https://github.com/gridcat/gridcoinresearch-tui/releases/latest/download/gridcoinresearch-tui_linux_amd64.tar.gz \
    &&  tar -xzf gridcoinresearch-tui_linux_amd64.tar.gz -C /bin/ \
    &&  rm gridcoinresearch-tui_linux_amd64.tar.gz /tmp/tui-release.json

EXPOSE 32749/tcp
EXPOSE 47813/tcp

ENV GRC_DATADIR=/root/.GridcoinResearch

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
