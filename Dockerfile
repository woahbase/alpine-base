FROM scratch

ADD data/rootfs.tar /

RUN apk add --no-cache --purge -uU bash && \
    rm -rf /var/cache/apk/* /tmp/*

CMD ["/bin/bash"]
