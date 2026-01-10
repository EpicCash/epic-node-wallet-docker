# Multistage Docker build for Epic mainnet (latest Rust & Linux)

FROM rust:latest AS build
RUN apt-get update --fix-missing && \
    apt-get install --no-install-recommends -y \
        clang \
        libclang-dev \
        llvm-dev \
        cmake \
        git \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/EpicCash/epic.git
WORKDIR epic
RUN git submodule update --init --recursive
COPY . .
RUN cargo build --release

WORKDIR /
RUN git clone https://github.com/EpicCash/epic-wallet.git
WORKDIR epic-wallet
RUN git submodule update --init --recursive
COPY . .
RUN cargo build --release
#COPY --chown=epicsvcs:epicsvcs target/release/epic-wallet /home/epicsvcs/epic-wallet
#WORKDIR /
#RUN rm -R /epic
#RUN rm -R /epic-wallet

FROM ubuntu:24.04

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        sudo \
        cron \
        wget \
        git \
        unzip \
        screen \
        locales \
        openssl \
        sqlite3 \
        libncursesw6 \
#        nginx \
#        python3 \
#        certbot \
#        python3-certbot-nginx \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8  
ENV LANGUAGE=en_US:en
RUN locale-gen en_US.UTF-8

RUN useradd -u 1001 -G sudo -U -m -s /bin/bash epicsvcs \
  && echo "epicsvcs ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /home/epicsvcs

RUN sudo -u epicsvcs mkdir -p /home/epicsvcs/.epic/main

COPY --chown=epicsvcs:epicsvcs entrypoint.sh .
RUN chmod +x entrypoint.sh

COPY --from=build /epic/target/release/epic ./epic-node
COPY --from=build /epic-wallet/target/release/epic-wallet .

RUN chown epicsvcs:epicsvcs epic-node
RUN chown epicsvcs:epicsvcs epic-wallet

RUN chmod +x ./epic-node
RUN chmod +x ./epic-wallet

COPY --chown=epicsvcs:epicsvcs epic-server.toml .epic/main/epic-server.toml
COPY --chown=epicsvcs:epicsvcs epic-wallet.toml .epic/main/epic-wallet.toml

USER epicsvcs

RUN (echo "7 23 * * 2,4,6 screen -S epicnode -X quit && sleep 15 && /usr/bin/screen -dmS epicnode /home/epicsvcs/epic-node") | crontab -

EXPOSE 3413 3414

ENTRYPOINT ["/home/epicsvcs/entrypoint.sh"]

