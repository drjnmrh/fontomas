#!/bin/bash

OLDWD=${PWD}

_mydir="$(cd "$(dirname "$0")" && pwd)"
cd $_mydir

cd ${OLDWD}
