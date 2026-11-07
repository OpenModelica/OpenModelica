import sys

from fmpy import extract, read_model_description
from fmpy.fmi3 import FMU3Model

name, out = sys.argv[1:3]
md = read_model_description(name + ".fmu")
folder = extract(name + ".fmu")
vr = {v.name: v.valueReference for v in md.modelVariables}


def directional(unknowns, knowns):
    fmu = FMU3Model(guid=md.guid, unzipDirectory=folder,
                    modelIdentifier=md.modelExchange.modelIdentifier, instanceName="dd")
    fmu.instantiate()
    fmu.enterInitializationMode()
    fmu.exitInitializationMode()
    fmu.updateDiscreteStates()
    fmu.enterContinuousTimeMode()
    try:
        return fmu.getDirectionalDerivative([vr[u] for u in unknowns], [vr[k] for k in knowns],
                                            [1.0] * len(knowns))
    except Exception:
        return "error"


with open(out, "w") as f:
    for unknowns, knowns in ((("der(a)", "der(b)"), ("a",)),
                             (("der(a)", "der(b)"), ("b",)),
                             (("der(a)", "der(b)"), ("time",)),
                             (("der(a)", "der(b)"), ("a", "time")),
                             (("der(a)", "der(b)"), ("p",)),
                             (("der(a)", "der(b)"), ("w",)),
                             (("w",), ("a",))):
        f.write("%s / %s: %s\n" % (", ".join(unknowns), ", ".join(knowns), directional(unknowns, knowns)))
