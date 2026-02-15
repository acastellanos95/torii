#pragma once

#include <torii/torii_library_export.hpp>
#include <libssh/server.h>
#include <string>
#include <string_view>

[[nodiscard]] TORII_LIBRARY_EXPORT int factorial(int) noexcept;

[[nodiscard]] constexpr int factorial_constexpr(int input) noexcept
{
  if (input == 0) { return 1; }

  return input * factorial_constexpr(input - 1);
}

class TORII_LIBRARY_EXPORT Torii final
{
public:

  Torii(const std::string_view& address, const unsigned short port) noexcept;
  ~Torii();
  // void start() noexcept;

private:
  ssh_bind ssh_bind_;
  // ssh_session ssh_session_;
  // ssh_event ssh_event_;
};