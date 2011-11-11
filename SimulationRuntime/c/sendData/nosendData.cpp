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


#include "sendData.h"



bool ellipse(double x0, double y0, double x1, double y1, const char* color, int colorR, int colorG, int colorB, const char* fillColor, int fillColorR, int fillColorG, int fillColorB)
{
  return true;
}

bool rect(double x0, double y0, double x1, double y1, const char* color, int colorR, int colorG, int colorB, const char* fillColor, int fillColorR, int fillColorG, int fillColorB)
{
  return true;
}

bool line(double x0, double y0, double x1, double y1, const char* color, int colorR, int colorG, int colorB, const char* fillColor, int fillColorR, int fillColorG, int fillColorB)
{
  return true;
}


bool hold(int status)
{
  return true;
}

bool pltWait(unsigned long msecs)
{
  return true;
}

bool pltTable(double* table, size_t r, size_t c) //, const char* legend, int size)
{
  return false;
}


void setDataPort(int port)
{
}

void enableSendData(int enable)
{
}

void initSendData(int variableCount, const struct omc_varInfo** names)
{
}


void sendPacket(const char* data)
{
}

void closeSendData()
{
}

void emulateStreamData(const char* data, const char* title, const char* xLabel, const char* yLabel, const char* interpolation5, int legend, int grid, int logX, int logY, int drawPoints, const char* range)
{
}



bool plt(const char* var, const char* model, const char* title, const char* xLabel, const char* yLabel, bool legend, bool grid, bool logX, bool logY, const char* interpolation, bool drawPoints, const char* range)
{
  return true;
}


int getVariableListSize(const char* model)
{
  return 0;
}

bool getVariableList(const char* model, char* lst)
{
  return true;
}


void emulateStreamData2(const char *info, const char* data, int port)
{
}

