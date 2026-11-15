"""Simulate the FMU twice, once with all calls on one thread and once with
each call on a new thread, and write the values after each step of the
second run and whether they are the same as in the first run.

usage: FmuThreadCalls.py <fmu> <output_txt>
"""
import sys
import threading

from fmpy import extract, read_model_description
from fmpy.fmi2 import FMU2Slave


def on_new_thread(f, *args):
    out = []
    t = threading.Thread(target=lambda: out.append(f(*args)))
    t.start()
    t.join()
    return out[0]


def run(fmu, call):
    md = read_model_description(fmu)
    vr = {v.name: v.valueReference for v in md.modelVariables}
    s = FMU2Slave(guid=md.guid, unzipDirectory=extract(fmu),
                  modelIdentifier=md.coSimulation.modelIdentifier, instanceName="instance")
    call(s.instantiate)
    call(s.setupExperiment, None, 0.0)
    call(s.enterInitializationMode)
    call(s.exitInitializationMode)
    rows = []
    for i in range(4):
        call(s.doStep, 0.1 * i, 0.1)
        a, x = call(s.getReal, [vr["a"], vr["x"]])
        f, g = call(s.getBoolean, [vr["f"], vr["g"]])
        c, = call(s.getInteger, [vr["c"]])
        rows.append("t=%g a=%g f=%d g=%d c=%d x=%.4f" % (0.1 * (i + 1), a, f, g, c, x))
    call(s.terminate)
    call(s.freeInstance)
    return rows


def main(fmu, output):
    one = run(fmu, lambda f, *a: f(*a))
    moved = run(fmu, on_new_thread)
    with open(output, "w") as f:
        f.write("\n".join(moved) + "\n")
        f.write("same as on one thread: %s\n" % (one == moved))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
