"""Spatial history through an independent FMI 3 co-simulation master."""
import contextlib
import shutil
import unittest

from fmpy import extract, read_model_description
from fmpy.fmi3 import FMU3Slave


@contextlib.contextmanager
def instance(name, event_mode=False, early=False):
    description = read_model_description(name + ".fmu")
    directory = extract(name + ".fmu")
    fmu = FMU3Slave(guid=description.instantiationToken, unzipDirectory=directory,
                    modelIdentifier=description.coSimulation.modelIdentifier)
    try:
        fmu.instantiate(eventModeUsed=event_mode, earlyReturnAllowed=early)
        fmu.enterInitializationMode(tolerance=1e-8)
        fmu.exitInitializationMode()
        if event_mode:
            while fmu.updateDiscreteStates()[0]:
                pass
            fmu.enterStepMode()
        vr = {v.name: v.valueReference for v in description.modelVariables}
        yield fmu, vr
    finally:
        fmu.freeInstance()
        shutil.rmtree(directory)


def advance(fmu, start, target):
    events = []
    for _ in range(100):
        event, terminate, early, reached = fmu.doStep(start, target - start)
        assert not terminate
        start = reached if early else target
        if event:
            events.append(start)
            fmu.enterEventMode()
            while fmu.updateDiscreteStates()[0]:
                pass
            fmu.enterStepMode()
        if start >= target - 1e-12:
            return events
    raise AssertionError("co-simulation made no progress")


class SpatialCoSimulation(unittest.TestCase):
    def test_dae_refreshes_inlet(self):
        with instance("SpatialCSDae") as (fmu, vr):
            advance(fmu, 0, 1)
            expected = sum(0.1**(k-1) * (1-0.1*k)**2 / 2 for k in range(1, 11))
            self.assertAlmostEqual(fmu.getFloat64([vr["area"]])[0], expected, places=6)

    def test_repeated_history_subdivision(self):
        for event_mode, early in [(False, False), (True, False), (True, True)]:
            with self.subTest(event_mode=event_mode, early=early):
                with instance("SpatialCSHistory", event_mode, early) as (fmu, vr):
                    advance(fmu, 0, 1)
                    self.assertAlmostEqual(fmu.getFloat64([vr["y"]])[0], 0.9, places=6)
                    self.assertEqual(fmu.getInt32([vr["ticks"]])[0], 2)

    def test_deferred_event_keeps_left_limit(self):
        with instance("SpatialCSEvent", event_mode=True, early=True) as (fmu, vr):
            events = advance(fmu, 0, 1.125)
            self.assertTrue(any(abs(t - 0.25) < 1e-6 for t in events))
            self.assertAlmostEqual(fmu.getFloat64([vr["y"]])[0], 0, places=6)
            advance(fmu, 1.125, 1.5)
            self.assertAlmostEqual(fmu.getFloat64([vr["y"]])[0], 1, places=6)

    def test_internal_events_preserve_pulse(self):
        with instance("SpatialCSPulse", event_mode=True) as (fmu, vr):
            self.assertEqual(advance(fmu, 0, 1), [])
            self.assertAlmostEqual(fmu.getFloat64([vr["area"]])[0], 0.2, places=6)


if __name__ == "__main__":
    unittest.main()
