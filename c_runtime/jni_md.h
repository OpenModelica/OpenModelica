#if defined(__MINGW32__) || defined(_MSC_VER)
#include "jni_md_windows.h"
#else /* Linux /MinGW */
#include "jni_md_solaris.h"
#endif
