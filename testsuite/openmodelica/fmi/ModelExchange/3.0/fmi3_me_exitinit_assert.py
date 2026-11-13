"""Write the status of fmi3ExitInitializationMode and of the Model Exchange
calls after it.

usage: fmi3_me_exitinit_assert.py <fmu> <output_txt>
"""
import sys

from fmpy import extract, read_model_description
from fmpy.fmi3 import FMU3Model

NAMES = ["fmi3OK", "fmi3Warning", "fmi3Discard", "fmi3Error", "fmi3Fatal"]


def status(call, *args, **kw):
    try:
        call(*args, **kw)
        return NAMES[0]
    except Exception as e:
        return NAMES[e.status] if isinstance(getattr(e, "status", None), int) else type(e).__name__


def main(fmu, output):
    md = read_model_description(fmu)
    s = FMU3Model(guid=md.instantiationToken, unzipDirectory=extract(fmu),
                  modelIdentifier=md.modelExchange.modelIdentifier, instanceName="instance")
    s.instantiate()
    s.enterInitializationMode(startTime=0.0)
    calls = [
        ("fmi3ExitInitializationMode", s.exitInitializationMode),
        ("fmi3ExitInitializationMode", s.exitInitializationMode),
        ("fmi3EnterContinuousTimeMode", s.enterContinuousTimeMode),
        ("fmi3SetTime", lambda: s.setTime(0.1)),
        ("fmi3CompletedIntegratorStep", s.completedIntegratorStep),
        ("fmi3EnterEventMode", s.enterEventMode),
        ("fmi3UpdateDiscreteStates", s.updateDiscreteStates),
        ("fmi3Terminate", s.terminate),
    ]
    with open(output, "w") as f:
        f.writelines("%s: %s\n" % (name, status(call)) for name, call in calls)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
