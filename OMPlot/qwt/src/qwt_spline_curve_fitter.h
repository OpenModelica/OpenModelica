/* -*- mode: C++ ; c-file-style: "stroustrup" -*- *****************************
 * Qwt Widget Library
 * Copyright (C) 1997   Josef Wilgen
 * Copyright (C) 2002   Uwe Rathmann
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the Qwt License, Version 1.0
 *****************************************************************************/

#ifndef QWT_SPLINE_CURVE_FITTER_H
#define QWT_SPLINE_CURVE_FITTER_H

#include "qwt_curve_fitter.h"

/*!
  \brief A curve fitter using cubic splines
  \sa QwtSpline
*/
class QWT_EXPORT QwtSplineCurveFitter: public QwtCurveFitter
{
public:
    QwtSplineCurveFitter();
    virtual ~QwtSplineCurveFitter();

    virtual QPolygonF fitCurve( const QPolygonF & ) const;
    virtual QPainterPath fitCurvePath( const QPolygonF & ) const;
};

#endif
