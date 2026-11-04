import subprocess, sys
from fmpy import read_model_description, extract, instantiate_fmu

# Not 0.5: there an Euler step ends exactly on x = 0, which is an event.
T = [0.49, 0.5000002]

def run(fmu):
    md = read_model_description(fmu)
    fmu_inst = instantiate_fmu(extract(fmu), md, fmi_type="CoSimulation")
    if md.fmiVersion == "2.0":
        fmu_inst.setupExperiment(startTime=0.0)
    fmu_inst.enterInitializationMode()
    fmu_inst.exitInitializationMode()
    t = 0.0
    for t1 in T:
        fmu_inst.doStep(t, t1 - t)
        t = t1
    fmu_inst.terminate()
    fmu_inst.freeInstance()

if sys.argv[1] == "--run":
    run(sys.argv[2])
    sys.exit(0)

with open(sys.argv[-1], "w") as out:
    for name, fmu in zip(("FMI 2.0", "FMI 3.0", "FMI 2.0 Euler"), sys.argv[1:-1]):
        p = subprocess.run([sys.executable, __file__, "--run", fmu], capture_output=True, text=True, timeout=120)
        out.write("%s: chattering detected: %s\n" % (name, "Chattering detected" in p.stdout))
