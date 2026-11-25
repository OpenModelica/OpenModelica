/* struct R and struct Inner are defined by the generated code, struct
   MyComp_R2 by the Include annotation of its record. */
#include <stddef.h>
#include <string.h>

double ers_read(const struct R *r)
{
  return r->x + 10*r->n + 100*r->flag + 1000*r->c + 10000*r->in1.i + 100000*r->in1.b + 1000000*strlen(r->s);
}

void ers_write(double t, struct R *r)
{
  r->x = t + 0.5;
  r->n = 7;
  r->flag = 1;
  r->c = 3;
  r->in1.i = 4;
  r->in1.b = 1;
  r->s = "abc";
}

struct R ers_return(double t)
{
  struct R r = {t + 0.25, 5, 0, 2, {6, 1}, "xy"};
  return r;
}

void ers_fill(double t, struct Inner *a, size_t n)
{
  size_t k;
  for (k = 0; k < n; k++) {
    a[k].i = (int) (k + 1 + t);
    a[k].b = (int) (k % 2);
  }
}

double ers_sum(const struct Inner *a, size_t n)
{
  double s = 0;
  size_t k;
  for (k = 0; k < n; k++) {
    s += (k + 1) * a[k].i + 10 * a[k].b;
  }
  return s;
}

double ers_tagged(const struct MyComp_Tagged *r)
{
  return r->val + 10 * r->cnt;
}

void MyComp_foo(const struct MyComp_R *r, struct MyComp_R2 *r2)
{
  r2->a = -1;
  r2->w = r->x;
  r2->z = r->y;
}
