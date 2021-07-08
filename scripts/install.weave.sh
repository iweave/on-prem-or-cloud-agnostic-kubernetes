#!/bin/bash

echo "installing weave"
curl -L git.io/weave -o /usr/local/bin/weave
chmod a+x /usr/local/bin/weave

echo "prepull images"
weave setup
