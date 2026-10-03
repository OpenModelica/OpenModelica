/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package NFResizableConnections
  "Connection sets of arrays of connectors whose sizes are resizable parameters
   (--resizableArrays). Like NFArrayConnections, but all sizes, loop ranges and
   indices stay symbolic, so that the equations are valid for every value of the
   size parameters (changed with -override without translating again).

   Numbers are piecewise linear expressions in the size parameters in the normal
   form max_i(min_j(a_ij)) with affine a_ij. Comparisons are decided
   symbolically (yes, no or maybe), assuming size parameters >= 1 and the facts
   given by the valid indices of the connections (e.g. N <= P for a[1:N] connected
   to b). Undecidable comparisons give pieces that may be empty: their equations
   are for loops over possibly empty ranges and sums over possibly empty slices.

   The connected connectors are split into pieces (boxes of indices), such that
   every connection maps whole pieces to whole pieces. A union-find over the
   pieces and their dimensions gives the connection sets: per set the free
   dimensions (loops) and the collapsed ones (all elements in the same set).
   Connections inside one array shifted by one (p[i] to p[i+1]) are handled in
   closed form, connections that cover a whole array one to one merge it into
   the other array."

  import FlatModel = NFFlatModel;

protected
  import Binding = NFBinding;
  import Call = NFCall;
  import ComponentRef = NFComponentRef;
  import Connector = NFConnector;
  import DAE;
  import Dimension = NFDimension;
  import Equation = NFEquation;
  import ElementSource;
  import MetaModelica.Dangerous.*;
  import Expression = NFExpression;
  import NFFunction.Function;
  import NFInstNode.InstNode;
  import NFInstNode;
  import NFPrefixes.Purity;
  import NFPrefixes.Variability;
  import Operator = NFOperator;
  import Op = NFOperator.Op;
  import SimplifyExp = NFSimplifyExp;
  import Subscript = NFSubscript;
  import Type = NFType;
  import Variable = NFVariable;
  import UnorderedMap;
  import UnorderedSet;

  constant Integer NO = 0;
  constant Integer YES = 1;
  constant Integer MAYBE = 2;
  constant Integer PARAM_MIN = 1 "size parameters are at least this";
  constant Integer MAX_PIECES = 300 "pieces of one connector array before giving up";
  constant Integer MAX_ROUNDS = 50;

  // ---------------------------------------------------------------------------
  // affine expressions c + sum k_p * p
  // ---------------------------------------------------------------------------

  uniontype Aff
    record AFF
      Integer c;
      list<tuple<String, Integer>> k "sorted by name, no zero coefficients";
    end AFF;
  end Aff;

  function affInt
    input Integer c;
    output Aff a = AFF(c, {});
  end affInt;

  function affParam
    input String name;
    output Aff a = AFF(0, {(name, 1)});
  end affParam;

  function affAdd
    input Aff a;
    input Aff b;
    output Aff res;
  protected
    list<tuple<String, Integer>> k1, k2, k = {};
    String n1, n2;
    Integer c1, c2, ca, cb;
  algorithm
    AFF(ca, k1) := a;
    AFF(cb, k2) := b;
    while not listEmpty(k1) and not listEmpty(k2) loop
      (n1, c1) := listHead(k1);
      (n2, c2) := listHead(k2);
      if n1 == n2 then
        if c1 + c2 <> 0 then
          k := (n1, c1 + c2) :: k;
        end if;
        k1 := listRest(k1);
        k2 := listRest(k2);
      elseif stringCompare(n1, n2) < 0 then
        k := (n1, c1) :: k;
        k1 := listRest(k1);
      else
        k := (n2, c2) :: k;
        k2 := listRest(k2);
      end if;
    end while;
    res := AFF(ca + cb, List.append_reverse(k, listAppend(k1, k2)));
  end affAdd;

  function affScale
    input Aff a;
    input Integer f;
    output Aff res;
  protected
    Integer c;
    list<tuple<String, Integer>> k;
  algorithm
    AFF(c, k) := a;
    if f == 0 then
      res := AFF(0, {});
    else
      res := AFF(c * f, list((Util.tuple21(t), f * Util.tuple22(t)) for t in k));
    end if;
  end affScale;

  function affNeg
    input Aff a;
    output Aff res = affScale(a, -1);
  end affNeg;

  function affSub
    input Aff a;
    input Aff b;
    output Aff res = affAdd(a, affNeg(b));
  end affSub;

  function affIsConst
    input Aff a;
    output Boolean b;
  protected
    list<tuple<String, Integer>> k;
  algorithm
    AFF(k = k) := a;
    b := listEmpty(k);
  end affIsConst;

  function affString
    input Aff a;
    output String str;
  protected
    Integer c, v;
    list<tuple<String, Integer>> k;
    list<String> strl = {};
    String n;
  algorithm
    AFF(c, k) := a;
    for t in k loop
      (n, v) := t;
      strl := (if v == 1 then n elseif v == -1 then "-" + n else intString(v) + "*" + n) :: strl;
    end for;
    if c <> 0 or listEmpty(strl) then
      strl := intString(c) :: strl;
    end if;
    str := stringDelimitList(listReverseInPlace(strl), " + ");
  end affString;

  function affNonNeg
    "a >= 0 for all parameter values >= PARAM_MIN"
    input Aff a;
    output Boolean b = true;
  protected
    Integer c, s, v;
    list<tuple<String, Integer>> k;
  algorithm
    AFF(c, k) := a;
    s := c;
    for t in k loop
      (_, v) := t;
      if v < 0 then
        b := false;
        return;
      end if;
      s := s + v * PARAM_MIN;
    end for;
    b := s >= 0;
  end affNonNeg;

  function affProvable
    "a >= 0 from the parameter bounds and up to two facts"
    input Aff a;
    input list<Aff> facts;
    output Boolean b = true;
  protected
    list<Aff> rest = facts;
    Aff f, d;
  algorithm
    if affNonNeg(a) then
      return;
    end if;
    while not listEmpty(rest) loop
      f :: rest := rest;
      d := affSub(a, f);
      if affNonNeg(d) then
        return;
      end if;
      for h in rest loop
        if affNonNeg(affSub(d, h)) then
          return;
        end if;
      end for;
    end while;
    b := false;
  end affProvable;

  function affLe
    "a <= b: YES, NO or MAYBE"
    input Aff a;
    input Aff b;
    input list<Aff> facts;
    output Integer res;
  protected
    Aff d = affSub(b, a);
    Integer c;
  algorithm
    if affIsConst(d) then
      AFF(c = c) := d;
      res := if c >= 0 then YES else NO;
    elseif affProvable(d, facts) then
      res := YES;
    elseif affProvable(affAdd(affNeg(d), affInt(-1)), facts) then
      res := NO;
    else
      res := MAYBE;
    end if;
  end affLe;

  // ---------------------------------------------------------------------------
  // symbolic numbers max_i(min_j(a_ij))
  // ---------------------------------------------------------------------------

  type Term = list<Aff> "min over the elements";

  uniontype Sym
    record SYM
      list<list<Aff>> terms "max over the terms, a term is the min over its elements";
      String key "unique string of the normal form";
    end SYM;
  end Sym;

  function symInt
    input Integer c;
    output Sym s = SYM({{affInt(c)}}, intString(c));
  end symInt;

  function symAff
    input Aff a;
    output Sym s = SYM({{a}}, affString(a));
  end symAff;

  function symString
    input Sym s;
    output String str;
  algorithm
    SYM(key = str) := s;
  end symString;

  function symEq
    input Sym a;
    input Sym b;
    output Boolean eq = symString(a) == symString(b);
  end symEq;

  function symIsAff
    input Sym s;
    output Boolean b;
  algorithm
    b := match s
      case SYM(terms = {{_}}) then true;
      else false;
    end match;
  end symIsAff;

  function symGetAff
    input Sym s;
    output Aff a;
  algorithm
    SYM(terms = {{a}}) := s;
  end symGetAff;

  function termString
    input list<Aff> t;
    output String str;
  algorithm
    str := match t
      case {_} then affString(listHead(t));
      else "min(" + stringDelimitList(list(affString(a) for a in t), ", ") + ")";
    end match;
  end termString;

  function termLe
    "min(t) <= min(u) for certain: every element of u is >= some element of t"
    input list<Aff> t;
    input list<Aff> u;
    input list<Aff> facts;
    output Boolean res = true;
  protected
    Boolean found;
  algorithm
    for b in u loop
      found := false;
      for a in t loop
        if affLe(a, b, facts) == YES then
          found := true;
          break;
        end if;
      end for;
      if not found then
        res := false;
        return;
      end if;
    end for;
  end termLe;

  function termGt
    "min(t) > min(u) for certain: some element of u is < every element of t"
    input list<Aff> t;
    input list<Aff> u;
    input list<Aff> facts;
    output Boolean res = false;
  protected
    Boolean all_gt;
  algorithm
    for b in u loop
      all_gt := true;
      for a in t loop
        if affLe(a, b, facts) <> NO then
          all_gt := false;
          break;
        end if;
      end for;
      if all_gt then
        res := true;
        return;
      end if;
    end for;
  end termGt;

  function pruneTerm
    "min over affine expressions without the elements >= another one, sorted"
    input list<Aff> t;
    input list<Aff> facts;
    output list<Aff> res = {};
  protected
    Boolean dominated;
  algorithm
    for a in t loop
      dominated := false;
      for b in res loop
        if affLe(b, a, facts) == YES then
          dominated := true;
          break;
        end if;
      end for;
      if not dominated then
        res := a :: list(b for b guard affLe(a, b, facts) <> YES in res);
      end if;
    end for;
    res := List.sort(res, affGreater);
  end pruneTerm;

  function affGreater
    input Aff a;
    input Aff b;
    output Boolean gt = stringCompare(affString(a), affString(b)) > 0;
  end affGreater;

  function symMake
    "the normal form of max over terms"
    input list<list<Aff>> terms;
    input list<Aff> facts;
    output Sym s;
  protected
    list<list<Aff>> keep = {};
    Boolean dominated;
    list<String> strl;
    UnorderedMap<String, Term> uniq;
  algorithm
    for t in terms loop
      t := pruneTerm(t, facts);
      dominated := false;
      for u in keep loop
        if termLe(t, u, facts) then
          dominated := true;
          break;
        end if;
      end for;
      if not dominated then
        keep := t :: list(u for u guard not termLe(u, t, facts) in keep);
      end if;
    end for;
    // unique terms, sorted by their strings (the normal form)
    uniq := UnorderedMap.new<Term>(stringHashDjb2, stringEq);
    for t in keep loop
      UnorderedMap.tryAdd(termString(t), t, uniq);
    end for;
    strl := List.sort(UnorderedMap.keyList(uniq), stringGreater);
    keep := list(UnorderedMap.getOrFail(str, uniq) for str in strl);
    s := SYM(keep, if listLength(strl) == 1 then listHead(strl) else "max(" + stringDelimitList(strl, ", ") + ")");
  end symMake;

  function stringGreater
    input String a;
    input String b;
    output Boolean gt = stringCompare(a, b) > 0;
  end stringGreater;

  function symAdd
    input Sym a;
    input Sym b;
    input list<Aff> facts;
    output Sym s;
  protected
    list<list<Aff>> ta, tb, terms = {};
    list<Aff> t;
  algorithm
    SYM(terms = ta) := a;
    SYM(terms = tb) := b;
    if symIsAff(a) and symIsAff(b) then
      s := symAff(affAdd(symGetAff(a), symGetAff(b)));
      return;
    end if;
    for x in ta loop
      for y in tb loop
        t := {};
        for ex in x loop
          for ey in y loop
            t := affAdd(ex, ey) :: t;
          end for;
        end for;
        terms := t :: terms;
      end for;
    end for;
    s := symMake(terms, facts);
  end symAdd;

  function symAddInt
    input Sym a;
    input Integer c;
    input list<Aff> facts;
    output Sym s = symAdd(a, symInt(c), facts);
  end symAddInt;

  function symMin
    input Sym a;
    input Sym b;
    input list<Aff> facts;
    output Sym s;
  protected
    list<list<Aff>> ta, tb, terms = {};
  algorithm
    if symEq(a, b) then
      s := a;
      return;
    end if;
    SYM(terms = ta) := a;
    SYM(terms = tb) := b;
    for x in ta loop
      for y in tb loop
        terms := listAppend(x, y) :: terms;
      end for;
    end for;
    s := symMake(terms, facts);
  end symMin;

  function symMax
    input Sym a;
    input Sym b;
    input list<Aff> facts;
    output Sym s;
  protected
    list<list<Aff>> ta, tb;
  algorithm
    if symEq(a, b) then
      s := a;
      return;
    end if;
    SYM(terms = ta) := a;
    SYM(terms = tb) := b;
    s := symMake(listAppend(ta, tb), facts);
  end symMax;

  function symNeg
    "-max_i min_j a_ij = min_i max_j (-a_ij)"
    input Sym a;
    input list<Aff> facts;
    output Sym s;
  protected
    list<list<Aff>> ta;
    Boolean first = true;
    Sym m;
  algorithm
    if symIsAff(a) then
      s := symAff(affNeg(symGetAff(a)));
      return;
    end if;
    SYM(terms = ta) := a;
    for t in ta loop
      m := symMake(list({affNeg(x)} for x in t), facts);
      s := if first then m else symMin(s, m, facts);
      first := false;
    end for;
  end symNeg;

  function symSub
    input Sym a;
    input Sym b;
    input list<Aff> facts;
    output Sym s = symAdd(a, symNeg(b, facts), facts);
  end symSub;

  function symLe
    "a <= b: YES, NO or MAYBE"
    input Sym a;
    input Sym b;
    input list<Aff> facts;
    output Integer res;
  protected
    Sym d;
    list<list<Aff>> td, ta, tb;
    Aff zero = affInt(0);
    Boolean b1, b2;
  algorithm
    if symEq(a, b) then
      res := YES;
      return;
    end if;
    if symIsAff(a) and symIsAff(b) then
      res := affLe(symGetAff(a), symGetAff(b), facts);
      return;
    end if;
    // the sign of the difference b - a = max_i min_j d_ij
    d := symSub(b, a, facts);
    SYM(terms = td) := d;
    for t in td loop
      if List.all(list(affLe(zero, x, facts) == YES for x in t), Util.id) then
        res := YES;
        return;
      end if;
    end for;
    b1 := true;
    for t in td loop
      if not List.any(list(affLe(zero, x, facts) == NO for x in t), Util.id) then
        b1 := false;
        break;
      end if;
    end for;
    if b1 then
      res := NO;
      return;
    end if;
    // term by term
    SYM(terms = ta) := a;
    SYM(terms = tb) := b;
    b1 := true;
    for t in ta loop
      b2 := false;
      for u in tb loop
        if termLe(t, u, facts) then
          b2 := true;
          break;
        end if;
      end for;
      if not b2 then
        b1 := false;
        break;
      end if;
    end for;
    if b1 then
      res := YES;
      return;
    end if;
    for t in ta loop
      b2 := true;
      for u in tb loop
        if not termGt(t, u, facts) then
          b2 := false;
          break;
        end if;
      end for;
      if b2 then
        res := NO;
        return;
      end if;
    end for;
    res := MAYBE;
  end symLe;

  function symToExp
    input Sym s;
    input UnorderedMap<String, Expression> params;
    output Expression exp;
  protected
    list<list<Aff>> terms;
    list<Expression> maxl, minl;
  algorithm
    SYM(terms = terms) := s;
    maxl := {};
    for t in terms loop
      minl := list(affToExp(a, params) for a in t);
      maxl := foldBuiltin(NFBuiltinFuncs.MIN_INT, minl) :: maxl;
    end for;
    exp := foldBuiltin(NFBuiltinFuncs.MAX_INT, listReverseInPlace(maxl));
  end symToExp;

  function foldBuiltin
    input Function fn;
    input list<Expression> expl;
    output Expression exp;
  protected
    list<Expression> rest;
  algorithm
    exp :: rest := expl;
    for e in rest loop
      exp := Expression.CALL(Call.makeTypedCall(fn, {exp, e},
        NFPrefixes.variabilityMax(Expression.variability(exp), Expression.variability(e)), Purity.PURE));
    end for;
  end foldBuiltin;

  function affToExp
    input Aff a;
    input UnorderedMap<String, Expression> params;
    output Expression exp;
  protected
    Integer c, v;
    list<tuple<String, Integer>> k;
    String n;
    Expression e;
  algorithm
    AFF(c, k) := a;
    exp := Expression.INTEGER(c);
    for t in k loop
      (n, v) := t;
      e := UnorderedMap.getOrFail(n, params);
      if v <> 1 then
        e := Expression.BINARY(Expression.INTEGER(v), Operator.makeMul(Type.INTEGER()), e);
      end if;
      exp := Expression.BINARY(exp, Operator.makeAdd(Type.INTEGER()), e);
    end for;
    exp := SimplifyExp.simplify(exp);
  end affToExp;

  // ---------------------------------------------------------------------------
  // intervals [lo, hi] (step 1, empty if hi < lo) and boxes of intervals
  // ---------------------------------------------------------------------------

  uniontype Iv
    record IV
      Sym lo;
      Sym hi;
    end IV;
  end Iv;

  type Box = list<Iv>;

  function ivLo
    input Iv iv;
    output Sym lo;
  algorithm
    IV(lo = lo) := iv;
  end ivLo;

  function ivHi
    input Iv iv;
    output Sym hi;
  algorithm
    IV(hi = hi) := iv;
  end ivHi;

  function ivString
    input Iv iv;
    output String str;
  protected
    Sym lo, hi;
  algorithm
    IV(lo, hi) := iv;
    str := symString(lo) + ":" + symString(hi);
  end ivString;

  function boxString
    input Box box;
    output String str = "[" + stringDelimitList(list(ivString(iv) for iv in box), ", ") + "]";
  end boxString;

  function ivEmpty
    input Iv iv;
    input list<Aff> facts;
    output Integer res;
  protected
    Sym lo, hi;
  algorithm
    IV(lo, hi) := iv;
    res := match symLe(lo, hi, facts)
      case 1 then NO;   // YES
      case 0 then YES;  // NO
      else MAYBE;
    end match;
  end ivEmpty;

  function boxEmpty
    input Box box;
    input list<Aff> facts;
    output Integer res = NO;
  protected
    Integer r;
  algorithm
    for iv in box loop
      r := ivEmpty(iv, facts);
      if r == YES then
        res := YES;
        return;
      elseif r == MAYBE then
        res := MAYBE;
      end if;
    end for;
  end boxEmpty;

  function ivInter
    input Iv a;
    input Iv b;
    input list<Aff> facts;
    output Iv res;
  algorithm
    res := IV(symMax(a.lo, b.lo, facts), symMin(a.hi, b.hi, facts));
  end ivInter;

  function ivMinus
    "a without b: up to two pieces, possibly empty"
    input Iv a;
    input Iv b;
    input list<Aff> facts;
    output list<Iv> res = {};
  protected
    Iv left, right;
  algorithm
    left := IV(a.lo, symMin(a.hi, symAddInt(b.lo, -1, facts), facts));
    right := IV(symMax(a.lo, symAddInt(b.hi, 1, facts), facts), a.hi);
    if ivEmpty(right, facts) <> YES then
      res := right :: res;
    end if;
    if ivEmpty(left, facts) <> YES then
      res := left :: res;
    end if;
  end ivMinus;

  function boxInter
    input Box a;
    input Box b;
    input list<Aff> facts;
    output Box res = List.threadMap(a, b, function ivInter(facts = facts));
  end boxInter;

  function boxMinus
    "a without b as disjoint boxes"
    input Box a;
    input Box b;
    input list<Aff> facts;
    output list<Box> res = {};
  protected
    array<Iv> rest = listArray(a);
    array<Iv> bb = listArray(b);
    Box bx;
  algorithm
    for d in 1:arrayLength(rest) loop
      for p in ivMinus(rest[d], bb[d], facts) loop
        bx := {};
        for j in arrayLength(rest):-1:1 loop
          bx := (if j == d then p else rest[j]) :: bx;
        end for;
        if boxEmpty(bx, facts) <> YES then
          res := bx :: res;
        end if;
      end for;
      rest[d] := ivInter(rest[d], bb[d], facts);
    end for;
    res := listReverseInPlace(res);
  end boxMinus;

  function boxContains
    "b is a subset of a for certain"
    input Box a;
    input Box b;
    input list<Aff> facts;
    output Boolean res = true;
  protected
    list<Iv> rb = b;
    Iv y;
  algorithm
    for x in a loop
      y :: rb := rb;
      if symLe(x.lo, y.lo, facts) <> YES or symLe(y.hi, x.hi, facts) <> YES then
        res := false;
        return;
      end if;
    end for;
  end boxContains;

  function boxKey
    input Box box;
    output String key = boxString(box);
  end boxKey;

  // ---------------------------------------------------------------------------
  // graph: connector arrays and connections (edges) between them
  // ---------------------------------------------------------------------------

  uniontype Side
    "one side of a connection: per dimension of the connector the iterator of
     the connection domain (0 for a constant index) and an offset:
     index = iterator + offset, or index = offset"
    record SIDE
      Integer vertex;
      list<Integer> iters;
      list<Sym> offs;
    end SIDE;
  end Side;

  function sideVertex
    input Side side;
    output Integer v;
  algorithm
    SIDE(vertex = v) := side;
  end sideVertex;

  uniontype Edge
    record EDGE
      Box dom "the ranges of the iterators";
      Side a;
      Side b;
      DAE.ElementSource source;
    end EDGE;
  end Edge;

  uniontype Vertex
    record VERTEX
      String name;
      Option<Connector> conn "NONE for virtual hubs";
      Box box;
    end VERTEX;
  end Vertex;

  function vertexBox
    input Vector<Vertex> vertices;
    input Integer v;
    output Box box;
  algorithm
    VERTEX(box = box) := Vector.get(vertices, v);
  end vertexBox;

  function vertexName
    input Vector<Vertex> vertices;
    input Integer v;
    output String name;
  algorithm
    VERTEX(name = name) := Vector.get(vertices, v);
  end vertexName;

  function sideImage
    input Side side;
    input Box dom;
    input list<Aff> facts;
    output Box box = {};
  protected
    list<Sym> offs = side.offs;
    Sym off;
    Iv iv;
  algorithm
    for it in side.iters loop
      off :: offs := offs;
      if it > 0 then
        iv := listGet(dom, it);
        box := IV(symAdd(iv.lo, off, facts), symAdd(iv.hi, off, facts)) :: box;
      else
        box := IV(off, off) :: box;
      end if;
    end for;
    box := listReverseInPlace(box);
  end sideImage;

  function sidePreimage
    "the part of the domain mapped into box"
    input Side side;
    input Box dom;
    input Box box;
    input list<Aff> facts;
    output Box res;
  protected
    array<Iv> ivs = listArray(dom);
    list<Sym> offs = side.offs;
    list<Iv> bl = box;
    Sym off;
    Iv b;
  algorithm
    for it in side.iters loop
      off :: offs := offs;
      b :: bl := bl;
      if it > 0 then
        ivs[it] := ivInter(ivs[it], IV(symSub(b.lo, off, facts), symSub(b.hi, off, facts)), facts);
      end if;
    end for;
    res := arrayList(ivs);
  end sidePreimage;

  function sideConstIn
    "every constant index of the side lies in box for certain"
    input Side side;
    input Box box;
    input list<Aff> facts;
    output Boolean res = true;
  protected
    list<Sym> offs = side.offs;
    list<Iv> bl = box;
    Sym off;
    Iv b;
  algorithm
    for it in side.iters loop
      off :: offs := offs;
      b :: bl := bl;
      if it == 0 and (symLe(b.lo, off, facts) <> YES or symLe(off, b.hi, facts) <> YES) then
        res := false;
        return;
      end if;
    end for;
  end sideConstIn;

  function indexFacts
    "valid indices: the image of a certainly non-empty connection domain lies in
     the connector array, which gives facts like N <= P"
    input Vector<Vertex> vertices;
    input list<Edge> edges;
    output list<Aff> facts = {};
  protected
    list<Iv> vbox;
    Iv viv;
    Sym f;
    UnorderedSet<String> keys = UnorderedSet.new(stringHashDjb2, stringEq);
  algorithm
    for e in edges loop
      if boxEmpty(e.dom, {}) == NO then
        for side in {e.a, e.b} loop
          vbox := vertexBox(vertices, side.vertex);
          for iv in sideImage(side, e.dom, {}) loop
            viv :: vbox := vbox;
            for f in {symSub(viv.hi, iv.hi, {}), symSub(iv.lo, viv.lo, {})} loop
              if symIsAff(f) and not affIsConst(symGetAff(f)) and not UnorderedSet.contains(symString(f), keys) then
                UnorderedSet.add(symString(f), keys);
                facts := symGetAff(f) :: facts;
              end if;
            end for;
          end for;
        end for;
      end if;
    end for;
  end indexFacts;

  // ---------------------------------------------------------------------------
  // contraction of one to one connected arrays, shifts inside one array
  // ---------------------------------------------------------------------------

  uniontype Merge
    "x merged into y: y[d'] = x[d] + c for (d, c) = tr[d']"
    record MERGE
      Integer x;
      Integer y;
      list<tuple<Integer, Sym>> tr;
    end MERGE;
  end Merge;

  function substituteSide
    input Side side;
    input Integer x;
    input Integer y;
    input list<tuple<Integer, Sym>> tr;
    input list<Aff> facts;
    output Side res;
  protected
    array<Integer> iters;
    array<Sym> offs;
    list<Integer> it_l = {};
    list<Sym> off_l = {};
    Integer d;
    Sym c;
  algorithm
    if side.vertex <> x then
      res := side;
      return;
    end if;
    iters := listArray(side.iters);
    offs := listArray(side.offs);
    for t in tr loop
      (d, c) := t;
      it_l := iters[d] :: it_l;
      off_l := symAdd(offs[d], c, facts) :: off_l;
    end for;
    res := SIDE(y, listReverseInPlace(it_l), listReverseInPlace(off_l));
  end substituteSide;

  function fullBijection
    "the transformation x -> y if the edge maps all of sx.vertex one to one into
     sy.vertex (every dimension its own iterator)"
    input Vector<Vertex> vertices;
    input Edge e;
    input Side sx;
    input Side sy;
    input list<Aff> facts;
    output Option<list<tuple<Integer, Sym>>> otr = NONE();
  protected
    list<Integer> its_x = sx.iters, its_y = sy.iters;
    array<Sym> offx = listArray(sx.offs);
    list<Sym> offy = sy.offs;
    list<Iv> img, vbox;
    list<tuple<Integer, Sym>> tr = {};
    Integer d;
    Sym oy;
    UnorderedMap<Integer, Integer> pos_x "iterator -> dimension of x";
    UnorderedSet<Integer> set_y;
  algorithm
    // every dimension of both sides its own iterator, all iterators of the domain
    pos_x := UnorderedMap.new<Integer>(Util.id, intEq);
    d := 0;
    for it in its_x loop
      d := d + 1;
      UnorderedMap.add(it, d, pos_x);
    end for;
    set_y := UnorderedSet.fromList(its_y, Util.id, intEq);
    if sx.vertex == sy.vertex or UnorderedMap.contains(0, pos_x) or UnorderedSet.contains(0, set_y) or
       UnorderedMap.size(pos_x) <> listLength(its_x) or UnorderedSet.size(set_y) <> listLength(its_y) or
       listLength(its_x) <> listLength(e.dom) or listLength(its_y) <> listLength(e.dom) then
      return;
    end if;
    img := sideImage(sx, e.dom, facts);
    vbox := vertexBox(vertices, sx.vertex);
    for iv in img loop
      if not (symEq(iv.lo, ivLo(listHead(vbox))) and symEq(iv.hi, ivHi(listHead(vbox)))) then
        return;
      end if;
      vbox := listRest(vbox);
    end for;
    for it in its_y loop
      oy :: offy := offy;
      d := UnorderedMap.getOrFail(it, pos_x);
      tr := (d, symSub(oy, offx[d], facts)) :: tr;
    end for;
    otr := SOME(listReverseInPlace(tr));
  end fullBijection;

  function contract
    "merges arrays that are fully and one to one connected to another array"
    input Vector<Vertex> vertices;
    input array<Boolean> alive;
    input output list<Edge> edges;
    input list<Aff> facts;
    output list<Merge> merges = {};
  protected
    Boolean changed = true;
    Integer k, x, y, z, w;
    Option<list<tuple<Integer, Sym>>> otr;
    list<tuple<Integer, Sym>> tr, tz;
    array<Edge> ea;
    Edge ek, ej;
  algorithm
    while changed loop
      changed := false;
      ea := listArray(edges);
      for k in 1:arrayLength(ea) loop
        ek := ea[k];
        for sides in {(ek.a, ek.b), (ek.b, ek.a)} loop
          otr := fullBijection(vertices, ek, Util.tuple21(sides), Util.tuple22(sides), facts);
          if isSome(otr) then
            SOME(tr) := otr;
            x := sideVertex(Util.tuple21(sides));
            y := sideVertex(Util.tuple22(sides));
            edges := {};
            for j in arrayLength(ea):-1:1 loop
              if j <> k then
                ej := ea[j];
                edges := EDGE(ej.dom, substituteSide(ej.a, x, y, tr, facts),
                              substituteSide(ej.b, x, y, tr, facts), ej.source) :: edges;
              end if;
            end for;
            arrayUpdate(alive, x, false);
            // z -> x -> y
            merges := list(composeMerge(m, x, y, tr, facts) for m in merges);
            merges := MERGE(x, y, tr) :: merges;
            changed := true;
            break;
          end if;
        end for;
        if changed then
          break;
        end if;
      end for;
    end while;
  end contract;

  function composeMerge
    input Merge m;
    input Integer x;
    input Integer y;
    input list<tuple<Integer, Sym>> tr;
    input list<Aff> facts;
    output Merge res;
  protected
    array<tuple<Integer, Sym>> tz;
    Integer d;
    Sym c;
    list<tuple<Integer, Sym>> l = {};
  algorithm
    if m.y <> x then
      res := m;
      return;
    end if;
    // y[d'] = x[d2] + c = z[tz[d2].d] + tz[d2].c + c
    tz := listArray(m.tr);
    for t in tr loop
      (d, c) := t;
      l := (Util.tuple21(tz[d]), symAdd(c, Util.tuple22(tz[d]), facts)) :: l;
    end for;
    res := MERGE(m.x, y, listReverseInPlace(l));
  end composeMerge;

  function mergedImage
    "the image of the box of x in y"
    input Box box;
    input list<tuple<Integer, Sym>> tr;
    input list<Aff> facts;
    output Box res;
  protected
    array<Iv> b = listArray(box);
    Integer d;
    Sym c;
  algorithm
    res := list(IV(symAdd(ivLo(b[Util.tuple21(t)]), Util.tuple22(t), facts),
                   symAdd(ivHi(b[Util.tuple21(t)]), Util.tuple22(t), facts)) for t in tr);
  end mergedImage;

  function reduceSelfShifts
    "connect(p[.., i, ..], p[.., i + s, ..]) for i in lo:hi with s = +-1 joins
     p[.., min(lo, lo+s):max(hi, hi+s), ..] into one set, for every size and also
     for an empty domain. Such an edge is replaced by a virtual hub vertex
     connected to the whole range."
    input Vector<Vertex> vertices;
    input array<Boolean> alive;
    input output list<Edge> edges;
    input list<Aff> facts;
    output array<Boolean> outAlive;
  protected
    list<Edge> res = {};
    list<Integer> diff;
    array<Integer> ia, ib;
    array<Sym> oa, ob;
    Integer d, it, n, hub, newit;
    Sym shift, lo, hi;
    array<Iv> dom;
    Box hub_box, new_dom;
    list<Integer> hub_iters, p_iters;
    list<Sym> hub_offs, p_offs;
    list<Boolean> alive_l;
  algorithm
    alive_l := listReverse(arrayList(alive));
    for e in edges loop
      if e.a.vertex <> e.b.vertex then
        res := e :: res;
        continue;
      end if;
      ia := listArray(e.a.iters); ib := listArray(e.b.iters);
      oa := listArray(e.a.offs); ob := listArray(e.b.offs);
      diff := list(j for j guard not (ia[j] == ib[j] and symEq(oa[j], ob[j])) in 1:arrayLength(ia));
      if listEmpty(diff) then
        continue; // p[i] -- p[i]
      end if;
      if listLength(diff) > 1 then
        unsupported("a connection inside one array shifted in more than one dimension", e.source);
      end if;
      d := listHead(diff);
      if ia[d] == 0 or ia[d] <> ib[d] then
        unsupported("a connection inside one array with a constant or permuted index", e.source);
      end if;
      shift := symSub(ob[d], oa[d], facts);
      if not (symEq(shift, symInt(1)) or symEq(shift, symInt(-1))) then
        unsupported("a connection inside one array shifted by " + symString(shift), e.source);
      end if;
      it := ia[d];
      dom := listArray(e.dom);
      n := arrayLength(dom);
      lo := symMin(symAdd(ivLo(dom[it]), oa[d], facts), symAdd(ivLo(dom[it]), ob[d], facts), facts);
      hi := symMax(symAdd(ivHi(dom[it]), oa[d], facts), symAdd(ivHi(dom[it]), ob[d], facts), facts);
      // the hub: [1:1] and the other iterators of the domain
      hub_box := IV(symInt(1), symInt(1)) :: list(dom[j] for j guard j <> it in 1:n);
      hub := Vector.size(vertices) + 1;
      Vector.push(vertices, VERTEX("$hub" + intString(hub), NONE(), hub_box));
      alive_l := true :: alive_l;
      // new domain: the shifted iterator replaced by [1:1], the whole range as a new last iterator
      newit := n + 1;
      new_dom := listAppend(list(if j == it then IV(symInt(1), symInt(1)) else dom[j] for j in 1:n), {IV(lo, hi)});
      hub_iters := 0 :: list(j for j guard j <> it in 1:n);
      hub_offs := symInt(1) :: list(symInt(0) for j guard j <> it in 1:n);
      p_iters := list(if j == d then newit else ia[j] for j in 1:arrayLength(ia));
      p_offs := list(if j == d then symInt(0) else oa[j] for j in 1:arrayLength(ia));
      res := EDGE(new_dom, SIDE(hub, hub_iters, hub_offs), SIDE(e.a.vertex, p_iters, p_offs), e.source) :: res;
    end for;
    edges := listReverseInPlace(res);
    outAlive := listArray(listReverseInPlace(alive_l));
  end reduceSelfShifts;

  function unsupported
    input String msg;
    input DAE.ElementSource source;
  algorithm
    Error.addSourceMessage(Error.INTERNAL_ERROR,
      {"--resizableArrays: " + msg + " is not supported in connections yet."}, ElementSource.getInfo(source));
    fail();
  end unsupported;

  // ---------------------------------------------------------------------------
  // pieces
  // ---------------------------------------------------------------------------

  function splitPieces
    "splits every piece by box into the part inside and the parts outside"
    input list<Box> pieces;
    input Box box;
    input list<Aff> facts;
    output list<Box> res = {};
    output Boolean changed = false;
  protected
    Box inside;
    list<Box> uniq;
    UnorderedSet<String> keys = UnorderedSet.new(stringHashDjb2, stringEq);
    String key;
  algorithm
    for p in pieces loop
      inside := boxInter(p, box, facts);
      if boxEmpty(inside, facts) == YES or boxContains(box, p, facts) then
        res := p :: res;
      else
        changed := true;
        res := inside :: res;
        res := List.append_reverse(boxMinus(p, box, facts), res);
      end if;
    end for;
    // unique pieces
    uniq := {};
    for p in res loop
      key := boxKey(p);
      if not UnorderedSet.contains(key, keys) then
        UnorderedSet.add(key, keys);
        uniq := p :: uniq;
      end if;
    end for;
    res := uniq;
    if listLength(res) > MAX_PIECES then
      Error.addInternalError(getInstanceName() + ": --resizableArrays: the connection sets do not converge (shifted connections around a cycle?).", sourceInfo());
      fail();
    end if;
  end splitPieces;

  function computePieces
    input Vector<Vertex> vertices;
    input array<Boolean> alive;
    input list<Edge> edges;
    input list<tuple<Integer, Box>> splits;
    input list<Aff> facts;
    output array<list<Box>> pieces;
  protected
    Boolean changed, c;
    Integer v;
    Box b, pre;
    list<Box> pl;
    Side sa, sb;
  algorithm
    pieces := arrayCreate(Vector.size(vertices), {});
    for v in 1:Vector.size(vertices) loop
      if alive[v] then
        pieces[v] := {vertexBox(vertices, v)};
      end if;
    end for;
    for s in splits loop
      (v, b) := s;
      (pl, _) := splitPieces(pieces[v], b, facts);
      pieces[v] := pl;
    end for;
    for round in 1:MAX_ROUNDS loop
      changed := false;
      for e in edges loop
        for sides in {(e.a, e.b), (e.b, e.a)} loop
          (sa, sb) := sides;
          (pl, c) := splitPieces(pieces[sa.vertex], sideImage(sa, e.dom, facts), facts);
          pieces[sa.vertex] := pl;
          changed := changed or c;
          for q in pieces[sb.vertex] loop
            if sideConstIn(sb, q, facts) then
              pre := sidePreimage(sb, e.dom, q, facts);
              if boxEmpty(pre, facts) <> YES then
                (pl, c) := splitPieces(pieces[sa.vertex], sideImage(sa, pre, facts), facts);
                pieces[sa.vertex] := pl;
                changed := changed or c;
              end if;
            end if;
          end for;
        end for;
      end for;
      if not changed then
        return;
      end if;
    end for;
    Error.addInternalError(getInstanceName() + ": --resizableArrays: the connection sets do not converge.", sourceInfo());
    fail();
  end computePieces;

  // ---------------------------------------------------------------------------
  // connection sets: union-find over the pieces and their dimensions
  // ---------------------------------------------------------------------------

  uniontype Sets
    record SETS
      Vector<Integer> pieceVertex;
      Vector<Box> pieceBox;
      Vector<Integer> pieceDim0 "the first dimension node of the piece";
      Vector<Integer> parent "of the pieces";
      Vector<Integer> dimParent;
      Vector<Sym> dimOff "coordinate of the parent - coordinate of the node";
      Vector<Boolean> collapsed;
      array<list<Integer>> vertexPieces;
    end SETS;
  end Sets;

  function addPiece
    input Sets sets;
    input Integer v;
    input Box box;
    output Integer p;
  protected
    Integer n0;
  algorithm
    Vector.push(sets.pieceVertex, v);
    Vector.push(sets.pieceBox, box);
    p := Vector.size(sets.pieceVertex);
    Vector.push(sets.parent, p);
    n0 := Vector.size(sets.dimParent) + 1;
    Vector.push(sets.pieceDim0, n0);
    for d in 1:listLength(box) loop
      Vector.push(sets.dimParent, n0 + d - 1);
      Vector.push(sets.dimOff, symInt(0));
      Vector.push(sets.collapsed, false);
    end for;
    arrayUpdate(sets.vertexPieces, v, List.appendElt(p, sets.vertexPieces[v]));
  end addPiece;

  function dimNode
    input Sets sets;
    input Integer p;
    input Integer d;
    output Integer n = Vector.get(sets.pieceDim0, p) + d - 1;
  end dimNode;

  function pieceFind
    input Sets sets;
    input output Integer p;
  algorithm
    while Vector.get(sets.parent, p) <> p loop
      p := Vector.get(sets.parent, p);
    end while;
  end pieceFind;

  function pieceUnion
    input Sets sets;
    input Integer p;
    input Integer q;
  protected
    Integer rp = pieceFind(sets, p), rq = pieceFind(sets, q);
  algorithm
    if rp <> rq then
      Vector.update(sets.parent, rq, rp);
    end if;
  end pieceUnion;

  function dimFind
    input Sets sets;
    input Integer x;
    input list<Aff> facts;
    output Integer root = x;
    output Sym off = symInt(0);
  algorithm
    while Vector.get(sets.dimParent, root) <> root loop
      off := symAdd(off, Vector.get(sets.dimOff, root), facts);
      root := Vector.get(sets.dimParent, root);
    end while;
  end dimFind;

  function dimUnion
    "coordinate y = coordinate x + d. Returns the shift if x and y are already in
     the same class (0 if consistent)."
    input Sets sets;
    input Integer x;
    input Integer y;
    input Sym d;
    input list<Aff> facts;
    output Option<Sym> shift = NONE();
  protected
    Integer rx, ry;
    Sym ox, oy;
  algorithm
    (rx, ox) := dimFind(sets, x, facts);
    (ry, oy) := dimFind(sets, y, facts);
    if rx == ry then
      shift := SOME(symSub(ox, symAdd(d, oy, facts), facts));
    else
      Vector.update(sets.dimParent, ry, rx);
      Vector.update(sets.dimOff, ry, symSub(symSub(ox, d, facts), oy, facts));
    end if;
  end dimUnion;

  function pieceOf
    input Sets sets;
    input Integer v;
    input Box box;
    input Vector<Vertex> vertices;
    input DAE.ElementSource source;
    input list<Aff> facts;
    output Integer p = 0;
  algorithm
    for q in sets.vertexPieces[v] loop
      if boxContains(Vector.get(sets.pieceBox, q), box, facts) then
        p := q;
        return;
      end if;
    end for;
    unsupported("the connection of " + vertexName(vertices, v) + boxString(box) + " (no matching piece)", source);
  end pieceOf;

  function addEdgeToSets
    input Sets sets;
    input Edge e;
    input Vector<Vertex> vertices;
    input list<Aff> facts;
  protected
    Box pre, qbox;
    Integer p, ndom, dp, dq;
    list<Integer> dps, dqs;
    array<Integer> ia, ib;
    array<Sym> oa, ob;
    Option<Sym> shift;
    Sym s;
  algorithm
    ia := listArray(e.a.iters); ib := listArray(e.b.iters);
    oa := listArray(e.a.offs); ob := listArray(e.b.offs);
    ndom := listLength(e.dom);
    for q in sets.vertexPieces[e.b.vertex] loop
      qbox := Vector.get(sets.pieceBox, q);
      if not sideConstIn(e.b, qbox, facts) then
        continue;
      end if;
      pre := sidePreimage(e.b, e.dom, qbox, facts);
      if boxEmpty(pre, facts) == YES then
        continue;
      end if;
      p := pieceOf(sets, e.a.vertex, sideImage(e.a, pre, facts), vertices, e.source, facts);
      pieceUnion(sets, p, q);
      for j in 1:ndom loop
        dps := list(d for d guard ia[d] == j in 1:arrayLength(ia));
        dqs := list(d for d guard ib[d] == j in 1:arrayLength(ib));
        if listLength(dps) > 1 or listLength(dqs) > 1 then
          unsupported("an iterator in two dimensions of a connector", e.source);
        end if;
        if not listEmpty(dps) and not listEmpty(dqs) then
          dp := listHead(dps);
          dq := listHead(dqs);
          shift := dimUnion(sets, dimNode(sets, p, dp), dimNode(sets, q, dq), symSub(ob[dq], oa[dp], facts), facts);
          if isSome(shift) then
            SOME(s) := shift;
            if not symEq(s, symInt(0)) then
              if symEq(s, symInt(1)) or symEq(s, symInt(-1)) then
                Vector.update(sets.collapsed, dimNode(sets, p, dp), true);
              else
                unsupported("connections shifted by " + symString(s) + " around a cycle", e.source);
              end if;
            end if;
          end if;
        elseif not listEmpty(dps) then
          Vector.update(sets.collapsed, dimNode(sets, p, listHead(dps)), true);
        elseif not listEmpty(dqs) then
          Vector.update(sets.collapsed, dimNode(sets, q, listHead(dqs)), true);
        end if;
      end for;
    end for;
  end addEdgeToSets;

  function readdMerged
    "the merged arrays back as members: a piece of x for every piece of y in its image"
    input Sets sets;
    input list<Merge> merges;
    input Vector<Vertex> vertices;
    input list<Aff> facts;
  protected
    Box img, qbox;
    array<Iv> ivs;
    Integer px, d, dq;
    Sym c;
  algorithm
    for m in merges loop
      img := mergedImage(vertexBox(vertices, m.x), m.tr, facts);
      for q in sets.vertexPieces[m.y] loop
        qbox := Vector.get(sets.pieceBox, q);
        if boxContains(img, qbox, facts) then
          ivs := arrayCreate(listLength(m.tr), IV(symInt(1), symInt(1)));
          dq := 0;
          for t in m.tr loop
            (d, c) := t;
            dq := dq + 1;
            ivs[d] := IV(symSub(ivLo(listGet(qbox, dq)), c, facts), symSub(ivHi(listGet(qbox, dq)), c, facts));
          end for;
          px := addPiece(sets, m.x, arrayList(ivs));
          pieceUnion(sets, q, px);
          dq := 0;
          for t in m.tr loop
            (d, c) := t;
            dq := dq + 1;
            // coordinate px = coordinate q - c
            _ := dimUnion(sets, dimNode(sets, q, dq), dimNode(sets, px, d), symNeg(c, facts), facts);
          end for;
        elseif boxEmpty(boxInter(img, qbox, facts), facts) <> YES then
          Error.addInternalError(getInstanceName() + ": --resizableArrays: piece " + boxString(qbox) + " of " +
            vertexName(vertices, m.y) + " is partly in the image of " + vertexName(vertices, m.x), sourceInfo());
          fail();
        end if;
      end for;
    end for;
  end readdMerged;

  function connectionSets
    input Vector<Vertex> vertices;
    input list<Edge> edges;
    output Sets sets;
    output list<Aff> facts;
  protected
    array<Boolean> alive;
    list<Merge> merges;
    list<Edge> el = edges;
    array<list<Box>> pieces;
  algorithm
    facts := indexFacts(vertices, el);
    alive := arrayCreate(Vector.size(vertices), true);
    (el, merges) := contract(vertices, alive, el, facts);
    (el, alive) := reduceSelfShifts(vertices, alive, el, facts);
    pieces := computePieces(vertices, alive, el,
      list((m.y, mergedImage(vertexBox(vertices, m.x), m.tr, facts)) for m in merges), facts);
    sets := SETS(Vector.new<Integer>(), Vector.new<Box>(), Vector.new<Integer>(), Vector.new<Integer>(),
                 Vector.new<Integer>(), Vector.new<Sym>(), Vector.new<Boolean>(),
                 arrayCreate(Vector.size(vertices), {}));
    for v in 1:arrayLength(pieces) loop
      for b in pieces[v] loop
        addPiece(sets, v, b);
      end for;
    end for;
    for e in el loop
      addEdgeToSets(sets, e, vertices, facts);
    end for;
    readdMerged(sets, merges, vertices, facts);
  end connectionSets;

  // ---------------------------------------------------------------------------
  // from the flat model to the graph
  // ---------------------------------------------------------------------------

  uniontype SubEntry
    "a subscript of one side of a connect: an index (iterator + offset or a
     constant), or a slice that is paired with a slice of the other side"
    record FIXED
      Integer it;
      Sym off;
    end FIXED;
    record SLICED
      Sym lo;
      Sym hi;
    end SLICED;
  end SubEntry;

  uniontype Context
    record CONTEXT
      Vector<Vertex> vertices;
      UnorderedMap<String, Integer> vertexIndex;
      UnorderedMap<String, Expression> params "size parameters by name";
      UnorderedMap<String, Variable> variables;
    end CONTEXT;
  end Context;

  function isConnection
    input Equation eq;
    output Boolean isConn;
  algorithm
    isConn := match eq
      local
        Equation e;
      case Equation.CONNECT() then true;
      case Equation.FOR(body = e :: _) then isConnection(e);
      else false;
    end match;
  end isConnection;

  function crefDims
    input ComponentRef cr;
    output list<Dimension> dims = {};
  protected
    ComponentRef c = cr;
  algorithm
    while not ComponentRef.isEmpty(c) loop
      dims := listAppend(Type.arrayDims(ComponentRef.nodeType(c)), dims);
      c := ComponentRef.rest(c);
    end while;
  end crefDims;

  function isInComponentArray
    "true if a cref is a component of an array of components, e.g. s.N for s[M]"
    input ComponentRef cref;
    output Boolean b;
  protected
    ComponentRef rest;
  algorithm
    rest := ComponentRef.rest(cref);
    b := not ComponentRef.isEmpty(rest) and Type.isArray(ComponentRef.nodeType(ComponentRef.stripSubscripts(rest)));
  end isInComponentArray;

  function uniformArrayElement
    "The value of all elements of an array expression if they are all the same."
    input Expression exp;
    output Option<Expression> elem;
  algorithm
    elem := match exp
      local
        Expression body;
        list<tuple<InstNode, Expression>> iters;
      case Expression.CALL(call = Call.TYPED_ARRAY_CONSTRUCTOR(exp = body, iters = iters))
        guard not List.any(iters, function iteratorOccursIn(exp = body))
        then uniformArrayElement(body);
      case Expression.CALL() guard Call.isNamed(exp.call, "fill")
        then uniformArrayElement(listHead(Call.arguments(exp.call)));
      case _ guard not Type.isArray(Expression.typeOf(exp)) then SOME(exp);
      else NONE();
    end match;
  end uniformArrayElement;

  function iteratorOccursIn
    input tuple<InstNode, Expression> iter;
    input Expression exp;
    output Boolean b = Expression.containsIterator(exp, Util.tuple21(iter));
  end iteratorOccursIn;

  function resolveAlias
    "a parameter of an array of components with the same value for all elements
     (e.g. s[i].N for s[M](each N = K)) is that value"
    input ComponentRef cref;
    input Context ctx;
    output Option<Expression> alias = NONE();
  protected
    Option<Variable> ovar;
    Variable var;
    Option<Expression> obexp;
    Expression bexp;
  algorithm
    // an integer parameter bound to an affine expression of other parameters
    // (e.g. s.N = N for s(N = N)) is that expression
    ovar := UnorderedMap.get(ComponentRef.toString(cref), ctx.variables);
    if isSome(ovar) then
      SOME(var) := ovar;
      obexp := Binding.getExpOpt(var.binding);
      if isSome(obexp) and Type.isInteger(var.ty) then
        SOME(bexp) := obexp;
        // only an expression of resizable parameters, like NFFlatten.resizableDimensionAlias
        if not Expression.isInteger(bexp) and isAffineExp(bexp) and onlyResizableCrefs(bexp) then
          alias := SOME(bexp);
          return;
        end if;
      end if;
    end if;

    if isInComponentArray(cref) then
      ovar := UnorderedMap.get(ComponentRef.toString(ComponentRef.stripSubscriptsAll(cref)), ctx.variables);
      if isSome(ovar) then
        SOME(var) := ovar;
        obexp := Binding.getExpOpt(var.binding);
        if isSome(obexp) then
          SOME(bexp) := obexp;
          alias := uniformArrayElement(bexp);
        end if;
      end if;
    end if;
  end resolveAlias;

  function onlyResizableCrefs
    input Expression exp;
    output Boolean b = not Expression.contains(exp, isNonResizableCref);
  end onlyResizableCrefs;

  function isNonResizableCref
    input Expression exp;
    output Boolean b;
  algorithm
    b := match exp
      case Expression.CREF() then not ComponentRef.isResizable(exp.cref);
      else false;
    end match;
  end isNonResizableCref;

  function isAffineExp
    "an integer expression of crefs, +, - and multiplication with integers"
    input Expression exp;
    output Boolean b;
  algorithm
    b := match exp
      case Expression.INTEGER() then true;
      case Expression.CREF() then not ComponentRef.isIterator(exp.cref) and Type.isInteger(exp.ty);
      case Expression.BINARY() guard exp.operator.op == Op.ADD or exp.operator.op == Op.SUB
        then isAffineExp(exp.exp1) and isAffineExp(exp.exp2);
      case Expression.BINARY() guard exp.operator.op == Op.MUL
        then isAffineExp(exp.exp1) and isAffineExp(exp.exp2) and
             (Expression.isInteger(exp.exp1) or Expression.isInteger(exp.exp2));
      case Expression.UNARY() guard exp.operator.op == Op.UMINUS then isAffineExp(exp.exp);
      else false;
    end match;
  end isAffineExp;

  function expToAff
    "an integer expression as affine expression; iterators become #<position in
     the domain>, other crefs size parameters"
    input Expression exp;
    input list<String> iterNames;
    input Context ctx;
    input DAE.ElementSource source;
    output Aff a;
  algorithm
    a := match exp
      local
        Option<Expression> alias;
        Expression e;
        Aff a1, a2;
        String name;
        Integer pos;

      case Expression.INTEGER() then affInt(exp.value);

      case Expression.CREF() guard ComponentRef.isIterator(exp.cref)
        algorithm
          name := ComponentRef.firstName(exp.cref);
          pos := 0;
          for i in 1:listLength(iterNames) loop
            if listGet(iterNames, i) == name then
              pos := i;
            end if;
          end for;
          if pos == 0 then
            unsupported("the iterator " + name + " in " + Expression.toString(exp), source);
          end if;
        then affParam("#" + intString(pos));

      case Expression.CREF()
        algorithm
          alias := resolveAlias(exp.cref, ctx);
          if isSome(alias) then
            SOME(e) := alias;
            a1 := expToAff(e, iterNames, ctx, source);
          else
            name := ComponentRef.toString(exp.cref);
            UnorderedMap.tryAdd(name, exp, ctx.params);
            a1 := affParam(name);
          end if;
        then a1;

      case Expression.BINARY()
        algorithm
          a1 := expToAff(exp.exp1, iterNames, ctx, source);
          a2 := expToAff(exp.exp2, iterNames, ctx, source);
          a1 := match exp.operator.op
            case Op.ADD then affAdd(a1, a2);
            case Op.SUB then affSub(a1, a2);
            case Op.MUL guard affIsConst(a1) then affScale(a2, a1.c);
            case Op.MUL guard affIsConst(a2) then affScale(a1, a2.c);
            else algorithm
              unsupported("the expression " + Expression.toString(exp) + " (not affine)", source);
            then fail();
          end match;
        then a1;

      case Expression.UNARY() guard exp.operator.op == Op.UMINUS
        then affNeg(expToAff(exp.exp, iterNames, ctx, source));

      else algorithm
        unsupported("the expression " + Expression.toString(exp) + " in a connection index or range", source);
      then fail();
    end match;
  end expToAff;

  function expToSym
    "an expression without iterators"
    input Expression exp;
    input Context ctx;
    input DAE.ElementSource source;
    output Sym s = symAff(expToAff(exp, {}, ctx, source));
  end expToSym;

  function dimToSym
    input Dimension dim;
    input Context ctx;
    input DAE.ElementSource source;
    output Sym s;
  algorithm
    s := match dim
      case Dimension.RESIZABLE() then expToSym(dim.exp, ctx, source);
      case Dimension.INTEGER() then symInt(dim.size);
      case Dimension.EXP() then expToSym(dim.exp, ctx, source);
      case _ guard Dimension.isKnown(dim) then symInt(Dimension.size(dim));
      else algorithm
        unsupported("the dimension " + Dimension.toString(dim) + " of a connector", source);
      then fail();
    end match;
  end dimToSym;

  function vertexOf
    "the vertex of a connector (unsubscripted), created if it does not exist"
    input ComponentRef connCref;
    input DAE.ElementSource source;
    input Context ctx;
    output Integer v;
  protected
    Connector conn = Connector.fromCref(connCref, ComponentRef.nodeType(connCref), source);
    String key = vertexKey(ComponentRef.toString(connCref), Connector.isOutside(conn));
    Option<Integer> ov;
  algorithm
    ov := UnorderedMap.get(key, ctx.vertexIndex);
    if isSome(ov) then
      SOME(v) := ov;
    else
      Vector.push(ctx.vertices, VERTEX(key, SOME(conn),
        list(IV(symInt(1), dimToSym(d, ctx, source)) for d in crefDims(connCref))));
      v := Vector.size(ctx.vertices);
      UnorderedMap.add(key, v, ctx.vertexIndex);
    end if;
  end vertexOf;

  function vertexKey
    "a vertex for each face of a connector: inside and outside elements of a
     connector are in different connection sets"
    input String name;
    input Boolean outside;
    output String key = name + (if outside then "$outside" else "$inside");
  end vertexKey;

  function connectSide
    input Expression exp;
    input list<String> iterNames;
    input DAE.ElementSource source;
    input Context ctx;
    output Integer v;
    output list<SubEntry> entries = {};
  protected
    ComponentRef cr;
    list<Subscript> subs;
    Box box;
    Iv viv;
    Aff a, rest;
    Integer it, c;
    String n;
    Expression range;
  algorithm
    cr := ComponentRef.fillSubscripts(Expression.toCref(exp));
    subs := ComponentRef.subscriptsAllFlat(cr);
    v := vertexOf(ComponentRef.stripSubscriptsAll(cr), source, ctx);
    box := vertexBox(ctx.vertices, v);
    if listLength(subs) <> listLength(box) then
      unsupported("the subscripts of " + Expression.toString(exp), source);
    end if;
    for s in subs loop
      viv :: box := box;
      entries := match s
        case Subscript.INDEX()
          algorithm
            a := expToAff(s.index, iterNames, ctx, source);
            it := 0;
            rest := a;
            for t in a.k loop
              (n, c) := t;
              if stringGet(n, 1) == 35 /* # */ then
                if it <> 0 or c <> 1 then
                  unsupported("the index " + Expression.toString(s.index), source);
                end if;
                it := stringInt(substring(n, 2, stringLength(n)));
                rest := affSub(a, affParam(n));
              end if;
            end for;
          then FIXED(it, symAff(rest)) :: entries;
        case Subscript.SLICE(slice = range as Expression.RANGE())
          algorithm
            checkStep(range.step, source);
          then SLICED(expToSym(range.start, ctx, source), expToSym(range.stop, ctx, source)) :: entries;
        case Subscript.WHOLE() then SLICED(viv.lo, viv.hi) :: entries;
        else algorithm
          unsupported("the subscript " + Subscript.toString(s) + " in " + Expression.toString(exp), source);
        then fail();
      end match;
    end for;
    entries := listReverseInPlace(entries);
  end connectSide;

  function checkStep
    input Option<Expression> step;
    input DAE.ElementSource source;
  algorithm
    _ := match step
      case NONE() then ();
      case SOME(Expression.INTEGER(1)) then ();
      else algorithm
        unsupported("a range with a step", source);
      then fail();
    end match;
  end checkStep;

  function collectEdges
    input Equation eq;
    input list<String> iterNames;
    input Box dom;
    input Context ctx;
    input output list<Edge> edges;
  protected
    Integer va, vb, it;
    list<SubEntry> ea, eb, sa, sb;
    list<Integer> ia, ib;
    list<Sym> oa, ob;
    Box d, slice_ivs;
    Sym lo, hi, len_a, len_b;
    list<Aff> facts = {};
  algorithm
    edges := match eq
      local
        Expression range;
      case Equation.CONNECT()
        algorithm
          (va, ea) := connectSide(eq.lhs, iterNames, eq.source, ctx);
          (vb, eb) := connectSide(eq.rhs, iterNames, eq.source, ctx);
          sa := list(e for e guard isSliced(e) in ea);
          sb := list(e for e guard isSliced(e) in eb);
          if listLength(sa) <> listLength(sb) then
            unsupported("connecting arrays with different numbers of dimensions", eq.source);
          end if;
          // every pair of slices gets a new iterator 1:n
          slice_ivs := {};
          it := listLength(dom);
          for p in List.zip(sa, sb) loop
            len_a := symSub(sliceHi(Util.tuple21(p)), sliceLo(Util.tuple21(p)), facts);
            len_b := symSub(sliceHi(Util.tuple22(p)), sliceLo(Util.tuple22(p)), facts);
            if not symEq(len_a, len_b) then
              unsupported("connecting slices whose sizes " + symString(len_a) + " + 1 and " + symString(len_b) +
                " + 1 are not equal symbolically", eq.source);
            end if;
            slice_ivs := IV(symInt(1), symAddInt(len_a, 1, facts)) :: slice_ivs;
          end for;
          d := listAppend(dom, listReverse(slice_ivs));
          (ia, oa) := sideDims(ea, it, facts);
          (ib, ob) := sideDims(eb, it, facts);
        then EDGE(d, SIDE(va, ia, oa), SIDE(vb, ib, ob), eq.source) :: edges;

      case Equation.FOR(range = SOME(range as Expression.RANGE()))
        algorithm
          checkStep(range.step, eq.source);
          lo := expToSym(range.start, ctx, eq.source);
          hi := expToSym(range.stop, ctx, eq.source);
          for e in eq.body loop
            edges := collectEdges(e, listAppend(iterNames, {InstNode.name(eq.iterator)}),
              listAppend(dom, {IV(lo, hi)}), ctx, edges);
          end for;
        then edges;

      else algorithm
        unsupported("the connection equation " + Equation.toString(eq), Equation.source(eq));
      then fail();
    end match;
  end collectEdges;

  function isSliced
    input SubEntry e;
    output Boolean b;
  algorithm
    b := match e case SLICED() then true; else false; end match;
  end isSliced;

  function sliceLo
    input SubEntry e;
    output Sym s;
  algorithm
    SLICED(lo = s) := e;
  end sliceLo;

  function sliceHi
    input SubEntry e;
    output Sym s;
  algorithm
    SLICED(hi = s) := e;
  end sliceHi;

  function sideDims
    "iterators and offsets of a side, the k-th slice gets iterator n + k with
     the offset lo - 1"
    input list<SubEntry> entries;
    input Integer n;
    input list<Aff> facts;
    output list<Integer> iters = {};
    output list<Sym> offs = {};
  protected
    Integer k = n;
  algorithm
    for e in entries loop
      _ := match e
        case FIXED()
          algorithm
            iters := e.it :: iters;
            offs := e.off :: offs;
          then ();
        case SLICED()
          algorithm
            k := k + 1;
            iters := k :: iters;
            offs := symAddInt(e.lo, -1, facts) :: offs;
          then ();
      end match;
    end for;
    iters := listReverseInPlace(iters);
    offs := listReverseInPlace(offs);
  end sideDims;

  // ---------------------------------------------------------------------------
  // equations
  // ---------------------------------------------------------------------------

  uniontype ConnVar
    "a variable of a connector: its cref, the number of dimensions of the
     connector and the path inside the connector"
    record CONN_VAR
      ComponentRef cref;
      Integer connDims;
      String member;
    end CONN_VAR;
  end ConnVar;

  uniontype Idx
    record IDX_EXP
      Expression exp;
    end IDX_EXP;
    record IDX_LOOP
      Integer dim;
    end IDX_LOOP;
  end Idx;

  function memberName
    "the path of a connector variable inside its connector, e.g. v for line.a.v"
    input ComponentRef var;
    input ComponentRef conn;
    output String name;
  protected
    list<String> var_names = crefNames(var);
  algorithm
    for i in 1:listLength(crefNames(conn)) loop
      var_names := List.restOrEmpty(var_names);
    end for;
    name := stringDelimitList(var_names, ".");
  end memberName;

  function crefNames
    input ComponentRef cref;
    output list<String> names = {};
  protected
    ComponentRef c = cref;
  algorithm
    while not ComponentRef.isEmpty(c) loop
      names := ComponentRef.firstName(c) :: names;
      c := ComponentRef.rest(c);
    end while;
  end crefNames;

  function connectorVariables
    "the potential and flow variables of every connector array"
    input list<Variable> variables;
    input Vector<Vertex> vertices;
    input UnorderedMap<String, Integer> vertexIndex;
    output array<list<ConnVar>> potentials;
    output array<list<ConnVar>> flows;
  protected
    ComponentRef c;
    Option<Integer> ov;
    Integer v;
    Connector conn;
    Box box;
  algorithm
    potentials := arrayCreate(Vector.size(vertices), {});
    flows := arrayCreate(Vector.size(vertices), {});
    for var in listReverse(variables) loop
      if Variable.isPotential(var) or Variable.isFlow(var) then
        // the connectors containing the variable, or the variable itself
        // (connector RealInput = input Real)
        c := var.name;
        while not ComponentRef.isEmpty(c) loop
          for outside in {false, true} loop
            ov := UnorderedMap.get(vertexKey(ComponentRef.toString(c), outside), vertexIndex);
            if isSome(ov) then
              SOME(v) := ov;
              VERTEX(conn = SOME(conn), box = box) := Vector.get(vertices, v);
              if Variable.isFlow(var) then
                flows[v] := CONN_VAR(var.name, listLength(box), memberName(var.name, Connector.name(conn))) :: flows[v];
              else
                potentials[v] := CONN_VAR(var.name, listLength(box), memberName(var.name, Connector.name(conn))) :: potentials[v];
              end if;
            end if;
          end for;
          c := ComponentRef.rest(c);
        end while;
      end if;
    end for;
  end connectorVariables;

  function applyConnSubs
    "the variable of a connector subscripted with the indices of the connector,
     the dimensions of the variable inside the connector stay whole"
    input ComponentRef cr;
    input Integer connDims;
    input list<Subscript> indices;
    output Expression outExp;
  protected
    list<Subscript> subs;
  algorithm
    outExp := Expression.fromCref(cr);
    if Type.isArray(Expression.typeOf(outExp)) and connDims > 0 then
      subs := List.firstN(indices, intMin(connDims, Type.dimensionCount(Expression.typeOf(outExp))));
      outExp := Expression.applySubscripts(subs, outExp);
    end if;
  end applyConnSubs;

  function makeEqualityAssert
    "assert(abs(l - r) <= 0) for Reals, assert(l == r) else"
    input Expression l;
    input Expression r;
    input Type ty;
    output Equation eq;
  protected
    Type elem_ty = Type.arrayElementType(ty);
    Expression exp;
  algorithm
    if Type.isArray(ty) then
      Error.addInternalError(getInstanceName() + ": connected parameters of array type are not supported with --resizableArrays yet: "
        + Expression.toString(l) + ", " + Expression.toString(r), sourceInfo());
      fail();
    end if;
    if Type.isReal(elem_ty) then
      exp := Expression.BINARY(l, Operator.makeSub(elem_ty), r);
      exp := Expression.CALL(Call.makeTypedCall(NFBuiltinFuncs.ABS_REAL, {exp}, Expression.variability(exp), Purity.PURE));
      exp := Expression.RELATION(exp, Operator.makeLessEq(elem_ty), Expression.REAL(0.0), -1);
    else
      exp := Expression.RELATION(l, Operator.makeEqual(elem_ty), r, -1);
    end if;
    eq := Equation.ASSERT(exp, Expression.STRING("Connected constants/parameters must be equal"),
      NFBuiltin.ASSERTIONLEVEL_ERROR, NFInstNode.NO_SCOPE, DAE.emptyElementSource);
  end makeEqualityAssert;

  function wrapLoops
    "the equations in for loops, the first loop outermost"
    input list<Equation> body;
    input list<tuple<InstNode, Expression>> loops;
    output list<Equation> eqs = body;
  algorithm
    if listEmpty(body) then
      return;
    end if;
    for l in listReverse(loops) loop
      eqs := {Equation.FOR(Util.tuple21(l), SOME(Util.tuple22(l)), eqs, NFInstNode.NO_SCOPE, DAE.emptyElementSource)};
    end for;
  end wrapLoops;

  function iterExp
    input InstNode iter;
    output Expression exp = Expression.fromCref(ComponentRef.makeIterator(iter, Type.INTEGER()));
  end iterExp;

  function rangeExp
    input Sym lo;
    input Sym hi;
    input UnorderedMap<String, Expression> params;
    output Expression exp = Expression.makeRange(symToExp(lo, params), NONE(), symToExp(hi, params));
  end rangeExp;

  function generateEquations
    input Sets sets;
    input Vector<Vertex> vertices;
    input array<list<ConnVar>> potentials;
    input array<list<ConnVar>> flows;
    input UnorderedMap<String, Expression> params;
    input list<Aff> facts;
    output list<Equation> equations = {};
  protected
    Integer n = Vector.size(sets.pieceVertex);
    array<list<Integer>> groups = arrayCreate(n, {});
    Integer r;
  algorithm
    for p in n:-1:1 loop
      r := pieceFind(sets, p);
      groups[r] := p :: groups[r];
    end for;
    for p in 1:n loop
      if not listEmpty(groups[p]) then
        equations := setEquations(groups[p], sets, vertices, potentials, flows, params, facts, equations);
      end if;
    end for;
    equations := listReverseInPlace(equations);
  end generateEquations;

  function setEquations
    input list<Integer> members;
    input Sets sets;
    input Vector<Vertex> vertices;
    input array<list<ConnVar>> potentials;
    input array<list<ConnVar>> flows;
    input UnorderedMap<String, Expression> params;
    input list<Aff> facts;
    input output list<Equation> equations;
  protected
    UnorderedMap<Integer, ClassNodes> cls "class -> (piece, dim, off)";
    list<Integer> cls_order = {}, free = {}, real = {}, refs, nonempty;
    UnorderedSet<Integer> nonempty_set;
    Boolean collapsed, elementwise;
    Integer c, cnt, ref, v, d;
    Sym off, lo, hi;
    Box box;
    list<tuple<Integer, Integer, Sym>> nodes;
    UnorderedMap<Integer, Sym> tlo, thi "the range of a free class";
    UnorderedMap<Integer, Expression> tval "the iterator (or constant) of a free class";
    list<tuple<InstNode, Expression>> loops = {}, ploops;
    UnorderedMap<Integer, InstNode> loop_iters "loop dimension -> its iterator";
    UnorderedMap<Integer, IdxList> idx;
    list<Idx> pidx, ridx;
    list<Subscript> pexps, rexps;
    InstNode iter;
    Expression e;
    list<Equation> body;
    Option<Sym> trange_lo, trange_hi;
  algorithm
    cls := UnorderedMap.new<ClassNodes>(Util.id, intEq);
    for p in members loop
      for d in 1:listLength(Vector.get(sets.pieceBox, p)) loop
        (c, off) := dimFind(sets, dimNode(sets, p, d), facts);
        if not UnorderedMap.contains(c, cls) then
          cls_order := c :: cls_order;
        end if;
        UnorderedMap.addUpdate(c, function prependNode(node = (p, d, off)), cls);
      end for;
    end for;
    cls_order := listReverseInPlace(cls_order);

    // free classes: no collapsed node, every member exactly once
    for c in cls_order loop
      nodes := UnorderedMap.getOrFail(c, cls);
      collapsed := false;
      for nd in nodes loop
        if Vector.get(sets.collapsed, dimNode(sets, Util.tuple31(nd), Util.tuple32(nd))) then
          collapsed := true;
        end if;
      end for;
      for p in members loop
        cnt := 0;
        for nd in nodes loop
          if Util.tuple31(nd) == p then
            cnt := cnt + 1;
          end if;
        end for;
        if cnt <> 1 then
          collapsed := true;
        end if;
      end for;
      if not collapsed then
        free := c :: free;
      end if;
    end for;
    free := listReverseInPlace(free);

    // the members that may be non-empty
    nonempty := list(p for p guard boxEmpty(Vector.get(sets.pieceBox, p), facts) <> YES in members);
    if listEmpty(nonempty) then
      return;
    end if;
    nonempty_set := UnorderedSet.fromList(nonempty, Util.id, intEq);

    // the ranges of the free classes are the same for all nonempty
    tlo := UnorderedMap.new<Sym>(Util.id, intEq);
    thi := UnorderedMap.new<Sym>(Util.id, intEq);
    tval := UnorderedMap.new<Expression>(Util.id, intEq);
    for c in free loop
      for nd in UnorderedMap.getOrFail(c, cls) loop
        (ref, d, off) := nd;
        if UnorderedSet.contains(ref, nonempty_set) then
          box := Vector.get(sets.pieceBox, ref);
          lo := symAdd(ivLo(listGet(box, d)), off, facts);
          hi := symAdd(ivHi(listGet(box, d)), off, facts);
          if UnorderedMap.contains(c, tlo) then
            if not (symEq(lo, UnorderedMap.getOrFail(c, tlo)) and symEq(hi, UnorderedMap.getOrFail(c, thi))) then
              Error.addInternalError(getInstanceName() + ": --resizableArrays: different ranges in one connection set: " +
                setString(nonempty, sets, vertices), sourceInfo());
              fail();
            end if;
          else
            UnorderedMap.add(c, lo, tlo);
            UnorderedMap.add(c, hi, thi);
          end if;
        end if;
      end for;
      lo := UnorderedMap.getOrFail(c, tlo);
      hi := UnorderedMap.getOrFail(c, thi);
      if symEq(lo, hi) then
        UnorderedMap.add(c, symToExp(lo, params), tval);
      else
        iter := InstNode.newUniqueIterator();
        loops := (iter, rangeExp(lo, hi, params)) :: loops;
        UnorderedMap.add(c, iterExp(iter), tval);
      end if;
    end for;
    loops := listReverseInPlace(loops);

    // the indices of the nonempty
    idx := UnorderedMap.new<IdxList>(Util.id, intEq);
    for p in nonempty loop
      box := Vector.get(sets.pieceBox, p);
      pidx := {};
      for d in 1:listLength(box) loop
        (c, off) := dimFind(sets, dimNode(sets, p, d), facts);
        if UnorderedMap.contains(c, tval) then
          // t - off
          e := Expression.BINARY(UnorderedMap.getOrFail(c, tval), Operator.makeSub(Type.INTEGER()), symToExp(off, params));
          pidx := IDX_EXP(SimplifyExp.simplify(e)) :: pidx;
        elseif symEq(ivLo(listGet(box, d)), ivHi(listGet(box, d))) then
          pidx := IDX_EXP(symToExp(ivLo(listGet(box, d)), params)) :: pidx;
        else
          pidx := IDX_LOOP(d) :: pidx;
        end if;
      end for;
      UnorderedMap.add(p, listReverseInPlace(pidx), idx);
    end for;

    real := list(p for p guard isSome(vertexConn(vertices, Vector.get(sets.pieceVertex, p))) in nonempty);
    if listEmpty(real) then
      return;
    end if;

    // the reference member: no loops, else certainly non-empty with one loop
    refs := list(p for p guard listEmpty(loopDims(UnorderedMap.getOrFail(p, idx))) in real);
    if listEmpty(refs) then
      refs := list(p for p guard boxEmpty(Vector.get(sets.pieceBox, p), facts) == NO and
        listLength(loopDims(UnorderedMap.getOrFail(p, idx))) == 1 in real);
    end if;
    if listEmpty(refs) then
      Error.addInternalError(getInstanceName() + ": --resizableArrays: no reference element in the connection set " +
        setString(nonempty, sets, vertices), sourceInfo());
      fail();
    end if;
    ref := listHead(refs);
    box := Vector.get(sets.pieceBox, ref);
    ridx := UnorderedMap.getOrFail(ref, idx);
    rexps := list(Subscript.INDEX(idxValue(i, box, NONE(), params)) for i in ridx);

    // potential equations: every member equal to the reference
    for p in real loop
      v := Vector.get(sets.pieceVertex, p);
      box := Vector.get(sets.pieceBox, p);
      pidx := UnorderedMap.getOrFail(p, idx);
      ploops := {};
      loop_iters := UnorderedMap.new<InstNode>(Util.id, intEq);
      for d in loopDims(pidx) loop
        iter := InstNode.newUniqueIterator();
        UnorderedMap.add(d, iter, loop_iters);
        lo := ivLo(listGet(box, d));
        if p == ref then
          lo := symAddInt(lo, 1, facts);
        end if;
        ploops := (iter, rangeExp(lo, ivHi(listGet(box, d)), params)) :: ploops;
      end for;
      ploops := listReverseInPlace(ploops);
      if p == ref and listEmpty(ploops) then
        continue;
      end if;
      pexps := list(Subscript.INDEX(idxValue(i, box, SOME(loop_iters), params)) for i in pidx);
      body := potentialEquations(potentials[v], potentials[Vector.get(sets.pieceVertex, ref)], pexps, rexps);
      equations := List.append_reverse(wrapLoops(wrapLoops(body, ploops), loops), equations);
    end for;

    // the flow equation: the sum over all nonempty, the loop dimensions summed
    elementwise := List.any(list(not listEmpty(loopDims(UnorderedMap.getOrFail(p, idx))) for p in real), Util.id);
    body := flowEquations(real, sets, vertices, flows, idx, elementwise, params);
    equations := List.append_reverse(wrapLoops(body, loops), equations);
  end setEquations;

  function prependNode
    input Option<list<tuple<Integer, Integer, Sym>>> old;
    input tuple<Integer, Integer, Sym> node;
    output list<tuple<Integer, Integer, Sym>> res;
  algorithm
    res := match old
      local list<tuple<Integer, Integer, Sym>> l;
      case SOME(l) then listAppend(l, {node});
      else {node};
    end match;
  end prependNode;

  function vertexConn
    input Vector<Vertex> vertices;
    input Integer v;
    output Option<Connector> conn;
  algorithm
    VERTEX(conn = conn) := Vector.get(vertices, v);
  end vertexConn;

  type ClassNodes = list<tuple<Integer, Integer, Sym>> "the nodes of a dimension class: piece, dimension, offset";
  type IdxList = list<Idx>;

  function loopDims
    input list<Idx> idx;
    output list<Integer> dims = {};
  algorithm
    for i in listReverse(idx) loop
      _ := match i
        case IDX_LOOP() algorithm dims := i.dim :: dims; then ();
        else ();
      end match;
    end for;
  end loopDims;

  function idxValue
    "the index expression of a dimension: loops get their iterators in order,
     without loops the first element"
    input Idx i;
    input Box box;
    input Option<UnorderedMap<Integer, InstNode>> loopIters "the iterators of the loop dimensions, NONE for the first element";
    input UnorderedMap<String, Expression> params;
    output Expression exp;
  algorithm
    exp := match (i, loopIters)
      local
        UnorderedMap<Integer, InstNode> iters;
      case (IDX_EXP(), _) then i.exp;
      case (IDX_LOOP(), NONE()) then symToExp(ivLo(listGet(box, i.dim)), params);
      case (IDX_LOOP(), SOME(iters)) then iterExp(UnorderedMap.getOrFail(i.dim, iters));
    end match;
  end idxValue;

  function potentialEquations
    input list<ConnVar> vars1;
    input list<ConnVar> vars2;
    input list<Subscript> inds1;
    input list<Subscript> inds2;
    output list<Equation> equations = {};
  protected
    Expression l, r;
    Type ty;
  algorithm
    for v1 in vars1 loop
      for v2 in vars2 loop
        if v1.member == v2.member and
           Type.isEqual(Type.arrayElementType(ComponentRef.nodeType(v1.cref)), Type.arrayElementType(ComponentRef.nodeType(v2.cref))) then
          l := applyConnSubs(v1.cref, v1.connDims, inds1);
          r := applyConnSubs(v2.cref, v2.connDims, inds2);
          ty := Expression.typeOf(l);
          if ComponentRef.variability(v1.cref) > Variability.PARAMETER and ComponentRef.variability(v2.cref) > Variability.PARAMETER then
            equations := Equation.makeEquality(l, r, ty, scalarizeMode = NFEquation.ScalarizeMode.DONT_SCALARIZE) :: equations;
          else
            equations := makeEqualityAssert(l, r, ty) :: equations;
          end if;
        end if;
      end for;
    end for;
    equations := listReverseInPlace(equations);
  end potentialEquations;

  function flowEquations
    input list<Integer> members;
    input Sets sets;
    input Vector<Vertex> vertices;
    input array<list<ConnVar>> flows;
    input UnorderedMap<Integer, IdxList> idx;
    input Boolean elementwise;
    input UnorderedMap<String, Expression> params;
    output list<Equation> equations = {};
  protected
    UnorderedMap<String, ExpList> terms = UnorderedMap.new<ExpList>(stringHashDjb2, stringEq) "the terms of each sum, in reverse order";
    Integer v, sz;
    Box box;
    list<Idx> pidx;
    list<Subscript> inds;
    Box vbox;
    Boolean is_sum, outside, all_outside;
    Connector conn;
    Expression e, sum_exp;
    list<Expression> expl;
    Type ty;
    list<Dimension> mdims;
  algorithm
    // the outside connectors are subtracted, if all are outside nothing is
    all_outside := true;
    for p in members loop
      SOME(conn) := vertexConn(vertices, Vector.get(sets.pieceVertex, p));
      if not Connector.isOutside(conn) then
        all_outside := false;
      end if;
    end for;
    for p in members loop
      v := Vector.get(sets.pieceVertex, p);
      SOME(conn) := vertexConn(vertices, v);
      outside := Connector.isOutside(conn) and not all_outside;
      box := Vector.get(sets.pieceBox, p);
      pidx := UnorderedMap.getOrFail(p, idx);
      is_sum := not listEmpty(loopDims(pidx));
      vbox := vertexBox(vertices, v);
      inds := list(flowSubscript(i, box, vbox, params) for i in pidx);
      for fv in flows[v] loop
        mdims := Type.arrayDims(ComponentRef.nodeType(fv.cref));
        if elementwise and not listEmpty(mdims) then
          if listLength(mdims) <> 1 or not Dimension.isKnown(listHead(mdims)) then
            Error.addInternalError(getInstanceName() + ": the flow variable " + ComponentRef.toString(fv.cref) +
              " has to be a vector of known size inside its connector to sum it over a range of connectors.", sourceInfo());
            fail();
          end if;
          sz := Dimension.size(listHead(mdims));
          for k in 1:sz loop
            e := flowTerm(ComponentRef.setSubscripts({Subscript.INDEX(Expression.INTEGER(k))}, fv.cref), fv.connDims, inds, is_sum, outside);
            addNamed(fv.member + "[" + intString(k) + "]", e, terms);
          end for;
        else
          e := flowTerm(fv.cref, fv.connDims, inds, is_sum, outside);
          addNamed(fv.member, e, terms);
        end if;
      end for;
    end for;

    // one sum for each flow variable, in the order of their first terms
    for name in UnorderedMap.keyList(terms) loop
      expl := listReverse(UnorderedMap.getOrFail(name, terms));
      sum_exp :: expl := expl;
      for e in expl loop
        sum_exp := Expression.BINARY(sum_exp, Operator.makeAdd(Expression.typeOf(e)), e);
      end for;
      ty := Expression.typeOf(sum_exp);
      equations := Equation.makeEquality(sum_exp, Expression.makeZero(ty), ty) :: equations;
    end for;
    equations := listReverseInPlace(equations);
  end flowEquations;

  function flowSubscript
    "an index or a slice of the summed elements (no : for whole dimensions, the
     backend needs the ranges of resizable dimensions)"
    input Idx i;
    input Box box;
    input Box vertexBox;
    input UnorderedMap<String, Expression> params;
    output Subscript sub;
  protected
    Iv iv, viv;
  algorithm
    sub := match i
      case IDX_EXP() then Subscript.INDEX(i.exp);
      case IDX_LOOP()
        algorithm
          iv := listGet(box, i.dim);
          viv := listGet(vertexBox, i.dim);
        then Subscript.SLICE(rangeExp(ivLo(iv), ivHi(iv), params));
    end match;
  end flowSubscript;

  function flowTerm
    input ComponentRef cr;
    input Integer connDims;
    input list<Subscript> inds;
    input Boolean isSum;
    input Boolean outside;
    output Expression e;
  algorithm
    e := applyConnSubs(cr, connDims, inds);
    if isSum then
      // the sum over all elements of the summed dimensions
      e := Expression.CALL(Call.makeTypedCall(NFBuiltinFuncs.SUM,
        {e}, Expression.variability(e), Purity.PURE, Type.arrayElementType(Expression.typeOf(e))));
    end if;
    if outside then
      e := Expression.negate(e);
    end if;
  end flowTerm;

  type ExpList = list<Expression>;

  function addNamed
    "adds a term to the sum of the flow variable name"
    input String name;
    input Expression e;
    input UnorderedMap<String, ExpList> terms;
  algorithm
    UnorderedMap.addUpdate(name, function prependTerm(e = e), terms);
  end addNamed;

  function prependTerm
    input Option<list<Expression>> old;
    input Expression e;
    output list<Expression> res = e :: Util.getOptionOrDefault(old, {});
  end prependTerm;

  function setString
    input list<Integer> members;
    input Sets sets;
    input Vector<Vertex> vertices;
    output String str = stringDelimitList(list(vertexName(vertices, Vector.get(sets.pieceVertex, p)) +
      boxString(Vector.get(sets.pieceBox, p)) for p in members), ", ");
  end setString;

  function dumpSets
    input Sets sets;
    input Vector<Vertex> vertices;
    input list<Aff> facts;
  protected
    Integer n = Vector.size(sets.pieceVertex);
    array<list<Integer>> groups = arrayCreate(n, {});
    Integer r;
  algorithm
    print("Resizable connection sets (facts: " + stringDelimitList(list(affString(f) + " >= 0" for f in facts), ", ") + "):\n");
    for p in n:-1:1 loop
      r := pieceFind(sets, p);
      groups[r] := p :: groups[r];
    end for;
    for p in 1:n loop
      if not listEmpty(groups[p]) then
        print("  {" + setString(groups[p], sets, vertices) + "}\n");
      end if;
    end for;
  end dumpSets;

  // ---------------------------------------------------------------------------
  // entry point
  // ---------------------------------------------------------------------------

public
  function resolve
    "Generates the connection equations of the connect equations of the model
     with symbolic sizes and adds them to the equations."
    input output FlatModel flatModel;
  protected
    list<Equation> conns, eql;
    Context ctx;
    list<Edge> edges = {};
    Sets sets;
    list<Aff> facts;
    array<list<ConnVar>> potentials, flows;
    ComponentRef c;
  algorithm
    (conns, eql) := List.splitOnTrue(flatModel.equations, isConnection);
    ctx := CONTEXT(Vector.new<Vertex>(), UnorderedMap.new<Integer>(stringHashDjb2, stringEq),
      UnorderedMap.new<Expression>(stringHashDjb2, stringEq), UnorderedMap.new<Variable>(stringHashDjb2, stringEq));
    for var in flatModel.variables loop
      UnorderedMap.add(ComponentRef.toString(var.name), var, ctx.variables);
    end for;

    // every connector with flow variables is a vertex: unconnected flows are zero
    for var in flatModel.variables loop
      if Variable.isFlow(var) then
        c := ComponentRef.rest(var.name);
        if not ComponentRef.isEmpty(c) then
          vertexOf(c, ElementSource.createElementSource(var.info), ctx);
        end if;
      end if;
    end for;

    for eq in conns loop
      edges := collectEdges(eq, {}, {}, ctx, edges);
    end for;
    edges := listReverseInPlace(edges);

    (sets, facts) := connectionSets(ctx.vertices, edges);
    if Flags.isSet(Flags.DUMP_SET_BASED_GRAPHS) then
      dumpSets(sets, ctx.vertices, facts);
    end if;

    (potentials, flows) := connectorVariables(flatModel.variables, ctx.vertices, ctx.vertexIndex);
    flatModel.equations := listAppend(eql, generateEquations(sets, ctx.vertices, potentials, flows, ctx.params, facts));
  end resolve;

  annotation(__OpenModelica_Interface="nf_frontend");
end NFResizableConnections;
