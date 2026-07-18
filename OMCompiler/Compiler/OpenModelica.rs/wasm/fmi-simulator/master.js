// Master algorithms for FMI 3.0 Co-Simulation and Model Exchange FMUs.
//
// Co-Simulation advances the FMU with do-step; Model Exchange integrates the
// state derivatives here, with a Dormand-Prince 5(4) step and bisection on the
// event indicators to locate state events.
//
// Nothing in this file touches the DOM: the drivers work against the instance
// API that jco generates from the fmi:fmi3 WIT worlds.

const okish = (s) => s === 'ok' || s === 'warning';

// jco raises the error variant of a WIT result as a thrown value carrying the payload.
function reason(e) {
  if (e && typeof e === 'object' && e.payload !== undefined) return `status ${e.payload}`;
  return (e && e.message) || String(e);
}
function call(what, fn) {
  try { return fn(); } catch (e) { throw new Error(`${what}: ${reason(e)}`); }
}
function check(what, status) {
  if (!okish(status)) throw new Error(`${what}: status ${status}`);
}

const BIG = new Set(['Int64', 'UInt64']);
function coerce(type, v) {
  if (type === 'Boolean') return typeof v === 'boolean' ? v : !!v && v !== 'false';
  if (type === 'String') return String(v);
  if (BIG.has(type)) return BigInt(Math.round(Number(v)));
  if (type.startsWith('Float')) return Number(v);
  return Math.round(Number(v));
}
// Booleans plot as 0/1; s64/u64 arrive as BigInt.
const toNumber = (v) => (typeof v === 'boolean' ? (v ? 1 : 0) : Number(v));

function groupByType(items) {
  const groups = new Map();
  for (const it of items) {
    if (!groups.has(it.type)) groups.set(it.type, { type: it.type, vrs: [], items: [] });
    const g = groups.get(it.type);
    g.vrs.push(it.vr);
    g.items.push(it);
  }
  return [...groups.values()];
}

// Values pushed into the FMU each time the master reaches a new time point.
export function makeInputs(inputs) {
  const groups = groupByType(inputs);
  return (inst, t) => {
    for (const g of groups) {
      const values = g.items.map((i) => coerce(g.type, i.value(t)));
      check(`set-${g.type.toLowerCase()}`, inst[`set${g.type}`](g.vrs, values));
    }
  };
}

// Everything worth plotting: numeric variables the FMU computes or is driven with.
const RECORDED = new Set(['output', 'local', 'input']);

export function makeRecorder(md) {
  const vars = md.variables.filter(
    (v) => v.numeric && v.variability !== 'constant' && RECORDED.has(v.causality));
  const groups = groupByType(vars);
  const columns = vars.map((v) => ({ name: v.name, unit: v.unit, causality: v.causality, values: [] }));
  const index = new Map(vars.map((v, i) => [v, i]));
  const time = [];
  return {
    columns, time,
    warning: null,   // set when a run ends before the stop time for a benign reason
    sample(inst, t) {
      time.push(t);
      for (const g of groups) {
        const values = call(`get-${g.type.toLowerCase()}`, () => inst[`get${g.type}`](g.vrs));
        g.items.forEach((it, k) => columns[index.get(it)].values.push(toNumber(values[k])));
      }
    },
  };
}

function eventIteration(inst) {
  for (let i = 0; i < 100; i++) {
    const info = call('update-discrete-states', () => inst.updateDiscreteStates());
    if (!info.newDiscreteStatesNeeded) return info;
  }
  throw new Error('event iteration did not converge after 100 updates of the discrete states');
}

// fmi3GetNumberOfContinuousStates/EventIndicators are optional in practice; the
// model description carries the same counts.
function count(inst, method, fallback) {
  try { return Number(inst[method]()); } catch { return fallback; }
}

// Parameters are only settable in Initialization Mode, unlike the inputs, which
// the master keeps feeding the FMU as the simulation advances.
function initialize(inst, o, setInputs) {
  check('enter-initialization-mode',
    inst.enterInitializationMode(o.tolerance ?? undefined, o.startTime, o.stopTime ?? undefined));
  makeInputs(o.parameters || [])(inst, o.startTime);
  setInputs(inst, o.startTime);
  check('exit-initialization-mode', inst.exitInitializationMode());
}

// A cooperative yield so the page stays responsive and the run can be cancelled.
async function pump(o, t) {
  if (o.onProgress) o.onProgress(t);
  if (o.shouldCancel && o.shouldCancel()) throw new Error('cancelled');
  await new Promise((r) => setTimeout(r, 0));
}

export async function runCS(inst, md, o) {
  const setInputs = makeInputs(o.inputs || []);
  const rec = makeRecorder(md);
  // Resolved by `simulate` (capability AND the user's choice); default on.
  const eventMode = !!o.eventMode;

  initialize(inst, o, setInputs);
  if (eventMode) {
    eventIteration(inst);
    check('enter-step-mode', inst.enterStepMode());
  }
  rec.sample(inst, o.startTime);

  let t = o.startTime;
  let next = performance.now() + 40;
  while (t < o.stopTime - 1e-12) {
    const h = Math.min(o.stepSize, o.stopTime - t);
    setInputs(inst, t);
    const r = call('do-step', () => inst.doStep(t, h, false));
    const tNew = r.lastSuccessfulTime;
    if (!(tNew > t)) throw new Error(`do-step did not advance time past ${t}`);
    t = tNew;
    rec.sample(inst, t);
    if (r.eventHandlingNeeded && eventMode) {
      check('enter-event-mode', inst.enterEventMode());
      const info = eventIteration(inst);
      check('enter-step-mode', inst.enterStepMode());
      rec.sample(inst, t);
      if (info.terminateSimulation) { rec.warning = `the FMU requested termination at t = ${t}.`; break; }
    }
    if (r.terminateSimulation) { rec.warning = `the FMU requested termination at t = ${t}.`; break; }
    if (performance.now() > next) { await pump(o, t); next = performance.now() + 40; }
  }
  check('terminate', inst.terminate());
  return rec;
}

// Dormand-Prince 5(4).
const A = [
  [1 / 5],
  [3 / 40, 9 / 40],
  [44 / 45, -56 / 15, 32 / 9],
  [19372 / 6561, -25360 / 2187, 64448 / 6561, -212 / 729],
  [9017 / 3168, -355 / 33, 46732 / 5247, 49 / 176, -5103 / 18656],
  [35 / 384, 0, 500 / 1113, 125 / 192, -2187 / 6784, 11 / 84],
];
const C = [0, 1 / 5, 3 / 10, 4 / 5, 8 / 9, 1, 1];
const B5 = [35 / 384, 0, 500 / 1113, 125 / 192, -2187 / 6784, 11 / 84, 0];
const B4 = [5179 / 57600, 0, 7571 / 16695, 393 / 640, -92097 / 339200, 187 / 2100, 1 / 40];

export async function runME(inst, md, o) {
  const setInputs = makeInputs(o.inputs || []);
  const rec = makeRecorder(md);

  initialize(inst, o, setInputs);
  // exit-initialization-mode leaves a Model Exchange FMU in Event Mode.
  let info = eventIteration(inst);
  if (info.terminateSimulation) throw new Error('the FMU requested termination during initialization');
  check('enter-continuous-time-mode', inst.enterContinuousTimeMode());

  const nx = count(inst, 'getNumberOfContinuousStates', md.nStates);
  const nz = count(inst, 'getNumberOfEventIndicators', md.nEventIndicators);
  const rtol = o.tolerance || 1e-6;
  const atol = rtol * 1e-3;

  const commit = (t, x) => {
    check('set-time', inst.setTime(t));
    if (nx) check('set-continuous-states', inst.setContinuousStates(x));
    setInputs(inst, t);
  };
  const derivatives = (t, x) => {
    commit(t, x);
    return nx ? call('get-continuous-state-derivatives', () => inst.getContinuousStateDerivatives()) : [];
  };
  const indicators = (t, x) => {
    commit(t, x);
    return nz ? call('get-event-indicators', () => inst.getEventIndicators()) : [];
  };
  // One DP5(4) step from (t, x); returns the 5th-order state and the error estimate.
  const step = (t, x, h) => {
    const k = [derivatives(t, x)];
    for (let s = 1; s < 7; s++) {
      const xs = x.map((xi, i) => {
        let sum = xi;
        for (let j = 0; j < s; j++) if (A[s - 1][j]) sum += h * A[s - 1][j] * k[j][i];
        return sum;
      });
      k.push(derivatives(t + C[s] * h, xs));
    }
    const y5 = x.map((xi, i) => xi + h * B5.reduce((a, b, j) => a + b * k[j][i], 0));
    const y4 = x.map((xi, i) => xi + h * B4.reduce((a, b, j) => a + b * k[j][i], 0));
    let err = 0;
    for (let i = 0; i < x.length; i++) {
      const sc = atol + rtol * Math.max(Math.abs(x[i]), Math.abs(y5[i]));
      err += ((y5[i] - y4[i]) / sc) ** 2;
    }
    return { y: y5, err: x.length ? Math.sqrt(err / x.length) : 0 };
  };
  const crossed = (z0, z1) => z0.some((v, i) => (v < 0) !== (z1[i] < 0));

  const handleEvent = (t, x) => {
    check('enter-event-mode', inst.enterEventMode());
    const ev = eventIteration(inst);
    if (ev.valuesOfContinuousStatesChanged && nx) {
      x = call('get-continuous-states', () => inst.getContinuousStates());
    }
    check('enter-continuous-time-mode', inst.enterContinuousTimeMode());
    return { x, ev };
  };

  let t = o.startTime;
  let x = nx ? call('get-continuous-states', () => inst.getContinuousStates()) : [];
  let z = indicators(t, x);
  let tEvent = info.nextEventTimeDefined ? info.nextEventTime : Infinity;
  rec.sample(inst, t);

  const span = o.stopTime - o.startTime;
  const hMax = o.stepSize > 0 ? o.stepSize : span / 500;
  const hMin = span * 1e-12;
  let h = Math.min(hMax, span / 100);
  let next = performance.now() + 40;
  // Zeno models (a bouncing ball is the classic one) reach a point where events
  // never stop arriving. Give up there instead of spinning, keeping the results.
  let lastEvent = -Infinity, chatter = 0;

  while (t < o.stopTime - 1e-12) {
    let timed = false;
    let hTry = Math.min(h, hMax, o.stopTime - t);
    if (tEvent <= t + hTry) { hTry = tEvent - t; timed = true; }
    if (hTry < hMin) throw new Error(`the step size underflowed at t = ${t}`);

    const { y, err } = step(t, x, hTry);
    if (err > 1 && !timed && hTry > hMin) {
      h = Math.max(hMin, hTry * Math.max(0.2, 0.9 * err ** -0.25));
      continue;
    }
    if (!timed) h = Math.min(hMax, hTry * Math.min(5, Math.max(0.2, 0.9 * err ** -0.2)));

    // A sign change over the step means a state event inside it: bisect for the
    // earliest crossing, then step exactly onto it.
    let tNew = t + hTry, xNew = y;
    let zNew = indicators(tNew, xNew);
    let event = timed;
    if (nz && crossed(z, zNew)) {
      let lo = 0, hi = hTry;
      const eps = Math.max(1e-14, span * 1e-10);
      while (hi - lo > eps) {
        const mid = (lo + hi) / 2;
        const xm = step(t, x, mid).y;
        if (crossed(z, indicators(t + mid, xm))) hi = mid; else lo = mid;
      }
      tNew = t + hi; xNew = step(t, x, hi).y;
      zNew = indicators(tNew, xNew);
      event = true;
      h = Math.max(hMin, Math.min(h, hTry));
    }

    commit(tNew, xNew);
    const cis = call('completed-integrator-step', () => inst.completedIntegratorStep(true));
    t = tNew; x = xNew; z = zNew;
    rec.sample(inst, t);
    if (cis.terminateSimulation) { rec.warning = `the FMU requested termination at t = ${t}.`; break; }

    if (event || cis.enterEventMode) {
      const r = handleEvent(t, x);
      x = r.x;
      z = indicators(t, x);
      tEvent = r.ev.nextEventTimeDefined ? r.ev.nextEventTime : Infinity;
      rec.sample(inst, t);
      if (r.ev.terminateSimulation) { rec.warning = `the FMU requested termination at t = ${t}.`; break; }
      chatter = t - lastEvent < span * 1e-9 ? chatter + 1 : 0;
      lastEvent = t;
      if (chatter > 100) {
        rec.warning = `stopped at t = ${t}: over 100 events arrived within ${span * 1e-9} of each other, so the model is chattering (a Zeno model reaches this).`;
        break;
      }
    }
    if (performance.now() > next) { await pump(o, t); next = performance.now() + 40; }
  }
  check('terminate', inst.terminate());
  return rec;
}

// Instantiates the FMU for the requested interface and runs the matching master.
export async function simulate(fmu, kind, o) {
  const md = fmu.md;
  const name = md.modelName || 'fmu';
  const token = md.instantiationToken;
  let inst;
  if (kind === 'cs') {
    // Needs the capability; within it the caller may opt out. Default on.
    // eventModeUsed and earlyReturnAllowed move together.
    const eventMode = !!md.cs.hasEventMode && (o.eventMode ?? true);
    inst = fmu.cs.CoSimulationInstance.instantiateCoSimulation(
      name, token, fmu.resourcePath, false, true, eventMode, eventMode, []);
    if (!inst) throw new Error('instantiate-co-simulation returned no instance');
    return await runCS(inst, md, { ...o, eventMode });
  }
  inst = fmu.me.ModelExchangeInstance.instantiateModelExchange(
    name, token, fmu.resourcePath, false, true);
  if (!inst) throw new Error('instantiate-model-exchange returned no instance');
  return await runME(inst, md, o);
}
