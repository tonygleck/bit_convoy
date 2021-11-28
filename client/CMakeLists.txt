#Licensed under the MIT license. See LICENSE file in the project root for full license information.

cmake_minimum_required(VERSION 3.5.0)

set(bit_convoy_client_include_files
    #${CMAKE_CURRENT_LIST_DIR}/inc/config_mgr.h
)
set(bit_convoy_client_src_files
    ${CMAKE_CURRENT_LIST_DIR}/src/client_main.c
)

add_executable(bit_convoy_client ${bit_convoy_client_include_files} ${bit_convoy_client_src_files})
#target_link_libraries(bit_convoy_client clock_util)

#bit_convoy_addCompileSettings(bit_convoy_client)
compileTargetAsC99(bit_convoy_client)

# Add testing
if (${bit_convoy_ut})

    #add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/tests)
endif()

