"""Co-simulate the FMU with Event Mode and early return.

usage: fmi3_cs_event_mode_reinit.py <fmu> <output_txt>
"""
import sys

from fmpy import simulate_fmu


def main(fmu, output):
    r = simulate_fmu(fmu, stop_time=1.0, output_interval=0.01, output=["h", "v"],
                     use_event_mode=True, early_return_allowed=True)
    at = abs(r["time"] - 0.5).argmin()
    with open(output, "w") as f:
        f.write("bounced: %s\n" % (r["v"][at] > 0))
        f.write("min(h) > -0.05: %s\n" % (min(r["h"]) > -0.05))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
