# the minimum version of CMake.
cmake_minimum_required(VERSION 3.5.0)
project(billReport)

add_library(billreport SHARED napi_init.cpp bill_report.cpp)

# 链接 NAPI 和 HiLog NDK 库
target_link_libraries(billreport PUBLIC
    libace_napi.z.so
    libhilog_ndk.z.so
)
