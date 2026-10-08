#include <ModelicaUtilities.h>

/* The shape ExternalMedia's library has: the record filled through a pointer to
   C's `<record>_external`, and the message handlers passed in rather than called
   directly, so a wrapper is the only thing an `Include` can offer. */
typedef struct { double T; double p; int phase; } om_state_external;

void om_state_err(double p, double h, int hint, om_state_external* s,
                  const char* medium, void (*err)(const char*))
{
  if (p <= 0.0) {
    err("om_state_err: pressure must be positive");
    return;
  }
  s->T = h / 4200.0;
  s->p = p;
  s->phase = h > 250000.0 ? 2 : 1;
  if (medium == 0 || medium[0] == '\0') {
    err("om_state_err: no medium name");
  }
  (void) hint;
}
