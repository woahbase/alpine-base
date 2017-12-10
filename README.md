[![Build Status](https://travis-ci.org/woahbase/alpine-base.svg?branch=master)](https://travis-ci.org/woahbase/alpine-base)

[![](https://images.microbadger.com/badges/image/woahbase/alpine-base.svg)](https://microbadger.com/images/woahbase/alpine-base)

[![](https://images.microbadger.com/badges/commit/woahbase/alpine-base.svg)](https://microbadger.com/images/woahbase/alpine-base)

[![](https://images.microbadger.com/badges/version/woahbase/alpine-base.svg)](https://microbadger.com/images/woahbase/alpine-base)

## Alpine-Base
#### Container for Alpine Linux Base Builds

---

This [image][5] serves as the base rootfs container for [Alpine Linux][8].
Built from scratch using the minirootfs image from [here][9].

The image is tagged respectively for 2 architectures,
* **armhf**
* **x86_64**

---
#### Get the Image
---

Pull the image for your architecture it's already available from
Docker Hub.

```
# make pull
docker pull woahbase/alpine-base:x86_64

```

---
#### Run
---

```
# make
docker run --rm -it \
  --name docker_base --hostname base \
  woahbase/alpine-base:x86_64

# make stop
docker stop -t 2 docker_base

# make rm
# stop first
docker rm -f docker_base

# make restart
docker restart docker_base

```

---
#### Shell access
---

```
# make rshell
docker exec -u root -it docker_base /bin/bash

# make shell
docker exec -it docker_base /bin/bash

# make logs
docker logs -f docker_base

```

---
## Development
---

If you have the repository access, you can clone and
build the image yourself for your own system, and can push after.

---
#### Setup
---

Before you clone the repo, you must have [Git][1], [GNU make][2],
and [Docker][3] setup on the machine.

```
git clone <repository url>
cd <repository>

```
You can always skip installing **make** but you will have to
type the whole docker commands then instead of using the sweet
make targets.

---
#### Build
---

To locally build the image for your system.

```
# make build
# fetches latest minirootfs
docker build --rm --force-rm \
  -t woahbase/alpine-base:x86_64 \
  --no-cache=true .

# make push
docker push woahbase/alpine-base:x86_64

```

---
## Maintenance
---

Built daily at Travis.CI (armhf / x64 builds). Docker hub builds maintained by [woahbase][4].

[1]: https://git-scm.com
[2]: https://www.gnu.org/software/make/
[3]: https://www.docker.com
[4]: https://hub.docker.com/u/woahbase

[5]: https://hub.docker.com/r/woahbase/alpine-base
[8]: https://alpinelinux.org/
[9]: http://dl-4.alpinelinux.org/alpine/latest-stable/releases/
