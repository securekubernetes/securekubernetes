FROM alpine:latest

ENV MKDOCS_VERSION="1.0.4"

RUN \
    apk add --no-cache --update \
        ca-certificates \
        git \
        git-fast-import \
        openssh-client \
        python2 \
        python2-dev \
        py-setuptools; \
    easy_install-2.7 pip && \
    pip install mkdocs==${MKDOCS_VERSION} && \
    pip install mkdocs-material && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*

WORKDIR /data

EXPOSE 8080

ENTRYPOINT ["mkdocs"]
