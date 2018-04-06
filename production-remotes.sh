#!/bin/bash

# This script will add remotes for all currently provisioned apps on
# the dokku server. It is recommend to remove all remotes other than
# origin before running this script.

for x in $(git remote | grep -v origin); do
    git remote remove ${x}
done

# tadl
git remote add tadl dokku@appstwo.tadl.org:tadl-catalog

# contract libraries
git remote add kcl dokku@appstwo.tadl.org:kalkaska-catalog
git remote add kcl-youth dokku@appstwo.tadl.org:kalkaska-youth
git remote add kcl-teen dokku@appstwo.tadl.org:kalkaska-teen
git remote add sbbdl dokku@appstwo.tadl.org:sbbdl
git remote add ica dokku@appstwo.tadl.org:ica

# dev
git remote add test dokku@appstwo.tadl.org:test
