"""Log categories of a C FMU (#11500): the runtime's messages go to logMessage,
in the category of their stream, and only while that category is enabled.

usage: fmi3_log_categories.py <fmu> <output_txt>
"""
import sys
import xml.etree.ElementTree as ET
import zipfile

from fmpy import extract, read_model_description
from fmpy.fmi3 import FMU3Slave

fmu = sys.argv[1]
out = open(sys.argv[2], "w")
md = read_model_description(fmu)
unzipdir = extract(fmu)
log = []

with zipfile.ZipFile(fmu) as z:
    root = ET.fromstring(z.read("modelDescription.xml"))
out.write("declared: " + " ".join(c.get("name") for c in root.iter("Category")) + "\n")


def logMessage(env, status, category, message):
    log.append((category.decode() if category else "NULL", message.decode()))


def run(title, loggingOn, calls, check=None):
    del log[:]
    f = FMU3Slave(guid=md.guid, unzipDirectory=unzipdir, modelIdentifier=md.coSimulation.modelIdentifier, instanceName="i")
    f.instantiate(loggingOn=loggingOn, logMessage=logMessage)
    if calls:
        del log[:]
    for on, categories in calls:
        f.setDebugLogging(on, categories)
    f.enterInitializationMode()
    f.exitInitializationMode()
    for i in range(10):
        f.doStep(0.1 * i, 0.1)
    f.terminate()
    f.freeInstance()
    logged = {c for c, _ in log}
    if check:
        out.write(title + ":" + "".join(" %s=%s" % (c, c in logged) for c in check) + "\n")
    else:
        out.write(title + ":" + "".join(" " + c for c in sorted(logged)) + "\n")
    for c, m in log:
        if c in ("LOG_STDOUT", "logStatusWarning"):
            out.write("  %s: %s\n" % (c, m))


run("logging off", False, [])
run("logging on", True, [], ["LOG_STDOUT", "LOG_INIT", "LOG_SOLVER", "logEvents"])
run("LOG_STDOUT, then logEvents", True, [(False, []), (True, ["LOG_STDOUT"]), (True, ["logEvents"])])
run("unknown category, warnings off", True, [(False, []), (True, ["noSuchCategory"])])
run("unknown category, warnings on", True, [(False, []), (True, ["logStatusWarning"]), (True, ["noSuchCategory"])])
