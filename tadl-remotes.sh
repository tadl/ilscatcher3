#!/bin/bash

# This script will add remotes for all currently provisioned apps on
# the dokku server. It is recommend to remove all remotes other than
# origin before running this script.

for x in $(git remote | grep -v origin); do
    git remote remove ${x}
done

# public catalog
git remote add tadl dokku@apps.tadl.org:tadl

# opacs
git remote add ebb dokku@opacs.tadl.org:ebb
git remote add flpl dokku@opacs.tadl.org:flpl
git remote add ipl dokku@opacs.tadl.org:ipl
git remote add ipl-youth dokku@opacs.tadl.org:ipl-youth
git remote add kbl dokku@opacs.tadl.org:kbl
git remote add main dokku@opacs.tadl.org:main
git remote add main-reg dokku@opacs.tadl.org:main-reg
git remote add main-ss dokku@opacs.tadl.org:main-ss
git remote add main-teen dokku@opacs.tadl.org:main-teen
git remote add main-youth dokku@opacs.tadl.org:main-youth
git remote add pcl dokku@opacs.tadl.org:pcl
