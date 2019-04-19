ARG BASE=alpine

# Base Image ##################################################################
FROM $BASE as base

ARG arch=none
ENV ARCH=$arch

COPY qemu/qemu-$ARCH-static* /usr/bin/

RUN cat /etc/apk/repositories && \
    echo '@edge http://nl.alpinelinux.org/alpine/edge/main' >> /etc/apk/repositories && \
    echo '@testing http://nl.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories && \
    cat /etc/apk/repositories && \
    apk add --no-cache tini librtlsdr@testing libusb ncurses-libs


# Builder Image ###############################################################
FROM base as builder

RUN apk add --no-cache \
        curl ca-certificates \
        coreutils make gcc pkgconf \
        libc-dev librtlsdr-dev@testing libusb-dev ncurses-dev


ARG DUMP1090_VERSION=v3.7.0.1
ARG DUMP1090_GIT_HASH=883399cee3bc7e6c990b1b706537fa2673900696
ARG DUMP1090_TAR_HASH=b21803c32d10a059122d1206f96592a94e4470717097c7cc5f07eb0cd9ea2646


RUN curl -L --output 'dump1090-fa.tar.gz' "https://github.com/flightaware/dump1090/archive/${DUMP1090_GIT_HASH}.tar.gz" && \
    sha256sum dump1090-fa.tar.gz && echo "${DUMP1090_TAR_HASH}  dump1090-fa.tar.gz" | sha256sum -c
RUN mkdir dump1090 && cd dump1090 && \
    tar -xvf ../dump1090-fa.tar.gz --strip-components=1
WORKDIR dump1090
RUN make BLADERF=NO DUMP1090_VERSION="${DUMP1090_VERSION}"
RUN make test


# Final Image #################################################################
FROM base

COPY --from=builder /dump1090/dump1090 /usr/local/bin/dump1090

# Raw output
EXPOSE 30002/tcp
# Beast output
EXPOSE 30005/tcp

ENTRYPOINT ["tini", "--", "nice", "-n", "-5", "dump1090", "--net", "--net-bind-address", "0.0.0.0", "--debug", "n", "--mlat", "--net-heartbeat", "5", "--quiet", "--stats-every", "60"]

# Metadata
ARG VCS_REF="Unknown"
LABEL maintainer="ginnserv@gmail.com" \
      org.label-schema.name="Docker ADS-B - dump1090" \
      org.label-schema.description="Docker container for ADS-B - This is the flightaware dump1090 component" \
      org.label-schema.url="https://github.com/ShoGinn/dump1090" \
      org.label-schema.vcs-ref="${VCS_REF}" \
      org.label-schema.vcs-url="https://github.com/ShoGinn/dump1090" \
      org.label-schema.schema-version="1.0"

