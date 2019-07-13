# {{{ -- meta

HOSTARCH  := $(shell uname -m | sed "s_armv6l_armhf_")# x86_64# on travis.ci
ARCH      := $(shell uname -m | sed "s_armv6l_armhf_")# armhf/x86_64 auto-detect on build and run
OPSYS     := alpine
SHCOMMAND := /bin/bash
SVCNAME   := base
USERNAME  := woahbase
OSVERSION := 3.10.1

DOCKERSRC := scratch
DOCKEREPO := $(OPSYS)-$(SVCNAME)
IMAGETAG  := $(USERNAME)/$(DOCKEREPO):$(ARCH)

CNTNAME   := $(SVCNAME) # name for container name : docker_name, hostname : name

BUILD_NUMBER := 0#assigned in .travis.yml
BRANCH       := master

# -- }}}

# {{{ -- flags

BUILDFLAGS := --rm --force-rm --compress \
	-f $(CURDIR)/Dockerfile_$(ARCH) \
	-t $(IMAGETAG) \
	--build-arg DOCKERSRC=$(DOCKERSRC) \
	--build-arg http_proxy=$(http_proxy) \
	--build-arg https_proxy=$(https_proxy) \
	--build-arg no_proxy=$(no_proxy) \
	--label online.woahbase.source-image=$(DOCKERSRC) \
	--label online.woahbase.build-number=$(BUILD_NUMBER) \
	--label online.woahbase.branch=$(BRANCH) \
	--label org.label-schema.build-date=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ") \
	--label org.label-schema.name=$(DOCKEREPO) \
	--label org.label-schema.schema-version="1.0" \
	--label org.label-schema.url="https://woahbase.online/" \
	--label org.label-schema.usage="https://woahbase.online/\#/images/$(DOCKEREPO)" \
	--label org.label-schema.vcs-ref=$(shell git rev-parse --short HEAD) \
	--label org.label-schema.vcs-url="https://github.com/$(USERNAME)/$(DOCKEREPO)" \
	--label org.label-schema.vendor=$(USERNAME)

CACHEFLAGS := --no-cache=true --pull
MOUNTFLAGS := #
NAMEFLAGS  := --name docker_$(CNTNAME) --hostname $(CNTNAME)
OTHERFLAGS := # -v /etc/hosts:/etc/hosts:ro -v /etc/localtime:/etc/localtime:ro -e TZ=Asia/Kolkata
PORTFLAGS  := #

RUNFLAGS   := -c 64 -m 32m 

# -- }}}

# {{{ -- docker targets

all : run

build : fetch
	echo "Building for $(ARCH) from $(HOSTARCH)";
	if [ "$(ARCH)" != "$(HOSTARCH)" ]; then make regbinfmt fetchqemu; fi;
	docker build $(BUILDFLAGS) $(CACHEFLAGS) .

clean :
	if [ -d $(CURDIR)/data ]; then rm -rf $(CURDIR)/data; fi;
	docker images | awk '(NR>1) && ($$2!~/none/) {print $$1":"$$2}' | grep $(USERNAME)/$(DOCKEREPO) | xargs -n1 docker rmi

logs :
	docker logs -f docker_$(CNTNAME)

pull :
	docker pull $(IMAGETAG)

push :
	docker push $(IMAGETAG);
	if [ "$(ARCH)" = "$(HOSTARCH)" ]; \
	then \
		LATESTTAG=$$(echo $(IMAGETAG) | sed 's/:$(ARCH)/:latest/'); \
		docker tag $(IMAGETAG) $${LATESTTAG}; \
		docker push $${LATESTTAG}; \
	fi;
	VERSIONTAG=$$(echo $(IMAGETAG)_$(OSVERSION)); \
	if [ "$$(docker pull $${VERSIONTAG} 1>/dev/null 2>&1 && echo 'exists' || echo 'doesnotexist')" = "doesnotexist" ]; \
	then \
		docker tag $(IMAGETAG) $${VERSIONTAG}; \
		docker push $${VERSIONTAG}; \
	fi;

restart :
	docker ps -a | grep 'docker_$(CNTNAME)' -q && docker restart docker_$(CNTNAME) || echo "Service not running.";

rm :
	docker rm -f docker_$(CNTNAME)

run : shell

shell :
	docker run --rm -it $(NAMEFLAGS) $(RUNFLAGS) $(PORTFLAGS) $(MOUNTFLAGS) $(OTHERFLAGS) $(IMAGETAG) $(SHCOMMAND)

rdebug :
	docker exec -u root -it docker_$(CNTNAME) $(SHCOMMAND)

debug :
	docker exec -it docker_$(CNTNAME) $(SHCOMMAND)

stop :
	docker stop -t 2 docker_$(CNTNAME)

test :
	docker run --rm -it $(NAMEFLAGS) $(RUNFLAGS) $(PORTFLAGS) $(MOUNTFLAGS) $(OTHERFLAGS) $(IMAGETAG) bash -ec 'uname -a; bash --version'

# -- }}}

# {{{ -- other targets

regbinfmt :
	docker run --rm --privileged multiarch/qemu-user-static:register --reset

fetch :
	mkdir -p data && cd data \
	&& OSARCH="$$(echo $(ARCH) | sed -e 's_armv7l_armv7_')" \
	&& OSVERSION="$$(echo $(OSVERSION))" \
	&& OSVESHORT="$$(v=$(OSVERSION); echo $${v%.*}; unset v;)" \
	&& echo "Using os arch   : "$${OSARCH} \
	&& echo "Using os version: "$${OSVERSION} \
	&& curl \
		-o ./rootfs.tar.gz \
		-jkSL https://nl.alpinelinux.org/alpine/v$${OSVESHORT}/releases/$${OSARCH}/alpine-minirootfs-$(OSVERSION)-$${OSARCH}.tar.gz \
		&& gunzip -f ./rootfs.tar.gz; \
		# -jkSL https://nl.alpinelinux.org/alpine/latest-stable/releases/$${OSARCH}/alpine-minirootfs-$(OSVERSION)-$${OSARCH}.tar.gz \
		#

fetchqemu :
	mkdir -p data \
	&& QEMUARCH="$$(echo $(ARCH) | sed -e 's_\(armhf\|armv7l\)_arm_')" \
	&& QEMUVERS="$$(curl -SL https://api.github.com/repos/multiarch/qemu-user-static/releases/latest | awk '/tag_name/{print $$4;exit}' FS='[""]')" \
	&& echo "Using qemu-user-static host arch   : "$(HOSTARCH) \
	&& echo "Using qemu-user-static target arch : "$${QEMUARCH} \
	&& echo "Using qemu-user-static version     : "$${QEMUVERS} \
	&& curl \
		-o ./data/$(HOSTARCH)_qemu-$${QEMUARCH}-static.tar.gz \
		-jkSL https://github.com/multiarch/qemu-user-static/releases/download/$${QEMUVERS}/$(HOSTARCH)_qemu-$${QEMUARCH}-static.tar.gz \
	&& tar xv -C data/ -f ./data/$(HOSTARCH)_qemu-$${QEMUARCH}-static.tar.gz;

# -- }}}
