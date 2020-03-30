# OctoPrint-docker 

This is a remix from the original repo of [OctoPrint/docker](https://github.com/OctoPrint/docker) with extras:

* support 2 or more running containers (each associated with one printer via 1 USB connection): verified working on both my Ender3 and CR10s
* privleged mode to support accessing USB/Serial ports from each container
* support [klipper](https://www.klipper3d.org/) working isolated on each container

Since [Klipper](https://www.klipper3d.org/) only supports Py2, the Octoprint is also kept at Py2.7 (feel free to explore and post a pull request).


# Pre-requisites
Ensure docker and docker-compose are installed on your host. Some references:

* [How to install Docker on Raspberry Pi](https://phoenixnap.com/kb/docker-on-raspberry-pi)
* [How to install Docker Compose on Ubuntu](https://phoenixnap.com/kb/install-docker-compose-ubuntu)

# Getting started

**Create images**

```
git clone https://github.com/stevenvo/octoprint-docker && cd octoprint-docker

docker build -t octoprint:py2.7 .

# the above will take a while to complete building
```

**Spin up containers using the created image `octoprint:py2.7`**

```
docker-compose up -d

# you should see something like this:
# Creating network "octoprint-docker_default" with the default driver
# Creating cr10s  ... done
# Creating ender3 ... done

```
Verify Octoprint has been up and running for 2 printers by going to:

* http://yourHostOrIp:5000 
* http://yourHostOrIp:5001 

Proceed if you want to use Klipper, otherwise this is completed.

# For Klipper user

```
# Login to each container - note: `cr10s` is the container name
docker exec -it cr10s /bin/bash

nano printer.cfg
# and add your klipper config as usual
# make sure you update the serial port to the corresponding printer
# to search for serial port:
# ls /dev/serial/by-id

# once done, restart klipper service
sudo service klipper restart

# tail log to see if klipper service working
tail -f /tmp/klippy.log
```


# Additional tools

## mjpg-streamer (webcam access)

the matching mjpg-streamer container I have linked here with instruction:

https://hub.docker.com/r/badsmoke/mjpg-streamer


## FFMPEG

Octoprint allows you to make timelapses using an IP webcam and ffmpeg. It is installed in `/opt/ffmpeg/ffmpeg`

## Cura Engine

Octoprint allows you to import .STL files and slice them directly in the application. For this you need to upload the profiles that you want to use (you can export them from Cura). Cura Engine is installed in `/opt/cura/CuraEngine`.
