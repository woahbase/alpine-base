# {{{ -- meta

HOSTARCH  := $(shell uname -m | sed "s_armv7l_armhf_")#
QEMUVERS  := v2.9.1-1#
ARCH      := x86_64# $(shell uname -m | sed "s_armv7l_armhf_")# armhf/x86_64 auto-detect on build
OPSYS     := alpine
SHCOMMAND := /bin/bash
SVCNAME   := base
USERNAME  := woahbase
VERSION   := 3.7.0

DOCKEREPO := $(USERNAME)/$(OPSYS)-$(SVCNAME)
IMAGETAG  := $(DOCKEREPO):$(ARCH)

# -- }}}

# {{{ -- flags

BUILDFLAGS := --rm --force-rm -f $(CURDIR)/Dockerfile_$(ARCH) -t $(IMAGETAG) \
	--build-arg VCS_REF=$(shell git rev-parse --short HEAD) \
	--build-arg BUILD_DATE=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

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
	echo "Building for $(ARCH) from $(HOSTARCH)";
	[[ "$(ARCH)" = "armhf" ]] && (make regbinfmt fetchqemu) || true;
	docker build $(BUILDFLAGS) $(CACHEFLAGS) $(PROXYFLAGS) .

clean :
	[[ -d $(CURDIR)/data ]] && rm -rf $(CURDIR)/data || true;
	docker images | awk '(NR>1) && ($$2!~/none/) {print $$1":"$$2}' | grep $(DOCKEREPO) | xargs -n1 docker rmi

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
	docker run --rm -it $(NAMEFLAGS) $(RUNFLAGS) $(PORTFLAGS) $(MOUNTFLAGS) $(OTHERFLAGS) $(IMAGETAG) bash --version

# -- }}}

# {{{ -- other targets

regbinfmt :
	docker run --rm --privileged multiarch/qemu-user-static:register --reset

fetch :
	mkdir -p data && cd data \
	&& curl \
		-o ./rootfs.tar.gz -SL https://nl.alpinelinux.org/alpine/latest-stable/releases/$(ARCH)/alpine-minirootfs-$(VERSION)-$(ARCH).tar.gz \
		&& gunzip -f ./rootfs.tar.gz;

fetchqemu :
	mkdir -p data && \
	QEMU_ARCH="$$(echo $(ARCH) | sed 's_armhf_arm_')" \
	&& curl \
		-o ./data/$(HOSTARCH)_qemu-$${QEMU_ARCH}-static.tar.gz -SL https://github.com/multiarch/qemu-user-static/releases/download/${QEMUVERS}/$(HOSTARCH)_qemu-$${QEMU_ARCH}-static.tar.gz \
		&& tar xv -C data/ -f ./data/$(HOSTARCH)_qemu-$${QEMU_ARCH}-static.tar.gz;

# -- }}}
