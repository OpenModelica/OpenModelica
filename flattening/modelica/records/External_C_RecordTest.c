struct ADD {
  double a1;
  double a2;
};

struct ADD mk_add_ext(double a1, double a2)
{
  struct ADD add;
  add.a1 = a1;
  add.a2 = a2;
  return add;
}

struct PLUS {
  struct ADD left;
  struct ADD right;
};

struct PLUS mk_plus_ext(struct ADD left, struct ADD right)
{
  struct PLUS out;
  out.left = left;
  out.right = right;
  return out;
}

struct EMPTY {
};

struct EMPTY mk_empty_ext()
{
  struct EMPTY empty;
  return empty;
}

