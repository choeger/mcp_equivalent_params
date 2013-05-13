cmake_minimum_required (VERSION 2.8)
project (ModelicaEquivalenceMockup)

find_package(Boost 1.50 REQUIRED)
include_directories(${Boost_INCLUDE_DIR})

include_directories(src/cpp/)

add_library(equivalence SHARED src/cpp/equivalence.cpp)
