import sys

from fmpy import simulate_fmu

T_BOUNCE = 0.4515236

def run(fmu, **kw):
    return simulate_fmu(fmu, stop_time=1.0, output_interval=0.01, output=["v"], **kw)

with open(sys.argv[3], "w") as out:
    for name, fmu, kw in (("FMI 2.0", sys.argv[1], {}),
                          ("FMI 3.0", sys.argv[2], {}),
                          ("FMI 3.0 Event Mode", sys.argv[2], dict(use_event_mode=True))):
        r = run(fmu, **kw)
        v = r["v"][abs(r["time"] - 0.5).argmin()]
        out.write("%s: v(0.5) = %.4f\n" % (name, v))
    r = run(sys.argv[2], use_event_mode=True, early_return_allowed=True)
    out.write("FMI 3.0 early return at the bounce: %s\n" % any(abs(r["time"] - T_BOUNCE) < 1e-5))
    out.write("FMI 3.0 early return: v(0.5) = %.4f\n" % r["v"][abs(r["time"] - 0.5).argmin()])
