#!/bin/sh

mkdir build || echo "build directory already exists"
cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
cmake --build ..
cpack
cd ..
