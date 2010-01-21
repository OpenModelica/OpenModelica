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
 *
 * For more information about the Qt-library visit TrollTech:s webpage regarding
 * licence: http://www.trolltech.com/products/qt/licensing.html
 *
 */

#include <iostream>

//IAEX headers
#include "humbug.h"

using namespace std;

void _errmesg()
{
    cerr << "OMC is compiled without Qt. Check the QTHOME environment variable and recompile." << endl;
}

bool Static::enabled_ = false;

bool ellipse(double x0, double y0, double x1, double y1, const char* color, int colorR, int colorG, int colorB, const char* fillColor, int fillColorR, int fillColorG, int fillColorB)
{

	_errmesg();
	return true;
}

bool rect(double x0, double y0, double x1, double y1, const char* color, int colorR, int colorG, int colorB, const char* fillColor, int fillColorR, int fillColorG, int fillColorB)
{


	_errmesg();
	return true;
}

bool line(double x0, double y0, double x1, double y1, const char* color, int colorR, int colorG, int colorB, const char* fillColor, int fillColorR, int fillColorG, int fillColorB)
{
	_errmesg();
	return true;
}


bool hold(int status)
{

	_errmesg();
	return true;
}

bool pltWait(unsigned long msecs)
{

	_errmesg();
	return true;
}

void emulateStreamData(const char* data, const char* title, const char* xLabel, const char* yLabel, const char* interpolation5, int legend, int grid, int logX, int logY, int drawPoints, const char* range)
{
	_errmesg();
}

bool plt(const char* var, const char* model, const char* title, const char* xLabel, const char* yLabel, bool legend, bool grid, double xmin, double xmax, double ymin, double ymax, bool logX, bool logY, const char* interpolation, bool drawPoints, const char* range)
{
	_errmesg();
        return true;
}

void setVariableFilter(const char* variables)
{
	_errmesg();
        return;
}

void setDataPort(int port)
{
	_errmesg();
        return;
}

void enableSendData(int enable)
{
	_errmesg();
        return;
}

	//void initSendData(int variableCount, const char* variableNames);
void initSendData(int variableCount1, int variableCount2, char** statesNames, char** stateDerivativesNames,  char** algebraicsNames)
{
	_errmesg();
        return;
}

void sendPacket(const char* data)
{
	_errmesg();
        return;
}


void closeSendData()
{
	_errmesg();
        return;
}

bool pltTable(double*, size_t r, size_t c) //, const char*, int size);
{
	_errmesg();
        return true;
}

bool Static::enabled()
{
	return false;
}


int getVariableListSize(const char* model)
{
	_errmesg();
	return 0;

}

bool getVariableList(const char* model, char* lst)
{
	_errmesg();
	return false;

}

void emulateStreamData2(const char *info, const char* data, int port)
{
  _errmesg();
}
