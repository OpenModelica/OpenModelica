typedef struct ExternalR {
  double x;
  int y;
  int z;
} ExternalR;

void f_impl(ExternalR *r)
{
  r->x = 1.0;
  r->y = 2;
  r->z = 3;
}
