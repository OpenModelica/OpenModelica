#!/usr/bin/env python3
"""Run a --daeMode Model Exchange FMU of fmi-ls-dae with FMPy, with implicit
Euler and fixed steps.

In DAE mode the importer owns the states and the algebraic variables, and
solves the residuals that the FMU gives with Newton. In the semi-explicit form
the derivatives of the states are algebraic variables too (ContinuousStateDerivative),
and the importer adds the rows der(x) = getContinuousStateDerivatives(). In ODE mode
the FMU solves them. After an event the event indicators are read again, as
FMI 3.0 says. Prints the residuals after initialization and the variables at
the stop time. In ODE mode, also whether the derivatives right after each event
are those of the new discrete values: the same as a solve forced at that point.

Usage: fmi3_daemode_me.py <fmu> <ode|dae> <stop_time> <steps> <var> [<var> ...]
"""
import sys
import zipfile
import xml.etree.ElementTree as ET
from ctypes import c_double

import numpy as np
from fmpy import extract, read_model_description
from fmpy.fmi3 import FMU3Model

LS_DAE = "extra/org.fmi-standard.fmi-ls-dae/fmi-ls-manifest.xml"


def main(fmu, mode, stop, steps, variables):
    md = read_model_description(fmu)
    with zipfile.ZipFile(fmu) as z:
        manifest = ET.fromstring(z.read(LS_DAE))
    enable = int(manifest.find("EnableDAEParameter").get("valueReference"))
    alg = [int(a.get("valueReference")) for a in manifest.iter("AlgebraicVariable")]
    res = [int(r.get("valueReference")) for r in manifest.iter("Residual")]
    semi = manifest.find("ModelStructure/ContinuousStateDerivative") is not None
    ders = [u.variable.valueReference for u in md.derivatives]
    states = [u.variable.derivative.valueReference for u in md.derivatives]
    vrs = {v.name: v.valueReference for v in md.modelVariables}
    nx, nz = len(states), md.numberOfEventIndicators
    dae = mode == "dae"

    inst = FMU3Model(guid=md.guid, unzipDirectory=extract(fmu),
                     modelIdentifier=md.modelExchange.modelIdentifier, instanceName="dae")
    inst.instantiate()
    if dae:
        inst.enterConfigurationMode()
        inst.setBoolean([enable], [True])
        inst.exitConfigurationMode()
    inst.enterInitializationMode(startTime=0.0, stopTime=stop)
    inst.exitInitializationMode()

    def event_iteration():
        while inst.updateDiscreteStates()[0]:
            pass

    def indicators():
        z = (c_double * nz)()
        if nz:
            inst.getEventIndicators(z, nz)
        return np.array(z[:])

    event_iteration()
    inst.enterContinuousTimeMode()
    print("initial residuals: %.3g" % max(abs(r) for r in inst.getFloat64(res)))

    x = np.array(inst.getFloat64(states))
    h = stop / steps
    t = 0.0
    ei = indicators()

    def set_states(xn):
        inst.setContinuousStates((c_double * nx)(*xn), nx)

    def residual(u):
        if dae:
            set_states(u[:nx])
            if not semi:
                inst.setFloat64(ders, list((u[:nx] - x) / h))
            inst.setFloat64(alg, list(u[nx:]))
            f = np.array(inst.getFloat64(res))
            if semi:
                return np.concatenate((f, (u[:nx] - x) / h - derivatives()))
            return f
        set_states(u)
        der = (c_double * nx)()
        inst.getContinuousStateDerivatives(der, nx)
        return u - x - h * np.array(der[:])

    def derivatives():
        der = (c_double * nx)()
        inst.getContinuousStateDerivatives(der, nx)
        return np.array(der[:])

    stale = []

    def check_after_event():
        """The FMU's derivatives at the event point against a solve forced there:
        moving the states away and back makes it solve again."""
        first = derivatives()
        set_states(x + 1e-3 * (1.0 + np.abs(x)))
        derivatives()
        set_states(x)
        if not np.allclose(first, derivatives(), rtol=1e-8, atol=1e-10):
            stale.append(t)

    for _ in range(steps):
        t += h
        inst.setTime(t)
        u = np.array(inst.getFloat64(states + alg if dae else states))
        for _ in range(20):
            f = residual(u)
            jac = np.empty((len(u), len(u)))
            for j in range(len(u)):
                du = 1e-7 * max(1.0, abs(u[j]))
                v = u.copy()
                v[j] += du
                jac[:, j] = (residual(v) - f) / du
            step = np.linalg.solve(jac, -f)
            u += step
            if np.all(np.abs(step) <= 1e-10 * (1.0 + np.abs(u))):
                break
        residual(u)
        x = u[:nx]
        enter_event, _ = inst.completedIntegratorStep()
        ei_new = indicators()
        if enter_event or np.any(ei * ei_new < 0):
            inst.enterEventMode()
            event_iteration()
            inst.enterContinuousTimeMode()
            if not dae:
                check_after_event()
            ei_new = indicators()
        ei = ei_new

    if not dae:
        print("derivatives after events: %s" % ("stale at t = %s" % stale if stale else "fresh"))

    for name in variables:
        print("%s = %.4f" % (name, inst.getFloat64([vrs[name]])[0]))
    inst.terminate()
    inst.freeInstance()
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1], sys.argv[2], float(sys.argv[3]), int(sys.argv[4]), sys.argv[5:]))
