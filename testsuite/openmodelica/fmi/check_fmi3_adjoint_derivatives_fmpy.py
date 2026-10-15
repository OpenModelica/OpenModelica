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
from fmpy.fmi1 import FMICallException
from fmpy.fmi3 import FMU3Model, fmi3Float64


def check(actual, expected):
    assert len(actual) == len(expected), (actual, expected)
    assert all(
        math.isclose(a, e, rel_tol=1e-12, abs_tol=1e-12)
        for a, e in zip(actual, expected)
    ), "Expected %s, got %s" % (expected, actual)


def main(argv):
    if len(argv) not in (2, 3) or (
        len(argv) == 3 and argv[2] not in ("parameters", "default-parameters")
    ):
        sys.stderr.write(
            "usage: check_fmi3_adjoint_derivatives_fmpy.py <fmu> "
            "[parameters|default-parameters]\n"
        )
        return 2

    filename = argv[1]
    mode = argv[2] if len(argv) == 3 else "states-inputs"
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
            # Suppress the expected fmi3Error diagnostic in the default-parameter
            # rejection check so the regression output is independent of logging.
            if mode == "default-parameters":
                fmu.instantiate(logMessage=lambda *args: None)
            else:
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

            if mode == "parameters":
                parameters = [vr[name] for name in ("p", "q", "r", "unused")]
                all_knowns = knowns + parameters
                for seed, expected in [
                    ([1.0, 0.0, 0.0], [-2.0, 3.0, 5.0, 1.0, 0.0, 0.0, 0.0]),
                    ([0.0, 1.0, 0.0], [7.0, -11.0, 13.0, 0.0, 0.5, 0.0, 0.0]),
                    ([0.0, 0.0, 1.0], [17.0, 19.0, 23.0, 0.0, 0.0, 0.5, 0.0]),
                    ([2.0, -3.0, 5.0], [60.0, 134.0, 86.0, 2.0, -1.5, 2.5, 0.0]),
                    ([0.0, 0.0, 0.0], [0.0] * 7),
                ]:
                    check(adjoint(unknowns, all_knowns, seed), expected)

                # Non-consecutive/reordered parameter VRs and unequal axis lengths.
                check(
                    adjoint(unknowns[::-1], parameters[::-1], [5.0, -3.0, 2.0]),
                    [0.0, 2.5, -1.5, 2.0],
                )
                check(adjoint([vr["der(x)"]], [vr["p"]], [1.0]), [1.0])

                # Derivatives must use current state/input values, not initial ones.
                fmu.setContinuousStates(
                    (fmi3Float64 * 2)(4.0, -1.0), 2
                )
                fmu.setFloat64([vr["u"]], [2.0])
                check(adjoint(unknowns, parameters, [2.0, -3.0, 5.0]),
                      [8.0, -6.0, 10.0, 0.0])
                check(adjoint(unknowns, parameters, [0.0, 0.0, 0.0]), [0.0] * 4)
                message = "PASS: FMI 3 New Backend adjoint parameter derivatives"
            elif mode == "default-parameters":
                # A parameter must not be mistaken for a state after a failed
                # input lookup. Check this last, since fmi3Error may end the session.
                try:
                    adjoint([vr["der(x)"]], [vr["p"]], [1.0])
                except FMICallException as error:
                    assert error.status == 3, error
                else:
                    raise AssertionError("Parameter derivatives enabled by default")
                message = "PASS: FMI 3 New Backend adjoint parameters excluded by default"
            else:
                message = "PASS: FMI 3 New Backend export and adjoint derivatives"

            if mode != "default-parameters":
                fmu.terminate()
            print(message)
        finally:
            if instantiated:
                fmu.freeInstance()
            else:
                fmu.freeLibrary()

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
