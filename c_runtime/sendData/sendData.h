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

#ifndef SENDDATA_H
#define SENDDATA_H

//Qt headers
//#include <QApplication>
#include <QtNetwork/QTcpSocket>
//#include <QThread>

//Std headers
//#include <iostream>

#ifdef __cplusplus
using namespace std;
extern "C"
{
#endif

	void emulateStreamData(const char* data, int port=7778, const char* title="Plot by OpenModelica", const char* xLabel = "time", const char* yLabel = "", const char* interpolation="linear", int legend = 1, int grid = 1, double xMin=0, double xMax=0, double yMin=0, double yMax=0, int logX=0, int logY=0, int drawPoints = 1, const char* range = "0.0,0.0 0.0,0.0");

	bool plt(const char* var, const char* mdl, const char* title, const char* xLabel, const char* yLabel, bool legend, bool grid, double xmin, double xmax, double ymin, double ymax, bool logX, bool logY, const char* interpolation, bool drawPoints, const char* range);
	bool pltParametric(const char*, const char*, const char*);
	bool clear();
	bool ellipse(double x0, double y0, double x1, double y1, const char* color, int colorR, int colorG, int colorB, const char* fillColor, int fillColorR, int fillColorG, int fillColorB);
	bool rect(double x0, double y0, double x1, double y1, const char* color, int colorR, int colorG, int colorB, const char* fillColor, int fillColorR, int fillColorG, int fillColorB);
	bool line(double x0, double y0, double x1, double y1, const char* color, int colorR, int colorG, int colorB, const char* fillColor, int fillColorR, int fillColorG, int fillColorB);

	bool hold(int = 1);
	bool pltWait(unsigned long msecs);

	QColor stringToColor(QString str_);
	QColor getColor(const char* color, int colorR, int colorG, int colorB);

#ifdef __cplusplus
}
#endif

class Connection
{
public:
	Connection();
	~Connection();

	QTcpSocket* newConnection();

private:
	QTcpSocket* socket;
	QApplication* app;
};

#endif
