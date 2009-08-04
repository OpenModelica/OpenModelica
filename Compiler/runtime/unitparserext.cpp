/* External interface for UnitParserExt module */
#include "unitparser.h"

UnitParser unitParser;

using namespace std;

extern "C"
{
#include <assert.h>
#include "rml.h"
#include "../absyn_builder/yacclib.h"


void UnitParserExt_5finit(void)
{
	unitParser.initSIUnits();
}

RML_BEGIN_LABEL(UnitParserExt__initSIUnits)
{

    RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(UnitParserExt__unit2str)
{
	void* nums=rmlA0; void* denoms=rmlA1; void* tpnoms=rmlA2; void* tpdenoms=rmlA3; void* tpstrs=rmlA4;
	long int i1,i2;
	string tpParam;
	nums = rmlA0;
	Unit unit;
	/* Add baseunits*/
	while(RML_GETHDR(nums) == RML_CONSHDR) {
		i1 = RML_UNTAGFIXNUM(RML_CAR(nums));
		i2 = RML_UNTAGFIXNUM(RML_CAR(denoms));
		unit.unitVec.push_back(Rational(i1,i2));
		nums = RML_CDR(nums);
		denoms = RML_CDR(denoms);
	}
	/* Add type parameters*/
	while(RML_GETHDR(tpnoms) == RML_CONSHDR) {
		i1 = RML_UNTAGFIXNUM(RML_CAR(tpnoms));
		i2 = RML_UNTAGFIXNUM(RML_CAR(tpdenoms));
		tpParam = string(RML_STRINGDATA(RML_CAR(tpstrs)));
		unit.typeParamVec[tpParam]=Rational(i1,i2);
		tpnoms = RML_CDR(tpnoms);
		tpdenoms = RML_CDR(tpdenoms);
	}
	//string res = unitParser.unit2str(unit);
	string res = unitParser.prettyPrintUnit2str(unit);

	rmlA0 = (void*) mk_scon((char*)res.c_str());
    RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(UnitParserExt__str2unit)
{
    string str = string(RML_STRINGDATA(rmlA0));
    Unit unit;
    unitParser.str2unit(str,unit);

    /* Build rml objects */
    void* nums=mk_nil(); void* denoms=mk_nil(); void* tpnoms=mk_nil(); void* tpdenoms=mk_nil(); void* tpstrs=mk_nil();
    /* baseunits */
    vector<Rational>::reverse_iterator rii;
    for(rii=unit.unitVec.rbegin(); rii!=unit.unitVec.rend(); ++rii) {
    	nums = mk_cons(mk_icon(rii->num),nums);
    	denoms = mk_cons(mk_icon(rii->denom),denoms);
    }
    /* type parameters*/
    map<string,Rational>::reverse_iterator rii2;
    for(rii2=unit.typeParamVec.rbegin(); rii2!=unit.typeParamVec.rend(); ++rii2) {
    	tpnoms = mk_cons(mk_icon(rii2->second.num),tpnoms);
    	tpdenoms = mk_cons(mk_icon(rii2->second.denom),tpdenoms);
    	tpstrs = mk_cons(mk_scon((char*)rii2->first.c_str()),tpstrs);
    }

    rmlA0 = (void*)nums;
    rmlA1 = (void*)denoms;
    rmlA2 = (void*)tpnoms;
    rmlA3 = (void*)tpdenoms;
    rmlA4 = (void*)tpstrs;
    RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

} // extern "C"

