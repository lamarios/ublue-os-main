ARG IMAGE_NAME="${IMAGE_NAME:-silverblue}"
ARG SOURCE_IMAGE="${SOURCE_IMAGE:-silverblue}"
ARG BASE_IMAGE="quay.io/fedora-ostree-desktops/${SOURCE_IMAGE}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-38}"

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} AS builder
ARG IMAGE_NAME="${IMAGE_NAME}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"

ADD build.sh /tmp/build.sh
ADD post-install.sh /tmp/post-install.sh
ADD packages.json /tmp/packages.json
ADD repos/tailscale.repo /etc/yum.repos.d/tailscale.repo
ADD repos/docker-ce.repo /etc/yum.repos.d/docker-ce.repo
ADD config/etc/xdg/user-dirs.defaults /etc/xdg/user-dirs.defaults
ADD config/usr/share/lpis/lpis.yml /usr/share/lpis/lpis.yml
ADD config/etc/dconf/db/local.d/01-custom-config /etc/dconf/db/local.d/01-custom-config
ADD config/etc/xdg/autostart/lpis.desktop /etc/xdg/autostart/lpis.desktop
ADD config/etc/xdg/autostart/lpis-kde.desktop /etc/xdg/autostart/lpis-kde.desktop
ADD config/etc/sysctl.d/90-override.conf /etc/sysctl.d/90-override.conf
ADD config/usr/share/applications/com.jetbrains.IntelliJ-IDEA-Ultimate.desktop /usr/share/applications/com.jetbrains.IntelliJ-IDEA-Ultimate.desktop

RUN dconf update

# install lpis
RUN cd /tmp && wget https://github.com/lamarios/lpis/releases/latest/download/lpis-linux-amd64.tar.gz -O lpis.tar.gz && tar xvf lpis.tar.gz && cp lpis /usr/bin/lpis && chmod +x /usr/bin/lpis

# Install auto-epp
# for amd laptop only
RUN wget https://raw.githubusercontent.com/jothi-prasath/auto-epp/master/auto-epp -O /usr/bin/auto-epp
RUN wget https://raw.githubusercontent.com/jothi-prasath/auto-epp/master/auto-epp.service -O /etc/systemd/system/auto-epp.service


COPY --from=ghcr.io/ublue-os/config:latest /rpms /tmp/rpms
COPY --from=ghcr.io/ublue-os/akmods:${FEDORA_MAJOR_VERSION} /rpms /tmp/akmods-rpms


# Renaming os
RUN sed  's/NAME="Fedora Linux/NAME="CalvadOS/' /etc/os-release -i
RUN sed  's/NAME="Fedora Linux/NAME="CalvadOS/' /usr/lib/os-release -i

RUN /tmp/build.sh
RUN /tmp/post-install.sh
RUN rm -rf /tmp/* /var/*
RUN ostree container commit
RUN mkdir -p /var/tmp && chmod -R 1777 /var/tmp
