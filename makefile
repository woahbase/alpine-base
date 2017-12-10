# {{{ -- meta

ARCH      := $(shell uname -m | sed "s_armv7l_armhf_")# armhf/x86_64 auto-detect on build
OPSYS     := alpine
SHCOMMAND := /bin/bash
SVCNAME   := base
USERNAME  := woahbase
VERSION   := 3.7.0

IMAGETAG  := $(USERNAME)/$(OPSYS)-$(SVCNAME):$(ARCH)

# -- }}}

# {{{ -- flags

BUILDFLAGS := --rm --force-rm -t $(IMAGETAG)
CACHEFLAGS := --no-cache=true --pull
MOUNTFLAGS := #
NAMEFLAGS  := --name docker_$(SVCNAME) --hostname $(SVCNAME)
OTHERFLAGS := # -v /etc/hosts:/etc/hosts:ro -v /etc/localtime:/etc/localtime:ro -e TZ=Asia/Kolkata
PORTFLAGS  := #
PROXYFLAGS := --build-arg http_proxy=$(http_proxy) --build-arg https_proxy=$(https_proxy) --build-arg no_proxy=$(no_proxy)

RUNFLAGS   := -c 64 -m 32m # -e PGID=$(shell id -g) -e PUID=$(shell id -u)

# -- }}}

# {{{ -- docker targets

all : run

build : fetch
	docker build $(BUILDFLAGS) $(CACHEFLAGS) $(PROXYFLAGS) .

clean :
	rm -rf $(CURDIR)/data
	docker rmi $(IMAGETAG)

logs :
	docker logs -f docker_$(SVCNAME)

pull :
	docker pull $(IMAGETAG)

push :
	docker push $(IMAGETAG)

restart :
	docker ps -a | grep 'docker_$(SVCNAME)' -q && docker restart docker_$(SVCNAME) || echo "Service not running.";

rm : stop
	docker rm -f docker_$(SVCNAME)

run :
	docker run --rm -it $(NAMEFLAGS) $(RUNFLAGS) $(PORTFLAGS) $(MOUNTFLAGS) $(OTHERFLAGS) $(IMAGETAG)

rshell :
	docker exec -u root -it docker_$(SVCNAME) $(SHCOMMAND)

shell :
	docker exec -it docker_$(SVCNAME) $(SHCOMMAND)

stop :
	docker stop -t 2 docker_$(SVCNAME)

test :
	docker run --rm -it $(NAMEFLAGS) $(RUNFLAGS) $(PORTFLAGS) $(MOUNTFLAGS) $(OTHERFLAGS) -u root $(IMAGETAG) uname -a

# -- }}}

# {{{ -- other targets

fetch :
	mkdir -p data && cd data \
		&& curl \
		-o ./rootfs.tar.gz -SL https://nl.alpinelinux.org/alpine/latest-stable/releases/$(ARCH)/alpine-minirootfs-$(VERSION)-$(ARCH).tar.gz \
		&& gunzip -f ./rootfs.tar.gz;

# -- }}}
