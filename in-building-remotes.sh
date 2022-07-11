#!/bin/bash

# This script will add remotes for all currently provisioned apps on
# the dokku server. It is recommend to remove all remotes other than
# origin before running this script.

for x in $(git remote | grep -v origin); do
    git remote remove ${x}
done

git remote add kclopac dokku@app.tadl.org:kclopac
git remote add kclteenopac dokku@app.tadl.org:kclteenopac
git remote add kclyouthopac dokku@app.tadl.org:kclyouthopac
git remote add sbbdl-light dokku@opac.tadl.org:sbbdl-light
git remote add ebb-light dokku@opac.tadl.org:ebb-light
git remote add flpl-light dokku@opac.tadl.org:flpl-light
git remote add ipl-light dokku@opac.tadl.org:ipl-light
git remote add ipl-youth-light dokku@opac.tadl.org:ipl-youth-light
git remote add kbl-light dokku@opac.tadl.org:kbl-light
git remote add pcl-light dokku@opac.tadl.org:pcl-light
git remote add tc-light dokku@opac.tadl.org:tc-light
git remote add tc-registration-light dokku@opac.tadl.org:tc-registration-light
git remote add tc-sightandsound-light dokku@opac.tadl.org:tc-sightandsound-light
git remote add tc-teen-light dokku@opac.tadl.org:tc-teen-light
git remote add tc-youth-light dokku@opac.tadl.org:tc-youth-light
git remote add kps-bse-light dokku@opac.tadl.org:kps-bse-light
git remote add kps-csi-light dokku@opac.tadl.org:kps-csi-light
git remote add kps-rce-light dokku@opac.tadl.org:kps-rce-light

git remote add ebb dokku@opacs.tadl.org:ebb
git remote add flpl dokku@opacs.tadl.org:flpl
git remote add ipl dokku@opacs.tadl.org:ipl
git remote add ipl-youth dokku@opacs.tadl.org:ipl-youth
git remote add kbl dokku@opacs.tadl.org:kbl
git remote add kcl dokku@opacs.tadl.org:kcl
git remote add kcl-teen dokku@opacs.tadl.org:kcl-teen
git remote add kcl-youth dokku@opacs.tadl.org:kcl-youth
git remote add kps-bse dokku@opacs.tadl.org:kps-bse
git remote add kps-csi dokku@opacs.tadl.org:kps-csi
git remote add kps-rce dokku@opacs.tadl.org:kps-rce
git remote add main dokku@opacs.tadl.org:main
git remote add main-reg dokku@opacs.tadl.org:main-reg
git remote add main-ss dokku@opacs.tadl.org:main-ss
git remote add main-teen dokku@opacs.tadl.org:main-teen
git remote add main-youth dokku@opacs.tadl.org:main-youth
git remote add pcl dokku@opacs.tadl.org:pcl
git remote add sbbdl dokku@opacs.tadl.org:sbbdl

