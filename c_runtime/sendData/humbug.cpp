/*
------------------------------------------------------------------------------------
This file is part of OpenModelica.

Copyright (c) 1997-2007, Linköpings universitet,
Department of Computer and Information Science, PELAB
See also: www.ida.liu.se/projects/OpenModelica

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

* Neither the name of Linköpings universitet nor the names of its contributors
may be used to endorse or promote products derived from this software without
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

For more information about the Qt-library visit TrollTech:s webpage regarding
licence: http://www.trolltech.com/products/qt/licensing.html

------------------------------------------------------------------------------------
*/

#include <iostream>

//IAEX headers
#include "humbug.h"

using namespace std;

void errmsg()
{
    cerr << "OMC is compiled without Qt. Check the QTHOME environment variable and recompile." << endl;
}

bool Static::enabled_ = false;

bool ellipse(double x0, double y0, double x1, double y1, const char* color, int colorR, int colorG, int colorB, const char* fillColor, int fillColorR, int fillColorG, int fillColorB)
{

	errmsg();
	return true;
}

bool rect(double x0, double y0, double x1, double y1, const char* color, int colorR, int colorG, int colorB, const char* fillColor, int fillColorR, int fillColorG, int fillColorB)
{


	errmsg();
	return true;
}

bool line(double x0, double y0, double x1, double y1, const char* color, int colorR, int colorG, int colorB, const char* fillColor, int fillColorR, int fillColorG, int fillColorB)
{
	errmsg();
	return true;
}


bool hold(int status)
{

	errmsg();
	return true;
}

bool pltWait(unsigned long msecs)
{

	errmsg();
	return true;
}

void emulateStreamData(const char* data, int port, const char* title, const char* xLabel, const char* yLabel, const char* interpolation5, int legend, int grid, double xMin, double xMax, double yMin, double yMax, int logX, int logY, int drawPoints, const char* range)
{
	errmsg();

}

bool plt(const char* var, const char* model, const char* title, const char* xLabel, const char* yLabel, bool legend, bool grid, double xmin, double xmax, double ymin, double ymax, bool logX, bool logY, const char* interpolation, bool drawPoints, const char* range)
{
	errmsg();
        return true;
}

void setVariableFilter(const char* variables)
{
	errmsg();
        return;
}

void setDataPort(int port)
{
	errmsg();
        return;
}

void enableSendData(int enable)
{
	errmsg();
        return;
}

	//void initSendData(int variableCount, const char* variableNames);
void initSendData(int variableCount1, int variableCount2, char** statesNames, char** stateDerivativesNames,  char** algebraicsNames)
{
	errmsg();
        return;
}

void sendPacket(const char* data)
{
	errmsg();
        return;
}


void closeSendData()
{
	errmsg();
        return;
}

bool pltTable(double*, size_t r, size_t c) //, const char*, int size);
{
	errmsg();
        return true;
}	

bool Static::enabled()
{
	return false;	
}
