#!/bin/sh

cmake -DCMAKE_BUILD_TYPE=Release .
cmake --build .
cpack
