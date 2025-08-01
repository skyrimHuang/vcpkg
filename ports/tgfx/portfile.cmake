include("${CMAKE_CURRENT_LIST_DIR}/tgfx-functions.cmake")

vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
        OUT_SOURCE_PATH SOURCE_PATH
        REPO Tencent/tgfx
        REF de33316656ad7b5ab905731e6d03c4fc1315b466
        SHA512 c743716f2cb873cdb78e995302bc14cc36a43d006a046e0e09c558b0ede58cec40b7648b189499c072557006fa2002acb7b6d03aa041ed3405b677f2b7d5d912
        PATCHES
            disable-depsync.patch
)

parse_and_declare_deps_externals("${SOURCE_PATH}")

get_tgfx_externals("${SOURCE_PATH}")

vcpkg_cmake_get_vars(cmake_vars_file)
include("${cmake_vars_file}")

find_program(NODEJS
        NAMES node
        PATHS
        "${CURRENT_HOST_INSTALLED_DIR}/tools/node"
        "${CURRENT_HOST_INSTALLED_DIR}/tools/node/bin"
        ENV PATH
        NO_DEFAULT_PATH
)
if(NOT NODEJS)
    message(FATAL_ERROR "node not found! Please install it via your system package manager!")
endif()

get_filename_component(NODEJS_DIR "${NODEJS}" DIRECTORY )
vcpkg_add_to_path(PREPEND "${NODEJS_DIR}")

find_program(NINJA
        NAMES ninja
        PATHS
        "${CURRENT_HOST_INSTALLED_DIR}/tools/ninja"
        ENV PATH
        NO_DEFAULT_PATH
)
if(NOT NINJA)
    message(FATAL_ERROR "ninja not found! Please install it via your system package manager!")
endif()

get_filename_component(NINJA_DIR "${NINJA}" DIRECTORY )
vcpkg_add_to_path(PREPEND "${NINJA_DIR}")

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
        FEATURES
        svg             TGFX_BUILD_SVG
        layers          TGFX_BUILD_LAYERS
        drawers         TGFX_BUILD_DRAWERS
        qt              TGFX_USE_QT
        swiftshader     TGFX_USE_SWIFTSHADER
        angle           TGFX_USE_ANGLE
        async-promise   TGFX_USE_ASYNC_PROMISE
)

set(PLATFORM_OPTIONS)

if(VCPKG_TARGET_IS_ANDROID)
    if(NOT VCPKG_DETECTED_CMAKE_ANDROID_NDK)
        message(FATAL_ERROR "Android NDK not detected. Please set ANDROID_NDK_HOME")
    endif()

    list(APPEND PLATFORM_OPTIONS
            -DCMAKE_ANDROID_NDK=${VCPKG_DETECTED_CMAKE_ANDROID_NDK}
            -DCMAKE_ANDROID_API=${VCPKG_DETECTED_CMAKE_SYSTEM_VERSION}
            -DCMAKE_ANDROID_ARCH_ABI=${VCPKG_TARGET_ARCHITECTURE}
    )
elseif(VCPKG_TARGET_IS_WINDOWS)
    if(VCPKG_PLATFORM_TOOLSET VERSION_LESS "v142")
        message(WARNING "TGFX requires Visual Studio 2019+ for optimal C++17 support")
    endif()
endif()

if(VCPKG_DETECTED_CMAKE_C_COMPILER)
    list(APPEND PLATFORM_OPTIONS "-DCMAKE_C_COMPILER=\"${VCPKG_DETECTED_CMAKE_C_COMPILER}\"")
endif()
if(VCPKG_DETECTED_CMAKE_CXX_COMPILER)
    list(APPEND PLATFORM_OPTIONS "-DCMAKE_CXX_COMPILER=\"${VCPKG_DETECTED_CMAKE_CXX_COMPILER}\"")
endif()

set(TGFX_PLATFORM "")
set(TGFX_ARCH "")

if(VCPKG_TARGET_IS_WINDOWS)
    set(TGFX_PLATFORM "win")
    if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x86")
        set(TGFX_ARCH "x86")
    elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
        set(TGFX_ARCH "x64")
    elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
        set(TGFX_ARCH "arm64")
    endif()
elseif(VCPKG_TARGET_IS_OSX)
    set(TGFX_PLATFORM "mac")
    if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
        set(TGFX_ARCH "x64")
    elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
        set(TGFX_ARCH "arm64")
    endif()
elseif(VCPKG_TARGET_IS_IOS)
    set(TGFX_PLATFORM "ios")
    if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
        set(TGFX_ARCH "x64")
    elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
        set(TGFX_ARCH "arm64")
    endif()
elseif(VCPKG_TARGET_IS_LINUX)
    set(TGFX_PLATFORM "linux")
    if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x86")
        set(TGFX_ARCH "x86")
    elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
        set(TGFX_ARCH "x64")
    elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
        set(TGFX_ARCH "arm64")
    endif()
elseif(VCPKG_TARGET_IS_ANDROID)
    set(TGFX_PLATFORM "android")
    if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x86")
        set(TGFX_ARCH "x86")
    elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
        set(TGFX_ARCH "x64")
    elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
        set(TGFX_ARCH "arm64")
    endif()
elseif(VCPKG_TARGET_IS_EMSCRIPTEN)
    set(TGFX_PLATFORM "web")
    set(TGFX_ARCH "wasm-mt")
    # set(TGFX_ARCH "wasm")
endif()

if(NOT TGFX_PLATFORM)
    message(FATAL_ERROR "Unsupported platform: ${VCPKG_TARGET_TRIPLET}")
endif()

set(BASE_BUILD_ARGS "build_tgfx")
list(APPEND BASE_BUILD_ARGS "-p" "${TGFX_PLATFORM}")

if(TGFX_ARCH)
    list(APPEND BASE_BUILD_ARGS "-a" "${TGFX_ARCH}")
endif()

foreach(option IN LISTS FEATURE_OPTIONS)
    if(option MATCHES "^-D(.+)=(.+)$")
        list(APPEND BASE_BUILD_ARGS "-D${CMAKE_MATCH_1}=${CMAKE_MATCH_2}")
    elseif(option MATCHES "^-D(.+)$")
        list(APPEND BASE_BUILD_ARGS "-D${CMAKE_MATCH_1}=ON")
    endif()
endforeach()

foreach(option IN LISTS PLATFORM_OPTIONS)
    if(option MATCHES "^-D(.+)=(.+)$")
        list(APPEND BASE_BUILD_ARGS "-D${CMAKE_MATCH_1}=${CMAKE_MATCH_2}")
    elseif(option MATCHES "^-D(.+)$")
        list(APPEND BASE_BUILD_ARGS "-D${CMAKE_MATCH_1}=ON")
    endif()
endforeach()

if(VCPKG_TARGET_IS_OSX OR VCPKG_TARGET_IS_IOS)
    set(CMAKE_OSX_SYSROOT_INT "${VCPKG_DETECTED_CMAKE_OSX_SYSROOT}")
    set(SDK_VERSION "")
    find_program(XCODEBUILD_EXECUTABLE xcodebuild)
    if(XCODEBUILD_EXECUTABLE AND NOT CMAKE_OSX_SYSROOT_INT)
        vcpkg_execute_required_process(
                COMMAND ${XCODEBUILD_EXECUTABLE} -sdk ${CMAKE_OSX_SYSROOT_INT} -version
                WORKING_DIRECTORY ${SOURCE_PATH}
                LOGNAME "xcodebuild-sdk-version"
                OUTPUT_VARIABLE xcodebuild_output
        )
        if(xcodebuild_output)
            if(VCPKG_TARGET_IS_OSX)
                string(REGEX MATCH "MacOSX([0-9]+\\.[0-9]+)" _ "${xcodebuild_output}")
                set(SDK_VERSION "${CMAKE_MATCH_1}")
                if(NOT CMAKE_OSX_SYSROOT_INT)
                    string(REGEX MATCH "Path: ([^\n]*MacOSX[0-9.]+\.sdk)" _ "${xcodebuild_output}")
                    set(CMAKE_OSX_SYSROOT_INT "${CMAKE_MATCH_1}")
                endif ()
            elseif(VCPKG_TARGET_IS_IOS)
                string(REGEX MATCH "iPhone(OS|Simulator)([0-9]+\\.[0-9]+)" _ "${xcodebuild_output}")
                set(SDK_VERSION "${CMAKE_MATCH_2}")
                if(NOT CMAKE_OSX_SYSROOT_INT)
                    string(REGEX MATCH "Path: ([^\n]*iPhone(OS|Simulator)[0-9.]+\.sdk)" _ "${xcodebuild_output}")
                    set(CMAKE_OSX_SYSROOT_INT "${CMAKE_MATCH_1}")
                endif ()
            endif ()
        endif ()
    endif()
    if(CMAKE_OSX_SYSROOT_INT AND NOT SDK_VERSION)
        if(VCPKG_TARGET_IS_OSX)
            string(REGEX MATCH "MacOSX([0-9]+\\.[0-9]+)" _ "${CMAKE_OSX_SYSROOT_INT}")
            set(SDK_VERSION "${CMAKE_MATCH_1}")
        elseif(VCPKG_TARGET_IS_IOS)
            string(REGEX MATCH "iPhone(OS|Simulator)([0-9]+\\.[0-9]+)" _ "${CMAKE_OSX_SYSROOT_INT}")
            set(SDK_VERSION "${CMAKE_MATCH_2}")
        endif ()
    endif()
    if(NOT SDK_VERSION AND NOT CMAKE_OSX_SYSROOT_INT)
        message(FATAL_ERROR "Unable to extract SDK path and SDK version.")
    endif()
    set(ENV{_CMAKE_OSX_SYSROOT_INT} "${VCPKG_DETECTED_CMAKE_OSX_SYSROOT}")
    set(ENV{_SDK_VERSION} "${SDK_VERSION}")
endif()

set(ENV{CMAKE_COMMAND} "${CMAKE_COMMAND}")
set(ENV{CMAKE_PREFIX_PATH} "${CURRENT_INSTALLED_DIR}")

if(NOT VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "release")
    set(RELEASE_BUILD_ARGS ${BASE_BUILD_ARGS})
    vcpkg_execute_required_process(
            COMMAND "${NODEJS}" ${RELEASE_BUILD_ARGS}
            WORKING_DIRECTORY "${SOURCE_PATH}"
            LOGNAME tgfx_build_release
    )
endif()

if(NOT VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug")
    set(DEBUG_BUILD_ARGS ${BASE_BUILD_ARGS})
    list(APPEND DEBUG_BUILD_ARGS "-d")
    vcpkg_execute_required_process(
            COMMAND "${NODEJS}" ${DEBUG_BUILD_ARGS}
            WORKING_DIRECTORY "${SOURCE_PATH}"
            LOGNAME tgfx_build_debug
    )
endif()

set(RELEASE_OUT_DIR "${SOURCE_PATH}/out/release/${TGFX_PLATFORM}")
set(DEBUG_OUT_DIR "${SOURCE_PATH}/out/debug/${TGFX_PLATFORM}")

if(TGFX_ARCH)
    set(RELEASE_OUT_DIR "${RELEASE_OUT_DIR}/${TGFX_ARCH}")
    set(DEBUG_OUT_DIR "${DEBUG_OUT_DIR}/${TGFX_ARCH}")
endif()

file(INSTALL "${SOURCE_PATH}/include/"
        DESTINATION "${CURRENT_PACKAGES_DIR}/include"
        FILES_MATCHING PATTERN "*.h" PATTERN "*.hpp" PATTERN "*.hxx")

if(EXISTS "${RELEASE_OUT_DIR}")
    file(GLOB RELEASE_LIBS "${RELEASE_OUT_DIR}/*.a" "${RELEASE_OUT_DIR}/*.lib" "${RELEASE_OUT_DIR}/*.so")
    if(RELEASE_LIBS)
        file(INSTALL ${RELEASE_LIBS}
                DESTINATION "${CURRENT_PACKAGES_DIR}/lib")
    endif()
endif()

if(NOT VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug")
    if(EXISTS "${DEBUG_OUT_DIR}")
        file(GLOB DEBUG_LIBS "${DEBUG_OUT_DIR}/*.a" "${DEBUG_OUT_DIR}/*.lib" "${DEBUG_OUT_DIR}/*.so")
        if(DEBUG_LIBS)
            file(INSTALL ${DEBUG_LIBS}
                    DESTINATION "${CURRENT_PACKAGES_DIR}/debug/lib")
        endif()
    endif()
endif()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
        DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.txt")

generate_tgfx_config_cmake()

file(INSTALL "${CURRENT_PACKAGES_DIR}/share/tgfx/tgfxConfig.cmake"
        DESTINATION "${CURRENT_PACKAGES_DIR}/share/tgfx")

if(VCPKG_TARGET_IS_WINDOWS)
    set(VCPKG_POLICY_SKIP_CRT_LINKAGE_CHECK enabled)
endif()
