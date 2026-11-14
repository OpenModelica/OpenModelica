"""Run an FMI 3.0 Model Exchange FMU whose model has two asserts with "%s"
in the text. Write the status of fmi3GetContinuousStateDerivatives and the
warning and error messages that the FMU gives to the logMessage callback.
In FMI 3.0 the message is plain text, not a format.

usage: fmi3LogFormatCpp.py <fmu> <output_txt>
"""
import sys

from fmpy import extract, read_model_description
from fmpy.fmi3 import FMU3Model, fmi3Float64

messages = []


def log_message(env, status, category, message):
    # status 1 = fmi3Warning, 3 = fmi3Error
    if status in (1, 3):
        messages.append("status %d: %s" % (status, message.decode(errors="backslashreplace")))


def main(fmu, output):
    md = read_model_description(fmu)
    m = FMU3Model(guid=md.guid, unzipDirectory=extract(fmu),
                  modelIdentifier=md.modelExchange.modelIdentifier)
    m.instantiate(loggingOn=True, logMessage=log_message)
    m.enterInitializationMode(startTime=0.0)
    m.exitInitializationMode()
    m.enterContinuousTimeMode()
    lines = []
    x, dx = (fmi3Float64 * 1)(), (fmi3Float64 * 1)()
    for xv in (0.6, 0.9):
        del messages[:]
        x[0] = xv
        m.setTime(xv)
        m.setContinuousStates(x, 1)
        status = m.dll.fmi3GetContinuousStateDerivatives(m.component, dx, 1)
        lines.append("x = %g: fmi3GetContinuousStateDerivatives status %d" % (xv, status))
        lines += messages
    with open(output, "w") as f:
        f.write("\n".join(lines) + "\n")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
