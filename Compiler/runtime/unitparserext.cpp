/* External interface for UnitParserExt module */
#include "unitparser.h"

#include <iostream>
#include <stack>

using namespace std;
UnitParser* unitParser = new UnitParser;
stack<UnitParser*> rollbackStack;

extern "C"
{
#include <assert.h>
#include <string.h>
#include <stdlib.h>

void UnitParserExtImpl__initSIUnits(void)
{
  unitParser->initSIUnits();
}

void UnitParserExtImpl__checkpoint(void)
{
  UnitParser *copy = new UnitParser(*unitParser);
  rollbackStack.push(unitParser);
  unitParser = copy;
}

void UnitParserExtImpl__rollback(void)
{
  if (rollbackStack.empty()) {
    cerr << "Error, rollback on empty stack" << endl;
    exit(1);
  }
  UnitParser * old = rollbackStack.top();
  rollbackStack.pop();
  delete unitParser;
  unitParser=old;
}

void UnitParserExtImpl__clear(void)
{
  if (unitParser) delete unitParser;
  unitParser = new UnitParser;
}

void UnitParserExtImpl__commit(void)
{
  unitParser->commit();
}

void UnitParserExtImpl__registerWeight(const char *name, double weight)
{
 //cout << "registerWeight(" << name << ", "<<w <<")"<<endl;
 unitParser->accumulateWeight(name,weight);
}

void* UnitParserExtImpl__allUnitSymbols()
{
  return unitParser->allUnitSymbols();
}

void UnitParserExtImpl__addBase(const char *name)
{
   //cout << "addBase(" << name << ")"<<endl;
   if (strcmp(name,"kg")==0) {
     unitParser->addBase("","",name,false);
   } else {
     unitParser->addBase("","",name,true);
   }
}

void UnitParserExtImpl__addDerived(const char *name, const char *exp)
{
   //cout << "addDerived(" << name << ", "<<exp << ")" << endl;
   unitParser->addDerived(name,name,name,exp,Rational(0),Rational(1),Rational(0),true);
}

void UnitParserExtImpl__addDerivedWeight(const char *name, const char *exp, double weight)
{
   //cout << "addDerived(" << name << ", "<<exp << ", " << w << ")"<< endl;
   unitParser->addDerived(name,name,name,exp,Rational(0),Rational(1),Rational(0),true,weight);
}

} // extern "C"

