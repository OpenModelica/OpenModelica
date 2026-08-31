#!/usr/bin/env python3

#
# This file belongs to the OpenModelica Run-Time System
#
# Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
# c/o Linköpings universitet, Department of Computer and Information Science,
# SE-58183 Linköping, Sweden. All rights reserved.
#
# THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
# AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
# USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
# ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
# VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
#
# The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
# (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
# http://www.openmodelica.org or https://github.com/OpenModelica/ or
# http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution.
# GNU AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL.
# The BSD NEW License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
#
# This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
# SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
# OSMC-PL.
#

"""Transcribe the gbode Butcher tableau data from gbode_tableau.c into Rust.

The tableau bodies in C are a very regular sequence of `const double x[] = {...}`
declarations followed by set*() calls, so this is a mechanical translation: the
numeric literals and arithmetic carry over to Rust unchanged, `sqrt(x)` becomes
`f64::sqrt(x)` and the set*() calls map onto the Rust builder helpers.
"""
import re
import sys

C = sys.argv[1]
OUT = sys.argv[2]
OPTS = sys.argv[3]

src = open(C).read()
# strip comments (they contain braces/semicolons that would confuse the split)
s = re.sub(r'/\*.*?\*/', '', src, flags=re.S)
s = re.sub(r'//[^\n]*', '', s)


def _num(m):
    """Normalize a C numeric literal to a Rust f64 literal."""
    lit = m.group(0)
    exp = ''
    for sep in ('e', 'E'):
        if sep in lit:
            lit, e = lit.split(sep, 1)
            exp = sep + e
            break
    if lit.startswith('.'):
        lit = '0' + lit
    if lit.endswith('.'):
        lit += '0'
    if '.' not in lit and not exp:
        lit += '.0'
    return lit + exp


def iexpr(e):
    """C int expression -> Rust integer expression (no float normalization)."""
    e = ' '.join(e.split())
    e = e.replace('tableau->nStages', '(t.n_stages as i32)')
    return e


def expr(e):
    """C double expression -> Rust f64 expression."""
    e = ' '.join(e.split())
    e = re.sub(r'\bsqrt\s*\(', 'sqrt(', e)
    e = e.replace('tableau->b_dt[', 'b_dt[')
    # Protect array subscripts from the numeric-literal normalization below.
    subs = []
    def keep(m):
        subs.append(m.group(0))
        return '__sub%d__' % (len(subs) - 1)
    e = re.sub(r'\[\s*\d+\s*\]', keep, e)
    e = re.sub(r'(?<![\w.])(\d+\.?\d*(?:[eE][+-]?\d+)?|\.\d+(?:[eE][+-]?\d+)?)', _num, e)
    for i, sub in enumerate(subs):
        e = e.replace('__sub%d__' % i, sub)
    e = e.replace('tableau->nStages', '(t.n_stages as i32)')
    e = e.replace('TRUE', 'true').replace('FALSE', 'false')
    return e


def num_list(text):
    """Split a brace initialiser into its top-level elements."""
    out, cur, depth = [], '', 0
    for ch in text:
        if ch in '([':
            depth += 1
        elif ch in ')]':
            depth -= 1
        if ch == ',' and depth == 0:
            out.append(cur)
            cur = ''
            continue
        cur += ch
    if cur.strip():
        out.append(cur)
    return [expr(x) for x in out]


def split_stmts(body):
    """Split a function body into statements / brace blocks, tracking nesting.

    A `}` at depth 0 ends the statement unless an `else` follows it.
    """
    stmts, cur, depth, i = [], '', 0, 0
    while i < len(body):
        ch = body[i]
        i += 1
        if ch == '{':
            depth += 1
        elif ch == '}':
            depth -= 1
            if depth == 0:
                cur += ch
                if re.match(r'\s*else\b', body[i:]):
                    continue
                stmts.append(cur.strip())
                cur = ''
                continue
        if ch == ';' and depth == 0:
            stmts.append(cur.strip())
            cur = ''
            continue
        cur += ch
    if cur.strip():
        stmts.append(cur.strip())
    return [x for x in stmts if x]


ARRAY_DECL = re.compile(r'const\s+(double|int|modelica_boolean|STAGE_VALUE_PREDICTOR_TYPE)\s+(\w+)\s*\[\]\s*=\s*\{(.*)\}', re.S)
NULL_DECL = re.compile(r'const\s+\w+\s*\*\s*(\w+)\s*=\s*NULL', re.S)
SCALAR_DECL = re.compile(r'const\s+double\s+(\w+)\s*=\s*(.*)', re.S)
FIELD = re.compile(r'tableau->(\w+)\s*=\s*(.*)', re.S)
CALL = re.compile(r'(\w+)\s*\((.*)\)\s*$', re.S)

FIELDS = {
    'richardson': ('t.richardson', 'bool'),
    'nStages': ('t.n_stages', 'usize'),
    'order_b': ('t.order_b', 'i32'),
    'order_bt': ('t.order_bt', 'i32'),
    'fac': ('t.fac', 'f64'),
    'isKLeftAvailable': ('t.k_left', 'bool'),
    'isKRightAvailable': ('t.k_right', 'bool'),
    'withDenseOutput': ('t.with_dense_output', 'bool'),
}

SVP_TYPE = {
    'SVP_NOT_AVAILABLE': 'SvpType::NotAvailable',
    'SVP_LINEAR_COMBINATION': 'SvpType::LinearCombination',
    'SVP_DENSE_OUTPUT': 'SvpType::DenseOutput',
}


def rust_name(c_name):
    """denseOutput_Radau_IIA_3 -> dense_radau_iia_3 style snake_case."""
    n = re.sub(r'([a-z0-9])([A-Z])', r'\1_\2', c_name)
    return n.lower()


class Ctx:
    def __init__(self):
        self.nulls = set()
        self.arrays = {}


def ref(ctx, name, kind='f64'):
    name = name.strip()
    if name == 'NULL' or name in ctx.nulls:
        return 'None'
    return 'Some(&%s)' % name


def emit_body(body, ctx, ind):
    out = []
    pad = ' ' * ind
    for st in split_stmts(body):
        st_flat = ' '.join(st.split())
        if st_flat.startswith('if ('):
            m = re.match(r'if\s*\((.*?)\)\s*\{(.*)\}\s*else\s*\{(.*)\}\s*$', st, flags=re.S)
            if m:
                cond = m.group(1).replace('tableau->richardson', 'richardson')
                out.append('%sif %s {' % (pad, expr(cond)))
                out += emit_body(m.group(2), ctx, ind + 4)
                out.append('%s} else {' % pad)
                out += emit_body(m.group(3), ctx, ind + 4)
                out.append('%s}' % pad)
                continue
            m = re.match(r'if\s*\((.*?)\)\s*\{(.*)\}\s*$', st, flags=re.S)
            cond = m.group(1).replace('tableau->richardson', 'richardson')
            out.append('%sif %s {' % (pad, expr(cond)))
            out += emit_body(m.group(2), ctx, ind + 4)
            out.append('%s}' % pad)
            continue

        m = ARRAY_DECL.match(st)
        if m:
            ty, name, items = m.group(1), m.group(2), m.group(3)
            vals = num_list(items)
            if ty == 'double':
                lst = ', '.join('%s' % v.strip() for v in vals)
                out.append('%slet %s: [f64; %d] = [%s];' % (pad, name, len(vals), lst))
            elif ty == 'int':
                vals = [iexpr(v) for v in num_list_args(items)]
                lst = ', '.join('%s' % v.strip() for v in vals)
                out.append('%slet %s: [usize; %d] = [%s];' % (pad, name, len(vals), lst))
            elif ty == 'modelica_boolean':
                lst = ', '.join(v.strip() for v in vals)
                out.append('%slet %s: [bool; %d] = [%s];' % (pad, name, len(vals), lst))
            else:
                lst = ', '.join(SVP_TYPE[v.strip()] for v in vals)
                out.append('%slet %s: [SvpType; %d] = [%s];' % (pad, name, len(vals), lst))
            ctx.arrays[name] = len(vals)
            # A later array declaration shadows an earlier `= NULL` of the same
            # name (the two arms of an `if (richardson)` share this context).
            ctx.nulls.discard(name)
            continue

        m = NULL_DECL.match(st)
        if m:
            ctx.nulls.add(m.group(1))
            continue

        m = FIELD.match(st)
        if m:
            f, v = m.group(1), m.group(2)
            if f == 'dense_output':
                out.append('%st.dense_output = Some(%s);' % (pad, rust_name(v.strip())))
                continue
            target, ty = FIELDS[f]
            v = iexpr(v) if ty in ('usize', 'i32') else expr(v)
            if ty == 'usize':
                out.append('%s%s = %s;' % (pad, target, v))
            elif ty == 'i32':
                out.append('%s%s = %s;' % (pad, target, v))
            else:
                out.append('%s%s = %s;' % (pad, target, v))
            continue

        m = SCALAR_DECL.match(st)
        if m:
            out.append('%slet %s: f64 = %s;' % (pad, m.group(1), expr(m.group(2))))
            continue

        m = CALL.match(st)
        if m:
            fn, args = m.group(1), [a.strip() for a in num_list_args(m.group(2))]
            if fn == 'setButcherTableau':
                _, c, a, b, bt = args
                out.append('%sset_butcher(&mut t, &%s, &%s, &%s, %s);' % (pad, c, a, b, ref(ctx, bt)))
            elif fn == 'setTTransform':
                (_, ainv, T, Tinv, gam, alpha, beta, frz, lcz, nre, nce, phi, rho) = args
                out.append('%sset_t_transform(&mut t, &%s, &%s, &%s, %s, %s, %s, %s, %s, %s, %s, %s, %s);'
                           % (pad, ainv, T, Tinv, ref(ctx, gam), ref(ctx, alpha), ref(ctx, beta),
                              expr(frz), expr(lcz), nre, nce, ref(ctx, phi), ref(ctx, rho)))
            elif fn == 'setTTransformLowerTriangular':
                (_, ainv, T, Tinv, gam, alpha, beta, frz, lcz, nrb, ncb, nre, nce,
                 rei, cei, L, hasL, phi, rho) = args
                out.append('%sset_t_transform_lower(&mut t, &%s, &%s, &%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);'
                           % (pad, ainv, T, Tinv, ref(ctx, gam), ref(ctx, alpha), ref(ctx, beta),
                              expr(frz), expr(lcz), nrb, ncb, nre, nce,
                              ref(ctx, rei), ref(ctx, cei), ref(ctx, L), ref(ctx, hasL),
                              ref(ctx, phi), ref(ctx, rho)))
            elif fn == 'setContractiveDefectError':
                _, dta, only = args
                out.append('%sset_contractive_defect(&mut t, %s, %s);' % (pad, ref(ctx, dta), expr(only)))
            elif fn == 'setTwoStepErrorEstimator':
                _, order, w = args
                out.append('%sset_two_step(&mut t, %s, %s);' % (pad, order, rust_name(w)))
            elif fn == 'setStageValuePredictors':
                _, apred, ty, dop = args
                dop = 'None' if dop == 'NULL' else 'Some(%s)' % rust_name(dop)
                out.append('%sset_svp(&mut t, &%s, &%s, %s);' % (pad, apred, ty, dop))
            else:
                raise SystemExit('unhandled call %s' % fn)
            continue
        raise SystemExit('unhandled statement: %r' % st[:200])
    return out


def num_list_args(text):
    """Split a call's argument list at top level."""
    out, cur, depth = [], '', 0
    for ch in text:
        if ch in '([{':
            depth += 1
        elif ch in ')]}':
            depth -= 1
        if ch == ',' and depth == 0:
            out.append(cur)
            cur = ''
            continue
        cur += ch
    if cur.strip():
        out.append(cur)
    return out


# ---- method enum -> builder function, from the big switch in initButcherTableau
methods = re.findall(r'case\s+(\w+)\s*:\s*getButcherTableau_(\w+)\(tableau\)\s*;', s)

tab_bodies = dict(re.findall(r'\nvoid getButcherTableau_(\w+)\(BUTCHER_TABLEAU\* tableau\)\n\{(.*?)\n\}\n', s, flags=re.S))

# ---- dense output functions: bodies are `tableau->b_dt[i] = <poly in dt>;`
dense = re.findall(
    r'\nvoid (\w+)\(BUTCHER_TABLEAU\* tableau, double\* yOld, double\* x, double\* k, double dt, double stepSize, double\* y, int nIdx, int\* idx, int nStates\)\n\{(.*?)\n\}\n',
    s, flags=re.S)
dense = [(n, b) for n, b in dense if n != 'denseOutput']

# ---- two step weight functions
two_step = re.findall(r'\nstatic void (twoStepWeights_\w+)\(double r, double \*d_old, double \*g_new, double \*mu\)\n\{(.*?)\n\}\n', s, flags=re.S)

L = []
L.append('//! Butcher tableaux for the gbode methods, transcribed from the C runtime\'s')
L.append('//! `gbode_tableau.c` (same constants, same per-method options).')
L.append('//!')
L.append('//! Generated by `gen_tableau.py`; edit that and regenerate rather than patching')
L.append('//! numbers here.')
L.append('#![allow(non_snake_case, non_camel_case_types, unused_parens, dead_code, clippy::all)]')
L.append('')
L.append('use super::math::sqrt;')
L.append('use super::tableau::*;')
L.append('')

# dense output
for name, body in dense:
    L.append('pub(super) fn %s(b_dt: &mut [f64], dt: f64) {' % rust_name(name))
    for st in split_stmts(body):
        st = ' '.join(st.split())
        m = re.match(r'tableau->b_dt\[(\d+)\]\s*=\s*(.*)$', st)
        if m:
            L.append('    b_dt[%s] = %s;' % (m.group(1), expr(m.group(2))))
            continue
        if st.startswith('denseOutput('):
            continue
        raise SystemExit('dense: unhandled %r' % st)
    L.append('}')
    L.append('')

# two-step weights
for name, body in two_step:
    L.append('pub(super) fn %s(r: f64, d_old: &mut [f64], g_new: &mut [f64]) -> f64 {' % rust_name(name))
    ctx = Ctx()
    call = None
    mu_call = None
    for st in split_stmts(body):
        stf = ' '.join(st.split())
        m = re.match(r'static const double \* const (\w+)\[\]\s*=\s*\{(.*)\}$', stf)
        if m:
            items = [x.strip() for x in num_list_args(m.group(2))]
            L.append('    let %s: [&[f64]; %d] = [%s];' % (m.group(1), len(items), ', '.join('&%s' % i for i in items)))
            continue
        m = re.match(r'static const (double|int) (\w+)\[\]\s*=\s*\{(.*)\}$', stf)
        if m:
            is_int = m.group(1) == 'int'
            vals = [iexpr(v) for v in num_list_args(m.group(3))] if is_int else num_list(m.group(3))
            ty = 'usize' if is_int else 'f64'
            L.append('    let %s: [%s; %d] = [%s];' % (m.group(2), ty, len(vals), ', '.join(v.strip() for v in vals)))
            continue
        m = re.match(r'evaluateTwoStepRationalWeights\((.*)\)$', stf)
        if m:
            a = [x.strip() for x in num_list_args(m.group(1))]
            call = '    two_step_rational_weights(%s, r, &%s, %s, &%s, &%s, d_old, g_new);' % (a[0], a[2], a[3], a[4], a[5])
            continue
        m = re.match(r'\*mu = evaluateTwoStepMu\((.*)\)$', stf)
        if m:
            a = [x.strip() for x in num_list_args(m.group(1))]
            mu_call = '    two_step_mu(r, %s, &%s, %s, &%s, %s)' % (a[1], a[2], a[3], a[4], a[5])
            continue
        raise SystemExit('two_step: unhandled %r' % stf)
    L.append(call)
    L.append(mu_call)
    L.append('}')
    L.append('')

# tableau builders
for cname, body in sorted(tab_bodies.items()):
    ctx = Ctx()
    L.append('fn tab_%s(richardson: bool) -> Tableau {' % cname.lower())
    L.append('    let mut t = Tableau::new(richardson);')
    L += emit_body(body, ctx, 4)
    L.append('    t')
    L.append('}')
    L.append('')

L.append('/// C\'s `initButcherTableau` dispatch.')
L.append('pub(super) fn build(method: GbMethod, richardson: bool) -> Tableau {')
L.append('    match method {')
for enum, fn in methods:
    L.append('        GbMethod::%s => tab_%s(richardson),' % (enum, fn.lower()))
L.append('    }')
L.append('}')
L.append('')

# ---- method names, from GB_METHOD_NAME in simulation_options.c
opts = open(OPTS).read()
tbl = re.search(r'const char \*GB_METHOD_NAME\[RK_MAX\] = \{(.*?)\n\};', opts, flags=re.S).group(1)
names = re.findall(r'/\*\s*(\w+)[^*]*\*/\s*"([^"]+)"', tbl)
names = [(e, n) for e, n in names if e != 'GB_UNKNOWN']
known = {e for e, _ in methods}
missing = [e for e, _ in names if e not in known]
if missing:
    raise SystemExit('names without a tableau: %s' % missing)

L.append('/// The `-gbm` values, in C\'s `GB_METHOD_NAME` order.')
L.append('pub(super) const METHOD_NAMES: &[(&str, GbMethod)] = &[')
for e, n in names:
    L.append('    ("%s", GbMethod::%s),' % (n, e))
L.append('];')
L.append('')

hdr = []
hdr.append('/// C\'s `enum GB_METHOD` (`-gbm` / `-gbfm`).')
hdr.append('#[derive(Clone, Copy, PartialEq, Eq, Debug)]')
hdr.append('pub enum GbMethod {')
for e, _ in names:
    hdr.append('    %s,' % e)
hdr.append('}')
hdr.append('')
L[9:9] = hdr

open(OUT, 'w').write('\n'.join(L) + '\n')
print('wrote', OUT, len(L), 'lines;', len(methods), 'methods,', len(dense), 'dense,', len(two_step), 'two-step')
