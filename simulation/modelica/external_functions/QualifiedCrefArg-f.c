typedef struct R_s {
  double x;
  double y;
} R;

double f_ext(double ri_x, double ri_y, R *r)
{
  r->x = ri_x * 3.0;
  r->y = ri_y * 4.0;
  return 42.0;
}
