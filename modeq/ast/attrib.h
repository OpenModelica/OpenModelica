
typedef struct {
  int type;
  union {
    int ival;
    double realval;
    char *stringval;
  } u;
} Attrib;

Attrib *copy_attr(Attrib *);
void print_attr(Attrib *, FILE *);
