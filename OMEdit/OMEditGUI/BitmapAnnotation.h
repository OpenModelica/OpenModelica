/*
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
 * Main Authors 2010: Syed Adeel Asghar, Sonia Tariq
 *
 */

//! @file   BitmapAnnotation.h
//! @author harka011
//! @date   2011-02-01

//! @brief Class to create the bitmap shape

#ifndef BITMAPANNOTATION_H
#define BITMAPANNOTATION_H

#include "ShapeAnnotation.h"
#include "Component.h"

class OMCProxy;

class  BitmapAnnotation : public ShapeAnnotation
{
    Q_OBJECT
public:    
    BitmapAnnotation(QString shape, Component *pParent = 0);
    BitmapAnnotation(GraphicsView *graphicsView, QGraphicsItem *pParent = 0);
    BitmapAnnotation(QString shape, GraphicsView *graphicsView, QGraphicsItem *pParent = 0);

    void addPoint(QPointF point);
    void drawRectangleCornerItems();    
    void updateEndPoint(QPointF point);
    void setFileName(QString fileName);    
    void updateAnnotation();
    void setImageSource(QString imageSource);
    void parseShapeAnnotation(QString shape, OMCProxy *omc);

    QString getFileName();
    QString getShapeAnnotation();

    QRectF boundingRect() const;
    void paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget = 0);
    QPainterPath shape() const;

    Component *mpComponent;
private:
    QString mFileName;
    QString mImageSource;

public slots:
    void updatePoint(int index, QPointF point);
};

//! @brief The popup when you create a bitmap shape

class BitmapWidget : public QDialog
{
    Q_OBJECT
public:
    BitmapWidget(BitmapAnnotation *pBitmapShape, MainWindow *parent = 0);

    void setUpForm();
    void show();

    MainWindow *mpParentMainWindow;
private:
   QLineEdit *mpBrowseBox;
   QPushButton *mpBrowseButton;
   QPushButton *mpOkButton;
   QPushButton *mpCancelButton;
   QDialogButtonBox *mpButtonBox;
   QCheckBox *mpCheckBox;
   BitmapAnnotation *mpBitmapAnnotation;
public slots:
    void edit();
    void browse();
};

#endif // BITMAPANNOTATION_H
