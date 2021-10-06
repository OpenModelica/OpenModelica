/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include "omc_config.h"
#include "unitparser.h"
#include <iostream>
#include <sstream>
#include <stack>

#ifndef NO_LPLIB

#if defined(__MINGW32__) || defined(_MSC_VER)
#ifndef WIN32
#define WIN32
#endif
#endif /* MINGW & MSVC */

#include CONFIG_LPSOLVEINC

#endif

string UnitRes::toString()
{
  switch (result) {
  case UNIT_OK: return "OK";
  case UNKNOWN_TOKEN: return "Unknown token";
  case UNKNOWN_IDENT: return "Unknown ident";
  case PARSE_ERROR: return "Parse error";
  case UNIT_OFFSET_ERROR: return "Offset error";
  case UNIT_EXPONENT_NOT_INT: return "Exponent is not an integer";
  case UNIT_WRONG_BASE: return "Wrong base";
  case UNIT_NOT_FOUND: return "Unit not found";
  case PREFIX_NOT_FOUND: return "Prefix not found";
  case INVALID_INT: return "Invalid integer";
  case PREFIX_NOT_ALLOWED: return "Prefix not allowed";
  case BASE_ALREADY_DEFINED: return "Base already defined";
  case ERROR_ADDING_UNIT: return "Error adding unit";
  case UNITS_DEFINED_WITH_DIFFERENT_EXPR:
  default: return "Unknown error";
  }
}

/***************************************************************************************/
/*   CLASS: Rational                                                                   */
/***************************************************************************************/

Rational::Rational(mmc_sint_t numerator, mmc_sint_t denominator) {
  num = numerator;
  denom = denominator;
  fixsign();
}

/* Rationalize a double precision number using an epsilon, should be a constructor but that leads to a lot
 * of ambiguity that needs to be adressed. */
void Rational::rationalize(double r) {
#ifndef NO_LPLIB
  const double eps = 1e-6;
  double rapp;
  mmc_sint_t numerator = (mmc_sint_t) r;
  mmc_sint_t denominator = 1;
  r = round(r / eps) * eps;
  do {
    rapp = (double) numerator / (double) denominator;
    denominator *= 10;
    numerator = (mmc_sint_t) (r * denominator);
  } while (fabs(r - rapp) > eps);

  mmc_sint_t d = gcd(numerator, denominator);
  num = numerator / d;
  denom = denominator / d;
  //cout << "Rationalized " << r << " to " << num << " / " << denom << endl;
#endif
}

Rational::Rational(const Rational& r) {
  num = r.num;
  denom = r.denom;
  fixsign();
}

bool Rational::isZero() {
  return num == 0;
}

bool Rational::is(mmc_sint_t numerator, mmc_sint_t denominator) {
  return (num == numerator) && (denom == denominator);
}

string Rational::toString() {
  stringstream ss;
  if (denom == 1) {
    ss << num;
    return ss.str();
  } else {
    ss << "(" << num << "/" << denom << ")";
    return ss.str();
  }
}

double Rational::toReal() {
  if (denom == 0)
    cerr << "Division by zero in << " << toString() << endl;
  double r = (double) num / (double) denom;
  return r;
}

Rational Rational::sub(Rational q1, Rational q2) {
  return simplify(Rational(q1.num * q2.denom - q2.num * q1.denom, q1.denom
      * q2.denom));
}

Rational Rational::add(Rational q1, Rational q2) {
  return simplify(Rational(q1.num * q2.denom + q2.num * q1.denom, q1.denom
      * q2.denom));
}

Rational Rational::mul(Rational q1, Rational q2) {
  return simplify(Rational(q1.num * q2.num, q1.denom * q2.denom));
}

Rational Rational::div(Rational q1, Rational q2) {
  return simplify(Rational(q1.num * q2.denom, q1.denom * q2.num));
}

static mmc_sint_t powint64(mmc_sint_t base, mmc_sint_t exp) {
  int res = 1;
  while (exp) {
    if (exp & 1) {
      res *= base;
    }
    exp >>= 1;
    base *= base;
  }
  return res;
}

Rational Rational::pow(Rational q1, Rational q2) {
  if (q2.denom != 1) {
    MMC_THROW();
  }
  if (q2.num < 0) {
    return simplify(Rational(powint64(q1.denom, -q2.num), powint64(q1.num, -q2.num)));
  } else {
    return simplify(Rational(powint64(q1.num, q2.num), powint64(q1.denom, q2.num)));
  }
}

Rational Rational::simplify(const Rational q) {
  mmc_sint_t gcd = Rational::gcd(q.num, q.denom);
  Rational q2(Rational(q.num / gcd, q.denom / gcd));
  q2.fixsign();
  return q2;
}

void Rational::fixsign() {
  if (denom < 0) {
    denom *= -1;
    num *= -1;
  }
}

mmc_sint_t Rational::gcd(mmc_sint_t a, mmc_sint_t b) {
  while (b != 0) {
    mmc_sint_t t = b;
    b = a % b;
    a = t;
  }
  return a;
}

/***************************************************************************************/
/*   CLASS: Unit                                                                       */
/***************************************************************************************/

UnitRes Unit::div(Unit u1, Unit u2, Unit& ur) {
  return paramutil(u1, u2, ur, false);
}

UnitRes Unit::mul(Unit u1, Unit u2, Unit& ur) {
  return paramutil(u1, u2, ur, true);
}

UnitRes Unit::paramutil(Unit u1, Unit u2, Unit& ur, bool mulop) {
  if (!u1.offset.isZero() || !u2.offset.isZero())
    return UnitRes(UnitRes::UNIT_OFFSET_ERROR);

  ur.offset = 0;
  ur.quantityName = "";
  ur.unitName = "";
  ur.prefixExpo = mulop ? Rational::add(u1.prefixExpo, u2.prefixExpo)
      : Rational::sub(u1.prefixExpo, u2.prefixExpo);
  ur.scaleFactor = mulop ? Rational::mul(u1.scaleFactor, u2.scaleFactor)
      : Rational::div(u1.scaleFactor, u2.scaleFactor);
  ur.unitVec.clear();
  for (unsigned int i = 0; i < max(u1.unitVec.size(), u2.unitVec.size()); i++) {
    Rational q1(0), q2(0);
    if (i < u1.unitVec.size())
      q1 = u1.unitVec[i];
    if (i < u2.unitVec.size())
      q2 = u2.unitVec[i];
    ur.unitVec.push_back(mulop ? Rational::add(q1, q2) : Rational::sub(q1,
        q2));
  }

  map<string, Rational>::iterator p1 = u1.typeParamVec.begin();
  map<string, Rational>::iterator p2 = u2.typeParamVec.begin();
  for (;;) {
    if (p1 != u1.typeParamVec.end() && p2 != u2.typeParamVec.end()) {
      int cval = (*p1).first.compare((*p2).first);
      if (cval == 0) {
        //Same parameter symbol
        ur.typeParamVec[(*p1).first] = mulop ? Rational::add(
            (*p1).second, (*p2).second) : Rational::sub(
            (*p1).second, (*p2).second);
        p1++;
        p2++;
      } else if (cval > 0) {
        ur.typeParamVec[(*p2).first] = (*p2).second;
        p2++;
      } else {
        ur.typeParamVec[(*p1).first] = (*p1).second;
        p1++;
      }
    } else if (p1 != u1.typeParamVec.end()) {
      ur.typeParamVec[(*p1).first] = (*p1).second;
      p1++;
    } else if (p2 != u2.typeParamVec.end()) {
      ur.typeParamVec[(*p2).first] = mulop ? (*p2).second
          : Rational::mul((*p2).second, Rational(-1));
      p2++;
    } else
      break;
  }
  return UnitRes(UnitRes::UNIT_OK);
}

UnitRes Unit::pow(Unit u, const Rational e, Unit& ur) {
  if (!u.offset.isZero())
    return UnitRes(UnitRes::UNIT_OFFSET_ERROR);

  if (e.denom != 1)
    return UnitRes(UnitRes::UNIT_EXPONENT_NOT_INT);

  ur = u;
  ur.prefixExpo = Rational::mul(u.prefixExpo, e);
  ur.scaleFactor = Rational::pow(u.scaleFactor, e);
  ur.unitVec.clear();
  for (unsigned int i = 0; i < u.unitVec.size(); i++) {
    ur.unitVec.push_back(Rational::mul(u.unitVec[i], e));
  }
  for (map<string, Rational>::iterator p = u.typeParamVec.begin(); p
      != u.typeParamVec.end(); p++) {
    (*p).second = Rational::mul((*p).second, e);
  }
  return UnitRes(UnitRes::UNIT_OK);
}

bool Unit::isDimensionless() {
  for (vector<Rational>::iterator p = unitVec.begin(); p != unitVec.end(); p++) {
    if (!(*p).isZero())
      return false;
  }
  return (typeParamVec.empty());
}

bool Unit::isBaseUnit() {
  bool onefound = false;
  for (vector<Rational>::iterator p = unitVec.begin(); p != unitVec.end(); p++) {
    if ((*p).denom != 1)
      return false;
    if ((*p).num == 1) {
      if (onefound)
        return false;
      else
        onefound = true;
    } else if ((*p).num != 0)
      return false;
  }
  return true;
}

bool Unit::equalNoWeight(const Unit& u) {
  unsigned int i = 0;
  if (unitVec.size() != u.unitVec.size())
    return false;
  for (unsigned int i = 0; i < unitVec.size(); i++) {
    if (!unitVec[i].equal(u.unitVec[i]))
      return false;
  }

  return (scaleFactor.equal(u.scaleFactor) && offset.equal(u.offset));
}

/***************************************************************************************/
/*   CLASS: UnitParser                                                                 */
/***************************************************************************************/

UnitParser::UnitParser() {
}

UnitParser::~UnitParser() {
}

void UnitParser::addPrefix(const string symbol, Rational exponent) {
  _prefix[symbol] = exponent;
}

void* UnitParser::allUnitSymbols()
{
  void* res = mmc_mk_nil();
  for (map<string, Unit>::iterator p = _units.begin(); p != _units.end(); p++) {
    res = mmc_mk_cons(mmc_mk_scon((*p).second.unitSymbol.c_str()), res);
  }
  return res;
}

void UnitParser::addBase(const string quantityName, const string unitName,

    const string unitSymbol, bool prefixAllowed) {
  if (_units.find(unitSymbol) == _units.end()) {
    Base b(quantityName, unitName, unitSymbol, prefixAllowed);
    _base.push_back(b);
    Unit u;
    u.prefixAllowed = b.prefixAllowed;
    u.quantityName = b.quantityName;
    u.unitName = b.unitName;
    u.unitSymbol = unitSymbol;
    for (mmc_uint_t j = 0; j < _base.size(); j++) {
      u.unitVec.push_back(Rational((_base.size() - 1) == j ? 1 : 0));
    }

    //Force the old unit vectors to have the same length as the new one
    for (map<string, Unit>::iterator p = _units.begin(); p != _units.end(); p++) {
      (*p).second.unitVec.push_back(Rational(0));
    }

    _units[b.unitSymbol] = u;
  }
}

void UnitParser::addDerived(const string quantityName, const string unitName,
    const string unitSymbol, const string unitStrExp, Rational prefixExpo,
    Rational scaleFactor, Rational offset, bool prefixAllowed,
    double weight) {
  DerivedInfo di(quantityName, unitName, unitSymbol, unitStrExp, prefixExpo,
      scaleFactor, offset, prefixAllowed, weight);
  _tempDerived.push_back(di);
}

UnitRes UnitParser::addDerivedInternal(const string quantityName,
    const string unitName, const string unitSymbol,
    const string unitStrExp, Rational prefixExpo, Rational scaleFactor,
    Rational offset, bool prefixAllowed, double weight = 1.0) {
  Unit u;
  UnitRes res = str2unit(unitStrExp, u);
  if (!res.Ok())
    return res;
  u.quantityName = quantityName;
  u.unitName = unitName;
  u.unitSymbol = unitSymbol;
  u.prefixAllowed = prefixAllowed;
  u.prefixExpo = prefixExpo;
  u.scaleFactor = scaleFactor;
  u.offset = offset;
  u.weight = weight;

  map<string, Unit>::iterator p = _units.find(unitSymbol);
  // Unit already defined?
  if (p == _units.end()) {
    //No - add new unit
    _units[unitSymbol] = u;
  } else {
    //Yes - just update weight
    if (u.equalNoWeight((*p).second)) {
      Unit u2 = _units[unitSymbol];
      u2.weight *= weight;
      _units[unitSymbol] = u2;
    } else
      return UnitRes(UnitRes::UNITS_DEFINED_WITH_DIFFERENT_EXPR);
  }
  return res;
}

void UnitParser::accumulateWeight(const string unitSymbol, double weight) {
  map<string, Unit>::iterator p = _units.find(unitSymbol);
  if (p != _units.end()) {
    Unit u2 = _units[unitSymbol];
    u2.weight *= weight;
    _units[unitSymbol] = u2;
  }
}

UnitRes UnitParser::commit() {
  list<DerivedInfo> tmp;
  while (!_tempDerived.empty()) {
    unsigned int startSize = _tempDerived.size();
    while (!_tempDerived.empty()) {
      DerivedInfo d = _tempDerived.front();
      UnitRes res = addDerivedInternal(d.quantityName, d.unitName,
          d.unitSymbol, d.unitStrExp, d.prefixExpo, d.scaleFactor,
          d.offset, d.prefixAllowed, d.weight);
      _tempDerived.pop_front();
      if (!res.Ok())
        tmp.push_back(d);
    }
    if (tmp.size() == startSize)
      return UnitRes::ERROR_ADDING_UNIT;
    _tempDerived = tmp;
    tmp.clear();
  }
  return UnitRes(UnitRes::UNIT_OK);
}

string UnitParser::prettyPrintUnit2str(Unit unit) {
  //Unit prettyUnit = solveMIP(unit);
  return unit2str(unit);//prettyUnit);
}

Unit UnitParser::solveMIP(Unit unit, bool innerCall) {
#ifndef NO_LPLIB
  int numBaseUnits = _base.size();
  int numDerivedUnits = 0;
  // Counting the derived units by traversing all units
  for (map<string, Unit>::iterator it = _units.begin(); it != _units.end(); it++)
    if (!it->second.isBaseUnit())
      numDerivedUnits++;
  int NU = numBaseUnits + numDerivedUnits;

  // Create MIP with 2*NU variables(columns)
  lprec *lp = make_lp(0, 2 * NU);
  if (lp == NULL) {
    cerr
        << "Internal error pretty printing expression. Using simple approach"
        << endl;
    return unit;
  }

  /* Set name of variables for debug printing */
  int i;
  for (i = 1; i <= numBaseUnits; i++) {
    char * s1 = (char*) _base[i - 1].unitName.c_str();
    char * s2 = (char*) (string("-") + string(s1)).c_str();
    if (!set_col_name(lp, i, s1)) {
      cerr << "ERROR1" << endl;
    }
    if (!set_col_name(lp, NU + i, s2)) {
      cerr << "ERROR" << endl;
    }
  }
  for (map<string, Unit>::iterator it = _units.begin(); it != _units.end(); it++) {
    if (!it->second.isBaseUnit()) {
      char * s1 = (char*) it->second.unitName.c_str();
      char * s2 = (char*) (string("-") + string(s1)).c_str();
      if (!set_col_name(lp, i, s1)) {
        cerr << "ERROR2" << endl;
      }
      if (!set_col_name(lp, NU + i, s2)) {
        cerr << "ERROR3" << endl;
      }
      i++;
    }
  }

  // Increases efficency when adding rows.
  set_add_rowmode(lp, TRUE);

  double *row = new double[2 * NU];
  int *colno = new int[2 * NU];

  if (!row || !colno) {
    cerr
        << "Internal error pretty printing expression (allocation of memory). Using simple approach"
        << endl;
    return unit;
  }

  int c;
  // Set the constraint
  for (int r = 0; r < numBaseUnits; r++) {
    int j = 0;
    /* Set 0..numBaseUnits-1 first columns */
    for (c = 0; c < numBaseUnits; c++) {
      colno[j] = c + 1;
      row[j++] = r == c ? 1 : 0;
    }
    /* Set numBaseUnits .. NU-1 following columns */
    for (map<string, Unit>::iterator it = _units.begin(); it
        != _units.end(); it++) {
      Unit u = it->second;
      if (!u.isBaseUnit()) {
        colno[j] = 1 + c;
        row[j++] = u.unitVec[r].toReal();
        c++;
      }
    }
    for (int j2 = 0; j2 < NU; j2++) {
      colno[j] = colno[j2] + NU;
      row[j++] = -row[j2];
    }
    double b = r < unit.unitVec.size() ? unit.unitVec[r].toReal() : 0.0;
    if (!add_constraintex(lp, j, row, colno, EQ, b)) {
      cerr
          << "Internal error pretty printing expression (adding row to lp). Using simple approach"
          << endl;
      return unit;
    }
  }
  set_add_rowmode(lp, FALSE);

  /* Set the objective */
  int j = 0;
  int c2;
  /* element 0..numBaseUnits-1*/
  for (c2 = 0; c2 < numBaseUnits; c2++) {
    double cost = 1;
    for (int r2 = 0; r2 < numBaseUnits; r2++) {
      double b = r2 < unit.unitVec.size() ? unit.unitVec[r2].toReal()
          : 0.0;
      cost += fabs(b - (c2 == r2 ? 1 : 0));
    }
    cost /= _base[c2].weight;
    colno[j] = c2 + 1;
    row[j++] = cost;
  }
  /* elements numBaseUnits .. NU -1 */
  c2 = numBaseUnits;
  for (map<string, Unit>::iterator it = _units.begin(); it != _units.end(); it++) {
    double cost = 1;
    Unit u = it->second;
    if (!u.isBaseUnit()) {
      for (int r2 = 0; r2 < numBaseUnits; r2++) {
        double b1 =
            r2 < unit.unitVec.size() ? unit.unitVec[r2].toReal()
                : 0.0;
        double b2 = r2 < u.unitVec.size() ? u.unitVec[r2].toReal()
            : 0.0;
        cost += fabs(b1 - b2);
      }
      cost /= u.weight;
      colno[j] = c2 + 1;
      row[j++] = cost;
      c2++;
    }
  }
  /* elements NU .. NU+numBaseUnits-1 */
  for (int c2 = 0; c2 < numBaseUnits; c2++) {
    double cost = 1;
    for (int r2 = 0; r2 < numBaseUnits; r2++) {
      double b = r2 < unit.unitVec.size() ? unit.unitVec[r2].toReal()
          : 0.0;
      cost += fabs(b - (c2 == r2 ? -1 : 0));
    }
    cost /= _base[c2].weight;
    colno[j] = c2 + NU + 1;
    row[j++] = cost;
  }
  /* elements NU+numBaseUnits .. 2*NU -1 */
  c2 = numBaseUnits;
  for (map<string, Unit>::iterator it = _units.begin(); it != _units.end(); it++) {
    double cost = 1;
    Unit u = it->second;
    if (!u.isBaseUnit()) {
      for (int r2 = 0; r2 < numBaseUnits; r2++) {
        double b1 =
            r2 < unit.unitVec.size() ? unit.unitVec[r2].toReal()
                : 0.0;
        double b2 = r2 < u.unitVec.size() ? u.unitVec[r2].toReal()
            : 0.0;
        cost += fabs(b1 + b2);
      }
      cost /= u.weight;
      colno[j] = c2 + NU + 1;
      row[j++] = cost;
      c2++;
    }
  }
  if (!set_obj_fnex(lp, j, row, colno)) {
    cerr
        << "Internal error pretty printing expression (adding objective to lp). Using simple approach"
        << endl;
    return unit;
  }

  /* Set up domain , Reals for base units, Integers for derived units */
  int v = 0;
  for (; v < numBaseUnits; v++)
    set_int(lp, v + 1, FALSE);
  for (; v < NU; v++)
    set_int(lp, v + 1, TRUE);
  for (; v < NU + numBaseUnits; v++)
    set_int(lp, v + 1, FALSE);
  for (; v < 2 * NU; v++)
    set_int(lp, v + 1, TRUE);

  /* Set up lower and upper bound */
  double maxDim = 0;
  for (vector<Rational>::iterator it = unit.unitVec.begin(); it
      != unit.unitVec.end(); it++) {
    maxDim = max(it->toReal(), maxDim);
  }
  for (v = 0; v < 2 * NU; v++) {
    set_upbo(lp, v + 1, maxDim);
  }
  //cout << "LP debug:" << endl;
  set_verbose(lp, -1); // NO printing
  //print_lp(lp);
  int res = solve(lp);
  Unit prettyUnit, retVal;
  if (res == 0) {
    //cout << "result =" << get_var_primalresult(lp,0) << endl;
    for (int i = 0; i < 2 * NU; i++) {
      double res = get_var_primalresult(lp, i + 1 + numBaseUnits);
      //cerr << i << " : " << res << endl ;
      if (i >= NU) {
        //cerr << "Resetting elt " << i << " at pos " << i%NU << endl;
        Rational r;
        r.rationalize(res);
        prettyUnit.unitVec[i % NU] = Rational::sub(prettyUnit.unitVec[i
            % NU], r);
      } else {
        //cerr << "Setting elt " << i << endl;
        Rational r;
        r.rationalize(res);
        //cerr << "setting elt " << i << " to rational " << r.toString() << endl;
        prettyUnit.unitVec.push_back(r);
      }
    }
    //cout << "resulting unit =" << unit2str(prettyUnit) << endl;
    retVal = prettyUnit;
  } else {
    retVal = unit;
  }
  free_lp(&lp);
  Unit retVal1,retVal2;
  if (!innerCall) {
    _derivedUnitsVisited.clear();
    //cout << "minimizing derived units for " << unit2str(retVal) <<  endl;
    retVal1 = minimizeDerivedUnits(retVal,unit,0.1);
    _derivedUnitsVisited.clear();
    retVal2 = minimizeDerivedUnits(retVal,unit,10.0);
    //cout << "increase factor gave " << unit2str(retVal1) <<  endl;
    //cout << "decrease factor gave " << unit2str(retVal2) <<  endl;
    if (actualNumDerived(retVal1) < actualNumDerived(retVal2)) {
      retVal = retVal1;
    } else {
      retVal = retVal2;
    }
    //cout << "returning unit " << unit2str(retVal) <<  endl;
  }

  delete[] row;
  delete[] colno;
  return retVal;
#else
  return unit;
#endif
}

int UnitParser::actualNumDerived(Unit unit) {
  int res = 0;
  int numBaseUnits = _base.size();
  for (int i = numBaseUnits; i < unit.unitVec.size(); i++) {
    if (!unit.unitVec[i].isZero()) {
      res++;
    }
  }
  return res;
}

/* If the unit contains several derived units, try to increase weight on each of them to see if number of derived units decrease */
Unit UnitParser::minimizeDerivedUnits(Unit unit,Unit origUnit, double factor) {

  if (unit.isBaseUnit()) {
    return unit;
  }

  int numBaseUnits = _base.size();
  int numDerivedUnits = 0;
  // Counting the derived units by traversing all units
  for (map<string, Unit>::iterator it = _units.begin(); it != _units.end(); it++)
    if (!it->second.isBaseUnit())
      numDerivedUnits++;

  stack<int> stack; // stack of indices for derived units =! 0
  if (actualNumDerived(unit) > 1) {
    for (int i = numBaseUnits; i < unit.unitVec.size(); i++) {
      if (!unit.unitVec[i].isZero()) {
        stack.push(i); // store nth position in unit map
      }
    }
  }
  Unit newUnit;
  while (actualNumDerived(unit) > 1 && !stack.empty()) {
    int actNumDerived = actualNumDerived(unit);
    //cout << "actNumDerived = "<<actNumDerived<< endl;
    int indx = stack.top();
    _derivedUnitsVisited.insert(indx);
    stack.pop();
    increaseNthUnitWeight(indx,factor);
    newUnit = solveMIP(origUnit, true);
    cout << "after increased weight on " << indx << "unit " << unit2str(unit) << " became " << unit2str(newUnit) << endl;
    if (actNumDerived < actualNumDerived(newUnit)) {
      //cout << "not decreased, resetting indx " << indx << endl;
      resetNthUnitWeight(indx,factor);
    }
    if (actualNumDerived(newUnit)==1) break;
    for (int i = numBaseUnits; i < newUnit.unitVec.size(); i++) {
          if (!newUnit.unitVec[i].isZero()&&_derivedUnitsVisited.find(i) == _derivedUnitsVisited.end()) {
            stack.push(i); // store nth position in unit map
            cout << "adding " << i << " to stack" << endl;
          }
        }
  }

  return newUnit;
}

/*
 * \brief resets the nth (derived) unit by dividing with a factor 10.
 */
void UnitParser::increaseNthUnitWeight(int indx,double factor) {
  //cout << "increasing weight for indx " << indx << endl;
  int i=_base.size();
  for (map<string, Unit>::iterator it = _units.begin(); it != _units.end(); it++) {
    //cout << "indx " << i << " unit:" << it->first << endl;
    if (!it->second.isBaseUnit()) {
      if (i == indx) {
        accumulateWeight(it->first, factor);
        cout << "increasing weight for " << it->first << endl;
      }
      i++;
    }
  }
}

  /*
   * \brief increases the nth (derived) unit by a factor 10, to investigate if that leads to fewer derived units used by the pretty printer
   */
void UnitParser::resetNthUnitWeight(int indx,double factor)
{
  //cout << "decreasing weight for indx " << indx << endl;
  int i=_base.size();
  for (map<string, Unit>::iterator it = _units.begin(); it != _units.end(); it++) {
    //cout << "indx " << i << " unit:" << it->first << endl;
    if (!it->second.isBaseUnit()) {
      if (i == indx) {
        accumulateWeight(it->first, 1/factor);
        cout << "decreasing weight for " << it->first << endl;
      }
      i++;
    }
  }
}

string UnitParser::unit2str(Unit unit) {
  //This code implements a simple unparser.
  //Todo in the future:
  // - Develop a way to generate the most appropriate derived units as well.
  // - Support for offset
  // - Support for SI-prefixes


  bool first(true);
  stringstream ss;

  //Print scale factor
  if (!unit.scaleFactor.is(1, 1) || (unit.isDimensionless()
      && unit.prefixExpo.isZero())) {
    ss << unit.scaleFactor.toString();
    first = false;
  }

  //Prefix exponent
  if (unit.prefixExpo.is(1, 1)) {
    if (!first)
      ss << ".";
    ss << "10";
    first = false;
  } else if (!unit.prefixExpo.isZero()) {
    if (!first)
      ss << ".";
    ss << "10^" << unit.prefixExpo.toString();
    first = false;
  }
  //print type parameters (variables)
  for (map<string, Rational>::iterator p = unit.typeParamVec.begin(); p
      != unit.typeParamVec.end(); p++) {
    if (!(*p).second.isZero()) {
      if (!first)
        ss << ".";
      ss << (*p).first << ((*p).second.is(1) ? ""
          : (*p).second.toString());
      first = false;
    }
  }
  //Print unit vector using base units
  unsigned int i;
  for (i = 0; i < min(unit.unitVec.size(), _base.size()); i++) {
    Rational q(i < unit.unitVec.size() ? unit.unitVec[i] : Rational(0, 0));
    if (!q.isZero()) {
      if (!first)
        ss << ".";
      ss << _base[i].unitSymbol << (q.is(1) ? "" : q.toString());
      first = false;
    }
  }
  //Print unit vector using derived units
  for (map<string, Unit>::iterator it = _units.begin(); it != _units.end(); it++) {
    if (!it->second.isBaseUnit()) {
      Rational q(i < unit.unitVec.size() ? unit.unitVec[i] : Rational(0,
          0));

      if (!q.isZero()) {
        if (!first)
          ss << ".";
        ss << it->second.unitSymbol << (q.is(1) ? "" : q.toString());
        first = false;
      }
      i++;
    }
  }
  return ss.str();
}

UnitRes UnitParser::str2unit(const string unitstr, Unit& unit) {
  if (unitstr == string("")) {
    return UnitRes(UnitRes::UNIT_OK);
  }
  Scanner scan(unitstr);
  UnitRes res = parseExpression(scan, unit);
  if (!res.Ok())
    return res;
  if (scan.finished())
    return UnitRes(UnitRes::UNIT_OK);
  else
    return UnitRes(UnitRes::PARSE_ERROR, scan.getPos());
}

UnitRes UnitParser::parseExpression(Scanner& scan, Unit& unit) {
  Unit u1, u2;
  UnitRes res = parseFactors(scan, u1); //Old: numerators
  unit = u1;
  if (!res.Ok())
    return res;
  string str;
  Scanner::TokenType tok = scan.peekToken(str);
  switch (tok) {
  case Scanner::TOK_EOS:
    scan.getToken(str);
    return UnitRes(UnitRes::UNIT_OK);
  case Scanner::TOK_DIV:
    scan.getToken(str);
    res = parseDenominator(scan, u2);
    if (!res.Ok())
      return res;
    res = Unit::div(u1, u2, unit);
    if (!res.Ok())
      return res;
    return res;
  default: break;
  }
  return UnitRes(UnitRes::UNIT_OK);
}

//Not used right now...
UnitRes UnitParser::parseNumerator(Scanner& scan, Unit& unit) {
  string str;
  Unit u;
  Scanner::TokenType tok = scan.peekToken(str);
  if (tok == Scanner::TOK_LPARAN) {
    scan.getToken(str);
    UnitRes res = parseExpression(scan, u);
    if (!res.Ok())
      return res;
    if (scan.getToken(str) != Scanner::TOK_RPARAN)
      return UnitRes(UnitRes::PARSE_ERROR, scan.getLastPos());
    unit = u;
    return res;
  }
  return parseFactors(scan, unit);
}

UnitRes UnitParser::parseDenominator(Scanner& scan, Unit& unit) {
  string str;
  Unit u;
  Scanner::TokenType tok = scan.peekToken(str);
  if (tok == Scanner::TOK_LPARAN) {
    scan.getToken(str);
    UnitRes res = parseExpression(scan, u);
    if (!res.Ok())
      return res;
    if (scan.getToken(str) != Scanner::TOK_RPARAN)
      return UnitRes(UnitRes::PARSE_ERROR, scan.getLastPos());
    unit = u;
    return res;
  }
  return parseFactor(scan, unit);
}

UnitRes UnitParser::parseFactors(Scanner& scan, Unit& unit) {
  string str;
  Unit u1, u2;
  UnitRes res = parseFactor(scan, u1);
  if (!res.Ok())
    return res;
  if (scan.peekToken(str) == Scanner::TOK_DOT) {
    scan.getToken(str);
    res = parseFactors(scan, u2);
    if (!res.Ok())
      return res;
    return Unit::mul(u1, u2, unit);
  } else {
    unit = u1;
    return UnitRes(UnitRes::UNIT_OK);
  }
}

UnitRes UnitParser::parseFactor(Scanner& scan, Unit& unit) {
  string str;
  Unit u1;
  Rational q(0), q2(0);
  unsigned int scanpostemp;
  UnitRes res;
  Scanner::TokenType tok = scan.peekToken(str);
  switch (tok) {
  case Scanner::TOK_ID: // Unit symbol e.g. [mm] including prefix.
    res = parseSymbol(scan, u1);
    if (!res.Ok())
      return res;
    unit = u1;
    scanpostemp = scan.getpos();
    res = parseRational(scan, q);
    if (!res.Ok()) {
      scan.setpos(scanpostemp);
      return UnitRes(UnitRes::UNIT_OK);
    } else {
      res = Unit::pow(u1, q, unit);
      return res;
    }

  case Scanner::TOK_PARAM: //Unit type parameter
    scan.getToken(str);
    if (!res.Ok())
      return res;
    unit = Unit();
    scanpostemp = scan.getpos();
    res = parseRational(scan, q);
    if (!res.Ok()) {
      unit.typeParamVec[str] = Rational(1);
      scan.setpos(scanpostemp);
      return UnitRes(UnitRes::UNIT_OK);
    } else {
      unit.typeParamVec[str] = q;
      return UnitRes(UnitRes::UNIT_OK);
      return res;
    }

  default: //Scale factor
    res = parseRational(scan, q);
    unit = Unit();
    if (!res.Ok())
      return res;
    if (scan.peekToken(str) != Scanner::TOK_EXPO) {
      unit.scaleFactor = q;
      return res;
    }
    scan.getToken(str);
    res = parseRational(scan, q2);
    if (!res.Ok())
      return res;
    if (!q.is(10))
      return UnitRes(UnitRes::UNIT_WRONG_BASE, scan.getLastPos());
    unit.prefixExpo = q2;
    return res;
  }
}

UnitRes UnitParser::parseSymbol(Scanner& scan, Unit& unit) {
  //Derived symbol exists?
  string str;
  Scanner::TokenType tok = scan.getToken(str);
  if (tok != scan.TOK_ID)
    return UnitRes(UnitRes::PARSE_ERROR, scan.getLastPos());

  //Only a derived unit?
  if (_units.find(str) != _units.end()) {
    unit = _units[str];
    return UnitRes(UnitRes::UNIT_OK);
  }

  //Find prefix
  for (unsigned int i = 1; i <= str.size(); i++) {
    if (_prefix.find(str.substr(0, i)) != _prefix.end()) {
      if (_units.find(str.substr(i)) != _units.end()) {
        unit = _units[str.substr(i)];
        if (!unit.prefixAllowed)
          return UnitRes(UnitRes::PREFIX_NOT_ALLOWED,
              scan.getLastPos());
        unit.prefixExpo = Rational::add(unit.prefixExpo,
            _prefix[str.substr(0, i)]);
        return UnitRes(UnitRes::UNIT_OK);
      } else
        return UnitRes(UnitRes::UNIT_NOT_FOUND, scan.getLastPos() + i);
    }
  }
  return UnitRes(UnitRes::PREFIX_NOT_FOUND, scan.getLastPos());
}

UnitRes UnitParser::parseRational(Scanner& scan, Rational& q) {

  string str;
  mmc_sint_t l1, l2;
  Scanner::TokenType tok = scan.getToken(str);
  if (tok == scan.TOK_INT) {
    istringstream iss1(str);
    if (!(iss1 >> l1))
      return UnitRes(UnitRes::INVALID_INT, scan.getLastPos());
    q = Rational(l1);
    return UnitRes(UnitRes::UNIT_OK);
  } else if (tok == scan.TOK_LPARAN) {
    tok = scan.getToken(str);
    if (tok != scan.TOK_INT)
      return UnitRes(UnitRes::PARSE_ERROR, scan.getLastPos());
    istringstream iss1(str);
    if (!(iss1 >> l1))
      return UnitRes(UnitRes::INVALID_INT, scan.getLastPos());
    tok = scan.getToken(str);
    if (tok != scan.TOK_DIV)
      return UnitRes(UnitRes::PARSE_ERROR, scan.getLastPos());
    tok = scan.getToken(str);
    if (tok != scan.TOK_INT)
      return UnitRes(UnitRes::PARSE_ERROR, scan.getLastPos());
    istringstream iss2(str);
    if (!(iss2 >> l2))
      return UnitRes(UnitRes::INVALID_INT, scan.getLastPos());
    tok = scan.getToken(str);
    if (tok != scan.TOK_RPARAN)
      return UnitRes(UnitRes::PARSE_ERROR, scan.getLastPos());
    q = Rational(l1, l2);
    return UnitRes(UnitRes::UNIT_OK);
  } else
    return UnitRes(UnitRes::PARSE_ERROR, scan.getLastPos());
}

void UnitParser::initPrefixes() {
  //Add prefixes
  addPrefix("da", Rational(1)); // deca
  addPrefix("h", Rational(2)); // hecto
  addPrefix("k", Rational(3)); // kilo
  addPrefix("M", Rational(6)); // mega
  addPrefix("G", Rational(9)); // giga
  addPrefix("T", Rational(12)); // tera
  addPrefix("P", Rational(15)); // peta
  addPrefix("E", Rational(18)); // exa
  addPrefix("Z", Rational(21)); // zetta
  addPrefix("Y", Rational(24)); // yotta
  addPrefix("d", Rational(-1)); // deci
  addPrefix("c", Rational(-2)); // centi
  addPrefix("m", Rational(-3)); // milli
  addPrefix("u", Rational(-6)); // micro
  addPrefix("n", Rational(-9)); // nano
  addPrefix("p", Rational(-12)); // pico
  addPrefix("f", Rational(-15)); // femto
  addPrefix("a", Rational(-18)); // atto
  addPrefix("z", Rational(-21)); // zepto
  addPrefix("y", Rational(-24)); // yocto
}

void UnitParser::initSIUnits() {
  //Add prefixes
  initPrefixes();

  //Init base units (SI brochure 8th ed., page 116)
  addBase("length", "metre", "m", true);
  addBase("mass", "kilogram", "kg", false);
  addBase("time", "second", "s", true);
  addBase("electric current", "ampere", "A", true);
  addBase("thermodynamic temperature", "kelvin", "K", true);
  addBase("amount of substance", "mole", "mol", true);
  addBase("luminous intensity", "candela", "cd", true);

  //Special derived unit for handling gram
  addDerived("mass", "gram", "g", "kg", Rational(-3), Rational(1),
      Rational(0), true);

  //Standard derived units (SI brochure 8th ed., page 118)
  addDerived("plane angle", "radian", "rad", "m/m", Rational(0), Rational(1),
      Rational(0), true);
  addDerived("solid angle", "steradian", "sr", "m2/m2", Rational(0),
      Rational(1), Rational(0), true);
  addDerived("frequency", "hertz", "Hz", "s-1", Rational(0), Rational(1),
      Rational(0), true, 0.8);
  addDerived("force", "newton", "N", "m.kg.s-2", Rational(0), Rational(1),
      Rational(0), true);
  addDerived("pressure, stress", "pascal", "Pa", "N/m2", Rational(0),
      Rational(1), Rational(0), true);
  addDerived("power, radiant flux", "watt", "W", "J/s", Rational(0),
      Rational(1), Rational(0), true);
  addDerived("energy, work, amount of heat", "joule", "J", "N.m",
      Rational(0), Rational(1), Rational(0), true);
  addDerived("electric charge, amount of electricity", "coulomb", "C", "s.A",
      Rational(0), Rational(1), Rational(0), true);
  addDerived("electric potential difference, electromotive force", "volt",
      "V", "W/A", Rational(0), Rational(1), Rational(0), true);
  addDerived("capacitance", "farad", "F", "C/V", Rational(0), Rational(1),
      Rational(0), true);
  addDerived("electric resistance", "ohm", "Ohm", "V/A", Rational(0),
      Rational(1), Rational(0), true);
  addDerived("electric conductance", "siemens", "S", "A/V", Rational(0),
      Rational(1), Rational(0), true);
  addDerived("magnetic flux", "weber", "Wb", "V.s", Rational(0), Rational(1),
      Rational(0), true);
  addDerived("magnetic flux density", "tesla", "T", "Wb/m2", Rational(0),
      Rational(1), Rational(0), true);
  addDerived("inductance", "henry", "H", "Wb/A", Rational(0), Rational(1),
      Rational(0), true);
  addDerived("thermodynamic temperature", "degree Celsius", "degC", "K",
      Rational(0), Rational(1), Rational(27315, 100), true);
  addDerived("luminous flux", "lumen", "lm", "cd.sr", Rational(0),
      Rational(1), Rational(0), true);
  addDerived("illuminance", "lux", "lx", "lm/m2", Rational(0), Rational(1),
      Rational(0), true);
  addDerived("activity referred to a radionuclide", "becquerel", "Bq", "s-1",
      Rational(0), Rational(1), Rational(0), true, 0.8);
  addDerived("absorbed dose, specific energy (imparted), kerma", "gray",
      "Gy", "J/kg", Rational(0), Rational(1), Rational(0), true);
  addDerived(
      "dose equivalent, ambient dose equivalent, directional dose equivalent, personal dose equivalent",
      "sievert", "Sv", "J/kg", Rational(0), Rational(1), Rational(0),
      true);
  addDerived("catalyctic activity", "katal", "kat", "s-1.mol", Rational(0),
      Rational(1), Rational(0), true);

  // More derived units
  addDerived("plane angle", "degree", "deg", "rad", Rational(0),
      Rational(31415926535897932, 1800000000000000000), Rational(0), true);
  addDerived("plane angle", "revolutions", "rev", "rad", Rational(0),
      Rational(31415926535897932, 5000000000000000), Rational(0), true);

  addDerived("angular velocity", "revolutions per minute", "rpm", "rad/s", Rational(0),
      Rational(31415926535897932, 300000000000000000), Rational(0), true);

  addDerived("velocity", "knot", "kn", "m/s", Rational(0),
      Rational(1852, 3600), Rational(0), true);

  addDerived("mass", "metric ton", "t", "kg", Rational(3),
      Rational(1), Rational(0), true);

  addDerived("volume", "litre", "l", "m3", Rational(0),
      Rational(1, 1000), Rational(0), true);

  addDerived("apparent power", "volt-ampere", "VA", "J/s", Rational(0),
      Rational(1), Rational(0), true);
  addDerived("reactive power", "volt-ampere reactive", "var", "J/s", Rational(0),
      Rational(1), Rational(0), true);

  addDerived("thermodynamic temperature", "degree Fahrenheit", "degF", "K",
      Rational(0), Rational(5, 9), Rational(27315*9-3200*5, 900), true);
  addDerived("thermodynamic temperature", "degree Rankine", "degRk", "K",
      Rational(0), Rational(5, 9), Rational(0), true);

  addDerived("pressure", "bar", "bar", "Pa", Rational(0), Rational(100000), Rational(0), true);
  addDerived("pressure", "millimeter of mercury", "mmHg", "Pa", Rational(0),
      Rational(133322387415, 1000000000), Rational(0), true);

  addDerived("time", "minute", "min", "s", Rational(0), Rational(60), Rational(0), true);
  addDerived("time", "hour", "h", "s", Rational(0), Rational(60 * 60), Rational(0), true);
  addDerived("time", "day", "d", "s", Rational(0), Rational(60 * 60 * 24), Rational(0), true);

  // Imperial units
  addDerived("length", "inch", "in", "m", Rational(0),
      Rational(254, 10000), Rational(0), true);
  addDerived("length", "foot", "ft", "m", Rational(0),
      Rational(3048, 10000), Rational(0), true);

  addDerived("velocity", "miles per hour", "mph", "m/s", Rational(0),
      Rational(44704, 100000), Rational(0), true);

  addDerived("mass", "pound", "lb", "kg", Rational(0),
      Rational(45359237, 100000000), Rational(0), true);

  addDerived("pressure", "pound per square inch", "psi", "Pa", Rational(0),
      Rational(689475729, 100000), Rational(0), true);
  addDerived("pressure", "inch water gauge", "inWG", "Pa", Rational(0),
      Rational(249088908333, 1000000000), Rational(0), true);

  commit();
}

/***************************************************************************************/
/*   CLASS: Scanner                                                                    */
/***************************************************************************************/

Scanner::Scanner(string str) :
  _str(str), _index(0), _lastindex(0) {
  ;
}
Scanner::~Scanner() {
  ;
}

Scanner::TokenType Scanner::peekToken(string& tokstr) {
  unsigned int tmpindex = _index;
  return getTokenInternal(tokstr, tmpindex);
}

Scanner::TokenType Scanner::getToken(string& tokstr) {
  _lastindex = _index;
  return getTokenInternal(tokstr, _index);
}

Scanner::TokenType Scanner::getTokenInternal(string& tokstr,
    unsigned int& index) {
  //Eat white space
  while (index < _str.size() && (_str[index] == ' ' || _str[index] == '\t'
      || _str[_index] == '\n'))
    index++;

  //Check if it was the last token
  if (isEOS(index))
    return TOK_EOS;

  //Check character tokens
  switch (_str[index]) {
  case '/':
    index++;
    return TOK_DIV;
  case '(':
    index++;
    return TOK_LPARAN;
  case ')':
    index++;
    return TOK_RPARAN;
  case '.':
    index++;
    return TOK_DOT;
  case '^':
    index++;
    return TOK_EXPO;
  }

  //Check if identifier or token
  if (isTextChar(index) || _str[index] == '\'') {
    unsigned int idx = index++;
    while (!isEOS(index) && isTextChar(index))
      index++;
    tokstr = _str.substr(idx, index - idx);
    if (_str[idx] == '\'') {
      if (index - idx == 1) {
        index--;
        return TOK_UNKNOWN;
      } else
        return TOK_PARAM;
    }
    return TOK_ID;
  }

  //Get potential sign of integer
  unsigned int idx = index;
  if (_str[index] == '+' || _str[index] == '-')
    index++;

  //Check for integer
  if (isDigit(index)) {
    while (!isEOS(index) && isDigit(index))
      index++;
    tokstr = _str.substr(idx, index - idx);
    return TOK_INT;
  }

  return TOK_UNKNOWN;
}

unsigned int Scanner::getPos() {
  return _index;
}

unsigned int Scanner::getLastPos() {
  return _lastindex;
}

bool Scanner::isTextChar(unsigned int i) {
  return (_str[i] >= 'a' && _str[i] <= 'z') || (_str[i] >= 'A' && _str[i]
      <= 'Z');
}

bool Scanner::isEOS(unsigned int i) {
  return i >= _str.size();
}

bool Scanner::isDigit(unsigned int i) {
  return _str[i] >= '0' && _str[i] <= '9';
}

bool Scanner::finished() {
  return _index >= _str.size();
}

/** Test function that prints out tokenized strings. */
void TestScanner() {
  string s = "  (  . hi.There'we.are12.-0211 +77  ) /";
  cout << "\"" << s << "\"\n";
  Scanner scan(s);
  string str;
  Scanner::TokenType tok;
  while ((tok = scan.getToken(str)) != Scanner::TOK_EOS) {
    switch (tok) {
    case Scanner::TOK_DIV:
      cout << "/,";
      break;
    case Scanner::TOK_LPARAN:
      cout << "(,";
      break;
    case Scanner::TOK_RPARAN:
      cout << "),";
      break;
    case Scanner::TOK_DOT:
      cout << ".,";
      break;
    case Scanner::TOK_ID:
      cout << "\"" << str << "\",";
      break;
    case Scanner::TOK_PARAM:
      cout << "[" << str << "],";
      break;
    case Scanner::TOK_INT:
      cout << str << ",";
      break;
    case Scanner::TOK_UNKNOWN:
      cout << "** UNKNOWN at pos " << scan.getPos() << "\n";
      return;
    default:
      break;
    }
  }
  cout << "\n";
}
