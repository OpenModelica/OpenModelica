#include <stdio.h>

#include "test.c"

int main(int argc, char** argv)
{

  t_rettype r;

  r = t(5.0);

  printf("t(5.0) == %e\n",r.y);

  return 0;

}
