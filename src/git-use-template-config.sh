#!/bin/bash

for dir in $(find . -maxdepth 1 -type d); do if [ -d $dir/.git ]; then d=${dir/\.\//}; cp default_config $d/.git/config; sed -i "s/{REPO_NAME}/${d}/g" $d/.git/config; fi; done
