cmake_minimum_required(VERSION 3.16)

#Use solution folders.
set_property(GLOBAL PROPERTY USE_FOLDERS ON)
project(bit_convoy
    DESCRIPTION "Transfer bit from one place to another"
    LANGUAGES C)

SET(CMAKE_INCLUDE_CURRENT_DIR ON)
set(PROJECT_INC_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/inc)

#option(use_opengl "set the smartclock to run on opengl (default is OFF)" OFF)
option(bit_convoy_ut "Include unittest in build" OFF)
option(bit_convoy_samples "Include samples in build" OFF)

if (CMAKE_BUILD_TYPE MATCHES "Debug" AND NOT WIN32)
    set(DEBUG_CONFIG ON)
    set(ENABLE_COVERAGE ON)
    add_definitions(-DBIT_CONVOY_DEBUG)
else()
    set(ENABLE_COVERAGE OFF)
    set(DEBUG_CONFIG OFF)
endif()

set(CMAKE_POSITION_INDEPENDENT_CODE TRUE)

include("${PROJECT_SOURCE_DIR}/cmake_configs/proj_config.cmake")

# Setup dependencies
# Add dependencies
if ((NOT TARGET c_build_tools) AND (EXISTS ${CMAKE_CURRENT_LIST_DIR}/deps/c-build-tools/CMakeLists.txt))
    set(run_traceability OFF)
    set(build_traceability_tool OFF)
    add_subdirectory(deps/c-build-tools)
    set_default_build_options()
endif()
if (NOT TARGET macro_utils_c)
    add_subdirectory(${PROJECT_SOURCE_DIR}/deps/macro-utils-c)
endif()
include_directories(${MACRO_UTILS_INC_FOLDER})
if ((NOT TARGET c_logging) AND (EXISTS ${CMAKE_CURRENT_LIST_DIR}/deps/c-logging/CMakeLists.txt))
    add_subdirectory(${PROJECT_SOURCE_DIR}/deps/c-logging)
    include_directories(${PROJECT_SOURCE_DIR}/deps/c-logging/inc)
endif()
if (NOT TARGET umock_c)
    add_subdirectory(${PROJECT_SOURCE_DIR}/deps/umock-c)
    include_directories(${UMOCK_C_INC_FOLDER})
endif()
if (NOT TARGET lib-util-c)
    add_subdirectory(${PROJECT_SOURCE_DIR}/deps/lib-util-c)
    include_directories(${PROJECT_SOURCE_DIR}/deps/lib-util-c/inc/)
endif()
if (NOT TARGET patchcords)
    add_subdirectory(${PROJECT_SOURCE_DIR}/deps/patchcords)
    include_directories(${PROJECT_SOURCE_DIR}/deps/patchcords/inc)
endif()

include_directories(${PROJECT_SOURCE_DIR}/common/inc)

if (${bit_convoy_ut})

    include("${CMAKE_CURRENT_LIST_DIR}/cmake_configs/proj_testing.cmake")
    enable_coverage_testing()

    if ((NOT TARGET ctest) AND (EXISTS ${CMAKE_CURRENT_LIST_DIR}/deps/ctest/CMakeLists.txt))
        add_subdirectory(${PROJECT_SOURCE_DIR}/deps/ctest)
    endif()
    include_directories(${CTEST_INC_FOLDER})
    if ((NOT TARGET testrunnerswitcher) AND (EXISTS ${CMAKE_CURRENT_LIST_DIR}/deps/c-testrunnerswitcher/CMakeLists.txt))
        add_subdirectory(${PROJECT_SOURCE_DIR}/deps/c-testrunnerswitcher)
        include_directories(${TESTRUNNERSWITCHER_INC_FOLDER})
    endif()

    enable_testing()
    include (CTest)
endif()

add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/client)
