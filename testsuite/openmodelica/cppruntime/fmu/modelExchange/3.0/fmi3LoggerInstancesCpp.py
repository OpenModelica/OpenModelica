"""Use two instances of an FMI 3.0 Model Exchange FMU in one process. Each
instance logs a model warning. Write which instance the logMessage
callback was called for (by instanceEnvironment), also after the other
instance is freed.

usage: fmi3LoggerInstancesCpp.py <fmu> <output_txt>
"""
import sys

from fmpy import extract, read_model_description
from fmpy.fmi3 import (FMU3Model, fmi3Float64, fmi3InstanceEnvironment,
                       fmi3LogMessageCallback)

received = []
NAMES = {1: "a", 2: "b"}


def log_message(env, status, category, message):
    if b"x is above" in message:
        received.append(NAMES.get(env, "unknown"))


callback = fmi3LogMessageCallback(log_message)


def main(fmu, output):
    md = read_model_description(fmu)
    unzipdir = extract(fmu)
    inst = {}
    for env, name in NAMES.items():
        m = FMU3Model(guid=md.guid, unzipDirectory=unzipdir, instanceName=name,
                      modelIdentifier=md.modelExchange.modelIdentifier)
        # FMU3Model.instantiate has no instanceEnvironment argument
        m.component = m.fmi3InstantiateModelExchange(
            name.encode(), md.guid.encode(),
            (str(unzipdir) + "/resources/").encode(), False, True,
            fmi3InstanceEnvironment(env), callback)
        m.enterInitializationMode(startTime=0.0)
        m.exitInitializationMode()
        m.enterContinuousTimeMode()
        inst[name] = m
    out = open(output, "w")
    x, dx = (fmi3Float64 * 1)(), (fmi3Float64 * 1)()

    def warn(name, what):
        del received[:]
        m = inst[name]
        x[0] = 0.6
        m.setContinuousStates(x, 1)
        m.getContinuousStateDerivatives(dx, 1)
        # write each line at once: a crash must not hide the lines before it
        out.write("%s: warning received for %s\n" % (what, ", ".join(received) or "none"))
        out.flush()

    warn("a", "a")
    warn("b", "b")
    inst["b"].freeInstance()
    warn("a", "a after b was freed")
    inst["a"].freeInstance()
    out.close()


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
