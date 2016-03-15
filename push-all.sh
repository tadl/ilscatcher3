#!/bin/bash

printf "*** WARNING ***\nThis will push to all remotes. Type 'yes' to proceed: "

read input

if [ $input == "yes" ]; then
    for x in `git remote`; do
        echo "Pushing to ${x}"
        git push ${x}
    done
else
    echo "Okay then."
fi
