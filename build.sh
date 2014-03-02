#!/bin/bash

if [ ! -d build ]
then
  mkdir build
else
  rm -rf build/
fi

dmd "${@}" -defaultlib=phobos2 -fPIC -lib $(find 'src/' -type f -name '*.d') -ofbuild/libbot.a
