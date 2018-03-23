#!/bin/bash

# This script will add remotes for all currently provisioned apps on
# the dokku server. It is recommend to remove all remotes other than
# origin before running this script.

for x in $(git remote | grep -v origin); do
    git remote remove ${x}
done

# legacy opacs. remove when all opacs are replaced
git remote add eastbay dokku@apps.tadl.org:eastbay-catalog
git remote add fifelake dokku@apps.tadl.org:fifelake-catalog
git remote add interlochen dokku@apps.tadl.org:interlochen-catalog
git remote add interlochen-youth dokku@apps.tadl.org:interlochen-youth-catalog
git remote add kingsley dokku@apps.tadl.org:kingsley-catalog
git remote add peninsula dokku@apps.tadl.org:peninsula-catalog
git remote add woodmere dokku@apps.tadl.org:woodmere-catalog
git remote add woodmere-youth dokku@apps.tadl.org:youth-catalog

# contract libraries
git remote add kalkaska dokku@apps.tadl.org:kalkaska-catalog
git remote add kalkaska-teen dokku@apps.tadl.org:kalkaska-teen-catalog
git remote add kalkaska-youth dokku@apps.tadl.org:kalkaska-youth-catalog
git remote add kcl dokku@appstwo.tadl.org:kalkaska-catalog
git remote add sbbdl dokku@appstwo.tadl.org:sbbdl
git remote add ica dokku@appstwo.tadl.org:ica

# tadl
git remote add tadl dokku@appstwo.tadl.org:tadl-catalog

# dev
git remote add test dokku@apps.tadl.org:test-catalog
