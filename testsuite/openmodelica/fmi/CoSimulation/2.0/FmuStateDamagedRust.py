"""Restore damaged FMU states into an FMI 2.0 Co-Simulation FMU of the C+Rust
target, and write what fmi2DeSerializeFMUstate, fmi2SetFMUstate and the next
fmi2DoStep return. Each case runs in a process of its own, so that an abort
shows as a line of its own.
usage: FmuStateDamagedRust.py <fmu> <output_txt>
"""
import resource
import struct
import subprocess
import sys
from fmpy import extract, read_model_description
from fmpy.fmi2 import FMU2Slave
NAMES = ["fmi2OK", "fmi2Warning", "fmi2Discard", "fmi2Error", "fmi2Fatal", "fmi2Pending"]
# The runtime part of the state: the delay() buffers (flag, start time, number of
# buffers, then per buffer its length and its (time, value) rows), then the
# spatialDistribution() operators (flag, number of operators, ...). The model has
# one delay() and no spatialDistribution().
CASES = [
    ("saved state", None),
    ("huge number of delay buffers", [1.0, 0.0, 1e300, 1.0, 0.0]),
    ("infinite number of delay buffers", [1.0, 0.0, float("inf"), 1.0, 0.0]),
    ("huge delay buffer length", [1.0, 0.0, 1.0, 1e300, 1.0, 0.0]),
    ("no delay buffer", [1.0, 0.0, 0.0, 1.0, 0.0]),
    ("huge number of spatialDistribution operators", [1.0, 0.0, 1.0, 0.0, 1.0, 1e300]),
]
def call(f, *args, **kw):
    try:
        res = f(*args, **kw)
        return NAMES[res] if isinstance(res, int) else "fmi2OK", res
    except Exception as e:
        return (NAMES[e.status] if isinstance(getattr(e, "status", None), int) else type(e).__name__), None
def replace_runtime_words(state, words):
    # Layout: flat part, runtime part, schedule, then their sizes as three u64:
    # runtime part, schedule, flat part.
    n_runtime, n_schedule, n_flat = struct.unpack("<QQQ", state[-24:])
    runtime = struct.pack("<%dd" % len(words), *words)
    schedule = state[n_flat + n_runtime:n_flat + n_runtime + n_schedule]
    return state[:n_flat] + runtime + schedule + struct.pack("<QQQ", len(runtime), n_schedule, n_flat)
def run_case(fmu, index):
    name, words = CASES[index]
    md = read_model_description(fmu)
    s = FMU2Slave(guid=md.guid, unzipDirectory=extract(fmu),
                  modelIdentifier=md.coSimulation.modelIdentifier, instanceName="instance")
    s.instantiate()
    s.setupExperiment(startTime=0.0)
    s.enterInitializationMode()
    s.exitInitializationMode()
    s.doStep(currentCommunicationPoint=0.0, communicationStepSize=0.1)
    state = s.serializeFMUstate(s.getFMUstate())
    if words is not None:
        state = replace_runtime_words(bytes(state), words)
    line = name + ": fmi2DeSerializeFMUstate "
    status, fmu_state = call(s.deSerializeFMUstate, state)
    line += status
    if fmu_state is not None:
        status, _ = call(s.setFMUstate, fmu_state)
        line += ", fmi2SetFMUstate " + status
        if status == "fmi2OK":
            status, _ = call(s.doStep, currentCommunicationPoint=0.1, communicationStepSize=0.1)
            line += ", fmi2DoStep " + status
    print("RESULT " + line, flush=True)
def main(fmu, output):
    lines = []
    for index, (name, _) in enumerate(CASES):
        # No core file from a case that aborts.
        p = subprocess.run([sys.executable, __file__, fmu, "--case", str(index)],
                           stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True,
                           preexec_fn=lambda: resource.setrlimit(resource.RLIMIT_CORE, (0, 0)))
        result = [l[7:] for l in p.stdout.splitlines() if l.startswith("RESULT ")]
        lines.append(result[0] if result and p.returncode == 0 else
                     "%s: the process ended with exit code %d" % (name, p.returncode))
    with open(output, "w") as f:
        f.write("\n".join(lines) + "\n")
if __name__ == "__main__":
    if len(sys.argv) == 4 and sys.argv[2] == "--case":
        run_case(sys.argv[1], int(sys.argv[3]))
    else:
        main(sys.argv[1], sys.argv[2])
