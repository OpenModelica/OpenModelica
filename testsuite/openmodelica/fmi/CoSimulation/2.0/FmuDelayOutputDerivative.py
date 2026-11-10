"""Step a CS FMU with y = delay(x, 0.1) to t = 0.5 and get y and der(y).

usage: FmuDelayOutputDerivative.py <fmu> <output_txt>
"""
import sys

from fmpy import extract, read_model_description
from fmpy.fmi2 import FMU2Slave
from fmpy.fmi3 import FMU3Slave


def main(fmu, output):
    md = read_model_description(fmu)
    vr = [v.valueReference for v in md.modelVariables if v.name == "y"]
    fmi2 = md.fmiVersion == "2.0"
    kw = dict(guid=md.guid if fmi2 else md.instantiationToken,
              unzipDirectory=extract(fmu), instanceName="instance",
              modelIdentifier=md.coSimulation.modelIdentifier)
    if fmi2:
        s = FMU2Slave(**kw)
        s.instantiate()
        s.setupExperiment(startTime=0.0)
        s.enterInitializationMode()
        s.exitInitializationMode()
        get, get_der = s.getReal, s.getRealOutputDerivatives
    else:
        s = FMU3Slave(**kw)
        s.instantiate()
        s.enterInitializationMode(startTime=0.0)
        s.exitInitializationMode()
        get, get_der = s.getFloat64, s.getOutputDerivatives
    for k in range(50):
        s.doStep(0.01 * k, 0.01)
    with open(output, "w") as f:
        f.write("maxOutputDerivativeOrder = %s\n" % md.coSimulation.maxOutputDerivativeOrder)
        f.write("y(0.5) = %.3f\n" % get(vr)[0])
        f.write("der(y)(0.5) = %.3f\n" % get_der(vr, [1])[0])
    s.terminate()
    s.freeInstance()


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
