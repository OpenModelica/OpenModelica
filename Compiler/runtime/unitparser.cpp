/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2009, Linköpings University,
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


#include "unitparser.h"
#include <iostream>
#include <sstream>
#include "lp_lib.h"

/***************************************************************************************/
/*   CLASS: Rational                                                                   */
/***************************************************************************************/



Rational::Rational(long numerator, long denominator)
{
	num = numerator;
	denom = denominator;
	fixsign();
}

Rational::Rational(const Rational& r){
	num = r.num;
	denom = r.denom;
	fixsign();
}

bool Rational::isZero()
{
	return num == 0;
}

bool Rational::is(long numerator, long denominator)
{
	return (num == numerator) && (denom == denominator);
}


string Rational::toString()
{
	stringstream ss;
	if(denom == 1){
		ss << num;
		return ss.str();
	}
	else{
		ss << "(" << num << "/" << denom << ")";
		return ss.str();
	}
}

double Rational::toReal()
{
	if (denom == 0) cerr << "Division by zero in << "<<toString() << endl;
	double r = (double)num / (double) denom;
	return r;
}


Rational Rational::sub(Rational q1, Rational q2)
{
	return simplify(Rational(q1.num * q2.denom - q2.num * q1.denom, q1.denom * q2.denom));
}

Rational Rational::add(Rational q1, Rational q2)
{
	return simplify(Rational(q1.num * q2.denom + q2.num * q1.denom, q1.denom * q2.denom));
}

Rational Rational::mul(Rational q1, Rational q2)
{
	return simplify(Rational(q1.num * q2.num, q1.denom * q2.denom));
}

Rational Rational::div(Rational q1, Rational q2)
{
	return simplify(Rational(q1.num * q2.denom, q1.denom * q2.num));
}


Rational Rational::simplify(const Rational q)
{
	long gcd = Rational::gcd(q.num, q.denom);
	Rational q2(Rational(q.num / gcd, q.denom / gcd));
	q2.fixsign();
	return q2;
}

void Rational::fixsign()
{
	if(denom < 0){
		denom *= -1;
		num *= -1;
	}
}

long Rational::gcd(long a, long b)
{
	while(b != 0){
		long t = b;
		b = a % b;
		a = t;
	}
	return a;
}

/***************************************************************************************/
/*   CLASS: Unit                                                                       */
/***************************************************************************************/


UnitRes Unit::div(Unit u1, Unit u2, Unit& ur)
{
	return paramutil(u1,u2,ur,false);
}

UnitRes Unit::mul(Unit u1, Unit u2, Unit& ur)
{
	return paramutil(u1,u2,ur,true);
}


UnitRes Unit::paramutil(Unit u1, Unit u2, Unit& ur, bool mulop)
{
	if(!u1.offset.isZero() || !u2.offset.isZero())
		return UnitRes(UnitRes::UNIT_OFFSET_ERROR);

	ur.offset = 0;
	ur.quantityName = "";
	ur.unitName = "";
	ur.prefixExpo = mulop ? Rational::add(u1.prefixExpo, u2.prefixExpo) :
						    Rational::sub(u1.prefixExpo, u2.prefixExpo);
	ur.scaleFactor = mulop ? Rational::mul(u1.scaleFactor, u2.scaleFactor) :
						     Rational::div(u1.scaleFactor, u2.scaleFactor);
	ur.unitVec.clear();
	for(unsigned int i=0;i < max(u1.unitVec.size(), u2.unitVec.size()); i++){
		Rational q1(0),q2(0);
		if(i < u1.unitVec.size())
			q1 = u1.unitVec[i];
		if(i < u2.unitVec.size())
			q2 = u2.unitVec[i];
		ur.unitVec.push_back(mulop ? Rational::add(q1,q2) : Rational::sub(q1,q2));
	}

	map<string,Rational>::iterator p1 = u1.typeParamVec.begin();
	map<string,Rational>::iterator p2 = u2.typeParamVec.begin();
	for(;;){
		if(p1 != u1.typeParamVec.end() && p2 != u2.typeParamVec.end())
		{
			int cval = (*p1).first.compare((*p2).first);
			if(cval==0){
				//Same parameter symbol
				ur.typeParamVec[(*p1).first] = mulop ? Rational::add((*p1).second, (*p2).second) :
													   Rational::sub((*p1).second, (*p2).second);
				p1++;
				p2++;
			}
			else if(cval > 0){
				ur.typeParamVec[(*p2).first] = (*p2).second;
				p2++;
			}
			else{
				ur.typeParamVec[(*p1).first] = (*p1).second;
				p1++;
			}
		}
		else if(p1 != u1.typeParamVec.end()){
				ur.typeParamVec[(*p1).first] = (*p1).second;
				p1++;
		}
		else if(p2 != u2.typeParamVec.end()){
			ur.typeParamVec[(*p2).first] = mulop ? (*p2).second : Rational::mul((*p2).second,Rational(-1));
				p2++;
		}
		else
			break;
	}
	return UnitRes(UnitRes::UNIT_OK);
}

UnitRes Unit::pow(Unit u, const Rational e, Unit& ur)
{
	if(!u.offset.isZero())
		return UnitRes(UnitRes::UNIT_OFFSET_ERROR);

	if(!u.scaleFactor.is(1))
		return UnitRes(UnitRes::UNIT_SCALE_ERROR);

	ur = u;
	ur.prefixExpo = Rational::mul(u.prefixExpo, e);
	ur.unitVec.clear();
	for(unsigned int i=0;i < u.unitVec.size(); i++){
		ur.unitVec.push_back(Rational::mul(u.unitVec[i],e));
	}
	for(map<string,Rational>::iterator p = u.typeParamVec.begin(); p != u.typeParamVec.end(); p++){
		(*p).second = Rational::mul((*p).second, e);
	}
	return UnitRes(UnitRes::UNIT_OK);
}

bool Unit::isDimensionless()
{
	for(vector<Rational>::iterator p = unitVec.begin(); p != unitVec.end(); p++){
		if(!(*p).isZero())
			return false;
	}
	return (typeParamVec.size() == 0);
}

bool Unit::isBaseUnit()
{
	bool onefound = false;
	for(vector<Rational>::iterator p = unitVec.begin(); p != unitVec.end(); p++){
		if((*p).denom != 1)
			return false;
		if((*p).num == 1){
			if(onefound) return false;
			else onefound = true;
		}
		else if((*p).num != 0)
			 return false;
	}
	return true;
}


/***************************************************************************************/
/*   CLASS: UnitParser                                                                 */
/***************************************************************************************/


UnitParser::UnitParser()
{
}

UnitParser::~UnitParser()
{
}


void UnitParser::addPrefix(const string symbol, Rational exponent)
{
	_prefix[symbol] = exponent;
}

void UnitParser::addBase(const string quantityName, const string unitName, const string unitSymbol, bool prefixAllowed)
{
	Base b(quantityName, unitName, unitSymbol, prefixAllowed);
	_base.push_back(b);
	Unit u;
	u.prefixAllowed = b.prefixAllowed;
	u.quantityName = b.quantityName;
	u.unitName = b.unitName;
	u.unitSymbol = unitSymbol;
	for(unsigned long j=0; j < _base.size(); j++){
		u.unitVec.push_back(Rational((_base.size()-1)==j?1:0));
	}

	//Force the old unit vectors to have the same lenght as the new one
	for(map<string,Unit>::iterator p = _units.begin(); p != _units.end(); p++){
		(*p).second.unitVec.push_back(Rational(0));
	}

	_units[b.unitSymbol] = u;
}



void UnitParser::addDerived(const string quantityName, const string unitName, const string unitSymbol, const string unitStrExp, 
							   Rational prefixExpo, Rational scaleFactor, Rational offset, bool prefixAllowed)
{
	DerivedInfo di(quantityName, unitName, unitSymbol, unitStrExp, prefixExpo, scaleFactor, offset, prefixAllowed);
	_tempDerived.push_back(di);
}

UnitRes UnitParser::addDerivedInternal(const string quantityName, const string unitName, const string unitSymbol, const string unitStrExp, 
							   Rational prefixExpo, Rational scaleFactor, Rational offset, bool prefixAllowed)
{
	Unit u;
	UnitRes res = str2unit(unitStrExp, u);
	if(!res.Ok())
		return res;
	u.quantityName = quantityName;
	u.unitName = unitName;
	u.unitSymbol = unitSymbol;
	u.prefixAllowed = prefixAllowed;
	u.prefixExpo = prefixExpo;
	u.scaleFactor = scaleFactor;
	u.offset = offset;
	u.weight = weight;
	_units[unitSymbol] = u;
	return res;
}


UnitRes UnitParser::commit()
{
	list<DerivedInfo> tmp;
	int initSize = _tempDerived.size();
	while(_tempDerived.size() != 0)
	{	
		unsigned int startSize = _tempDerived.size();
		while(_tempDerived.size() != 0)
		{
			DerivedInfo d = _tempDerived.front();
			UnitRes res = addDerivedInternal(d.quantityName,d.unitName,d.unitSymbol,d.unitStrExp,
				d.prefixExpo, d.scaleFactor, d.offset, d.prefixAllowed);
			_tempDerived.pop_front();
			if(!res.Ok())
				tmp.push_back(d);
		}
		if(tmp.size() == startSize)
			return UnitRes::ERROR_ADDING_UNIT;
		_tempDerived = tmp;
		tmp.clear();
	}
	return UnitRes(UnitRes::UNIT_OK);
}


string UnitParser::prettyPrintUnit2str(Unit unit)
{
	Unit prettyUnit = solveMIP(unit);
   return unit2str(prettyUnit);
}

Unit UnitParser::solveMIP(Unit unit)
{
  int numBaseUnits = _base.size();
  int numDerivedUnits=0;
  // Counting the derived units by traversing all units
  for( map<string,Unit>::iterator it=_units.begin(); it != _units.end(); it++)
		  if (!it->second.isBaseUnit()) numDerivedUnits++;
  int NU = numBaseUnits + numDerivedUnits;

  // Create MIP with 2*NU variables(columns)
  lprec *lp = make_lp(0,2*NU);
  if (lp == NULL) {
	  cerr <<"Internal error pretty printing expression. Using simple approach" << endl;
	  return unit;
  }

  /* Set name of variables for debug printing */
  int i;
  for ( i=1;i<=numBaseUnits;i++) {
	  char * s1= (char*)_base[i-1].unitName.c_str();
	  char * s2 = (char*)(string("-")+string(s1)).c_str();
	  if (!set_col_name(lp,i,s1)) {cerr << "ERROR1" << endl;}
	  if (!set_col_name(lp,NU+i,s2)) {cerr << "ERROR" << endl;}
  }
  for( map<string,Unit>::iterator it=_units.begin(); it != _units.end(); it++) {
	  if (!it->second.isBaseUnit()) {
		  char * s1= (char*)it->second.unitName.c_str();
		  char * s2 = (char*)(string("-")+string(s1)).c_str();
		  if(!set_col_name(lp,i,s1)) { cerr << "ERROR2" << endl;}
		  if(!set_col_name(lp,NU+i,s2))  { cerr << "ERROR3" << endl; }
		  i++;
	  }
  }

  // Increases efficency when adding rows.
  set_add_rowmode(lp,TRUE);

  double *row = new double[2*NU];
  int *colno= new int[2*NU];

  if (!row || !colno) {
	  cerr <<"Internal error pretty printing expression (allocation of memory). Using simple approach" << endl;
	  return unit;
  }

  int c;
  // Set the constraint
  for (int r = 0;r<numBaseUnits;r++) {
      int j=0;
      /* Set 0..numBaseUnits-1 first columns */
	  for(c=0;c < numBaseUnits; c++) {
		  colno[j]=c+1;
    	  row[j++] = r == c?1:0;
	  }
	  /* Set numBaseUnits .. NU-1 following columns */
	  for( map<string,Unit>::iterator it=_units.begin(); it != _units.end(); it++) {
		 Unit u = it->second;
		 if (!u.isBaseUnit()) {
			 colno[j] = 1+c;
			 row[j++] = u.unitVec[r].toReal();
			 c++;
		 }
	  }
	  for (int j2=0 ; j2 < NU; j2++) {
		  colno[j]=colno[j2]+NU;
		  row[j++] = -row[j2];
	  }
	  double b = unit.unitVec[r].toReal();
	  if(!add_constraintex(lp,j,row,colno,EQ,b)) {
		  cerr << "Internal error pretty printing expression (adding row to lp). Using simple approach" << endl;
		  return unit;
	  }
  }
  set_add_rowmode(lp,FALSE);

  /* Set the objective */
  int j=0;
  int c2;
  /* element 0..numBaseUnits-1*/
  for (c2=0; c2 < numBaseUnits;c2++ ) {
	  double cost=0;
	  for (int r2=0; r2 < numBaseUnits; r2++) {
		  cost+= fabs(unit.unitVec[r2].toReal()- (c2==r2?1:0));
	  }
	  cost *= _base[c2].weight;
	  colno[j]=c2+1;
	  row[j++]=cost;
  }
  /* elements numBaseUnits .. NU -1 */
  c2=numBaseUnits;
  for(map<string,Unit>::iterator it=_units.begin(); it != _units.end(); it++) {
	  double cost=0;
	  Unit u = it->second;
	  if (!u.isBaseUnit()) {
		  for(int r2=0; r2 < numBaseUnits; r2++) {
			  cost += fabs(unit.unitVec[r2].toReal() - u.unitVec[r2].toReal());
		  }
		  cost *= u.weight;
		  colno[j]=c2+1;
		  row[j++]=cost;
		  c2++;
	  }
  }
  /* elements NU .. NU+numBaseUnits-1 */
  for (int c2=0; c2 < numBaseUnits;c2++ ) {
 	  double cost=0;
 	  for (int r2=0; r2 < numBaseUnits; r2++) {
 		  cost+= fabs(unit.unitVec[r2].toReal()- (c2==r2?-1:0));
 	  }
 	  cost *= _base[c2].weight;
 	  colno[j]=c2+NU+1;
 	  row[j++]=cost;
   }
  /* elements NU+numBaseUnits .. 2*NU -1 */
  c2=numBaseUnits;
   for(map<string,Unit>::iterator it=_units.begin(); it != _units.end(); it++) {
 	  double cost=0;
 	  Unit u = it->second;
 	  if (!u.isBaseUnit()) {
 		  for(int r2=0; r2 < numBaseUnits; r2++) {
 			  cost += fabs(unit.unitVec[r2].toReal() + u.unitVec[r2].toReal());
 		  }
 		  cost *= u.weight;
 		  colno[j]=c2+NU+1;
 		  row[j++]=cost;
 		 c2++;
 	  }
   }
  if (!set_obj_fnex(lp,j,row,colno)) {
	  cerr  << "Internal error pretty printing expression (adding objective to lp). Using simple approach" << endl;
	  return unit;
  }

  /* Set up domain , Reals for base units, Integers for derived units */
  int v=0;
  for ( ; v < numBaseUnits; v++) 	set_int(lp,v+1,FALSE);
  for ( ; v < NU; v++) 						set_int(lp,v+1,TRUE);
  for ( ; v < NU+numBaseUnits; v++) 			set_int(lp,v+1,FALSE);
  for ( ; v< 2*NU; v++) 						set_int(lp,v+1,TRUE);

  /* Set up lower and upper bound */
  double maxDim=0;
  for (vector<Rational>::iterator it=unit.unitVec.begin(); it != unit.unitVec.end(); it++) {
	  maxDim = max(it->toReal(),maxDim);
  }
  for(v=0;v<2*NU;v++) {
	  set_upbo(lp,v+1,maxDim);
  }
  //cout << "LP debug:" << endl;
  set_verbose(lp,-1); // NO printing
  //print_lp(lp);
  int res = solve(lp);
  Unit prettyUnit,retVal;
  if (res == 0) {
	  //cerr << "result =" << get_var_primalresult(lp,0) << endl;
	  for (int i =0 ; i< 2*NU; i++) {
		  double res = get_var_primalresult(lp,i+1+numBaseUnits);
		  //cerr << i << " : " << res << endl ;
		  if (i>=NU) {
			  //cerr << "Resetting elt " << i << " at pos " << i%NU << endl;
			  prettyUnit.unitVec[i%NU] = Rational((long)(prettyUnit.unitVec[i%NU].toReal()-res));
		  } else {
			  //cerr << "Setting elt " << i << endl;
			  prettyUnit.unitVec.push_back(Rational((long)res));
		  }
	  }
	  //cerr << "resulting unit =" << unit2str(prettyUnit) << endl;
	  retVal = prettyUnit;
  } else {
	  retVal = unit;
  }
  free_lp(&lp);
  delete row;
  delete colno;
  return retVal;
}

string UnitParser::unit2str(Unit unit)
{
	//This code implements a simple unparser.
	//Todo in the future:
	// - Develop a way to generate the most appropriate derived units as well.
	// - Support for offset
	// - Support for SI-prefixes


	bool first(true);
	stringstream ss;

	//Print scale factor
	if(!unit.scaleFactor.is(1,1) || (unit.isDimensionless() && unit.prefixExpo.isZero())){
		ss << unit.scaleFactor.toString();
		first = false;
	}

	//Prefix exponent
	if(unit.prefixExpo.is(1,1)){
		if(!first)
			ss << ".";
		ss << "10";
		first = false;
	}
	else if(!unit.prefixExpo.isZero()){
		if(!first)
			ss << ".";
		ss << "10^" << unit.prefixExpo.toString();
		first = false;
	}
    //print type parameters (variables)
	for(map<string,Rational>::iterator p = unit.typeParamVec.begin(); p != unit.typeParamVec.end(); p++){
		if(!(*p).second.isZero()){
			if(!first)
				ss << ".";
			ss << (*p).first << ((*p).second.is(1) ? "" : (*p).second.toString());
			first = false;
		}
	}
	//Print unit vector using base units
	unsigned int i;
	for(i = 0; i<min(unit.unitVec.size(),_base.size()); i++){
		Rational q(unit.unitVec[i]);
		if(!q.isZero()){
			if(!first)
				ss << ".";
			ss << _base[i].unitSymbol << (q.is(1) ? "" : q.toString());
			first = false;
		}
	}
	//Print unit vector using derived units
	for (map<string,Unit>::iterator it=_units.begin(); it!=_units.end(); it++) {
		if (!it->second.isBaseUnit()) {
			Rational q(unit.unitVec[i]);

			if(!q.isZero()){
				if(!first)
					ss << ".";
					ss << it->second.unitSymbol << (q.is(1) ? "" : q.toString());
					first = false;
			}
			i++;
		}
	}
	return ss.str();
}

UnitRes UnitParser::str2unit(const string unitstr, Unit& unit)
{
	Scanner scan(unitstr);
	UnitRes res = parseExpression(scan, unit);
	if(!res.Ok()) return res;
	if(scan.finished())
		return UnitRes(UnitRes::UNIT_OK);
	else
		return UnitRes(UnitRes::PARSE_ERROR, scan.getPos());
}


UnitRes UnitParser::parseExpression(Scanner& scan, Unit& unit)
{
	Unit u1,u2;
	UnitRes res = parseFactors(scan, u1);  //Old: numerators
	unit = u1;
	if(!res.Ok()) return res;
	string str;
	Scanner::TokenType tok = scan.peekToken(str);
	switch(tok){
		case Scanner::TOK_EOS :
			scan.getToken(str);
			return UnitRes(UnitRes::UNIT_OK);
		case Scanner::TOK_DIV :
			scan.getToken(str);
			res = parseDenominator(scan, u2);
			if(!res.Ok()) return res;
			res = Unit::div(u1,u2,unit);
			if(!res.Ok()) return res;
			return res;
	}
	return UnitRes(UnitRes::UNIT_OK);
}

//Not used right now...
UnitRes UnitParser::parseNumerator(Scanner& scan, Unit& unit)
{
	string str;
	Unit u;
	Scanner::TokenType tok = scan.peekToken(str);
	if(tok == Scanner::TOK_LPARAN){
			scan.getToken(str);
			UnitRes res = parseExpression(scan, u);
			if(!res.Ok()) return res;
			if(scan.getToken(str) != Scanner::TOK_RPARAN)
				return UnitRes(UnitRes::PARSE_ERROR, scan.getLastPos());
			unit = u;
			return res;
	}
	return parseFactors(scan, unit);
}

UnitRes UnitParser::parseDenominator(Scanner& scan, Unit& unit)
{
	string str;
	Unit u;
	Scanner::TokenType tok = scan.peekToken(str);
	if(tok == Scanner::TOK_LPARAN){
			scan.getToken(str);
			UnitRes res = parseExpression(scan, u);
			if(!res.Ok()) return res;
			if(scan.getToken(str) != Scanner::TOK_RPARAN)
				return UnitRes(UnitRes::PARSE_ERROR, scan.getLastPos());
			unit = u;
			return res;
	}
	return parseFactor(scan, unit);
}

UnitRes UnitParser::parseFactors(Scanner& scan, Unit& unit)
{
	string str;
	Unit u1,u2;
	UnitRes res =  parseFactor(scan, u1);
	if(!res.Ok()) return res;
	if(scan.peekToken(str) == Scanner::TOK_DOT){
		scan.getToken(str);
		res = parseFactors(scan, u2);
		if(!res.Ok()) return res;
		return Unit::mul(u1, u2, unit);
	}
	else{
		unit = u1;
		return UnitRes(UnitRes::UNIT_OK);
	}
}

UnitRes UnitParser::parseFactor(Scanner& scan, Unit& unit)
{
	string str;
	Unit u1;
	Rational q(0),q2(0);
	unsigned int scanpostemp;
	UnitRes res;
	Scanner::TokenType tok = scan.peekToken(str);
	switch(tok){
		case Scanner::TOK_ID : // Unit symbol e.g. [mm] including prefix.
			res = parseSymbol(scan, u1);
			if(!res.Ok()) return res;
			unit = u1;
			scanpostemp = scan.getpos();
			res = parseRational(scan, q);
			if(!res.Ok()){
				scan.setpos(scanpostemp);
				return UnitRes(UnitRes::UNIT_OK);
			}
			else{
				Unit::pow(u1, q, unit);
				return UnitRes(UnitRes::UNIT_OK);
				return res;
			}

		case Scanner::TOK_PARAM :  //Unit type parameter
			scan.getToken(str);
			if(!res.Ok()) return res;
			unit = Unit();
			scanpostemp = scan.getpos();
			res = parseRational(scan, q);
			if(!res.Ok()){
				unit.typeParamVec[str] =  Rational(1);
				scan.setpos(scanpostemp);
				return UnitRes(UnitRes::UNIT_OK);
			}
			else{
				unit.typeParamVec[str] = q;
				return UnitRes(UnitRes::UNIT_OK);
				return res;
			}

		default: //Scale factor
			res = parseRational(scan, q);
			unit = Unit();
			if(!res.Ok()) return res;
			if(scan.peekToken(str) != Scanner::TOK_EXPO){
				unit.scaleFactor = q;
				return res;
			}
			scan.getToken(str);
			res = parseRational(scan, q2);
			if(!res.Ok()) return res;
			if(!q.is(10)) return UnitRes(UnitRes::UNIT_WRONG_BASE, scan.getLastPos());
			unit.prefixExpo = q2;
			return res;
	}
}

UnitRes UnitParser::parseSymbol(Scanner& scan, Unit& unit)
{
	//Derived symbol exists?
	string str;
	Scanner::TokenType tok = scan.getToken(str);
	if(tok != scan.TOK_ID) return UnitRes(UnitRes::PARSE_ERROR, scan.getLastPos());

	//Only a derived unit?
	if(_units.find(str) != _units.end())
	{
		unit = _units[str];
		return UnitRes(UnitRes::UNIT_OK);
	}

	//Find prefix
	for(unsigned int i=1; i<=str.size(); i++){
		if(_prefix.find(str.substr(0,i)) != _prefix.end()){
			if(_units.find(str.substr(i)) != _units.end()){
				unit = _units[str.substr(i)];
				if(!unit.prefixAllowed)
					return UnitRes(UnitRes::PREFIX_NOT_ALLOWED, scan.getLastPos());
				unit.prefixExpo = Rational::add(unit.prefixExpo,_prefix[str.substr(0,i)]);
				return UnitRes(UnitRes::UNIT_OK);
			}
			else
				return UnitRes(UnitRes::UNIT_NOT_FOUND, scan.getLastPos()+i);
		}
	}
	return UnitRes(UnitRes::PREFIX_NOT_FOUND, scan.getLastPos());
}



UnitRes UnitParser::parseRational(Scanner& scan, Rational& q){

	string str;
	long l1,l2;
	Scanner::TokenType tok = scan.getToken(str);
	if(tok == scan.TOK_INT){
		istringstream iss1(str);
		if(!(iss1 >> l1))
			return UnitRes(UnitRes::INVALID_INT, scan.getLastPos());
		q = Rational(l1);
		return UnitRes(UnitRes::UNIT_OK);
	}
	else if(tok == scan.TOK_LPARAN){
		tok = scan.getToken(str);
		if(tok != scan.TOK_INT)
			return UnitRes(UnitRes::PARSE_ERROR, scan.getLastPos());
		istringstream iss1(str);
		if(!(iss1 >> l1))
			return UnitRes(UnitRes::INVALID_INT, scan.getLastPos());
		tok = scan.getToken(str);
		if(tok != scan.TOK_DIV)
			return UnitRes(UnitRes::PARSE_ERROR, scan.getLastPos());
		tok = scan.getToken(str);
		if(tok != scan.TOK_INT)
			return UnitRes(UnitRes::PARSE_ERROR, scan.getLastPos());
		istringstream iss2(str);
		if(!(iss2 >> l2))
			return UnitRes(UnitRes::INVALID_INT, scan.getLastPos());
		tok = scan.getToken(str);
		if(tok != scan.TOK_RPARAN)
			return UnitRes(UnitRes::PARSE_ERROR, scan.getLastPos());
		q = Rational(l1,l2);
		return UnitRes(UnitRes::UNIT_OK);
	}
	else
		return UnitRes(UnitRes::PARSE_ERROR, scan.getLastPos());
}

void UnitParser::initPrefixes(){
	//Add prefixes
	addPrefix("da",Rational(1));	// deca
	addPrefix("h",Rational(2));		// hecto
	addPrefix("k",Rational(3));		// kilo
	addPrefix("M",Rational(6));		// mega
	addPrefix("G",Rational(9));		// giga
	addPrefix("T",Rational(12));	// tera
	addPrefix("P",Rational(15));	// peta
	addPrefix("E",Rational(18));	// exa
	addPrefix("Z",Rational(21));	// zetta
	addPrefix("Y",Rational(24));	// yotta
	addPrefix("d",Rational(-1));	// deci
	addPrefix("c",Rational(-2));	// centi
	addPrefix("m",Rational(-3));	// milli
	addPrefix("u",Rational(-6));	// micro
	addPrefix("n",Rational(-9));	// nano
	addPrefix("p",Rational(-12));	// pico
	addPrefix("f",Rational(-15));	// femto
	addPrefix("a",Rational(-18));	// atto
	addPrefix("z",Rational(-21));	// zepto
	addPrefix("y",Rational(-24));	// yocto
}

void UnitParser::initSIUnits(){
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
	addDerived("mass", "gram", "g", "kg", Rational(-3), Rational(1), Rational(0), true);

	//Standard derived units (SI brochure 8th ed., page 118)
	addDerived("plane angle", "radian", "rad", "m/m", Rational(0), Rational(1), Rational(0), true); 
	addDerived("solid angle", "steradian", "sr", "m2/m2", Rational(0), Rational(1), Rational(0), true); 
	addDerived("frequency", "hertz", "Hz", "s-1", Rational(0), Rational(1), Rational(0), true); 
	addDerived("force", "newton", "N", "m.kg.s-2", Rational(0), Rational(1), Rational(0), true); 
	addDerived("pressure, stress", "pascal", "Pa", "N/m2", Rational(0), Rational(1), Rational(0), true); 
	addDerived("power, radiant flux", "watt", "W", "J/s", Rational(0), Rational(1), Rational(0), true); 
	addDerived("energy, work, amount of heat", "joule", "J", "N.m", Rational(0), Rational(1), Rational(0), true); 
	addDerived("electric charge, amount of electricity", "coulomb", "C", "s.A", Rational(0), Rational(1), Rational(0), true); 
	addDerived("electric potential difference, electromotive force", "volt", "V", "W/A", Rational(0), Rational(1), Rational(0), true); 
	addDerived("capacitance", "farad", "F", "C/V", Rational(0), Rational(1), Rational(0), true); 
	addDerived("electric resistance", "ohm", "Ohm", "V/A", Rational(0), Rational(1), Rational(0), true); 
	addDerived("electric conductance", "siemens", "S", "A/V", Rational(0), Rational(1), Rational(0), true); 
	addDerived("magnetic flux", "weber", "Wb", "V.s", Rational(0), Rational(1), Rational(0), true); 
	addDerived("magnetic flux density", "tesla", "T", "Wb/m2", Rational(0), Rational(1), Rational(0), true); 
	addDerived("inductance", "henry", "H", "Wb/A", Rational(0), Rational(1), Rational(0), true); 
	addDerived("Celsius temperature", "degree Celsius", "degC", "K", Rational(0), Rational(1), Rational(27315,100), true); 
	addDerived("luminous flux", "lumen", "lm", "cd.sr", Rational(0), Rational(1), Rational(0), true); 
	addDerived("illuminance", "lux", "lx", "lm/m2", Rational(0), Rational(1), Rational(0), true); 
	addDerived("activity referred to a radionuclide", "becquerel", "Bq", "s-1", Rational(0), Rational(1), Rational(0), true); 
	addDerived("absorbed dose, specific energy (imparted), kerma", "gray", "Gy", "J/kg", Rational(0), Rational(1), Rational(0), true); 
	addDerived("dose equivalent, ambient dose equivalent, directional dose equivalent, personal dose equivalent", "sievert", "Sv", "J/kg", Rational(0), Rational(1), Rational(0), true); 
	addDerived("catalyctic activity", "katal", "kat", "s-1.mol", Rational(0), Rational(1), Rational(0), true); 

	commit();
}

/***************************************************************************************/
/*   CLASS: Scanner                                                                    */
/***************************************************************************************/

Scanner::Scanner(string str) : _str(str), _index(0), _lastindex(0) {;}
Scanner::~Scanner(){;}

Scanner::TokenType Scanner::peekToken(string& tokstr){
	unsigned int tmpindex = _index;
	return getTokenInternal(tokstr, tmpindex);
}

Scanner::TokenType Scanner::getToken(string& tokstr){
	_lastindex = _index;
	return getTokenInternal(tokstr, _index);
}

Scanner::TokenType Scanner::getTokenInternal(string& tokstr, unsigned int& index){
	//Eat white space
	while(index < _str.size() && (_str[index] == ' ' || _str[index] == '\t' || _str[_index] == '\n'))
		index++;

	//Check if it was the last token
	if(isEOS(index))
		return TOK_EOS;

	//Check character tokens
	switch(_str[index]){
		case '/' :
			index++;
			return TOK_DIV;
		case '(' :
			index++;
			return TOK_LPARAN;
		case ')' :
			index++;
			return TOK_RPARAN;
		case '.' :
			index++;
			return TOK_DOT;
		case '^' :
			index++;
			return TOK_EXPO;
	}

	//Check if identifier or token
	if(isTextChar(index) || _str[index] == '\''){
		unsigned int idx = index++;
		while(!isEOS(index) && isTextChar(index))
			index++;
		tokstr = _str.substr(idx,index-idx);
		if(_str[idx] == '\''){
			if(index - idx == 1){
				index--;
				return TOK_UNKNOWN;
			}
			else
				return TOK_PARAM;
		}
		return TOK_ID;
	}

	//Get potential sign of integer
	unsigned int idx = index;
	if(_str[index] == '+' || _str[index] == '-')
		index++;

	//Check for integer
	if(isDigit(index)){
		while(!isEOS(index) && isDigit(index))
			index++;
		tokstr = _str.substr(idx,index-idx);
		return TOK_INT;
	}

	return TOK_UNKNOWN;
}

unsigned int Scanner::getPos(){
	return _index;
}

unsigned int Scanner::getLastPos(){
	return _lastindex;
}

bool Scanner::isTextChar(unsigned int i){
	return (_str[i] >= 'a' && _str[i] <= 'z') || (_str[i] >= 'A' && _str[i] <= 'Z');
}

bool Scanner::isEOS(unsigned int i){
	return i >= _str.size();
}

bool Scanner::isDigit(unsigned int i){
	return _str[i] >= '0' && _str[i] <= '9';
}

bool Scanner::finished(){
	return _index >= _str.size();
}


/** Test function that prints out tokenized strings. */
void TestScanner(){
	string s = "  (	. hi.There'we.are12.-0211 +77	) /";
	cout << "\"" << s << "\"\n";
	Scanner scan(s);
	string str;
	Scanner::TokenType tok;
	while((tok = scan.getToken(str)) != Scanner::TOK_EOS){
		switch(tok){
			case Scanner::TOK_DIV :
				cout << "/,";
				break;
			case Scanner::TOK_LPARAN :
				cout << "(,";
				break;
			case Scanner::TOK_RPARAN :
				cout << "),";
				break;
			case Scanner::TOK_DOT :
				cout << ".,";
				break;
			case Scanner::TOK_ID :
				cout << "\"" << str << "\",";
				break;
			case Scanner::TOK_PARAM :
				cout << "[" << str << "],";
				break;
			case Scanner::TOK_INT :
				cout << str << ",";
				break;
			case Scanner::TOK_UNKNOWN :
				cout << "** UNKNOWN at pos " << scan.getPos() << "\n";
				return;
		}
	}
	cout << "\n";
}


