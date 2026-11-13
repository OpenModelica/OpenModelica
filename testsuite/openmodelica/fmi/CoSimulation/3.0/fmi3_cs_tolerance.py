import math
import sys

from fmpy import simulate_fmu

with open(sys.argv[2], "w") as out:
    for tol, check in ((1e-3, lambda e: e > 1e-3), (1e-10, lambda e: e < 1e-6)):
        x = simulate_fmu(sys.argv[1], stop_time=10.0, output_interval=1.0,
                         relative_tolerance=tol, output=["x"])["x"][-1]
        out.write("tolerance %g: %s\n" % (tol, check(abs(x - math.cos(10.0)))))
