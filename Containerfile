ARG IMAGE_NAME="${IMAGE_NAME:-silverblue}"
ARG SOURCE_IMAGE="${SOURCE_IMAGE:-silverblue}"
ARG BASE_IMAGE="quay.io/fedora-ostree-desktops/${SOURCE_IMAGE}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-37}"

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
ADD config/etc/sysctl.d/90-override.conf /etc/sysctl.d/90-override.conf
ADD config/usr/share/applications/com.jetbrains.IntelliJ-IDEA-Ultimate.desktop /usr/share/applications/com.jetbrains.IntelliJ-IDEA-Ultimate.desktop

RUN dconf update

# install lpis
RUN cd /tmp && wget https://github.com/lamarios/lpis/releases/latest/download/lpis-linux-amd64.tar.gz -O lpis.tar.gz && tar xvf lpis.tar.gz && cp lpis /usr/bin/lpis && chmod +x /usr/bin/lpis
# Install intellij
RUN cd /tmp && wget https://download-cdn.jetbrains.com/idea/ideaIU-2023.1.1.tar.gz -O /tmp/intellij.tar.gz && mkdir /tmp/intellij && \
   tar xvf /tmp/intellij.tar.gz  -C /tmp/intellij --strip-components=1
RUN mv /tmp/intellij /usr/share/intellij


COPY --from=ghcr.io/ublue-os/config:latest /rpms /tmp/rpms

RUN /tmp/build.sh
RUN /tmp/post-install.sh

RUN rm -rf /tmp/* /var/*

RUN ostree container commit
RUN mkdir -p /var/tmp && chmod -R 1777 /var/tmp
