#include <stdexcept>

extern "C" int exception1_ext()
{
  throw std::runtime_error("exception test");
}
