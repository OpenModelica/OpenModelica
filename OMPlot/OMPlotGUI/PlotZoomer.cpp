/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linkoping University,
 * Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
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
 * from Linkoping University, either from the above address,
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
 * Main Author 2011: Adeel Asghar
 *
 */

#include "PlotZoomer.h"

using namespace OMPlot;

PlotZoomer::PlotZoomer(int xAxis, int yAxis, QwtPlotCanvas *pParent, bool doReplot)
    : QwtPlotZoomer(xAxis, yAxis, pParent, doReplot)
{
    setSelectionFlags(QwtPicker::DragSelection | QwtPicker::CornerToCorner);
    setTrackerMode(QwtPicker::AlwaysOn);
    setRubberBand(QwtPicker::RectRubberBand);
    setRubberBandPen(QPen(Qt::black));

    // RightButton: zoom out by 1
    // Ctrl+RightButton: zoom out to full size

#if QT_VERSION < 0x040000
    setMousePattern(QwtEventPattern::MouseSelect2,
        Qt::RightButton, Qt::ControlButton);
#else
    setMousePattern(QwtEventPattern::MouseSelect2,
        Qt::RightButton, Qt::ControlModifier);
#endif
    setMousePattern(QwtEventPattern::MouseSelect3,
        Qt::RightButton);
}

PlotZoomer::~PlotZoomer()
{

}

