#!/bin/bash

# This script will add remotes for all currently provisioned apps on
# the dokku server. It is recommend to remove all remotes other than
# origin before running this script.

git remote add eastbay dokku@apps.tadl.org:eastbay-catalog
git remote add fifelake dokku@apps.tadl.org:fifelake-catalog
git remote add ica dokku@apps.tadl.org:ica
git remote add interlochen dokku@apps.tadl.org:interlochen-catalog
git remote add interlochen-youth dokku@apps.tadl.org:interlochen-youth-catalog
git remote add kalkaska dokku@apps.tadl.org:kalkaska-catalog
git remote add kalkaska-teen dokku@apps.tadl.org:kalkaska-teen-catalog
git remote add kalkaska-youth dokku@apps.tadl.org:kalkaska-youth-catalog
git remote add kingsley dokku@apps.tadl.org:kingsley-catalog
git remote add peninsula dokku@apps.tadl.org:peninsula-catalog
git remote add tadl dokku@apps.tadl.org:catalog
git remote add test dokku@apps.tadl.org:test-catalog
git remote add woodmere dokku@apps.tadl.org:woodmere-catalog
git remote add woodmere-av dokku@apps.tadl.org:av-catalog
git remote add woodmere-youth dokku@apps.tadl.org:youth-catalog
git remote add sbbdl dokku@appstwo.tadl.org:sbbdl
git remote add ica-test dokku@apps.tadl.org:ica-test
