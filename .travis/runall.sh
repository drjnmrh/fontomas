#!/bin/bash

set -ev
if [ "$TRAVIS_BRANCH" == "develop" ]; then
    ./mk $PLATFORM --develop
else
    ./mk $PLATFORM
fi
