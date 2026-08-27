model ExtOutputRecord
  record State
    Real T;
    Real p;
    Integer phase;
  end State;

  function setState "Fill a record the C side writes through a pointer"
    input Real p;
    input Real h;
    input String medium;
    output State state;
    external "C" om_set_state(p, h, state, medium)
    annotation (Include="
/* C's `<record>_external`: the members' C types packed from offset 0, with none
   of the runtime record object's header. */
typedef struct { double T; double p; int phase; } om_state_external;

void om_set_state(double p, double h, om_state_external* s, const char* medium) {
  s->T = h / 4200.0;
  s->p = p;
  s->phase = h > 250000.0 ? 2 : 1;
}
");
  end setState;

  State st = setState(1e5, 1e5 * time + 2e5, "water");
end ExtOutputRecord;
