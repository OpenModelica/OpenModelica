// Unit conversion, shared by the simulator and the FMI simulator.
//
// FMI gives a display unit as `factor` and `offset`: the display value is
// `factor*value + offset`, or `factor/value` for a reciprocal unit such as mpg
// or Siemens, which `inverse` marks and the spec allows only with a zero
// offset. Doing
// that in doubles turns 293.15 K into 20.000000000000057 degC, so a value the
// reader sees or types goes through exact decimal arithmetic instead: factors,
// offsets and typed values are all decimal literals, and +, - and * over them
// are exact. Division is exact whenever it terminates and rounded at DIGITS
// otherwise.
//
// Sample arrays take the plain double path (`scale`): a plot is approximate by
// the time it is pixels, and exact arithmetic per sample is far too slow.

const DIGITS = 34;

// s * d * 10^e, with `d` a BigInt.
function dec(x) {
  const str = typeof x === 'string' ? x.trim() : String(x);
  const m = /^([+-]?)(\d*)(?:\.(\d*))?(?:[eE]([+-]?\d+))?$/.exec(str);
  if (!m || (!m[2] && !m[3])) return null;
  const digits = (m[2] || '') + (m[3] || '');
  if (!/^\d+$/.test(digits)) return null;
  return norm({ s: m[1] === '-' ? -1n : 1n, d: BigInt(digits), e: (m[3] ? -m[3].length : 0) + (m[4] ? +m[4] : 0) });
}

function norm(a) {
  if (a.d === 0n) return { s: 1n, d: 0n, e: 0 };
  while (a.d % 10n === 0n) { a.d /= 10n; a.e++; }
  return a;
}

const align = (a, b) => {
  const e = Math.min(a.e, b.e);
  return [a.s * a.d * 10n ** BigInt(a.e - e), b.s * b.d * 10n ** BigInt(b.e - e), e];
};

function add(a, b) {
  const [x, y, e] = align(a, b), v = x + y;
  return norm({ s: v < 0n ? -1n : 1n, d: v < 0n ? -v : v, e });
}
const sub = (a, b) => add(a, { ...b, s: -b.s });
const mul = (a, b) => norm({ s: a.s * b.s, d: a.d * b.d, e: a.e + b.e });

function div(a, b) {
  if (b.d === 0n) return null;
  // Scale the numerator until the division comes out whole, or DIGITS is spent.
  let num = a.d, e = a.e - b.e, k = 0;
  while (num % b.d !== 0n && k < DIGITS) { num *= 10n; e--; k++; }
  const q = num / b.d, r = num % b.d;
  // Not terminating: round half up on the digit after the last kept one.
  const rounded = r === 0n ? q : (2n * r >= b.d ? q + 1n : q);
  return norm({ s: a.s * b.s, d: rounded, e });
}

function str(a) {
  if (a.d === 0n) return '0';
  const sign = a.s < 0n ? '-' : '';
  let digits = a.d.toString();
  if (a.e >= 0) return sign + digits + '0'.repeat(a.e);
  const point = digits.length + a.e;
  if (point > 0) return sign + digits.slice(0, point) + '.' + digits.slice(point);
  return sign + '0.' + '0'.repeat(-point) + digits;
}

/// The `factor`/`offset`/`inverse` of one `<DisplayUnit>`, as decimals.
function parts(d) {
  const f = dec(d.factor == null ? 1 : d.factor), o = dec(d.offset == null ? 0 : d.offset);
  if (!f || !o || f.d === 0n) return null;
  // The spec allows `inverse` only with a zero offset; anything else is a
  // malformed file, and guessing what it meant would be worse than not converting.
  if (d.inverse && o.d !== 0n) return null;
  return { f, o, inverse: !!d.inverse };
}

/// A value in the unit, as a string in the display unit. `null` if it does not
/// convert -- including a reciprocal unit at zero, which has no display value.
export function toDisplay(value, d) {
  const p = parts(d), v = dec(value);
  if (!p || !v) return null;
  if (!p.inverse) return str(add(mul(p.f, v), p.o));
  const r = v.d === 0n ? null : div(p.f, v);
  return r && str(r);
}

/// The reverse: a value in the display unit, as a string in the unit itself.
/// `factor/value` is its own inverse, so a reciprocal unit converts back the
/// same way.
export function fromDisplay(value, d) {
  const p = parts(d), v = dec(value);
  if (!p || !v) return null;
  if (p.inverse) return v.d === 0n ? null : (div(p.f, v) && str(div(p.f, v)));
  const r = div(sub(v, p.o), p.f);
  return r && str(r);
}

/// The display unit as it applies to a `relativeQuantity` value: a difference in
/// the unit scales but does not shift, so FMI drops the offset. A reciprocal unit
/// has none to drop.
export function relative(d) {
  return d && !d.inverse && d.offset ? { ...d, offset: 0 } : d;
}

/// The double-precision `unit -> display` map, for sample arrays.
export function scale(d) {
  const f = d.factor == null ? 1 : d.factor, o = d.offset == null ? 0 : d.offset;
  return d.inverse ? (v) => f / v : (v) => f * v + o;
}
