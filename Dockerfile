# Use the official Ubuntu 20.04 base image
FROM ubuntu:20.04

# Set non-interactive mode for APT and configure timezone
ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=Etc/UTC
ENV TZ=${TZ}

# Install system dependencies and prerequisites
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    python3 \
    python3-pip \
    python3-venv \
    libpython3-dev \
    git \
    gperf \
    gdb \
    curl \
    sudo \
    unzip \
    wget \
    libncurses5-dev \
    autoconf \
    automake \
    libtool \
    pkg-config \
    libexpat1-dev \
    openssh-server \
    xauth \
    help2man \
    x11-apps \
    perl \
    g++ \
    flex \
    bison \
    bc \
    ccache \
    ca-certificates \
    libgoogle-perftools-dev \
    openssl \
    libssl-dev \
    numactl \
    perl-doc \
    libfl2 \
    libfl-dev \
    z3 \
    zlib1g \
    zlib1g-dev \
    gtkwave \
    firefox \
    xfce4 \
    xfce4-goodies \
    tightvncserver \
    supervisor \
    vim \
    xfonts-base \
    xfonts-100dpi \
    xfonts-75dpi \
    dbus-x11 \
    jq \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set locale
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
ENV LANGUAGE=C.UTF-8

# Environment variables
ENV TOOL_NAME=oss-cad-suite
ENV GITHUB_API_URL=https://api.github.com/repos/YosysHQ/oss-cad-suite-build/releases/latest
ENV TARGET_PLATFORM=linux-x64

# Fetch the latest release URL for the specified platform and download the asset
RUN RELEASE_URL=$(curl -sL ${GITHUB_API_URL} \
    | jq -r --arg PLATFORM "$TARGET_PLATFORM" '.assets[] | select(.name | contains($PLATFORM)).browser_download_url') \
    && [ -n "$RELEASE_URL" ] \
    && echo "Downloading $RELEASE_URL" \
    && curl -L -o $TOOL_NAME.tar.gz $RELEASE_URL \
    && mkdir -p /opt/$TOOL_NAME \
    && tar -xvzf $TOOL_NAME.tar.gz -C /opt/$TOOL_NAME --strip-components=1 \
    && rm $TOOL_NAME.tar.gz

ENV PATH="/opt/$TOOL_NAME/bin:${PATH}"

# Install Cocotb
RUN python3 -m pip install --upgrade pip setuptools && \
    python3 -m pip install cocotb


# Configure SSH server
RUN mkdir /var/run/sshd && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    echo 'X11Forwarding yes' >> /etc/ssh/sshd_config && \
    echo 'X11UseLocalhost no' >> /etc/ssh/sshd_config

# Set up default user for SSH access with a password
RUN useradd -rm -d /home/dev -s /bin/bash -g root -G sudo -u 1001 dev && \
    echo 'dev:dev' | chpasswd && \
    mkdir /home/dev/.ssh && \
    chmod 700 /home/dev/.ssh

# Expose SSH port
EXPOSE 22

# Set USER environment variable for VNC
ENV USER=dev

# Change to default user
USER dev
WORKDIR /home/dev

# Configure VNC server
RUN mkdir -p /home/dev/.vnc && \
    touch /home/dev/.Xauthority && \
    echo "dev" | vncpasswd -f > /home/dev/.vnc/passwd && \
    chmod 700 /home/dev/.vnc && \
    chmod 600 /home/dev/.vnc/passwd && \
    echo "startxfce4 &" > /home/dev/.vnc/xstartup && \
    chmod +x /home/dev/.vnc/xstartup

# Expose VNC port
EXPOSE 5901

# Add Supervisor configuration
USER root
RUN mkdir -p /etc/supervisor/conf.d
COPY supervisord.conf /etc/supervisor/supervisord.conf

# Start Supervisor to manage both VNC and SSH servers
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
