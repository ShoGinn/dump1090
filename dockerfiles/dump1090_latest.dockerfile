# Base Image ##################################################################
FROM alpine as base

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


ARG DUMP1090_VERSION=v3.8.0
ARG DUMP1090_GIT_HASH=c3541bcbeac0c6a83b50b988e503b49a349a40ad
ARG DUMP1090_TAR_HASH=cf1320cbfe3cd2aa110ebf4ac86a12df7d1b9b1b1f7bca5c0f423c4d5920f3af

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
