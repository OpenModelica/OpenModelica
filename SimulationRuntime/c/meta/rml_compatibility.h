/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/* File: rml_compatibility.h
 * Description: This is a compatibility header for old RML macros when bootstrapping.
 */

#ifndef OMC_RML_COMPAT_H_
#define OMC_RML_COMPAT_H_

#define mk_icon mmc_mk_icon
#define mk_rcon mmc_mk_rcon
#define mk_bcon mmc_mk_bcon
#define mk_scon mmc_mk_scon
#define mk_nil  mmc_mk_nil
#define mk_cons mmc_mk_cons
#define mk_some mmc_mk_some
#define mk_none mmc_mk_none
#define mk_box2 mmc_mk_box2
#define RML_FALSE MMC_FALSE
#define RML_TRUE MMC_TRUE
#define RML_SIZE_INT MMC_SIZE_INT
#define RML_TAGFIXNUM MMC_TAGFIXNUM
#define RML_IMMEDIATE MMC_IMMEDIATE
#define RML_GETHDR MMC_GETHDR
#define RML_UNTAGPTR MMC_UNTAGPTR
#define RML_STRUCTHDR(X,Y) MMC_STRUCTHDR(X+1,Y)
#define RML_NUM_ARGS 32
#define RML_CAR MMC_CAR
#define RML_CDR MMC_CDR
#define RML_HDRCTOR MMC_HDRCTOR
#define RML_STRUCTDATA MMC_STRUCTDATA
#define RML_HDRSTRLEN MMC_HDRSTRLEN
#define RML_STRINGDATA MMC_STRINGDATA
#define RML_UNTAGFIXNUM MMC_UNTAGFIXNUM
#define RML_NILHDR MMC_NILHDR
#define rml_prim_get_real mmc_prim_get_real
#define RML_REALHDR MMC_REALHDR
#define RML_HDRISSTRING MMC_HDRISSTRING
#define RML_HDRSLOTS MMC_HDRSLOTS
#define RML_FETCH MMC_FETCH
#define RML_OFFSET MMC_OFFSET
#define RML_CONSHDR MMC_CONSHDR

/* For external functions, since I was stupid and put the
record_description as index 0 instead of n-1 :) */
#define UNBOX_OFFSET 1


struct rml_struct {
    mmc_uint_t header;  /* MMC_STRUCTHDR(slots,ctor) */
    void *data[1];  /* `slots' elements */
};


#endif
