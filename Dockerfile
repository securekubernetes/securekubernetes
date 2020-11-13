FROM alpine:3.12.1

ENV MKDOCS_VERSION="1.1.2"

RUN \
    apk add --no-cache --update \
        ca-certificates \
        git \
        git-fast-import \
        openssh-client \
        python3 \
        python3-dev \
        build-base \
        py3-wheel \
        py3-pip; \
    pip install mkdocs==${MKDOCS_VERSION} && \
    pip install mkdocs-material && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*

WORKDIR /data

EXPOSE 8080

ENTRYPOINT ["mkdocs"]
