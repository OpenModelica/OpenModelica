/* MLS 3.6 style: the external code defines the structs. */
struct A {
  int b;
};

struct R {
  double x;
  double z;
  struct A a1, a2;
};

typedef struct {
  double p;
  int phase;
} MyState;

double mls36_read(struct R *r)
{
  return r->x + 10*r->z + 100*r->a1.b + 1000*r->a2.b;
}

void mls36_write(double t, struct R *r)
{
  r->x = t + 0.5;
  r->z = 2;
  r->a1.b = 3;
  r->a2.b = 4;
}

double mls36_state(const MyState *s)
{
  return s->p + 10*s->phase;
}

void mls36_set_state(double p, MyState *s)
{
  s->p = p;
  s->phase = 2;
}
