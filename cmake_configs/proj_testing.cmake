#Licensed under the MIT license. See LICENSE file in the project root for full license information.

function(add_unittest_directory whatIsBuilding)
    if (${bit_convoy_ut})
        add_subdirectory(${whatIsBuilding})
    endif()
endfunction(add_unittest_directory)

function(build_test_project whatIsBuilding folder)
    add_definitions(-DUSE_MEMORY_DEBUG_SHIM)

    set(test_include_dir ${MICROMOCK_INC_FOLDER} ${TESTRUNNERSWITCHER_INC_FOLDER} ${CTEST_INC_FOLDER} ${UMOCK_C_INC_FOLDER})
    set(logging_files ${CMAKE_SOURCE_DIR}/deps/lib-util-c/src/app_logging.c)
    include_directories(${test_include_dir})

    if (WIN32)
        add_definitions(-DUNICODE)
        add_definitions(-D_UNICODE)
        #windows needs this define
        add_definitions(-D_CRT_SECURE_NO_WARNINGS)

        set_target_properties(${whatIsBuilding} PROPERTIES LINKER_LANGUAGE CXX)
        set_target_properties(${whatIsBuilding} PROPERTIES FOLDER ${folder})
    else()
        find_program(MEMORYCHECK_COMMAND valgrind)
        set(MEMORYCHECK_COMMAND_OPTIONS "--trace-children=yes --leak-check=full" )
    endif()

    add_executable(${whatIsBuilding}_exe
        ${${whatIsBuilding}_test_files}
        ${${whatIsBuilding}_cpp_files}
        ${${whatIsBuilding}_h_files}
        ${${whatIsBuilding}_c_files}
        ${CMAKE_CURRENT_LIST_DIR}/main.c
        ${logging_files}
    )
    compileTargetAsC99(${whatIsBuilding}_exe)

    set_target_properties(${whatIsBuilding}_exe
            PROPERTIES
            FOLDER ${folder})

    target_compile_definitions(${whatIsBuilding}_exe PUBLIC -DUSE_CTEST)
    target_include_directories(${whatIsBuilding}_exe PUBLIC ${include_dir})

    target_link_libraries(${whatIsBuilding}_exe umock_c ctest m)

    if (${ENABLE_COVERAGE})
        set_target_properties(${whatIsBuilding}_exe PROPERTIES COMPILE_FLAGS "-fprofile-arcs -ftest-coverage")
        target_link_libraries(${whatIsBuilding}_exe gcov)
        set(CMAKE_CXX_OUTPUT_EXTENSION_REPLACE 1)
    endif()

    add_test(NAME ${whatIsBuilding} COMMAND $<TARGET_FILE:${whatIsBuilding}_exe>)
endfunction()

function(enable_coverage_testing)
    if (${ENABLE_COVERAGE})
        find_program(GCOV_PATH gcov)
        if(NOT GCOV_PATH)
            message(FATAL_ERROR "gcov not found! Aborting...")
        endif() # NOT GCOV_PATH
    endif()
endfunction()

macro(set_default_build_options)
    # Make sure we have a runtime output directory always set
    if (NOT CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG)
        set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG ${CMAKE_BINARY_DIR}/Debug)
    endif()
    if (NOT CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE)
        set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE ${CMAKE_BINARY_DIR}/Release)
    endif()
    if (NOT CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO)
        set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO ${CMAKE_BINARY_DIR}/RelWithDebInfo)
    endif()
    if (NOT CMAKE_RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL)
        set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL ${CMAKE_BINARY_DIR}/MinSizeRel)
    endif()

    # System-specific compiler flags
    if(MSVC)
        #use _CRT_SECURE_NO_WARNINGS by default
        add_definitions(-D_CRT_SECURE_NO_WARNINGS)

        # warning C4200: nonstandard extension used: zero-sized array in struct/union : looks very standard in C99 and it is called flexible array. Documentation-wise is a flexible array, but called "unsized" in Microsoft's docs
        # https://msdn.microsoft.com/en-us/library/b6fae073.aspx
        # /WX is "treats all compiler warnings as error". (https://docs.microsoft.com/en-us/cpp/build/reference/compiler-option-warning-level?view=vs-2019)
        # /bigobj is "increase number of sections in .obj file" (https://docs.microsoft.com/en-us/cpp/build/reference/bigobj-increase-number-of-sections-in-dot-obj-file?view=vs-2019)
        # /W4 displays level 1, level 2, and level 3 warnings, and all level 4 (informational) warnings that aren't off by default. (https://docs.microsoft.com/en-us/cpp/build/reference/compiler-option-warning-level?view=msvc-160)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /W4 /WX /wd4200 /bigobj")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /W4 /WX /wd4200 /bigobj")

        if(${CMAKE_GENERATOR} STREQUAL "Visual Studio 15 2017")
            #do nothing about preprocesor - automatically for C/C++ the "traditional preprocessor will be used
        else()
            #for what we suppose it is VS 2019 and forward, use the conformant preprocessor
            # /Zc:preprocessor means using the "conformant" (similar to gcc/clang) rather than the "traditional" preprocessor which is Microsoft's invention (https://docs.microsoft.com/en-us/cpp/build/reference/zc-preprocessor?view=vs-2019)
            # /wd5105 avoids in winbase.h "warning C5105: macro expansion producing 'defined' has undefined behavior" around #define MICROSOFT_WINDOWS_WINBASE_H_DEFINE_INTERLOCKED_CPLUSPLUS_OVERLOADS (_WIN32_WINNT >= 0x0502 || !defined(_WINBASE_)). Note how the macro expands to something that contains "defined"
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /Zc:preprocessor /wd5105")
            set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /Zc:preprocessor /wd5105")
        endif()


        # replace other warning levels (just in case - CMake used to add /W3 in previous versions, in 3.18 magically has /W1 for projects) with /W4 (warning level 4)
        string(REGEX REPLACE "/W[1-3]" "/W4" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
        string(REGEX REPLACE "/W[1-3]" "/W4" CMAKE_C_FLAGS "${CMAKE_C_FLAGS}")

    elseif(UNIX) #LINUX OR APPLE
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror -g")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Werror -g")
    endif()

    if(${run_valgrind} OR ${run_helgrind} OR ${run_drd})
        add_definitions(-DUSE_VALGRIND)
    endif()

    if (WIN32)
        if (${use_segment_heap})
            if (CMAKE_GENERATOR MATCHES "Visual Studio")
                set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /MANIFEST:EMBED /MANIFESTINPUT:${build_c_tests_internal_dir}/manifest.xml")
                #link.exe complains in the presence of both /MANIFESTFILE and /MANIFESTINPUT
                string(REGEX REPLACE "/MANIFESTFILE" "" CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS}")

                set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} /MANIFEST:EMBED /MANIFESTINPUT:${build_c_tests_internal_dir}/manifest.xml")
                #link.exe complains in the presence of both /MANIFESTFILE and /MANIFESTINPUT
                string(REGEX REPLACE "/MANIFESTFILE" "" CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS}")
            else()
                message(WARNING "Building with some other generator than Visual Studio, will not embed manifest! If you need to use segment heap then use Visual Studio!")
            endif()
        endif()

        set(CMAKE_EXE_LINKER_FLAGS "/INCREMENTAL:NO ${CMAKE_EXE_LINKER_FLAGS} /LTCG /IGNORE:4075 /WX")
        set(CMAKE_SHARED_LINKER_FLAGS "/INCREMENTAL:NO ${CMAKE_SHARED_LINKER_FLAGS} /LTCG /IGNORE:4075 /WX")
        set(CMAKE_STATIC_LINKER_FLAGS "${CMAKE_STATIC_LINKER_FLAGS} /WX")

        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /GL")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /GL")
    endif()

    enable_testing()
endmacro()
