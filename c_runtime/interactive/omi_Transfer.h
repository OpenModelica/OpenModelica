/*
 * OpenModelica Interactive (Ver 0.7)
 * Last Modification: 3. October 2009
 *
 * Developed by:
 * EADS IW Germany
 * Developer: Parham Vasaiely
 * Contact: vasaie_p@informatik.haw-hamburg.de
 *
 * File description: omi_Transfer.h
 *
 * Full specification available in the bachelor thesis of Parham Vasaiely
 * "Interactive Simulation of SysML Models using Modelica" (Chapter 5)
 */

#include <string>
#include "thread.h"

using namespace std;

//#ifndef _MY_SIMULATIONTRANSFER_H
#define _MY_SIMULATIONTRANSFER_H

//****** Network Configuration ******
void setTransferIPandPort(string, int);
void resetTransferIPandPortToDefault(void);
string getTransferActIP(void);
int getTransferActPort(void);

THREAD_RET_TYPE threadClientTransfer(THREAD_PARAM_TYPE);
