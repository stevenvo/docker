# ARG PYTHON_IMAGE_TAG=3.8.2-buster
ARG PYTHON_IMAGE_TAG=2.7-slim-buster

FROM buildpack-deps:curl AS ffmpeg
RUN apt-get update && apt-get install -y xz-utils
RUN curl -fsSLO https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-i686-static.tar.xz \
  && mkdir -p /opt \
  && tar -xJf ffmpeg-release-i686-static.tar.xz --strip-components=1 -C /opt


FROM python:${PYTHON_IMAGE_TAG} AS cura-compiler

ARG CURA_VERSION
ENV CURA_VERSION ${CURA_VERSION:-15.04.6}

RUN apt-get update && apt-get install -y g++ make curl
RUN curl -fsSLO https://github.com/Ultimaker/CuraEngine/archive/${CURA_VERSION}.tar.gz \
  && mkdir -p /opt \
  && tar -xzf ${CURA_VERSION}.tar.gz --strip-components=1 -C /opt --no-same-owner
WORKDIR /opt
RUN make

# build ocotprint
FROM python:${PYTHON_IMAGE_TAG} AS compiler

ARG tag
ENV tag ${tag:-master}

RUN apt-get update && apt-get install -y make g++ curl

RUN	curl -fsSLO --compressed --retry 3 --retry-delay 10 \
  https://github.com/foosel/OctoPrint/archive/${tag}.tar.gz \
	&& mkdir -p /opt/venv \
  && tar xzf ${tag}.tar.gz --strip-components 1 -C /opt/venv --no-same-owner

#install venv            
RUN pip install virtualenv
RUN python -m virtualenv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
WORKDIR /opt/venv
RUN python setup.py install


FROM python:${PYTHON_IMAGE_TAG} AS build
LABEL description="The snappy web interface for your 3D printer"
LABEL authors="longlivechief <chief@hackerhappyhour.com>, badsmoke <dockerhub@badcloud.eu>"
LABEL issues="github.com/OcotPrint/docker/issues"
# Install sudo, setup permission
RUN groupadd --gid 1000 octoprint 
RUN useradd --uid 1000 --gid octoprint -G dialout,sudo --shell /bin/bash --create-home octoprint
RUN apt-get update
RUN apt-get -y install sudo procps net-tools nano git wget
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers


# Create user
# RUN useradd -G dialout,sudo --shell /bin/bash --create-home klippy
USER octoprint
#This fixes issues with the volume command setting wrong permissions
RUN mkdir /home/octoprint/.config
VOLUME /home/octoprint/.config

### Klipper setup ###
WORKDIR /home/octoprint
RUN git clone https://github.com/KevinOConnor/klipper
COPY . klipper/
USER root
RUN chown octoprint:octoprint -R klipper
RUN su - octoprint -c ./klipper/scripts/install-octopi.sh
USER octoprint

USER root
#Install Octoprint, ffmpeg, and cura engine
COPY --from=compiler /opt/venv /opt/venv
COPY --from=ffmpeg /opt /opt/ffmpeg
COPY --from=cura-compiler /opt /opt/cura

# setup path
RUN chown -R octoprint:octoprint /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

EXPOSE 5000
COPY docker-entrypoint.sh /usr/local/bin/
USER octoprint
VOLUME /home/octoprint
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["octoprint", "serve"]

WORKDIR /home/octoprint
RUN git clone https://github.com/stevenvo/klipper-printer-cfg-files
VOLUME /home/octoprint/klipper-printer-cfg-files