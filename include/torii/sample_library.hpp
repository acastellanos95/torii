#pragma once

#include <torii/sample_library_export.hpp>
#include <libssh/libssh.h>
#include <libssh/server.h>

[[nodiscard]] SAMPLE_LIBRARY_EXPORT int factorial(int) noexcept;

[[nodiscard]] constexpr int factorial_constexpr(int input) noexcept
{
  if (input == 0) { return 1; }

  return input * factorial_constexpr(input - 1);
}