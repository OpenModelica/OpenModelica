#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

double real1_ext(double x)
{
  return x + 1;
}

double real2_ext(double x, double y, double z)
{
  return x + y + z;
}

void real3_ext(double x, double y, double *z)
{
  *z = x * y;
}

int integer1_ext(int x)
{
  return x + x;
}

int integer2_ext(int x, int y, int z)
{
  return x * y * z;
}


int boolean1_ext(int x)
{
  return !x;
}

int boolean2_ext(int x, int y, int z)
{
  return x || y || z;
}

int enum1_ext(int x)
{
  return x + 1;
}

int enum2_ext(int x, int y)
{
  return x + y;
}

int string1_ext(const char *s)
{
  int sz = 0;

  while (*s != '\0') {
    ++sz;
    ++s;
  }

  return sz;
}

void realArray1_ext(const double *x, size_t n, double *y)
{
  for (size_t i = 0; i < n; ++i) {
    y[i] = x[i] * 2;
  }
}

void stringArray1_ext(const char **s, size_t n, int *lens)
{
  for (size_t i = 0; i < n; ++i) {
    lens[i] = string1_ext(s[i]);
  }
}

struct record1
{
  double x;
};

double record1_ext(const struct record1 *r1)
{
  return r1->x;
}

struct record2
{
  double x;
  double y;
  double z;
};

void record2_ext(struct record2 *r2, double x, double y, double z)
{
  r2->x = x;
  r2->y = y;
  r2->z = z;
}

struct record3
{
  int i1;
  double r;
  int i2;
};

void record3_ext(struct record3 *r3, int i1, double r, int i2)
{
  r3->i1 = i1;
  r3->r = r;
  r3->i2 = i2;
}

struct record4
{
  double x;
  struct record2 r2;
  double y;
};

void record4_ext(const double *arr, struct record4 *r4)
{
  r4->x = arr[0];
  r4->r2.x = arr[1];
  r4->r2.y = arr[2];
  r4->r2.z = arr[3];
  r4->y = arr[4];
}

int crash1_ext()
{
  abort();
}
