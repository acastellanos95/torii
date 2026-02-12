include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


include(CheckCXXSourceCompiles)


macro(torii_supports_sanitizers)
  # Emscripten doesn't support sanitizers
  if(EMSCRIPTEN)
    set(SUPPORTS_UBSAN OFF)
    set(SUPPORTS_ASAN OFF)
  elseif((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)

    message(STATUS "Sanity checking UndefinedBehaviorSanitizer, it should be supported on this platform")
    set(TEST_PROGRAM "int main() { return 0; }")

    # Check if UndefinedBehaviorSanitizer works at link time
    set(CMAKE_REQUIRED_FLAGS "-fsanitize=undefined")
    set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=undefined")
    check_cxx_source_compiles("${TEST_PROGRAM}" HAS_UBSAN_LINK_SUPPORT)

    if(HAS_UBSAN_LINK_SUPPORT)
      message(STATUS "UndefinedBehaviorSanitizer is supported at both compile and link time.")
      set(SUPPORTS_UBSAN ON)
    else()
      message(WARNING "UndefinedBehaviorSanitizer is NOT supported at link time.")
      set(SUPPORTS_UBSAN OFF)
    endif()
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    if (NOT WIN32)
      message(STATUS "Sanity checking AddressSanitizer, it should be supported on this platform")
      set(TEST_PROGRAM "int main() { return 0; }")

      # Check if AddressSanitizer works at link time
      set(CMAKE_REQUIRED_FLAGS "-fsanitize=address")
      set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=address")
      check_cxx_source_compiles("${TEST_PROGRAM}" HAS_ASAN_LINK_SUPPORT)

      if(HAS_ASAN_LINK_SUPPORT)
        message(STATUS "AddressSanitizer is supported at both compile and link time.")
        set(SUPPORTS_ASAN ON)
      else()
        message(WARNING "AddressSanitizer is NOT supported at link time.")
        set(SUPPORTS_ASAN OFF)
      endif()
    else()
      set(SUPPORTS_ASAN ON)
    endif()
  endif()
endmacro()

macro(torii_setup_options)
  option(torii_ENABLE_HARDENING "Enable hardening" ON)
  option(torii_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    torii_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    torii_ENABLE_HARDENING
    OFF)

  torii_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR torii_PACKAGING_MAINTAINER_MODE)
    option(torii_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(torii_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(torii_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(torii_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(torii_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(torii_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(torii_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(torii_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(torii_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(torii_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(torii_ENABLE_PCH "Enable precompiled headers" OFF)
    option(torii_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(torii_ENABLE_IPO "Enable IPO/LTO" ON)
    option(torii_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(torii_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(torii_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(torii_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(torii_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(torii_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(torii_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(torii_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(torii_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(torii_ENABLE_PCH "Enable precompiled headers" OFF)
    option(torii_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      torii_ENABLE_IPO
      torii_WARNINGS_AS_ERRORS
      torii_ENABLE_SANITIZER_ADDRESS
      torii_ENABLE_SANITIZER_LEAK
      torii_ENABLE_SANITIZER_UNDEFINED
      torii_ENABLE_SANITIZER_THREAD
      torii_ENABLE_SANITIZER_MEMORY
      torii_ENABLE_UNITY_BUILD
      torii_ENABLE_CLANG_TIDY
      torii_ENABLE_CPPCHECK
      torii_ENABLE_COVERAGE
      torii_ENABLE_PCH
      torii_ENABLE_CACHE)
  endif()

  torii_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (torii_ENABLE_SANITIZER_ADDRESS OR torii_ENABLE_SANITIZER_THREAD OR torii_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(torii_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(torii_global_options)
  if(torii_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    torii_enable_ipo()
  endif()

  torii_supports_sanitizers()

  if(torii_ENABLE_HARDENING AND torii_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR torii_ENABLE_SANITIZER_UNDEFINED
       OR torii_ENABLE_SANITIZER_ADDRESS
       OR torii_ENABLE_SANITIZER_THREAD
       OR torii_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${torii_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${torii_ENABLE_SANITIZER_UNDEFINED}")
    torii_enable_hardening(torii_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(torii_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(torii_warnings INTERFACE)
  add_library(torii_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  torii_set_project_warnings(
    torii_warnings
    ${torii_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  include(cmake/Linker.cmake)
  # Must configure each target with linker options, we're avoiding setting it globally for now

  if(NOT EMSCRIPTEN)
    include(cmake/Sanitizers.cmake)
    torii_enable_sanitizers(
      torii_options
      ${torii_ENABLE_SANITIZER_ADDRESS}
      ${torii_ENABLE_SANITIZER_LEAK}
      ${torii_ENABLE_SANITIZER_UNDEFINED}
      ${torii_ENABLE_SANITIZER_THREAD}
      ${torii_ENABLE_SANITIZER_MEMORY})
  endif()

  set_target_properties(torii_options PROPERTIES UNITY_BUILD ${torii_ENABLE_UNITY_BUILD})

  if(torii_ENABLE_PCH)
    target_precompile_headers(
      torii_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(torii_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    torii_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(torii_ENABLE_CLANG_TIDY)
    torii_enable_clang_tidy(torii_options ${torii_WARNINGS_AS_ERRORS})
  endif()

  if(torii_ENABLE_CPPCHECK)
    torii_enable_cppcheck(${torii_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(torii_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    torii_enable_coverage(torii_options)
  endif()

  if(torii_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(torii_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(torii_ENABLE_HARDENING AND NOT torii_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR torii_ENABLE_SANITIZER_UNDEFINED
       OR torii_ENABLE_SANITIZER_ADDRESS
       OR torii_ENABLE_SANITIZER_THREAD
       OR torii_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    torii_enable_hardening(torii_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
