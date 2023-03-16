ARG IMAGE_NAME="${IMAGE_NAME:-silverblue}"
ARG SOURCE_IMAGE="${SOURCE_IMAGE:-silverblue}"
ARG BASE_IMAGE="quay.io/fedora-ostree-desktops/${SOURCE_IMAGE}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-38}"


FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} AS main
ARG IMAGE_NAME="${IMAGE_NAME:-silverblue}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-37}"

COPY github-release-install.sh /tmp/github-release-install.sh
COPY main-install.sh /tmp/main-install.sh
COPY main-post-install.sh /tmp/main-post-install.sh
COPY main-packages.json /tmp/main-packages.json
ADD repos/tailscale.repo /etc/yum.repos.d/tailscale.repo
ADD repos/docker-ce.repo /etc/yum.repos.d/docker-ce.repo


# Copy static configurations and component files.
# Warning: If you want to place anything in "/etc" of the final image, you MUST
# place them in "./usr/etc" in your repo, so that they're written to "/usr/etc"
# on the final system. That is the proper directory for "system" configuration
# templates on immutable Fedora distros, whereas the normal "/etc" is ONLY meant
# for manual overrides and editing by the machine's admin AFTER installation!
# See issue #28 (https://github.com/ublue-os/startingpoint/issues/28).
COPY usr /usr

# Setup Copr repos
RUN wget https://copr.fedorainfracloud.org/coprs/kylegospo/system76-scheduler/repo/fedora-$(rpm -E %fedora)/kylegospo-system76-scheduler-fedora-$(rpm -E %fedora).repo -O /etc/yum.repos.d/_copr_kylegospo-system76-scheduler.repo

RUN dconf update

COPY --from=ghcr.io/ublue-os/config:latest /rpms /tmp/rpms
COPY --from=ghcr.io/ublue-os/akmods:${FEDORA_MAJOR_VERSION} /rpms /tmp/akmods-rpms


RUN if grep -q "kinoite" <<< "${IMAGE_NAME}"; then \
    git clone https://github.com/maxiberta/kwin-system76-scheduler-integration.git --depth 1 /tmp/kwin-system76-scheduler-integration && \
    kpackagetool5 --type=KWin/Script --global --install /tmp/kwin-system76-scheduler-integration && \
    rm -rf /tmp/kwin-system76-scheduler-integration \
; fi


# Renaming os
RUN sed  's/NAME="Fedora Linux/NAME="CalvadOS/' /etc/os-release -i
RUN sed  's/NAME="Fedora Linux/NAME="CalvadOS/' /usr/lib/os-release -i



RUN /tmp/main-install.sh
RUN /tmp/main-post-install.sh

# Cleanup & Finalize
RUN systemctl enable com.system76.Scheduler.service && \
    pip install --prefix=/usr yafti
#  if grep -q "kinoite" <<< "${IMAGE_NAME}"; then \
#       systemctl --global enable com.system76.Scheduler.dbusproxy.service \
#  ; fi

RUN rm -rf /tmp/* /var/*
RUN ostree container commit
RUN mkdir -p /var/tmp && chmod -R 1777 /var/tmp


FROM main AS nvidia
ARG IMAGE_NAME="${IMAGE_NAME:-silverblue}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-37}"
ARG NVIDIA_MAJOR_VERSION="${NVIDIA_MAJOR_VERSION:-535}"

COPY nvidia-install.sh /tmp/nvidia-install.sh
COPY nvidia-post-install.sh /tmp/nvidia-post-install.sh

COPY --from=ghcr.io/ublue-os/akmods-nvidia:${FEDORA_MAJOR_VERSION}-${NVIDIA_MAJOR_VERSION} /rpms /tmp/akmods-rpms

RUN /tmp/nvidia-install.sh
RUN /tmp/nvidia-post-install.sh
RUN rm -rf /tmp/* /var/*
RUN ostree container commit
RUN mkdir -p /var/tmp && chmod -R 1777 /tmp /var/tmp
