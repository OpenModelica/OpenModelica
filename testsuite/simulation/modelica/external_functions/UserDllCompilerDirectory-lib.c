#if defined(_WIN32)
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif

#if !defined(VALUE)
#define VALUE 1.0
#endif

EXPORT double userdll_compiler_directory(double t)
{
  return VALUE;
}
