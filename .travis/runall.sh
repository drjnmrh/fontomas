#!/bin/bash

set -ev

if [ "$PLATFORM" == "linux" ]; then
    export CXX=$COMPILER
    ${CXX} --version
fi

if [ "$TRAVIS_BRANCH" == "develop" ]; then
    ./mk $PLATFORM --develop
else
    ./mk $PLATFORM
fi
