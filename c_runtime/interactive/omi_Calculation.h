/*
 * OpenModelica Interactive (Ver 0.7)
 * Last Modification: 3. October 2009
 *
 * Developed by:
 * EADS IW Germany
 * Developer: Parham Vasaiely
 * Contact: vasaie_p@informatik.haw-hamburg.de
 *
 * File description: omi_Calculation.h
 *
 * Full specification available in the bachelor thesis of Parham Vasaiely
 * "Interactive Simulation of SysML Models using Modelica" (Chapter 5)
 */

//#ifndef _MY_SIMULATIONCALCULATION_H
#define _MY_SIMULATIONCALCULATION_H

#include "thread.h"

extern bool* p_forZero;
THREAD_RET_TYPE threadSimulationCalculation(THREAD_PARAM_TYPE);
