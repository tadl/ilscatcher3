#!/bin/bash

# This script will add remotes for all currently provisioned apps on
# the dokku server. It is recommend to remove all remotes other than
# origin before running this script.

for x in $(git remote | grep -v origin); do
    git remote remove ${x}
done

# tadl
git remote add tadl dokku@apps.tadl.org:tadl

# contract libraries
git remote add kcl dokku@apps.tadl.org:kcl
git remote add kclyouth dokku@apps.tadl.org:kclyouth
git remote add kclteen dokku@apps.tadl.org:kclteen
git remote add sbbdl dokku@apps.tadl.org:sbbdl
git remote add kps dokku@apps.tadl.org:kps

# dev
#git remote add test dokku@apps.tadl.org:test
