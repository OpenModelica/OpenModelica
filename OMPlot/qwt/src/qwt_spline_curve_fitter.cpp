/* -*- mode: C++ ; c-file-style: "stroustrup" -*- *****************************
 * Qwt Widget Library
 * Copyright (C) 1997   Josef Wilgen
 * Copyright (C) 2002   Uwe Rathmann
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the Qwt License, Version 1.0
 *****************************************************************************/

#include "qwt_spline_curve_fitter.h"
#include "qwt_bezier.h"

//! Constructor
QwtSplineCurveFitter::QwtSplineCurveFitter():
    QwtCurveFitter( QwtCurveFitter::Path )
{
}

//! Destructor
QwtSplineCurveFitter::~QwtSplineCurveFitter()
{
}

/*!
  Find a curve which has the best fit to a series of data points

  \param points Series of data points
  \return Fitted Curve

  \sa fitCurvePath()
*/
QPolygonF QwtSplineCurveFitter::fitCurve( const QPolygonF &points ) const
{
    const QPainterPath path = fitCurvePath( points );

    const QList<QPolygonF> subPaths = fitCurvePath( points ).toSubpathPolygons();
    if ( subPaths.size() == 1 )
        subPaths.first();

    return QPolygonF();
}

/*!
  Find a curve path which has the best fit to a series of data points

  \param points Series of data points
  \return Fitted Curve

  \sa fitCurve()
*/
QPainterPath QwtSplineCurveFitter::fitCurvePath( const QPolygonF &points ) const
{
    return QwtBezier::path( points );
}
