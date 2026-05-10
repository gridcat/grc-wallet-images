FROM ubuntu:24.04

ENV TZ=Europe/Berlin

# gridcoinresearchd from the official stable PPA. Pin is explicit so a
# bad upstream release can't silently break the next image build; bump
# the version when a newer release is verified.
RUN apt-get update -qq \
    &&  apt-get upgrade -y -qq \
    &&  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y -qq \
          apt-utils software-properties-common wget \
    &&  add-apt-repository -y ppa:gridcoin/gridcoin-stable \
    &&  apt-get update -qq \
    &&  apt-get install --no-install-recommends -y -qq \
          gridcoinresearchd=5.5.0.0-79~ubuntu24.04.1 \
    &&  apt-get clean -qq \
    &&  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /root
COPY entrypoint.sh /

RUN mkdir -p /root/.GridcoinResearch \
    &&  wget -O /root/nodes.txt https://addnodes.cycy.me

# Always pull the latest gridcoinresearch-tui release.
#
# The ADD line uses GitHub's releases/latest API as a cache-buster:
# its body changes whenever upstream cuts a new tag, which invalidates
# this layer and forces the wget below to re-download. Without that
# preamble the wget URL is static, Docker thinks the layer is fresh,
# and rebuilds keep shipping the old binary indefinitely.
#
# /tmp/tui-release.json is NEVER read — its only job is to make the
# layer hash flip on each upstream release. The `rm ... /tmp/tui-
# release.json` at the end of the RUN below is just cleanup so the
# JSON doesn't bloat the final image.
ADD https://api.github.com/repos/gridcat/gridcoinresearch-tui/releases/latest /tmp/tui-release.json
RUN wget https://github.com/gridcat/gridcoinresearch-tui/releases/latest/download/gridcoinresearch-tui_linux_amd64.tar.gz \
    &&  tar -xzf gridcoinresearch-tui_linux_amd64.tar.gz -C /bin/ \
    &&  rm gridcoinresearch-tui_linux_amd64.tar.gz /tmp/tui-release.json

EXPOSE 32750/tcp
EXPOSE 47812/tcp

ENV GRC_DATADIR=/root/.GridcoinResearch

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
