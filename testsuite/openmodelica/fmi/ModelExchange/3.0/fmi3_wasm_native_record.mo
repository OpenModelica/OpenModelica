model ExtNativeRecord
  record State
    Real T;
    Real p;
    Integer phase;
  end State;

  function setState
    input Real p;
    input Real h;
    input Integer hint;
    output State state;
    input String medium = "water";
    external "C" om_state_wrap(p, h, hint, state, medium)
    annotation (
      Library = "fmi3_wasm_native_record-f.o",
      Include = "
#include \"ModelicaUtilities.h\"
typedef struct { double T; double p; int phase; } om_state_external;
void om_state_err(double p, double h, int hint, om_state_external* s,
                  const char* medium, void (*err)(const char*));

/* Only a wrapper: `om_state_err` is in the platform library alone, and takes a
   message handler this side has to pass in. */
void om_state_wrap(double p, double h, int hint, void* s, const char* medium)
{
  om_state_err(p, h, hint, (om_state_external*) s, medium, ModelicaError);
}
");
  end setState;

  State st = setState(1e5, 1e5 * time + 2e5, 3);
end ExtNativeRecord;
