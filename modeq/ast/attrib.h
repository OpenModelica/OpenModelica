
typedef struct {
  int type;
  union {
    int ival;
    float floatval;
    char *stringval;
  } u;
} Attrib;

Attrib *copy_attr(Attrib *);
void print_attr(Attrib *, FILE *);
