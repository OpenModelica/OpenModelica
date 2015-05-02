/* -*- mode: C++ ; c-file-style: "stroustrup" -*- *****************************
 * Qwt Widget Library
 * Copyright (C) 1997   Josef Wilgen
 * Copyright (C) 2002   Uwe Rathmann
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the Qwt License, Version 1.0
 *****************************************************************************/

#include "qwt_bezier.h"
#include <qmath.h>

static inline double qwtLineLength( const QPointF &p1, const QPointF &p2 )
{
   const double dx = p1.x() - p2.x();
   const double dy = p1.y() - p2.y();

   return qSqrt( dx * dx + dy * dy );
}

#if 0
static inline void qwtBezierInterpolate2(
    const QPointF &p1, const QPointF &p2,
    const QPointF &p3, const QPointF &p4,
    double &s1, double &s2 )
{
    const double d12 = qwtLineLength( p1, p2 );
    const double d23 = qwtLineLength( p2, p3 );
    const double d34 = qwtLineLength( p3, p4 ); 
    
    s1 = 0.5 * ( 1.0 - d12 / ( d12 + d23 ) );
    s2 = 0.5 * ( d23 / ( d23 + d34 ) );
}
#endif

static inline void qwtBezierInterpolate(
    double d13, double d23, double d24,
    const QPointF &p1, const QPointF &p2, 
    const QPointF &p3, const QPointF &p4, 
    double &s1, double &s2 )
{
    const bool b1 = ( d13 / 3.0 ) < d23;
    const bool b2 = ( d24 / 3.0 ) < d23;

    if ( b1 & b2 )
    {
        s1 = ( p1 != p2 ) ? ( 1.0 / 3.0 ) : ( 2.0 / 3.0 );
        s2 = ( p3 != p4 ) ? ( 1.0 / 3.0 ) : ( 2.0 / 3.0 );
    }
    else
    {
        s1 = d23 / ( b1 ? d24 : d13 );
        s2 = d23 / ( b2 ? d13 : d24 );
    }
}

static inline void qwtBezierControlPoints( 
    const QPointF &p1, const QPointF &p2,
    const QPointF &p3, const QPointF &p4,
    QPointF &cp1, QPointF &cp2 )
{
    const double d13 = qwtLineLength(p1, p3);
    const double d23 = qwtLineLength(p2, p3);
    const double d24 = qwtLineLength(p2, p4);

    double s1, s2;
    qwtBezierInterpolate( d13, d23, d24, p1, p2, p3, p4, s1, s2 );

    const double smoothness = 1.0;
    cp1 = p2 + 0.5 * ( p3 - p1 ) * s1 * smoothness;
    cp2 = p3 - 0.5 * ( p4 - p2 ) * s2 * smoothness;
}

static inline QPointF qwtBezierPoint( const QPointF &p1,
    const QPointF &cp1, const QPointF &cp2, const QPointF &p2, double t )
{
    const double d1 = 3.0 * t;
    const double d2 = 3.0 * t * t;
    const double d3 = t * t * t;
    const double s  = 1.0 - t;

    const double x = (( s * p1.x() + d1 * cp1.x() ) * s + d2 * cp2.x() ) * s + d3 * p2.x();
    const double y = (( s * p1.y() + d1 * cp1.y() ) * s + d2 * cp2.y() ) * s + d3 * p2.y();

    return QPointF( x, y );
}

QPolygonF QwtBezier::polygon( const QPolygonF& points, double dist )
{
    const int size = points.size();
    if ( size <= 2 || dist <= 0.0 )
        return points;

    const QPointF *p = points.constData();

    QPointF cp1, cp2;

    QPolygonF fittedPoints;
    fittedPoints += p[0];

    for ( int i = 0; i < size - 1; i++ )
    {
        const double length = qwtLineLength( p[i], p[i + 1] );
        if ( dist < length )
        {
            if ( i == 0 )
            {
                qwtBezierControlPoints( p[0], p[0], p[1], p[2], cp1, cp2 );
            }
            else if ( i == points.size() - 2 )
            {
                qwtBezierControlPoints( p[size - 3], p[size - 2], 
                    p[size - 1], p[size - 1], cp1, cp2 );
            }
            else
            {
                qwtBezierControlPoints( p[i-1], p[i], p[i+1], p[i+2], cp1, cp2);
            }

            const double off = dist / length;
            for( double t = off; t < 1.0; t += off ) 
            {
                fittedPoints += qwtBezierPoint( p[i], cp1, cp2, p[i + 1], t );
            }
        }

        fittedPoints += p[i + 1];
    }

    return fittedPoints;
}


static inline void qwtCubicTo( const QPointF &p1, const QPointF &p2, 
    const QPointF &p3, const QPointF &p4, QPainterPath &path )
{
    const double d13 = qwtLineLength(p1, p3);
    const double d24 = qwtLineLength(p2, p4);
    const double d23 = qwtLineLength(p2, p3);

    double s1, s2;
    qwtBezierInterpolate( d13, d23, d24, p1, p2, p3, p4, s1, s2 );

    const double smoothness = 1.0;
    const QPointF cp1 = p2 + 0.5 * ( p3 - p1 ) * s1 * smoothness;
    const QPointF cp2 = p3 - 0.5 * ( p4 - p2 ) * s2 * smoothness;

    path.cubicTo( cp1, cp2, p3 );
}

#define NEW 0

QPainterPath QwtBezier::path( const QPolygonF &points, bool isClosed )
{
    const double smoothness = 1.0;

    const int size = points.size();

    QPainterPath path;
    if ( size == 0 )
        return path;

    const QPointF *p = points.constData();

    path.moveTo( p[0] );
    if ( size == 1 )
        return path;

    if ( size == 2 )
    {
        path.lineTo( p[1] );
    }
    else
    {
        if ( isClosed )
        {
            qwtCubicTo( p[size - 1], p[0], p[1], p[2], path );
        }
        else
        {
            qwtCubicTo( p[0], p[0], p[1], p[2], path );
        }

        const double a = 0.5 * smoothness;

        QPointF vec1 = ( p[2] - p[0] ) * a;

#if NEW
        double d12 = qwtLineLength(p[0], p[1]);
        double d23 = qwtLineLength(p[1], p[2]);
        double s1 = 1.0 - d12 / ( d12 + d23 );
#else
        double d13 = qwtLineLength(p[0], p[2]);
#endif

        for ( int i = 1; i < size - 2; i++ )
        {
#if NEW
            const double d34 = qwtLineLength(p[i+1], p[i+2]);
            const double s2 = d23 / ( d23 + d34 );
#else
            const double d23 = qwtLineLength(p[i], p[i+1]);
            const double d24 = qwtLineLength(p[i], p[i+2]);

            double s1, s2;
            qwtBezierInterpolate( d13, d23, d24, p[i-1], p[i], p[i+1], p[i+2], s1, s2 );
#endif

            const QPointF vec2 = ( p[i+2] - p[i] ) * a;

            const QPointF cp1 = p[i] + vec1 * s1;
            const QPointF cp2 = p[i+1] - vec2 * s2;

            path.cubicTo( cp1, cp2, p[i+1] );

#if NEW
            d12 = d23;
            d23 = d34;
            s1 = 1.0 - s2;
#else
            d13 = d24;
#endif
            vec1 = vec2;
        }

        if ( isClosed )
        {
            qwtCubicTo( p[size - 3], p[size - 2], p[size - 1], p[0], path );
            qwtCubicTo( p[size - 2], p[size - 1], p[0], p[1], path );
        }
        else
        {
            qwtCubicTo( p[size - 3], p[size - 2], p[size - 1], p[size - 1], path );
        }
    }

    return path;
}
