FROM scratch

ARG BUILD_DATE
ARG VCS_REF

LABEL org.label-schema.schema-version="1.0" \
    org.label-schema.vcs-url="https://github.com/woahbase/alpine-base" \
    org.label-schema.name=alpine-base \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vendor=woahbase \

ADD data/rootfs.tar /

RUN apk add --no-cache --purge -uU bash && \
    rm -rf /var/cache/apk/* /tmp/*

CMD ["/bin/bash"]
