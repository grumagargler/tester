cmake_minimum_required ( VERSION 3.20 )
if ( POLICY CMP0091 )
    cmake_policy ( SET CMP0091 NEW )
endif ()
project ( testerClient )
set ( CMAKE_CXX_STANDARD 20 )
set ( CMAKE_CXX_STANDARD_REQUIRED ON )
set ( CMAKE_POSITION_INDEPENDENT_CODE ON )
if ( MSVC )
    set ( CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>" )
endif ()
option ( WITH_TESTS "Build the project with tests" OFF )
find_package ( Threads REQUIRED )
find_package ( httplib CONFIG REQUIRED )
set ( sources
    chars.cpp
    corestrings.cpp
    export.cpp
    extender.cpp
    httpServer.cpp
)
add_library ( ${PROJECT_NAME} SHARED ${sources} )
target_compile_definitions ( ${PROJECT_NAME} PRIVATE UNICODE )
target_include_directories ( ${PROJECT_NAME} PRIVATE ${PROJECT_SOURCE_DIR} )
target_link_libraries ( ${PROJECT_NAME} PRIVATE Threads::Threads httplib::httplib )
if ( WIN32 )
    target_compile_definitions ( ${PROJECT_NAME} PRIVATE _WIN32_WINNT=0x0601 WIN32_LEAN_AND_MEAN NOMINMAX )
    target_link_options ( ${PROJECT_NAME} PRIVATE "/DEF:${CMAKE_CURRENT_SOURCE_DIR}/extender.def" )
    target_link_libraries ( ${PROJECT_NAME} PRIVATE ws2_32 )
endif ()
if ( CMAKE_SIZEOF_VOID_P EQUAL 8 )
  set ( bundle_name testerClient64 )
else ()
  set ( bundle_name testerClient32 )
endif ()
set_target_properties ( ${PROJECT_NAME} PROPERTIES
    OUTPUT_NAME ${bundle_name}
    PREFIX ""
)
