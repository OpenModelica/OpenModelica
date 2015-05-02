/* -*- mode: C++ ; c-file-style: "stroustrup" -*- *****************************
 * Qwt Widget Library
 * Copyright (C) 1997   Josef Wilgen
 * Copyright (C) 2002   Uwe Rathmann
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the Qwt License, Version 1.0
 *****************************************************************************/

#ifndef QWT_BEZIER_H
#define QWT_BEZIER_H 1

#include "qwt_global.h"
#include <qpolygon.h>
#include <qline.h>
#include <qpainterpath.h>

namespace QwtBezier
{
    QWT_EXPORT QPolygonF polygon( const QPolygonF &, double distance );
    QWT_EXPORT QPainterPath path( const QPolygonF &, bool isClosed = false );
};

#endif
