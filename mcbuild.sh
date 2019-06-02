#!/bin/bash
#build latest rev'd spiggot using BuildTools
#https://hub.spigotmc.org/jenkins/job/BuildTools/

#TODO: check and see if new BuildTools.jar is availble and download it

PATH=~/jre1.8.0_161/bin:$PATH

java -jar BuildTools.jar --rev 1.14.2
