int f1234(int* t1, int* t2, int* t3)
{
  *t1 = 1;
  *t2 = 2;
  *t3 = 3;
  return 4;
}

/* FORTRAN 77 identifier alias
 * In GCC, we can load a function compiled in C as if it was a FORTRAN function.
 * There is no real distinction as long as we use the most basic types.
 */
#define f1234_ f1234
