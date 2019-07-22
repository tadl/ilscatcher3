#!/bin/bash

# This script will add remotes for all currently provisioned apps on
# the dokku server. It is recommend to remove all remotes other than
# origin before running this script.

for x in $(git remote | grep -v origin); do
    git remote remove ${x}
done

# tadl
git remote add tadl dokku@app.tadl.org:tadl

# contract libraries
git remote add kcl dokku@app.tadl.org:kcl
git remote add kclyouth dokku@app.tadl.org:kclyouth
git remote add kclteen dokku@app.tadl.org:kclteen
git remote add sbbdl dokku@app.tadl.org:sbbdl
git remote add ica dokku@app.tadl.org:ica

# dev
#git remote add test dokku@app.tadl.org:test
