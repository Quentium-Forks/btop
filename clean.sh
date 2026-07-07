#!/bin/bash

rm -rf build
rm -rf release
find . -name CMakeFiles -exec rm -rf {} +
find . -name '*_autogen' -exec rm -rf {} +

find . -name cmake_install.cmake -delete
find . -name CMakeCache.txt -delete
find . -name Makefile -not -path './Makefile' -delete
