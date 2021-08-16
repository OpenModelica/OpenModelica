#if defined(__MINGW32__) || defined(_MSC_VER)
  #include "socket_win.inc"
#else
  #include "socket_unix.inc"
#endif
