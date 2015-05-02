/* -*- mode: C++ ; c-file-style: "stroustrup" -*- *****************************
 * Qwt Widget Library
 * Copyright (C) 1997   Josef Wilgen
 * Copyright (C) 2002   Uwe Rathmann
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the Qwt License, Version 1.0
 *****************************************************************************/

#ifndef QWT_PLOT_CANVAS_H
#define QWT_PLOT_CANVAS_H

#include "qwt_global.h"
#include <qframe.h>
#include <qpainterpath.h>

class QwtPlot;
class QPixmap;

/*!
  \brief Canvas of a QwtPlot.
  
   Canvas is the widget where all plot items are displayed

  \sa QwtPlot::setCanvas(), QwtPlotGLCanvas
*/
class QWT_EXPORT QwtPlotCanvas : public QFrame
{
    Q_OBJECT

    Q_PROPERTY( double borderRadius READ borderRadius WRITE setBorderRadius )

public:

    /*!
      \brief Paint attributes

      The default setting enables BackingStore and Opaque.

      \sa setPaintAttribute(), testPaintAttribute()
     */
    enum PaintAttribute
    {
        /*!
          \brief Paint double buffered reusing the content 
                 of the pixmap buffer when possible. 

          Using a backing store might improve the performance
          significantly, when working with widget overlays ( like rubber bands ).
          Disabling the cache might improve the performance for
          incremental paints (using QwtPlotDirectPainter ).

          \sa backingStore(), invalidateBackingStore()
         */
        BackingStore = 1,

        /*!
          \brief Try to fill the complete contents rectangle
                 of the plot canvas

          When using styled backgrounds Qt assumes, that the
          canvas doesn't fill its area completely 
          ( f.e because of rounded borders ) and fills the area
          below the canvas. When this is done with gradients it might
          result in a serious performance bottleneck - depending on the size.

          When the Opaque attribute is enabled the canvas tries to
          identify the gaps with some heuristics and to fill those only. 

          \warning Will not work for semitransparent backgrounds 
         */
        Opaque       = 2,

        /*!
          \brief Try to improve painting of styled backgrounds

          QwtPlotCanvas supports the box model attributes for
          customizing the layout with style sheets. Unfortunately
          the design of Qt style sheets has no concept how to
          handle backgrounds with rounded corners - beside of padding.

          When HackStyledBackground is enabled the plot canvas tries
          to separate the background from the background border
          by reverse engineering to paint the background before and
          the border after the plot items. In this order the border
          gets perfectly antialiased and you can avoid some pixel
          artifacts in the corners.
         */
        HackStyledBackground = 4,

        /*!
          When ImmediatePaint is set replot() calls repaint()
          instead of update().

          \sa replot(), QWidget::repaint(), QWidget::update()
         */
        ImmediatePaint = 8,

        /*!
          \brief Render the canvas via an OpenGL buffer

          In OpenGL mode the plot scene will be rendered to a temporary 
          OpenGL buffer ( pixel buffer with Qt4, frame buffer object for Qt >= 5 ), 
          that will be translated to a QImage afterwards. 
          Then this image will be painted to the canvas.

          This mode might be useful for "heavy" plots on platforms to achieve 
          hardware acceleration on platforms, where the raster paint engine 
          ( = software renderer ) ould be used otherwise.
          But the penalty of copying out the image makes this mode less optimal for
          "normal" plots.

          On a hardware accelerated graphics system ( f.e. Qt4/X11 "native" ) 
          using this mode does not make much sense. Unfortunately those systems have 
          been removed from Qt5.

          \note Using QwtPlotGLCanvas is an hardware accelerated alternative without 
                suffering from the extra roundtrip of the rendered image. But this 
                type of canvas does not have a backing store, that helps to avoid
                replots in combination with of overlay widgets ( f.e the 
                rubberband of a zoomer ).

          \note The OpenGLBuffer mode has no effect, when "QwtOpenGL" has been disabled in 
                qwtconfig.pri.

          \sa QwtPlotGLCanvas
         */
        OpenGLBuffer = 16
    };

    //! Paint attributes
    typedef QFlags<PaintAttribute> PaintAttributes;

    /*!
      \brief Focus indicator
      The default setting is NoFocusIndicator
      \sa setFocusIndicator(), focusIndicator(), paintFocus()
    */

    enum FocusIndicator
    {
        //! Don't paint a focus indicator
        NoFocusIndicator,

        /*!
          The focus is related to the complete canvas.
          Paint the focus indicator using paintFocus()
         */
        CanvasFocusIndicator,

        /*!
          The focus is related to an item (curve, point, ...) on
          the canvas. It is up to the application to display a
          focus indication using f.e. highlighting.
         */
        ItemFocusIndicator
    };

    explicit QwtPlotCanvas( QwtPlot * = NULL );
    virtual ~QwtPlotCanvas();

    QwtPlot *plot();
    const QwtPlot *plot() const;

    void setFocusIndicator( FocusIndicator );
    FocusIndicator focusIndicator() const;

    void setBorderRadius( double );
    double borderRadius() const;

    void setPaintAttribute( PaintAttribute, bool on = true );
    bool testPaintAttribute( PaintAttribute ) const;

    const QPixmap *backingStore() const;
    void invalidateBackingStore();

    virtual bool event( QEvent * );

    Q_INVOKABLE QPainterPath borderPath( const QRect & ) const;

public Q_SLOTS:
    void replot();

protected:
    virtual void paintEvent( QPaintEvent * );
    virtual void resizeEvent( QResizeEvent * );

    virtual void drawFocusIndicator( QPainter * );
    virtual void drawBorder( QPainter * );

    void updateStyleSheetInfo();

private:
    void drawCanvas( QPainter *, bool withBackground );

    class PrivateData;
    PrivateData *d_data;
};

Q_DECLARE_OPERATORS_FOR_FLAGS( QwtPlotCanvas::PaintAttributes )

#endif
