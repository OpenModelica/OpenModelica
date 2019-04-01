/* -*- mode: C++ ; c-file-style: "stroustrup" -*- *****************************
 * Qwt Widget Library
 * Copyright (C) 1997   Josef Wilgen
 * Copyright (C) 2002   Uwe Rathmann
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the Qwt License, Version 1.0
 *****************************************************************************/

#ifndef QWT_SPLINE_H
#define QWT_SPLINE_H 1

#include "qwt_global.h"
#include <qpolygon.h>
#include <qpainterpath.h>

namespace QwtSplineAkima
{
    QWT_EXPORT QPainterPath path( const QPolygonF & );
    QWT_EXPORT QPainterPath path( const QPolygonF &,
        double slopeStart, double slopeEnd );
}

namespace QwtSplineHarmonicMean
{
    QWT_EXPORT QPainterPath path( const QPolygonF & );
    QWT_EXPORT QPainterPath path( const QPolygonF &, 
        double slopeStart, double slopeEnd );
}

namespace QwtSplineNatural
{
    // derivatives at each point
    QWT_EXPORT QVector<double> derivatives( const QPolygonF & );

    QWT_EXPORT QPolygonF polygon( const QPolygonF &, int numPoints );

    // interpolated spline as bezier curve
    QWT_EXPORT QPainterPath path( const QPolygonF & );
}

#endif
