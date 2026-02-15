include(GenerateExportHeader)

add_library(torii_library torii.cpp)
add_library(torii::torii_library ALIAS torii_library)

target_link_libraries(torii_library PRIVATE torii_options torii_warnings ssh)

target_include_directories(torii_library ${WARNING_GUARD} PUBLIC $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
                                                                  $<BUILD_INTERFACE:${PROJECT_BINARY_DIR}/include>
                                                                  ${libssh_BINARY_DIR}/include
                                                                  ${libssh_SOURCE_DIR}/include)

if (torii_BUILD_FUZZ_TESTS)
  target_link_libraries(torii_library PRIVATE -fsanitize=fuzzer-no-link)
  target_compile_options(torii_library PRIVATE -fsanitize=fuzzer-no-link)
endif()

target_compile_features(torii_library PUBLIC cxx_std_${CMAKE_CXX_STANDARD})

torii_configure_linker(torii_library)

set_target_properties(
  torii_library
  PROPERTIES VERSION ${PROJECT_VERSION}
             CXX_VISIBILITY_PRESET hidden
             VISIBILITY_INLINES_HIDDEN YES)

generate_export_header(torii_library EXPORT_FILE_NAME ${PROJECT_BINARY_DIR}/include/torii/torii_library_export.hpp)

if(NOT BUILD_SHARED_LIBS)
  target_compile_definitions(torii_library PUBLIC TORII_LIBRARY_STATIC_DEFINE)
endif()
