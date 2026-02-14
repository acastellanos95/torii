include(cmake/CPM.cmake)

# Done as a function so that updates to variables like
# CMAKE_CXX_FLAGS don't propagate out to other
# targets
function(torii_setup_dependencies)

  # For each dependency, see if it's
  # already been provided to us by a parent project

  cpmaddpackage(
          NAME
          libssh
          URL
          "https://git.libssh.org/projects/libssh.git/snapshot/stable-0.11.zip"
          OPTIONS
          "WITH_EXAMPLES OFF"
          "WITH_TESTING OFF"
          "BUILD_SHARED_LIBS OFF" # Ensure static build
  )

  if(NOT libssh_ADDED)
    message(FATAL_ERROR "libssh dependency not added by CPM")
  endif()

#  if(NOT TARGET fmtlib::fmtlib)
#    cpmaddpackage("gh:fmtlib/fmt#12.1.0")
#  endif()
#
#  if(NOT TARGET spdlog::spdlog)
#    cpmaddpackage(
#      NAME
#      spdlog
#      VERSION
#      1.17.0
#      GITHUB_REPOSITORY
#      "gabime/spdlog"
#      OPTIONS
#      "SPDLOG_FMT_EXTERNAL ON")
#  endif()

  if(NOT TARGET Catch2::Catch2WithMain)
    cpmaddpackage("gh:catchorg/Catch2@3.12.0")
  endif()

#  if(NOT TARGET CLI11::CLI11)
#    cpmaddpackage("gh:CLIUtils/CLI11@2.6.1")
#  endif()
#
#  if(NOT TARGET ftxui::screen)
#    cpmaddpackage("gh:ArthurSonzogni/FTXUI@6.1.9")
#  endif()
#
#  if(NOT TARGET tools::tools)
#    cpmaddpackage("gh:lefticus/tools#update_build_system")
#  endif()

endfunction()
