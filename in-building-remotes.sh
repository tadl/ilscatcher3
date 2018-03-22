#!/bin/bash

# This script will add remotes for all currently provisioned apps on
# the dokku server. It is recommend to remove all remotes other than
# origin before running this script.

for x in $(git remote | grep -v origin); do
    git remote remove ${x}
done

git remote add traversecity dokku@opac.tadl.org:traversecity
git remote add traversecity-sightandsound dokku@opac.tadl.org:traversecity-sightandsound
git remote add traversecity-teen dokku@opac.tadl.org:traversecity-teen
git remote add traversecity-youth dokku@opac.tadl.org:traversecity-youth
git remote add eastbay dokku@opac.tadl.org:eastbay
git remote add fifelake dokku@opac.tadl.org:fifelake
git remote add interlochen dokku@opac.tadl.org:interlochen
git remote add interlochen-youth dokku@opac.tadl.org:interlochen-youth
git remote add kingsley dokku@opac.tadl.org:kingsley
git remote add peninsula dokku@opac.tadl.org:peninsula
git remote add test dokku@opac.tadl.org:test
