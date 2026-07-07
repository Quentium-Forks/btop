#!/bin/bash

rm -rf build

cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug -DBTOP_GPU=ON -DBUILD_TESTING=OFF
cmake --build build -j $(nproc)

./build/btop
