#include <torii/torii.hpp>
#include <libssh/server.h>
#include <string_view>

int factorial(int input) noexcept
{
  int result = 1;

  while (input > 0) {
    result *= input;
    --input;
  }

  return result;
}
Torii::Torii(const std::string_view &address, const unsigned short port) noexcept :ssh_bind_(ssh_bind_new()) {
  ssh_bind_options_set(ssh_bind_, SSH_BIND_OPTIONS_BINDADDR, address.data());
  ssh_bind_options_set(ssh_bind_, SSH_BIND_OPTIONS_BINDPORT, &port);
}

Torii::~Torii() {
  ssh_bind_free(ssh_bind_);
}
