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

