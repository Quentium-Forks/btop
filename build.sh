#!/bin/bash

rm -rf build

cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug -DBTOP_GPU=ON
cmake --build build -j $(nproc)

./build/btop
