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

/* External interface for UnitParserExt module */
#include "unitparser.h"
#include "unitparserext.cpp"

extern "C"
{

#include "meta/meta_modelica.h"
#include "ModelicaUtilities.h"
#include "systemimpl.h"
#include "errorext.h"

const char* UnitParserExt_unit2str(void *nums, void *denoms, void *tpnoms, void *tpdenoms, void *tpstrs)
{
  mmc_sint_t i1,i2;
  string tpParam;
  Unit unit;
  unit.unitVec.clear();
  unit.typeParamVec.clear();
  /* Add baseunits*/
  while(MMC_GETHDR(nums) == MMC_CONSHDR) {
    i1 = MMC_UNTAGFIXNUM(MMC_CAR(nums));
    i2 = MMC_UNTAGFIXNUM(MMC_CAR(denoms));
    unit.unitVec.push_back(Rational(i1,i2));
    nums = MMC_CDR(nums);
    denoms = MMC_CDR(denoms);
  }
  /* Add type parameters*/
  while(MMC_GETHDR(tpnoms) == MMC_CONSHDR) {
    i1 = MMC_UNTAGFIXNUM(MMC_CAR(tpnoms));
    i2 = MMC_UNTAGFIXNUM(MMC_CAR(tpdenoms));
    tpParam = string(MMC_STRINGDATA(MMC_CAR(tpstrs)));
    unit.typeParamVec.insert(std::pair<string,Rational>(tpParam,Rational(i1,i2)));
    tpnoms = MMC_CDR(tpnoms);
    tpdenoms = MMC_CDR(tpdenoms);
  }
  //string res = unitParser->unit2str(unit);
  string res = unitParser->prettyPrintUnit2str(unit);

  return strcpy(ModelicaAllocateString(res.size()), res.c_str());
}

void UnitParserExt_str2unit(const char *inStr, void **nums, void **denoms, void **tpnoms, void **tpdenoms, void **tpstrs, double *scaleFactor, double *offset)
{
  string str = string(inStr);
  Unit unit;
  UnitRes res = unitParser->str2unit(str,unit);
  if (!res.Ok()) {
    string errmsg = res.toString();
    const char* tokens[2] = {errmsg.c_str(),str.c_str()};
    c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("Error parsing unit %s: %s"), tokens, 2);
    MMC_THROW();
  }

  /* Build rml objects */
  *nums     = mmc_mk_nil();
  *denoms   = mmc_mk_nil();
  *tpnoms   = mmc_mk_nil();
  *tpdenoms = mmc_mk_nil();
  *tpstrs   = mmc_mk_nil();
  /* baseunits */
  *scaleFactor = unit.scaleFactor.toReal() * pow(10,unit.prefixExpo.toReal());
  *offset = unit.offset.toReal();

  vector<Rational>::reverse_iterator rii;
  for(rii=unit.unitVec.rbegin(); rii!=unit.unitVec.rend(); ++rii) {
    *nums = mmc_mk_cons(mmc_mk_icon(rii->num),*nums);
    *denoms = mmc_mk_cons(mmc_mk_icon(rii->denom),*denoms);
  }
  /* type parameters*/
  map<string,Rational>::reverse_iterator rii2;
  for(rii2=unit.typeParamVec.rbegin(); rii2!=unit.typeParamVec.rend(); ++rii2) {
    *tpnoms = mmc_mk_cons(mmc_mk_icon(rii2->second.num),*tpnoms);
    *tpdenoms = mmc_mk_cons(mmc_mk_icon(rii2->second.denom),*tpdenoms);
    *tpstrs = mmc_mk_cons(mmc_mk_scon((char*)rii2->first.c_str()),*tpstrs);
  }
}

} // extern "C"

