#!/usr/bin/env python3
"""Validate FMI 3.0 adjoint derivatives via FMPy.

This helper is used by the FMI 3.0 ModelExchange tests. It opens an FMU
exported by OpenModelica with the new backend and verifies that
fmi3GetAdjointDerivative returns correct vector-Jacobian products.
"""

import math
import sys
from tempfile import TemporaryDirectory

from fmpy import extract, read_model_description
from fmpy.fmi3 import FMU3Model


def check(actual, expected):
    assert len(actual) == len(expected), (actual, expected)
    assert all(
        math.isclose(a, e, rel_tol=1e-12, abs_tol=1e-12)
        for a, e in zip(actual, expected)
    ), "Expected %s, got %s" % (expected, actual)


def main(argv):
    if len(argv) != 2:
        sys.stderr.write("usage: check_fmi3_adjoint_derivatives_fmpy.py <fmu>\n")
        return 2

    filename = argv[1]
    md = read_model_description(filename, validate=False)

    assert md.fmiVersion == "3.0", md.fmiVersion
    assert md.modelExchange is not None, "Not a Model Exchange FMU"
    assert md.modelExchange.providesAdjointDerivatives, (
        "FMU does not advertise providesAdjointDerivatives"
    )

    # Always obtain value references from metadata, never hard-code them.
    vr = {v.name: v.valueReference for v in md.modelVariables}
    unknowns = [vr["der(x)"], vr["der(z)"], vr["y"]]
    knowns = [vr["x"], vr["z"], vr["u"]]

    with TemporaryDirectory(prefix="adjoint-smoke-") as directory:
        extract(filename, unzipdir=directory)

        fmu = FMU3Model(
            guid=md.guid,
            unzipDirectory=directory,
            modelIdentifier=md.modelExchange.modelIdentifier,
            instanceName="adjoint-smoke",
        )

        instantiated = False
        try:
            fmu.instantiate()
            instantiated = True

            fmu.enterInitializationMode(startTime=0.0)
            fmu.setFloat64([vr["u"]], [0.5])
            fmu.exitInitializationMode()

            # Complete the initial event iteration before continuous-time mode.
            for _ in range(10):
                update = fmu.updateDiscreteStates()
                assert not update[1], "FMU requested termination"
                if not update[0]:
                    break
            else:
                raise AssertionError("Initial event iteration did not converge")

            fmu.enterContinuousTimeMode()

            check(fmu.getFloat64([vr["x"], vr["z"]]), [1.0, 2.0])
            check(fmu.getFloat64(unknowns), [6.5, -8.5, 66.5])

            def adjoint(unkns, kns, seed):
                return fmu.getAdjointDerivative(
                    unknowns=unkns,
                    knowns=kns,
                    seed=seed,
                    nSensitivity=len(kns),
                )

            # Basis seeds recover each row of the forward Jacobian.
            for seed, expected in [
                ([1.0, 0.0, 0.0], [-2.0, 3.0, 5.0]),
                ([0.0, 1.0, 0.0], [7.0, -11.0, 13.0]),
                ([0.0, 0.0, 1.0], [17.0, 19.0, 23.0]),
                ([2.0, -3.0, 5.0], [60.0, 134.0, 86.0]),
                ([0.0, 0.0, 0.0], [0.0, 0.0, 0.0]),
            ]:
                check(adjoint(unknowns, knowns, seed), expected)

            # Exercise value-reference mapping independently of internal ordering.
            check(
                adjoint(unknowns[::-1], knowns[::-1], [5.0, -3.0, 2.0]),
                [86.0, 134.0, 60.0],
            )

            # Unequal axis lengths; also checks that omitted seeds are cleared.
            check(
                adjoint([vr["y"]], knowns, [1.0]),
                [17.0, 19.0, 23.0],
            )

            fmu.terminate()
            print("PASS: FMI 3 New Backend export and adjoint derivatives")
        finally:
            if instantiated:
                fmu.freeInstance()
            else:
                fmu.freeLibrary()

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
