/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#include "MainWindow.h"
#include "LineAnnotation.h"
#include "Modeling/ItemDelegate.h"
#include "Modeling/Commands.h"
#include "OMS/BusDialog.h"

#include <QMessageBox>

LineAnnotation::LineAnnotation(QString annotation, GraphicsView *pGraphicsView)
  : ShapeAnnotation(false, pGraphicsView, 0)
{
  setLineType(LineAnnotation::ShapeType);
  setStartComponent(0);
  setEndComponent(0);
  setCondition("");
  setImmediate(true);
  setReset(true);
  setSynchronize(false);
  setPriority(1);
  mpTextAnnotation = 0;
  setOldAnnotation("");
  setDelay("");
  setZf("");
  setZfr("");
  setAlpha("");
  setOMSConnectionType(oms_connection_single);
  setActiveState(false);
  // set the default values
  GraphicItem::setDefaults();
  ShapeAnnotation::setDefaults();
  // set users default value by reading the settings file.
  ShapeAnnotation::setUserDefaults();
  parseShapeAnnotation(annotation);
  setShapeFlags(true);
}

LineAnnotation::LineAnnotation(ShapeAnnotation *pShapeAnnotation, Component *pParent)
  : ShapeAnnotation(pParent)
{
  updateShape(pShapeAnnotation);
  initUpdateVisible(); // DynamicSelect for visible attribute
  setLineType(LineAnnotation::ComponentType);
  setStartComponent(0);
  setEndComponent(0);
  setCondition("");
  setImmediate(true);
  setReset(true);
  setSynchronize(false);
  setPriority(1);
  mpTextAnnotation = 0;
  setOldAnnotation("");
  setDelay("");
  setZf("");
  setZfr("");
  setAlpha("");
  setOMSConnectionType(oms_connection_single);
  setActiveState(false);
  setPos(mOrigin);
  setRotation(mRotation);
  connect(pShapeAnnotation, SIGNAL(updateReferenceShapes()), pShapeAnnotation, SIGNAL(changed()));
  connect(pShapeAnnotation, SIGNAL(added()), this, SLOT(referenceShapeAdded()));
  connect(pShapeAnnotation, SIGNAL(changed()), this, SLOT(referenceShapeChanged()));
  connect(pShapeAnnotation, SIGNAL(deleted()), this, SLOT(referenceShapeDeleted()));
}

LineAnnotation::LineAnnotation(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView)
  : ShapeAnnotation(true, pGraphicsView, 0)
{
  updateShape(pShapeAnnotation);
  setShapeFlags(true);
  mpGraphicsView->addItem(this);
  connect(pShapeAnnotation, SIGNAL(updateReferenceShapes()), pShapeAnnotation, SIGNAL(changed()));
  connect(pShapeAnnotation, SIGNAL(added()), this, SLOT(referenceShapeAdded()));
  connect(pShapeAnnotation, SIGNAL(changed()), this, SLOT(referenceShapeChanged()));
  connect(pShapeAnnotation, SIGNAL(deleted()), this, SLOT(referenceShapeDeleted()));
}

LineAnnotation::LineAnnotation(LineAnnotation::LineType lineType, Component *pStartComponent, GraphicsView *pGraphicsView)
  : ShapeAnnotation(false, pGraphicsView, 0)
{
  setFlag(QGraphicsItem::ItemIsSelectable);
  mLineType = lineType;
  setZValue(1000);
  // set the default values
  GraphicItem::setDefaults();
  ShapeAnnotation::setDefaults();
  // set the start component
  setStartComponent(pStartComponent);
  setEndComponent(0);
  setCondition("");
  setImmediate(true);
  setReset(true);
  setSynchronize(false);
  setPriority(1);
  setOMSConnectionType(oms_connection_single);
  setActiveState(false);
  if (mLineType == LineAnnotation::ConnectionType) {
    /* Use the linecolor of the first shape from icon layer of start component for the connection line.
     * Or use black color if there is no shape in the icon layer
     * Dymola is doing it the way explained above. The Modelica specification doesn't say anything about it.
     * We are also doing it the same way except that we will use the diagram layer shape if there is no shape in the icon layer.
     * If there is no shape even in diagram layer then use the default black color.
     */
    if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
      if (pStartComponent->getShapesList().size() > 0) {
        ShapeAnnotation *pShapeAnnotation = pStartComponent->getShapesList().at(0);
        mLineColor = pShapeAnnotation->getLineColor();
      }
      if (pStartComponent->getLibraryTreeItem() && pStartComponent->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
        if (!pStartComponent->getLibraryTreeItem()->getModelWidget()) {
          MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(pStartComponent->getLibraryTreeItem(), false);
        }
        ShapeAnnotation *pShapeAnnotation;
        if (pStartComponent->getLibraryTreeItem()->getModelWidget()->getIconGraphicsView()
            && pStartComponent->getLibraryTreeItem()->getModelWidget()->getIconGraphicsView()->getShapesList().size() > 0) {
          pShapeAnnotation = pStartComponent->getLibraryTreeItem()->getModelWidget()->getIconGraphicsView()->getShapesList().at(0);
          mLineColor = pShapeAnnotation->getLineColor();
        }
      }
    }
    mpTextAnnotation = 0;
  } else if (mLineType == LineAnnotation::TransitionType) {
    /* From Modelica Spec 33revision1,
     * The recommended color is {175,175,175} for transition lines.
     */
    mLineColor = QColor(175, 175, 175);
    mSmooth = StringHandler::SmoothBezier;
    QString textShape = "true, {0.0, 0.0}, 0, {95, 95, 95}, {0, 0, 0}, LinePattern.Solid, FillPattern.None, 0.25, {{-4, 4}, {-4, 10}}, \"%condition\", 10, {TextStyle.Bold}, TextAlignment.Right";
    mpTextAnnotation = new TextAnnotation(textShape, this);
  }
  // set the graphics view
  mpGraphicsView->addItem(this);
  setOldAnnotation("");

  ComponentInfo *pInfo = getStartComponent()->getComponentInfo();
  bool tlm = (pInfo->getTLMCausality() == "Bidirectional");
  int dimensions = pInfo->getDimensions();

  setDelay("1e-4");
  if(tlm && dimensions>1) {         //3D connection, use Zf and Zfr
    setZf("10000");
    setZfr("100");
    setAlpha("0.2");
  }
  else if(tlm && dimensions == 1) { //1D connection, only Zf
    setZf("10000");
    setZfr("");
    setAlpha("0.2");
  }
  else {                            //Signal connection, no TLM parameters
    setZf("");
    setZfr("");
    setAlpha("");
  }
}

LineAnnotation::LineAnnotation(QString annotation, Component *pStartComponent, Component *pEndComponent, GraphicsView *pGraphicsView)
  : ShapeAnnotation(false, pGraphicsView, 0)
{
  setFlag(QGraphicsItem::ItemIsSelectable);
  mLineType = LineAnnotation::ConnectionType;
  setZValue(1000);
  // set the default values
  GraphicItem::setDefaults();
  ShapeAnnotation::setDefaults();
  // set the start component
  setStartComponent(pStartComponent);
  // set the end component
  setEndComponent(pEndComponent);
  setCondition("");
  setImmediate(true);
  setReset(true);
  setSynchronize(false);
  setPriority(1);
  mpTextAnnotation = 0;
  setOldAnnotation("");
  setDelay("");
  setZf("");
  setZfr("");
  setAlpha("");
  setOMSConnectionType(oms_connection_single);
  setActiveState(false);
  parseShapeAnnotation(annotation);
  /* make the points relative to origin */
  QList<QPointF> points;
  for (int i = 0 ; i < mPoints.size() ; i++) {
    QPointF point = mOrigin + mPoints[i];
    points.append(point);
  }
  mPoints = points;
  mOrigin = QPointF(0, 0);
  // set the graphics view
  mpGraphicsView->addItem(this);
}

LineAnnotation::LineAnnotation(QString annotation, QString text, Component *pStartComponent, Component *pEndComponent, QString condition,
                               QString immediate, QString reset, QString synchronize, QString priority, GraphicsView *pGraphicsView)
  : ShapeAnnotation(false, pGraphicsView, 0)
{
  setFlag(QGraphicsItem::ItemIsSelectable);
  mLineType = LineAnnotation::TransitionType;
  setZValue(1000);
  // set the default values
  GraphicItem::setDefaults();
  ShapeAnnotation::setDefaults();
  // set the start component
  setStartComponent(pStartComponent);
  // set the end component
  setEndComponent(pEndComponent);
  setCondition(condition);
  setImmediate(immediate.contains("true"));
  setReset(reset.contains("true"));
  setSynchronize(synchronize.contains("true"));
  setPriority(priority.toInt());
  setOldAnnotation("");
  setDelay("");
  setZf("");
  setZfr("");
  setAlpha("");
  setOMSConnectionType(oms_connection_single);
  setActiveState(false);
  parseShapeAnnotation(annotation);
  /* make the points relative to origin */
  QList<QPointF> points;
  for (int i = 0 ; i < mPoints.size() ; i++) {
    QPointF point = mOrigin + mPoints[i];
    points.append(point);
  }
  mPoints = points;
  mOrigin = QPointF(0, 0);
  mpTextAnnotation = new TextAnnotation(text, this);
  // set the graphics view
  mpGraphicsView->addItem(this);
}

LineAnnotation::LineAnnotation(QString annotation, Component *pComponent, GraphicsView *pGraphicsView)
  : ShapeAnnotation(false, pGraphicsView, 0)
{
  setFlag(QGraphicsItem::ItemIsSelectable);
  mLineType = LineAnnotation::InitialStateType;
  setZValue(1000);
  // set the default values
  GraphicItem::setDefaults();
  ShapeAnnotation::setDefaults();
  // set the start component
  setStartComponent(pComponent);
  // set the end component
  setEndComponent(0);
  setCondition("");
  setImmediate(true);
  setReset(true);
  setSynchronize(false);
  setPriority(1);
  mpTextAnnotation = 0;
  setOldAnnotation("");
  setDelay("");
  setZf("");
  setZfr("");
  setAlpha("");
  setOMSConnectionType(oms_connection_single);
  setActiveState(false);
  parseShapeAnnotation(annotation);
  /* make the points relative to origin */
  QList<QPointF> points;
  for (int i = 0 ; i < mPoints.size() ; i++) {
    QPointF point = mOrigin + mPoints[i];
    points.append(point);
  }
  mPoints = points;
  mOrigin = QPointF(0, 0);
  // set the graphics view
  mpGraphicsView->addItem(this);
}

LineAnnotation::LineAnnotation(Component *pParent)
  : ShapeAnnotation(pParent)
{
  setLineType(LineAnnotation::ComponentType);
  setStartComponent(0);
  setEndComponent(0);
  setCondition("");
  setImmediate(true);
  setReset(true);
  setSynchronize(false);
  setPriority(1);
  mpTextAnnotation = 0;
  setOldAnnotation("");
  setDelay("");
  setZf("");
  setZfr("");
  setAlpha("");
  setOMSConnectionType(oms_connection_single);
  setActiveState(false);
  // set the default values
  GraphicItem::setDefaults();
  ShapeAnnotation::setDefaults();
  // create a red cross
  setLineColor(QColor(255, 0, 0));
  // create a red cross with points
  addPoint(QPointF(-100, -100));
  addPoint(QPointF(100, 100));
  addPoint(QPointF(-100, 100));
  addPoint(QPointF(100, -100));
  addPoint(QPointF(-100, -100));
  addPoint(QPointF(-100, 100));
  addPoint(QPointF(100, 100));
  addPoint(QPointF(100, -100));
  setPos(mOrigin);
  setRotation(mRotation);
}

LineAnnotation::LineAnnotation(GraphicsView *pGraphicsView)
  : ShapeAnnotation(true, pGraphicsView, 0)
{
  setLineType(LineAnnotation::ShapeType);
  setStartComponent(0);
  setEndComponent(0);
  setCondition("");
  setImmediate(true);
  setReset(true);
  setSynchronize(false);
  setPriority(1);
  mpTextAnnotation = 0;
  setOldAnnotation("");
  setDelay("");
  setZf("");
  setZfr("");
  setAlpha("");
  setOMSConnectionType(oms_connection_single);
  setActiveState(false);
  // set the default values
  GraphicItem::setDefaults();
  ShapeAnnotation::setDefaults();
  // set users default value by reading the settings file.
  ShapeAnnotation::setUserDefaults();
  // create a red cross
  setLineColor(QColor(255, 0, 0));
  // create a red cross with points
  addPoint(QPointF(-100, -100));
  addPoint(QPointF(100, 100));
  addPoint(QPointF(-100, 100));
  addPoint(QPointF(100, -100));
  addPoint(QPointF(-100, -100));
  addPoint(QPointF(-100, 100));
  addPoint(QPointF(100, 100));
  addPoint(QPointF(100, -100));
  setShapeFlags(true);
  mpGraphicsView->addItem(this);
}

void LineAnnotation::parseShapeAnnotation(QString annotation)
{
  GraphicItem::parseShapeAnnotation(annotation);
  // parse the shape to get the list of attributes of Line.
  QStringList list = StringHandler::getStrings(annotation);
  if (list.size() < 10) {
    return;
  }
  mPoints.clear();
  // 4th item of list contains the points.
  QStringList pointsList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(3)));
  foreach (QString point, pointsList) {
    QStringList linePoints = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(point));
    if (linePoints.size() >= 2) {
      addPoint(QPointF(linePoints.at(0).toFloat(), linePoints.at(1).toFloat()));
    }
  }
  // 5th item of list contains the color.
  QStringList colorList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(4)));
  if (colorList.size() >= 3) {
    int red, green, blue = 0;
    red = colorList.at(0).toInt();
    green = colorList.at(1).toInt();
    blue = colorList.at(2).toInt();
    mLineColor = QColor (red, green, blue);
  }
  // 6th item of list contains the Line Pattern.
  mLinePattern = StringHandler::getLinePatternType(list.at(5));
  // 7th item of list contains the Line thickness.
  mLineThickness = list.at(6).toFloat();
  // 8th item of list contains the Line Arrows.
  QStringList arrowList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(7)));
  if (arrowList.size() >= 2) {
    mArrow.replace(0, StringHandler::getArrowType(arrowList.at(0)));
    mArrow.replace(1, StringHandler::getArrowType(arrowList.at(1)));
  }
  // 9th item of list contains the Line Arrow Size.
  mArrowSize = list.at(8).toFloat();
  // 10th item of list contains the smooth.
  mSmooth = StringHandler::getSmoothType(list.at(9));
}

QPainterPath LineAnnotation::getShape() const
{
  QPainterPath path;
  if (mPoints.size() > 0) {
    // mPoints.size() is at least 1
    path.moveTo(mPoints.at(0));
    if (mSmooth) {
      if (mPoints.size() == 2) {
        // if points are only two then spline acts as simple line
        path.lineTo(mPoints.at(1));
      } else {
        for (int i = 2 ; i < mPoints.size() ; i++) {
          QPointF point3 = mPoints.at(i);
          // calculate middle points for bezier curves
          QPointF point2 = mPoints.at(i - 1);
          QPointF point1 = mPoints.at(i - 2);
          QPointF point12((point1.x() + point2.x())/2, (point1.y() + point2.y())/2);
          QPointF point23((point2.x() + point3.x())/2, (point2.y() + point3.y())/2);
          path.lineTo(point12);
          path.cubicTo(point12, point2, point23);
          // if its the last point
          if (i == mPoints.size() - 1) {
            path.lineTo(point3);
          }
        }
      }
    } else {
      for (int i = 1 ; i < mPoints.size() ; i++) {
        path.lineTo(mPoints.at(i));
      }
    }
  }
  return path;
}

QRectF LineAnnotation::boundingRect() const
{
  return shape().boundingRect();
}

QPainterPath LineAnnotation::shape() const
{
  QPainterPath path = getShape();
  return addPathStroker(path);
}

void LineAnnotation::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
  Q_UNUSED(option);
  Q_UNUSED(widget);
  if (mVisible || !mDynamicVisible.isEmpty()) {
    if (mLineType == LineAnnotation::TransitionType && mpGraphicsView->isVisualizationView()) {
      if (isActiveState()) {
        painter->setOpacity(1.0);
      } else {
        painter->setOpacity(0.2);
      }
    }
    drawLineAnnotaion(painter);
  }
}

void LineAnnotation::drawLineAnnotaion(QPainter *painter)
{
  applyLinePattern(painter);
  // draw start arrow
  if (mPoints.size() > 1) {
    /* If line is a initial state then we need to draw filled arrow.
     * From Modelica Spec 33revision1,
     * The initialState line has a filled arrow head and a bullet at the opposite end of the initial state [ as shown above ].
     */
    if (mLineType == LineAnnotation::InitialStateType) {
      drawArrow(painter, mPoints.at(0), mPoints.at(1), mArrowSize, StringHandler::ArrowFilled);
    } else {
      /* If line is a transition then we need to draw starting fork if needed.
       * From Modelica Spec 33revision1,
       * For synchronize=true, an inverse "fork" symbol is used in the beginning of the arrow [ See the rightmost transition above. ].
       */
      if (mLineType == LineAnnotation::TransitionType) {
        if (mSynchronize) {
          painter->save();
          QPolygonF polygon1 = perpendicularLine(mPoints.at(0), mPoints.at(1), 4.0);
          QPointF midPoint = (polygon1.at(0) +  polygon1.at(1)) / 2;
          QPolygonF polygon2 = perpendicularLine(midPoint, mPoints.at(0), 4.0);
          QPolygonF polygon;
          polygon << polygon1 << polygon2 << polygon1.at(0);
          painter->drawPolygon(polygon);
          painter->restore();
        }
        /* From Modelica Spec 33revision1,
         * In addition to the line defined by the points of the Line annotation, a perpendicular line is used to represent the transition.
         * This line is closer to the first point if immediate=false otherwise closer to the last point.
         */
        painter->save();
        QPolygonF polygon;
        if (mImmediate) {
          polygon = perpendicularLine(mPoints.at(mPoints.size() - 1), mPoints.at(mPoints.size() - 2), 5.0);
        } else {
          polygon = perpendicularLine(mPoints.at(0), mPoints.at(1), 5.0);
        }
        QPen pen = painter->pen();
        pen.setWidth(2);
        painter->setPen(pen);
        painter->drawLine(polygon.at(0), polygon.at(1));
        painter->restore();
      }
      drawArrow(painter, mPoints.at(0), mPoints.at(1), mArrowSize, mArrow.at(0));
    }
  }
  painter->drawPath(getShape());
  // draw end arrow
  if (mPoints.size() > 1) {
    /* If line is a transition then we need to draw ending arrow in any case.
     * From Modelica Spec 33revision1,
     * If reset=true, a filled arrow head is used otherwise an open arrow head.
     */
    if (mLineType == LineAnnotation::TransitionType) {
      drawArrow(painter, mPoints.at(mPoints.size() - 1), mPoints.at(mPoints.size() - 2), mArrowSize,
                mReset ? StringHandler::ArrowFilled : StringHandler::ArrowOpen);
    } else if (mLineType == LineAnnotation::InitialStateType) {
      /* If line is a initial state then we need to draw bullet.
       * From Modelica Spec 33revision1,
       * The initialState line has a filled arrow head and a bullet at the opposite end of the initial state [ as shown above ].
       */
      painter->save();
      painter->setBrush(QBrush(mLineColor, Qt::SolidPattern));
      painter->drawEllipse(mPoints.at(mPoints.size() - 1), 2, 2);
      painter->restore();
    } else {
      drawArrow(painter, mPoints.at(mPoints.size() - 1), mPoints.at(mPoints.size() - 2), mArrowSize, mArrow.at(1));
    }
  }
}

/*!
 * \brief LineAnnotation::drawArrow
 * Draws the arrow according to the arrow type.
 * \param painter
 * \param startPos
 * \param endPos
 * \param size
 * \param arrowType
 */
void LineAnnotation::drawArrow(QPainter *painter, QPointF startPos, QPointF endPos, qreal size, int arrowType) const
{
  double xA = size / 2;
  double yA = size * sqrt(3) / 2;
  double xB = -xA;
  double yB = yA;
  double angle = 0.0f;

  if (arrowType == StringHandler::ArrowHalf) {
    xB = 0;
  }

  if (endPos.x() - startPos.x() == 0) {
    if (endPos.y() - startPos.y() >= 0) {
      angle = 0;
    } else {
      angle = M_PI;
    }
  } else {
    angle = -(M_PI / 2 - (atan((endPos.y() - startPos.y())/(endPos.x() - startPos.x()))));
    if(startPos.x() > endPos.x()) {
      angle += M_PI;
    }
  }
  qreal m11, m12, m13, m21, m22, m23, m31, m32, m33;
  m11 = cos(angle);
  m22 = m11;
  m21 = sin(angle);
  m12 = -m21;
  m13 = startPos.x();
  m23 = startPos.y();
  m31 = 0;
  m32 = 0;
  m33 = 1;
  QTransform t1(m11, m12, m13, m21, m22, m23, m31, m32, m33);
  QTransform t2(xA, 1, 1, yA, 1, 1, 1, 1, 1);
  QTransform t3 = t1 * t2;
  QPolygonF arrowPolygon;
  arrowPolygon << startPos;
  arrowPolygon << QPointF(t3.m11(), t3.m21());
  t2.setMatrix(xB, 1, 1, yB, 1, 1, 1, 1, 1);
  t3 = t1 * t2;
  arrowPolygon << QPointF(t3.m11(), t3.m21());
  arrowPolygon << startPos;
  // draw arrow
  switch (arrowType) {
    case StringHandler::ArrowFilled:
      painter->save();
      painter->setBrush(QBrush(mLineColor, Qt::SolidPattern));
      painter->drawPolygon(arrowPolygon);
      painter->restore();
      break;
    case StringHandler::ArrowOpen:
      if (arrowPolygon.size() > 2) {
        painter->drawLine(arrowPolygon.at(0), arrowPolygon.at(1));
        painter->drawLine(arrowPolygon.at(0), arrowPolygon.at(2));
      }
      break;
    case StringHandler::ArrowHalf:
      if (arrowPolygon.size() > 1) {
        painter->drawLine(arrowPolygon.at(0), arrowPolygon.at(1));
      }
      break;
    case StringHandler::ArrowNone:
    default:
      break;
  }
}

/*!
 * \brief LineAnnotation::perpendicularLine
 * Returns a polygon which represents a prependicular line.
 * \param painter
 * \param startPos
 * \param endPos
 * \param size
 */
QPolygonF LineAnnotation::perpendicularLine(QPointF startPos, QPointF endPos, qreal size) const
{
  double xA = size / 2;
  double yA = size * sqrt(3) / 2;
  double xB = -xA;
  double yB = yA;
  double angle = 0.0f;
  if (endPos.x() - startPos.x() == 0) {
    if (endPos.y() - startPos.y() >= 0) {
      angle = 0;
    } else {
      angle = M_PI;
    }
  } else {
    angle = -(M_PI / 2 - (atan((endPos.y() - startPos.y())/(endPos.x() - startPos.x()))));
    if(startPos.x() > endPos.x()) {
      angle += M_PI;
    }
  }
  qreal m11, m12, m13, m21, m22, m23, m31, m32, m33;
  m11 = cos(angle);
  m22 = m11;
  m21 = sin(angle);
  m12 = -m21;
  m13 = startPos.x();
  m23 = startPos.y();
  m31 = 0;
  m32 = 0;
  m33 = 1;
  QTransform t1(m11, m12, m13, m21, m22, m23, m31, m32, m33);
  QTransform t2(xA, 1, 1, yA, 1, 1, 1, 1, 1);
  QTransform t3 = t1 * t2;
  QPolygonF polygon;
  polygon << QPointF(t3.m11(), t3.m21());
  t2.setMatrix(xB, 1, 1, yB, 1, 1, 1, 1, 1);
  t3 = t1 * t2;
  polygon << QPointF(t3.m11(), t3.m21());
  return polygon;
}

/*!
 * \brief LineAnnotation::getOMCShapeAnnotation
 * Returns Line annotation in format as returned by OMC.
 * \return
 */
QString LineAnnotation::getOMCShapeAnnotation()
{
  QStringList annotationString;
  annotationString.append(GraphicItem::getOMCShapeAnnotation());
  // get points
  QString pointsString;
  if (mPoints.size() > 0) {
    pointsString.append("{");
  }
  for (int i = 0 ; i < mPoints.size() ; i++) {
    pointsString.append("{").append(QString::number(mPoints[i].x())).append(",");
    pointsString.append(QString::number(mPoints[i].y())).append("}");
    if (i < mPoints.size() - 1) {
      pointsString.append(",");
    }
  }
  if (mPoints.size() > 0) {
    pointsString.append("}");
    annotationString.append(pointsString);
  }
  // get the line color
  QString colorString;
  colorString.append("{");
  colorString.append(QString::number(mLineColor.red())).append(",");
  colorString.append(QString::number(mLineColor.green())).append(",");
  colorString.append(QString::number(mLineColor.blue()));
  colorString.append("}");
  annotationString.append(colorString);
  // get the line pattern
  annotationString.append(StringHandler::getLinePatternString(mLinePattern));
  // get the thickness
  annotationString.append(QString::number(mLineThickness));
  // get the start and end arrow
  QString arrowString;
  arrowString.append("{").append(StringHandler::getArrowString(mArrow.at(0))).append(",");
  arrowString.append(StringHandler::getArrowString(mArrow.at(1))).append("}");
  annotationString.append(arrowString);
  // get the arrow size
  annotationString.append(QString::number(mArrowSize));
  // get the smooth
  annotationString.append(StringHandler::getSmoothString(mSmooth));
  return annotationString.join(",");
}

/*!
 * \brief LineAnnotation::getShapeAnnotation
 * Returns Line annotation.
 * \return
 */
QString LineAnnotation::getShapeAnnotation()
{
  QStringList annotationString;
  annotationString.append(GraphicItem::getShapeAnnotation());
  // get points
  QString pointsString;
  if (mPoints.size() > 0) {
    pointsString.append("points={");
  }
  for (int i = 0 ; i < mPoints.size() ; i++) {
    pointsString.append("{").append(QString::number(mPoints[i].x())).append(",");
    pointsString.append(QString::number(mPoints[i].y())).append("}");
    if (i < mPoints.size() - 1) {
      pointsString.append(",");
    }
  }
  if (mPoints.size() > 0) {
    pointsString.append("}");
    annotationString.append(pointsString);
  }
  // get the line color
  if (mLineColor != Qt::black) {
    QString colorString;
    colorString.append("color={");
    colorString.append(QString::number(mLineColor.red())).append(",");
    colorString.append(QString::number(mLineColor.green())).append(",");
    colorString.append(QString::number(mLineColor.blue()));
    colorString.append("}");
    annotationString.append(colorString);
  }
  // get the line pattern
  if (mLinePattern != StringHandler::LineSolid) {
    annotationString.append(QString("pattern=").append(StringHandler::getLinePatternString(mLinePattern)));
  }
  // get the thickness
  if (mLineThickness != 0.25) {
    annotationString.append(QString("thickness=").append(QString::number(mLineThickness)));
  }
  // get the start and end arrow
  if ((mArrow.at(0) != StringHandler::ArrowNone) || (mArrow.at(1) != StringHandler::ArrowNone)) {
    QString arrowString;
    arrowString.append("arrow=");
    arrowString.append("{").append(StringHandler::getArrowString(mArrow.at(0))).append(",");
    arrowString.append(StringHandler::getArrowString(mArrow.at(1))).append("}");
    annotationString.append(arrowString);
  }
  // get the arrow size
  if (mArrowSize != 3) {
    annotationString.append(QString("arrowSize=").append(QString::number(mArrowSize)));
  }
  // get the smooth
  if (mSmooth != StringHandler::SmoothNone) {
    annotationString.append(QString("smooth=").append(StringHandler::getSmoothString(mSmooth)));
  }
  return QString("Line(").append(annotationString.join(",")).append(")");
}

/*!
 * \brief LineAnnotation::getCompositeModelShapeAnnotation
 * \return
 */
QString LineAnnotation::getCompositeModelShapeAnnotation()
{
  QStringList annotationString;
  annotationString.append(GraphicItem::getShapeAnnotation());
  // get points
  QString pointsString;
  if (mPoints.size() > 0) {
    pointsString.append("{");
  }
  for (int i = 0 ; i < mPoints.size() ; i++) {
    pointsString.append("{").append(QString::number(mPoints[i].x())).append(",");
    pointsString.append(QString::number(mPoints[i].y())).append("}");
    if (i < mPoints.size() - 1) {
      pointsString.append(",");
    }
  }
  if (mPoints.size() > 0) {
    pointsString.append("}");
    annotationString.append(pointsString);
  }
  return annotationString.join(",");
}

void LineAnnotation::addPoint(QPointF point)
{
  prepareGeometryChange();
  mPoints.append(point);
  if (mPoints.size() > 1) {
    if (mGeometries.size() == 0) {
      QPointF currentPoint = mPoints[mPoints.size() - 1];
      QPointF previousPoint = mPoints[mPoints.size() - 2];
      mGeometries.append(findLineGeometryType(previousPoint, currentPoint));
    } else {
      if (mGeometries.back() == ShapeAnnotation::HorizontalLine) {
        mGeometries.push_back(ShapeAnnotation::VerticalLine);
      } else if (mGeometries.back() == ShapeAnnotation::VerticalLine) {
        mGeometries.push_back(ShapeAnnotation::HorizontalLine);
      }
    }
  }
}

void LineAnnotation::removePoint(int index)
{
  prepareGeometryChange();
  if (mPoints.size() > index) {
    mPoints.removeAt(index);
  }
  if (mGeometries.size() > index - 1) {
    mGeometries.removeAt(index  -1);
    // adjust the remaining geometries accordingly
    for (int i = index - 1 ; i < mGeometries.size() ; i++) {
      if (mGeometries.size() > i - 1) {
        if (mGeometries[i - 1] == ShapeAnnotation::HorizontalLine) {
          mGeometries[i] = ShapeAnnotation::VerticalLine;
        } else if (mGeometries[i - 1] == ShapeAnnotation::VerticalLine) {
          mGeometries[i] = ShapeAnnotation::HorizontalLine;
        }
      }
    }
  }
}

/*!
  Clears the points list.
  */
void LineAnnotation::clearPoints()
{
  mPoints.clear();
  mGeometries.clear();
}

/*!
  Updates the first point of the connection, and adjusts the second point accordingly depending on the geometry list.
  \param point - is the new start point.
  \sa updateEndPoint(QPointF point)
  */
void LineAnnotation::updateStartPoint(QPointF point)
{
  prepareGeometryChange();
  manhattanizeShape();
  removeRedundantPointsGeometriesAndCornerItems();
  qreal dx = point.x() - mPoints[0].x();
  qreal dy = point.y() - mPoints[0].y();
  // if connection points are just two we need to add extra points
  if (mPoints.size() == 2) {
    // just check if additional points are really needed or not.
    if ((mGeometries[0] == ShapeAnnotation::HorizontalLine && mPoints[0].y() != point.y()) ||
        (mGeometries[0] == ShapeAnnotation::VerticalLine && mPoints[0].x() != point.x())) {
      insertPointsGeometriesAndCornerItems(1);
      setCornerItemsActiveOrPassive();
    }
  }
  /* update the 1st point */
  if (mPoints.size() > 0) {
    mPoints[0] = point;
    updateCornerItem(0);
  }
  /* update the 2nd point */
  if (mPoints.size() > 1) {
    if (mGeometries[0] == ShapeAnnotation::HorizontalLine) {
      mPoints[1] = QPointF(mPoints[1].x(), mPoints[1].y() + dy);
    } else if (mGeometries[0] == ShapeAnnotation::VerticalLine) {
      mPoints[1] = QPointF(mPoints[1].x() + dx, mPoints[1].y());
    }
    updateCornerItem(1);
  }
  removeRedundantPointsGeometriesAndCornerItems();
}

/*!
  Updates the end point of the connection, and adjusts the second last point accordingly depending on the geometry list.
  \param point - is the new end point.
  \sa updateStartPoint(QPointF point)
  */
void LineAnnotation::updateEndPoint(QPointF point)
{
  prepareGeometryChange();
  if (mLineType == LineAnnotation::ConnectionType || mLineType == LineAnnotation::TransitionType) {
    if (!mpGraphicsView->isCreatingConnection() && !mpGraphicsView->isCreatingTransition()) {
      manhattanizeShape();
      removeRedundantPointsGeometriesAndCornerItems();
    }
    int lastIndex = mPoints.size() - 1;
    int secondLastIndex = mPoints.size() - 2;
    qreal dx = point.x() - mPoints[lastIndex].x();
    qreal dy = point.y() - mPoints[lastIndex].y();
    /*
      if connection points are just two we need to add extra points
      This function is also called when creating a component so for that we don't need to add extra points. In order to avoid this we check
      for the mpEndComponent since mpEndComponent will only be set when the connection is complete.
      */
    if (mPoints.size() == 2 && mpEndComponent) {
      // just check if additional points are really needed or not.
      if ((mGeometries[secondLastIndex] == ShapeAnnotation::HorizontalLine && mPoints[lastIndex].y() != point.y()) ||
          (mGeometries[secondLastIndex] == ShapeAnnotation::VerticalLine && mPoints[lastIndex].x() != point.x())) {
        insertPointsGeometriesAndCornerItems(lastIndex);
        setCornerItemsActiveOrPassive();
        lastIndex = mPoints.size() - 1;
        secondLastIndex = mPoints.size() - 2;
      }
    }
    /* update the last point */
    if (mPoints.size() > 1) {
      mPoints.back() = point;
      updateCornerItem(lastIndex);
      /* update the 2nd point */
      assert(secondLastIndex < mGeometries.size());
      if (mGeometries[secondLastIndex] == ShapeAnnotation::HorizontalLine) {
        mPoints[secondLastIndex] = QPointF(mPoints[secondLastIndex].x(), mPoints[secondLastIndex].y() + dy);
      } else if (mGeometries[secondLastIndex] == ShapeAnnotation::VerticalLine) {
        mPoints[secondLastIndex] = QPointF(mPoints[secondLastIndex].x() + dx, mPoints[secondLastIndex].y());
      }
      updateCornerItem(secondLastIndex);
    }
    if (!mpGraphicsView->isCreatingConnection() && !mpGraphicsView->isCreatingTransition()) {
      removeRedundantPointsGeometriesAndCornerItems();
    }
  } else {
    mPoints.back() = point;
  }
}

/*!
 * \brief LineAnnotation::moveAllPoints
 * Moves all the whole connection.
 * \param offsetX
 * \param offsetY
 */
void LineAnnotation::moveAllPoints(qreal offsetX, qreal offsetY)
{
  prepareGeometryChange();
  for(int i = 0 ; i < mPoints.size() ; i++) {
    mPoints[i] = QPointF(mPoints[i].x() + offsetX, mPoints[i].y() + offsetY);
    /* updated the corresponding CornerItem */
    updateCornerItem(i);
  }
}

/*!
 * \brief LineAnnotation::updateTransitionTextPosition
 * Updates the position of the transition text.
 */
void LineAnnotation::updateTransitionTextPosition()
{
  /* From Modelica Spec 33revision1,
   * The extent of the Text is interpreted relative to either the first point of the Line, in the case of immediate=false,
   * or the last point (immediate=true).
   */
  if (mpTextAnnotation) {
    if (mPoints.size() > 0) {
      if (mImmediate) {
        mpTextAnnotation->setPos(mPoints.last());
      } else {
        mpTextAnnotation->setPos(mPoints.first());
      }
    }
  }
}

/*!
  Sets the shape flags.
  */
void LineAnnotation::setShapeFlags(bool enable)
{
  if ((mLineType == LineAnnotation::ConnectionType || mLineType == LineAnnotation::TransitionType || mLineType == LineAnnotation::ShapeType)
      && mpGraphicsView) {
    /*
      Only set the ItemIsMovable & ItemSendsGeometryChanges flags on Line if the class is not a system library class
      AND Line is not an inherited Line AND Line type is not ConnectionType.
      */
    bool isSystemLibrary = mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isSystemLibrary();
    if (!isSystemLibrary && !isInheritedShape() && mLineType != LineAnnotation::ConnectionType &&
        mLineType != LineAnnotation::TransitionType && mLineType != LineAnnotation::InitialStateType) {
      setFlag(QGraphicsItem::ItemIsMovable, enable);
      setFlag(QGraphicsItem::ItemSendsGeometryChanges, enable);
    }
    setFlag(QGraphicsItem::ItemIsSelectable, enable);
  }
}

void LineAnnotation::updateShape(ShapeAnnotation *pShapeAnnotation)
{
  prepareGeometryChange();
  LineAnnotation *pLineAnnotation = dynamic_cast<LineAnnotation*>(pShapeAnnotation);
  setLineType(pLineAnnotation->getLineType());
  setStartComponent(pLineAnnotation->getStartComponent());
  setStartComponentName(pLineAnnotation->getStartComponentName());
  setEndComponent(pLineAnnotation->getEndComponent());
  setEndComponentName(pLineAnnotation->getEndComponentName());
  setCondition(pLineAnnotation->getCondition());
  setImmediate(pLineAnnotation->getImmediate());
  setReset(pLineAnnotation->getReset());
  setSynchronize(pLineAnnotation->getSynchronize());
  setPriority(pLineAnnotation->getPriority());
  if (pLineAnnotation->getTextAnnotation()) {
    mpTextAnnotation = new TextAnnotation("", this);
    mpTextAnnotation->updateShape(pLineAnnotation->getTextAnnotation());
  } else {
    mpTextAnnotation = 0;
  }
  setOldAnnotation(pLineAnnotation->getOldAnnotation());
  setDelay(pLineAnnotation->getDelay());
  setZf(pLineAnnotation->getZf());
  setZfr(pLineAnnotation->getZfr());
  setAlpha(pLineAnnotation->getAlpha());
  setOMSConnectionType(pLineAnnotation->getOMSConnectionType());
  setActiveState(pLineAnnotation->isActiveState());
  // set the default values
  GraphicItem::setDefaults(pShapeAnnotation);
  mPoints.clear();
  QList<QPointF> points = pShapeAnnotation->getPoints();
  for (int i = 0 ; i < points.size() ; i++) {
    addPoint(points[i]);
  }
  updateTransitionTextPosition();
  ShapeAnnotation::setDefaults(pShapeAnnotation);
}

/*!
 * \brief LineAnnotation::setAligned
 * Marks the connection line as aligned or not aligned.
 * \param aligned
 */
void LineAnnotation::setAligned(bool aligned)
{
  if (aligned) {
    setLineColor(QColor(Qt::black));
  } else {
    setLineColor(QColor(Qt::red));
  }
  update();
}

/*!
 * \brief LineAnnotation::updateOMSConnection
 * Updates the OMSimulator model connection
 */
void LineAnnotation::updateOMSConnection()
{
  // connection geometry
  ssd_connection_geometry_t connectionGeometry;
  QList<QPointF> points = mPoints;
  if (points.size() >= 2) {
    points.removeFirst();
    points.removeLast();
  }
  connectionGeometry.n = points.size();
  if (points.size() == 0) {
    connectionGeometry.pointsX = NULL;
    connectionGeometry.pointsY = NULL;
  } else {
    connectionGeometry.pointsX = new double[points.size()];
    connectionGeometry.pointsY = new double[points.size()];
  }
  for (int i = 0 ; i < points.size() ; i++) {
    connectionGeometry.pointsX[i] = points.at(i).x();
    connectionGeometry.pointsY[i] = points.at(i).y();
  }

  OMSProxy::instance()->setConnectionGeometry(getStartComponentName(), getEndComponentName(), &connectionGeometry);
}

void LineAnnotation::showOMSConnection()
{
  if ((mpStartComponent && mpStartComponent->getLibraryTreeItem()->getOMSBusConnector())
      && (mpEndComponent && mpEndComponent->getLibraryTreeItem()->getOMSBusConnector())) {
    BusConnectionDialog *pBusConnectionDialog = new BusConnectionDialog(mpGraphicsView, this, false);
    pBusConnectionDialog->exec();
  } else if ((mpStartComponent && mpStartComponent->getLibraryTreeItem()->getOMSTLMBusConnector())
             && (mpEndComponent && mpEndComponent->getLibraryTreeItem()->getOMSTLMBusConnector())) {
    TLMConnectionDialog *pTLMBusConnectionDialog = new TLMConnectionDialog(mpGraphicsView, this, false);
    pTLMBusConnectionDialog->exec();
  }
}

void LineAnnotation::updateToolTip()
{
  if (mLineType == LineAnnotation::ConnectionType) {
    setToolTip(QString("<b>connect</b>(%1, %2)").arg(getStartComponentName()).arg(getEndComponentName()));
  } else if (mLineType == LineAnnotation::TransitionType) {
    setToolTip(QString("<b>transition</b>(%1, %2, %3, %4, %5, %6, %7)")
               .arg(getStartComponentName())
               .arg(getEndComponentName())
               .arg(getCondition())
               .arg(getImmediate() ? "true" : "false")
               .arg(getReset() ? "true" : "false")
               .arg(getSynchronize() ? "true" : "false")
               .arg(getPriority()));
  }
}

QVariant LineAnnotation::itemChange(GraphicsItemChange change, const QVariant &value)
{
  ShapeAnnotation::itemChange(change, value);
#if !defined(WITHOUT_OSG)
  if (change == QGraphicsItem::ItemSelectedHasChanged) {

    // if connection selection is changed in CompositeModel
    if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::CompositeModel) {
      MainWindow::instance()->getModelWidgetContainer()->updateThreeDViewer(mpGraphicsView->getModelWidget());
    }
  }
#endif
  return value;
}

/*!
 * \brief LineAnnotation::handleComponentMoved
 * If the component associated with the connection is moved then update the connection accordingly.\n
 * If the both start and end components associated with the connection are moved then move whole connection.
 */
void LineAnnotation::handleComponentMoved()
{
  if (mPoints.size() < 2) {
    return;
  }
  prepareGeometryChange();
  if (mpStartComponent && mpStartComponent->getRootParentComponent()->isSelected() &&
      mpEndComponent && mpEndComponent->getRootParentComponent()->isSelected()) {
    if (mLineType == LineAnnotation::TransitionType) {
      QPointF centerPos = mpGraphicsView->roundPoint(mpStartComponent->mapToScene(mpStartComponent->boundingRect().center()));
      QRectF sceneRectF = mpStartComponent->sceneBoundingRect();
      QList<QPointF> newPos = Utilities::liangBarskyClipper(sceneRectF.topLeft().x(), sceneRectF.topLeft().y(),
                                                            sceneRectF.bottomRight().x(), sceneRectF.bottomRight().y(),
                                                            centerPos.x(), centerPos.y(),
                                                            mPoints.at(1).x(), mPoints.at(1).y());
      moveAllPoints(mpGraphicsView->roundPoint(newPos.at(1)).x() - mPoints[0].x(),
          mpGraphicsView->roundPoint(newPos.at(1)).y() - mPoints[0].y());
      updateTransitionTextPosition();
    } else {
      moveAllPoints(mpStartComponent->mapToScene(mpStartComponent->boundingRect().center()).x() - mPoints[0].x(),
          mpStartComponent->mapToScene(mpStartComponent->boundingRect().center()).y() - mPoints[0].y());
    }
  } else {
    if (mpStartComponent) {
      Component *pComponent = qobject_cast<Component*>(sender());
      if (pComponent == mpStartComponent->getRootParentComponent()) {
        updateStartPoint(mpGraphicsView->roundPoint(mpStartComponent->mapToScene(mpStartComponent->boundingRect().center())));
        if (mLineType == LineAnnotation::TransitionType) {
          QRectF sceneRectF = mpStartComponent->sceneBoundingRect();
          QList<QPointF> newPos = Utilities::liangBarskyClipper(sceneRectF.topLeft().x(), sceneRectF.topLeft().y(),
                                                                sceneRectF.bottomRight().x(), sceneRectF.bottomRight().y(),
                                                                mPoints.at(0).x(), mPoints.at(0).y(),
                                                                mPoints.at(1).x(), mPoints.at(1).y());
          updateStartPoint(mpGraphicsView->roundPoint(newPos.at(1)));
          updateTransitionTextPosition();
        } else if (mLineType == LineAnnotation::InitialStateType) {
          QRectF sceneRectF = mpStartComponent->sceneBoundingRect();
          QList<QPointF> newPos = Utilities::liangBarskyClipper(sceneRectF.topLeft().x(), sceneRectF.topLeft().y(),
                                                                sceneRectF.bottomRight().x(), sceneRectF.bottomRight().y(),
                                                                mPoints.at(0).x(), mPoints.at(0).y(),
                                                                mPoints.at(1).x(), mPoints.at(1).y());
          updateStartPoint(mpGraphicsView->roundPoint(newPos.at(1)));
        }
      }
    }
    if (mpEndComponent) {
      Component *pComponent = qobject_cast<Component*>(sender());
      if (pComponent == mpEndComponent->getRootParentComponent()) {
        updateEndPoint(mpGraphicsView->roundPoint(mpEndComponent->mapToScene(mpEndComponent->boundingRect().center())));
        if (mLineType == LineAnnotation::TransitionType) {
          QRectF sceneRectF = mpEndComponent->sceneBoundingRect();
          QList<QPointF> newPos = Utilities::liangBarskyClipper(sceneRectF.topLeft().x(), sceneRectF.topLeft().y(),
                                                                sceneRectF.bottomRight().x(), sceneRectF.bottomRight().y(),
                                                                mPoints.at(mPoints.size() - 2).x(), mPoints.at(mPoints.size() - 2).y(),
                                                                mPoints.at(mPoints.size() - 1).x(), mPoints.at(mPoints.size() - 1).y());
          updateEndPoint(mpGraphicsView->roundPoint(newPos.at(0)));
          updateTransitionTextPosition();
        }
      }
    }
  }
}

/*!
 * \brief LineAnnotation::updateConnectionAnnotation
 * Updates the connection annotation.
 */
void LineAnnotation::updateConnectionAnnotation()
{
  if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType()== LibraryTreeItem::CompositeModel) {
    CompositeModelEditor *pCompositeModelEditor = dynamic_cast<CompositeModelEditor*>(mpGraphicsView->getModelWidget()->getEditor());
    pCompositeModelEditor->updateConnection(this);
  } else if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType()== LibraryTreeItem::OMS) {
    updateOMSConnection();
  } else {
    // get the connection line annotation.
    QString annotationString = QString("annotate=").append(getShapeAnnotation());
    // update the connection
    OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
    pOMCProxy->updateConnection(getStartComponentName(), getEndComponentName(),
                                mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure(), annotationString);
  }
}

/*!
 * \brief LineAnnotation::updateConnectionTransformation
 * Slot activated when Component transformChanging SIGNAL is emitted.\n
 * Updates the connection.
 */
void LineAnnotation::updateConnectionTransformation()
{
  assert(!mOldAnnotation.isEmpty());
  if (mLineType == LineAnnotation::ConnectionType) {
    mpGraphicsView->getModelWidget()->getUndoStack()->push(new UpdateConnectionCommand(this, mOldAnnotation, getOMCShapeAnnotation()));
  } else if (mLineType == LineAnnotation::TransitionType) {
    mpGraphicsView->getModelWidget()->getUndoStack()->push(new UpdateTransitionCommand(this, mCondition, mImmediate, mReset,
                                                                                       mSynchronize, mPriority, mOldAnnotation,
                                                                                       mCondition, mImmediate, mReset, mSynchronize,
                                                                                       mPriority, getOMCShapeAnnotation()));
  } else if (mLineType == LineAnnotation::InitialStateType) {
    mpGraphicsView->getModelWidget()->getUndoStack()->push(new UpdateInitialStateCommand(this, mOldAnnotation, getOMCShapeAnnotation()));
  }
}

/*!
 * \brief LineAnnotation::updateTransitionAnnotation
 * Updates the transition annotation.
 */
void LineAnnotation::updateTransitionAnnotation(QString oldCondition, bool oldImmediate, bool oldReset, bool oldSynchronize, int oldPriority)
{
  // get the transition line and text annotation.
  QString annotationString = QString("annotate=$annotation(%1,%2)").arg(getShapeAnnotation()).arg(mpTextAnnotation->getShapeAnnotation());
  // update the transition
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  pOMCProxy->updateTransition(mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure(), getStartComponentName(),
                              getEndComponentName(), oldCondition, oldImmediate, oldReset, oldSynchronize, oldPriority, getCondition(),
                              getImmediate(), getReset(), getSynchronize(), getPriority(), annotationString);
}

/*!
 * \brief LineAnnotation::updateInitialStateAnnotation
 * Updates the initial state annotation.
 */
void LineAnnotation::updateInitialStateAnnotation()
{
  // get the initial state line annotation.
  QString annotationString = QString("annotate=$annotation(%1)").arg(getShapeAnnotation());
  // update the initial state
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  pOMCProxy->updateInitialState(mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure(), getStartComponentName(),
                                annotationString);
}

/*!
 * \brief LineAnnotation::duplicate
 * Duplicates the shape.
 */
void LineAnnotation::duplicate()
{
  LineAnnotation *pLineAnnotation = new LineAnnotation("", mpGraphicsView);
  pLineAnnotation->updateShape(this);
  QPointF gridStep(mpGraphicsView->mCoOrdinateSystem.getHorizontalGridStep() * 5,
                   mpGraphicsView->mCoOrdinateSystem.getVerticalGridStep() * 5);
  pLineAnnotation->setOrigin(mOrigin + gridStep);
  pLineAnnotation->initializeTransformation();
  pLineAnnotation->drawCornerItems();
  pLineAnnotation->setCornerItemsActiveOrPassive();
  pLineAnnotation->update();
  mpGraphicsView->getModelWidget()->getUndoStack()->push(new AddShapeCommand(pLineAnnotation));
  mpGraphicsView->getModelWidget()->getLibraryTreeItem()->emitShapeAdded(pLineAnnotation, mpGraphicsView);
  setSelected(false);
  pLineAnnotation->setSelected(true);
}

/*!
 * \class ExpandableConnectorTreeItem
 * \brief Contains the information about the expandable connector item.
 */
/*!
 * \brief ExpandableConnectorTreeItem::ExpandableConnectorTreeItem
 * Used for creating the root item.
 */
ExpandableConnectorTreeItem::ExpandableConnectorTreeItem()
{
  mIsRootItem = true;
  mpParentExpandableConnectorTreeItem = 0;
  setName("");
  setArray(false);
  setArrayIndex("");
  setRestriction(StringHandler::Model);
  setNewVariable(false);
}

/*!
 * \brief ExpandableConnectorTreeItem::ExpandableConnectorTreeItem
 * Used for creatind the expandable item.
 * \param name
 * \param array
 * \param arrayIndex
 * \param restriction
 * \param newVariable
 * \param pParentExpandableConnectorTreeItem
 */
ExpandableConnectorTreeItem::ExpandableConnectorTreeItem(QString name, bool array, QString arrayIndex,
                                                         StringHandler::ModelicaClasses restriction, bool newVariable,
                                                         ExpandableConnectorTreeItem *pParentExpandableConnectorTreeItem)
{
  mIsRootItem = false;
  mpParentExpandableConnectorTreeItem = pParentExpandableConnectorTreeItem;
  setName(name);
  setArray(array);
  setArrayIndex(arrayIndex);
  setRestriction(restriction);
  setNewVariable(newVariable);
}

/*!
 * \brief ExpandableConnectorTreeItem::~ExpandableConnectorTreeItem
 * Destructor for ExpandableConnectorTreeItem
 */
ExpandableConnectorTreeItem::~ExpandableConnectorTreeItem()
{
  qDeleteAll(mChildren);
  mChildren.clear();
}

/*!
 * \brief ExpandableConnectorTreeItem::data
 * Returns the data stored under the given role for the item referred to by the column.
 * \param column
 * \param role
 * \return
 */
QVariant ExpandableConnectorTreeItem::data(int column, int role) const
{
  switch (column) {
    case 0:
      switch (role) {
        case Qt::DisplayRole:
          return mName;
        case Qt::DecorationRole:
          switch (mRestriction) {
            case StringHandler::ExpandableConnector:
              return QIcon(":/Resources/icons/connect-mode.svg");
              break;
            case StringHandler::Connector:
              return QIcon(":/Resources/icons/connector-icon.svg");
              break;
            default:
              return QVariant();
              break;
          }
        default:
          return QVariant();
      }
    default:
      return QVariant();
  }
}

/*!
 * \brief ExpandableConnectorTreeItem::row
 * Returns the row number corresponding to ExpandableConnectorTreeItem.
 * \return
 */
int ExpandableConnectorTreeItem::row() const
{
  if (mpParentExpandableConnectorTreeItem) {
    return mpParentExpandableConnectorTreeItem->mChildren.indexOf(const_cast<ExpandableConnectorTreeItem*>(this));
  }

  return 0;
}

/*!
 * \class ExpandableConnectorTreeProxyModel
 * \brief A sort filter proxy model for Expandable connectors treeview.
 */
/*!
 * \brief ExpandableConnectorTreeProxyModel::ExpandableConnectorTreeProxyModel
 * \param pCreateConnectionDialog
 */
ExpandableConnectorTreeProxyModel::ExpandableConnectorTreeProxyModel(CreateConnectionDialog *pCreateConnectionDialog)
  : QSortFilterProxyModel(pCreateConnectionDialog)
{
  mpCreateConnectionDialog = pCreateConnectionDialog;
}

/*!
 * \class ExpandableConnectorTreeModel
 * \brief A model for Expandable connectors treeview.
 */
/*!
 * \brief ExpandableConnectorTreeModel::ExpandableConnectorTreeModel
 * \param pCreateConnectionDialog
 */
ExpandableConnectorTreeModel::ExpandableConnectorTreeModel(CreateConnectionDialog *pCreateConnectionDialog)
  : QAbstractItemModel(pCreateConnectionDialog)
{
  mpCreateConnectionDialog = pCreateConnectionDialog;
  mpRootExpandableConnectorTreeItem = new ExpandableConnectorTreeItem;
}

/*!
 * \brief ExpandableConnectorTreeModel::columnCount
 * Returns the number of columns for the children of the given parent.
 * \param parent
 * \return
 */
int ExpandableConnectorTreeModel::columnCount(const QModelIndex &parent) const
{
  Q_UNUSED(parent);
  return 1;
}

/*!
 * \brief ExpandableConnectorTreeModel::rowCount
 * Returns the number of rows under the given parent.
 * When the parent is valid it means that rowCount is returning the number of children of parent.
 * \param parent
 * \return
 */
int ExpandableConnectorTreeModel::rowCount(const QModelIndex &parent) const
{
  ExpandableConnectorTreeItem *pParentExpandableConnectorTreeItem;
  if (parent.column() > 0) {
    return 0;
  }

  if (!parent.isValid()) {
    pParentExpandableConnectorTreeItem = mpRootExpandableConnectorTreeItem;
  } else {
    pParentExpandableConnectorTreeItem = static_cast<ExpandableConnectorTreeItem*>(parent.internalPointer());
  }
  return pParentExpandableConnectorTreeItem->getChildren().size();
}

/*!
 * \brief ExpandableConnectorTreeModel::headerData
 * Returns the data for the given role and section in the header with the specified orientation.
 * \param section
 * \param orientation
 * \param role
 * \return
 */
QVariant ExpandableConnectorTreeModel::headerData(int section, Qt::Orientation orientation, int role) const
{
  Q_UNUSED(section);
  if (orientation == Qt::Horizontal && role == Qt::DisplayRole) {
    return tr("Connector");
  }
  return QVariant();
}

/*!
 * \brief ExpandableConnectorTreeModel::index
 * Returns the index of the item in the model specified by the given row, column and parent index.
 * \param row
 * \param column
 * \param parent
 * \return
 */
QModelIndex ExpandableConnectorTreeModel::index(int row, int column, const QModelIndex &parent) const
{
  if (!hasIndex(row, column, parent)) {
    return QModelIndex();
  }

  ExpandableConnectorTreeItem *pParentExpandableConnectorTreeItem;
  if (!parent.isValid()) {
    pParentExpandableConnectorTreeItem = mpRootExpandableConnectorTreeItem;
  } else {
    pParentExpandableConnectorTreeItem = static_cast<ExpandableConnectorTreeItem*>(parent.internalPointer());
  }

  ExpandableConnectorTreeItem *pChildExpandableConnectorTreeItem = pParentExpandableConnectorTreeItem->child(row);
  if (pChildExpandableConnectorTreeItem) {
    return createIndex(row, column, pChildExpandableConnectorTreeItem);
  } else {
    return QModelIndex();
  }
}

/*!
 * \brief ExpandableConnectorTreeModel::parent
 * Finds the parent for QModelIndex
 * \param index
 * \return
 */
QModelIndex ExpandableConnectorTreeModel::parent(const QModelIndex &index) const
{
  if (!index.isValid()) {
    return QModelIndex();
  }

  ExpandableConnectorTreeItem *pChildExpandableConnectorTreeItem = static_cast<ExpandableConnectorTreeItem*>(index.internalPointer());
  ExpandableConnectorTreeItem *pParentExpandableConnectorTreeItem = pChildExpandableConnectorTreeItem->parent();
  if (pParentExpandableConnectorTreeItem == mpRootExpandableConnectorTreeItem)
    return QModelIndex();

  return createIndex(pParentExpandableConnectorTreeItem->row(), 0, pParentExpandableConnectorTreeItem);
}

/*!
 * \brief ExpandableConnectorTreeModel::data
 * Returns the LibraryTreeItem data.
 * \param index
 * \param role
 * \return
 */
QVariant ExpandableConnectorTreeModel::data(const QModelIndex &index, int role) const
{
  if (!index.isValid()) {
    return QVariant();
  }


  ExpandableConnectorTreeItem *pExpandableConnectorTreeItem = static_cast<ExpandableConnectorTreeItem*>(index.internalPointer());
  return pExpandableConnectorTreeItem->data(index.column(), role);
}

/*!
 * \brief ExpandableConnectorTreeModel::flags
 * Returns the LibraryTreeItem flags.
 * \param index
 * \return
 */
Qt::ItemFlags ExpandableConnectorTreeModel::flags(const QModelIndex &index) const
{
  ExpandableConnectorTreeItem *pExpandableConnectorTreeItem = static_cast<ExpandableConnectorTreeItem*>(index.internalPointer());
  if (pExpandableConnectorTreeItem &&
      ((pExpandableConnectorTreeItem->getRestriction() == StringHandler::ExpandableConnector) ||
      (pExpandableConnectorTreeItem->parent() && pExpandableConnectorTreeItem->parent()->getRestriction() == StringHandler::ExpandableConnector))) {
    return Qt::ItemIsEnabled | Qt::ItemIsSelectable;
  } else {
    return 0;
  }
}

/*!
 * \brief ExpandableConnectorTreeModel::findFirstEnabledItem
 * \param pExpandableConnectorTreeItem
 * Finds the first enabled item and returns its index.
 * \return
 */
QModelIndex ExpandableConnectorTreeModel::findFirstEnabledItem(ExpandableConnectorTreeItem *pExpandableConnectorTreeItem)
{
  for (int i = 0 ; i < pExpandableConnectorTreeItem->getChildren().size(); i++) {
    QModelIndex index = expandableConnectorTreeItemIndex(pExpandableConnectorTreeItem->child(i));
    if (index.isValid() && index.flags() & Qt::ItemIsEnabled) {
      return index;
    }
    index = findFirstEnabledItem(pExpandableConnectorTreeItem->child(i));
    if (index.isValid() && index.flags() & Qt::ItemIsEnabled) {
      return index;
    }
  }
  return QModelIndex();
}

/*!
 * \brief ExpandableConnectorTreeModel::expandableConnectorTreeItemIndex
 * Finds the QModelIndex attached to ExpandableConnectorTreeItem.
 * \param pExpandableConnectorTreeItem
 * \return
 */
QModelIndex ExpandableConnectorTreeModel::expandableConnectorTreeItemIndex(const ExpandableConnectorTreeItem *pExpandableConnectorTreeItem) const
{
  return expandableConnectorTreeItemIndexHelper(pExpandableConnectorTreeItem, mpRootExpandableConnectorTreeItem, QModelIndex());
}

void ExpandableConnectorTreeModel::createExpandableConnectorTreeItem(Component *pComponent,
                                                                     ExpandableConnectorTreeItem *pParentExpandableConnectorTreeItem)
{
  StringHandler::ModelicaClasses restriction = StringHandler::Model;
  if (pComponent->getLibraryTreeItem()) {
    restriction = pComponent->getLibraryTreeItem()->getRestriction();
  }
  ExpandableConnectorTreeItem *pExpandableConnectorTreeItem = new ExpandableConnectorTreeItem(pComponent->getName(),
                                                                                              pComponent->getComponentInfo()->isArray(),
                                                                                              pComponent->getComponentInfo()->getArrayIndex(),
                                                                                              restriction, false,
                                                                                              pParentExpandableConnectorTreeItem);
  int row = pParentExpandableConnectorTreeItem->getChildren().size();
  QModelIndex index = expandableConnectorTreeItemIndex(pParentExpandableConnectorTreeItem);
  beginInsertRows(index, row, row);
  pParentExpandableConnectorTreeItem->insertChild(row, pExpandableConnectorTreeItem);
  endInsertRows();
  if (pComponent->getLibraryTreeItem()) {
    foreach (Component *pChildComponent, pComponent->getLibraryTreeItem()->getModelWidget()->getDiagramGraphicsView()->getComponentsList()) {
      createExpandableConnectorTreeItem(pChildComponent, pExpandableConnectorTreeItem);
    }
  }
  // create add variable item only if item is expandable connector
  if (pExpandableConnectorTreeItem->getRestriction() == StringHandler::ExpandableConnector) {
    ExpandableConnectorTreeItem *pNewVariableExpandableConnectorTreeItem = new ExpandableConnectorTreeItem(Helper::newVariable, false, "",
                                                                                                           StringHandler::Model, true,
                                                                                                           pExpandableConnectorTreeItem);
    int row = pExpandableConnectorTreeItem->getChildren().size();
    QModelIndex index = expandableConnectorTreeItemIndex(pExpandableConnectorTreeItem);
    beginInsertRows(index, row, row);
    pExpandableConnectorTreeItem->insertChild(row, pNewVariableExpandableConnectorTreeItem);
    endInsertRows();
  }
}

/*!
 * \brief ExpandableConnectorTreeModel::expandableConnectorTreeItemIndexHelper
 * Helper function for ExpandableConnectorTreeModel::expandableConnectorTreeItemIndex()
 * \param pExpandableConnectorTreeItem
 * \param pParentExpandableConnectorTreeItem
 * \param parentIndex
 * \return
 */
QModelIndex ExpandableConnectorTreeModel::expandableConnectorTreeItemIndexHelper(const ExpandableConnectorTreeItem *pExpandableConnectorTreeItem,
                                                                                 const ExpandableConnectorTreeItem *pParentExpandableConnectorTreeItem,
                                                                                 const QModelIndex &parentIndex) const
{
  if (pExpandableConnectorTreeItem == pParentExpandableConnectorTreeItem) {
    return parentIndex;
  }
  for (int i = pParentExpandableConnectorTreeItem->getChildren().size(); --i >= 0; ) {
    const ExpandableConnectorTreeItem *childItem = pParentExpandableConnectorTreeItem->getChildren().at(i);
    QModelIndex childIndex = index(i, 0, parentIndex);
    QModelIndex index = expandableConnectorTreeItemIndexHelper(pExpandableConnectorTreeItem, childItem, childIndex);
    if (index.isValid()) {
      return index;
    }
  }
  return QModelIndex();
}

/*!
 * \class ExpandableConnectorTreeView
 * \brief A tree view for Expandable connectors.
 */
/*!
 * \brief ExpandableConnectorTreeView::ExpandableConnectorTreeView
 * \param pCreateConnectionDialog
 */
ExpandableConnectorTreeView::ExpandableConnectorTreeView(CreateConnectionDialog *pCreateConnectionDialog)
  : QTreeView(pCreateConnectionDialog), mpCreateConnectionDialog(pCreateConnectionDialog)
{
  setItemDelegate(new ItemDelegate(this));
  setTextElideMode(Qt::ElideMiddle);
  setIndentation(Helper::treeIndentation);
  setUniformRowHeights(true);
}

/*!
 * \class CreateConnectionDialog
 * \brief A dialog interface for making expandable & array connections.
 */
/*!
 * \brief CreateConnectionDialog::CreateConnectionDialog
 * \param pGraphicsView
 * \param pConnectionLineAnnotation
 * \param pParent
 */
CreateConnectionDialog::CreateConnectionDialog(GraphicsView *pGraphicsView, LineAnnotation *pConnectionLineAnnotation, QWidget *pParent)
  : QDialog(pParent), mpGraphicsView(pGraphicsView), mpConnectionLineAnnotation(pConnectionLineAnnotation)
{
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::createConnection));
  setAttribute(Qt::WA_DeleteOnClose);
  // heading
  mpHeading = Utilities::getHeadingLabel(Helper::createConnection);
  // horizontal line
  mpHorizontalLine = Utilities::getHeadingLine();
  // Start expandable connector treeview
  mpStartExpandableConnectorTreeView = 0;
  if ((!mpConnectionLineAnnotation->getStartComponent()->getParentComponent() && mpConnectionLineAnnotation->getStartComponent()->getRootParentComponent()->getLibraryTreeItem()->getRestriction() == StringHandler::ExpandableConnector) ||
      (mpConnectionLineAnnotation->getStartComponent()->getParentComponent() && mpConnectionLineAnnotation->getStartComponent()->getLibraryTreeItem()->getRestriction() == StringHandler::ExpandableConnector)) {
    mpStartExpandableConnectorTreeModel = new ExpandableConnectorTreeModel(this);
    mpStartExpandableConnectorTreeProxyModel = new ExpandableConnectorTreeProxyModel(this);
    mpStartExpandableConnectorTreeProxyModel->setDynamicSortFilter(true);
    mpStartExpandableConnectorTreeProxyModel->setSourceModel(mpStartExpandableConnectorTreeModel);
    mpStartExpandableConnectorTreeView = new ExpandableConnectorTreeView(this);
    mpStartExpandableConnectorTreeView->setModel(mpStartExpandableConnectorTreeProxyModel);
    if (mpConnectionLineAnnotation->getStartComponent()->getParentComponent()) {
      mpStartExpandableConnectorTreeModel->createExpandableConnectorTreeItem(mpConnectionLineAnnotation->getStartComponent()->getParentComponent(),
                                                                             mpStartExpandableConnectorTreeModel->getRootExpandableConnectorTreeItem());
    } else {
      mpStartExpandableConnectorTreeModel->createExpandableConnectorTreeItem(mpConnectionLineAnnotation->getStartComponent(),
                                                                             mpStartExpandableConnectorTreeModel->getRootExpandableConnectorTreeItem());
    }
    mpStartExpandableConnectorTreeView->expandAll();
    mpStartExpandableConnectorTreeView->setSortingEnabled(true);
    mpStartExpandableConnectorTreeView->sortByColumn(0, Qt::AscendingOrder);
    connect(mpStartExpandableConnectorTreeView->selectionModel(), SIGNAL(currentChanged(QModelIndex,QModelIndex)),
            SLOT(startConnectorChanged(QModelIndex,QModelIndex)));
  }
  // End expandable connector treeview
  mpEndExpandableConnectorTreeView = 0;
  if ((!mpConnectionLineAnnotation->getEndComponent()->getParentComponent() && mpConnectionLineAnnotation->getEndComponent()->getRootParentComponent()->getLibraryTreeItem()->getRestriction() == StringHandler::ExpandableConnector) ||
      (mpConnectionLineAnnotation->getEndComponent()->getParentComponent() && mpConnectionLineAnnotation->getEndComponent()->getLibraryTreeItem()->getRestriction() == StringHandler::ExpandableConnector)) {
    mpEndExpandableConnectorTreeModel = new ExpandableConnectorTreeModel(this);
    mpEndExpandableConnectorTreeProxyModel = new ExpandableConnectorTreeProxyModel(this);
    mpEndExpandableConnectorTreeProxyModel->setDynamicSortFilter(true);
    mpEndExpandableConnectorTreeProxyModel->setSourceModel(mpEndExpandableConnectorTreeModel);
    mpEndExpandableConnectorTreeView = new ExpandableConnectorTreeView(this);
    mpEndExpandableConnectorTreeView->setModel(mpEndExpandableConnectorTreeProxyModel);
    if (mpConnectionLineAnnotation->getEndComponent()->getParentComponent()) {
      mpEndExpandableConnectorTreeModel->createExpandableConnectorTreeItem(mpConnectionLineAnnotation->getEndComponent()->getParentComponent(),
                                                                           mpEndExpandableConnectorTreeModel->getRootExpandableConnectorTreeItem());
    } else {
      mpEndExpandableConnectorTreeModel->createExpandableConnectorTreeItem(mpConnectionLineAnnotation->getEndComponent(),
                                                                           mpEndExpandableConnectorTreeModel->getRootExpandableConnectorTreeItem());
    }
    mpEndExpandableConnectorTreeView->expandAll();
    mpEndExpandableConnectorTreeView->setSortingEnabled(true);
    mpEndExpandableConnectorTreeView->sortByColumn(0, Qt::AscendingOrder);
    connect(mpEndExpandableConnectorTreeView->selectionModel(), SIGNAL(currentChanged(QModelIndex,QModelIndex)),
            SLOT(endConnectorChanged(QModelIndex,QModelIndex)));
  }
  // Indexes Description text
  mpIndexesDescriptionLabel = new Label(tr("Specify the indexes below to connect to the parts of the connectors."));
  mpStartRootComponentSpinBox = 0;
  mpStartComponentSpinBox = 0;
  mpEndRootComponentSpinBox = 0;
  mpEndComponentSpinBox = 0;
  // only create normal start connector controls if start connector is not expandable
  if (!mpStartExpandableConnectorTreeView) {
    if (mpConnectionLineAnnotation->getStartComponent()->getParentComponent()) {
      mpStartRootComponentLabel = new Label(mpConnectionLineAnnotation->getStartComponent()->getRootParentComponent()->getName());
      if (mpConnectionLineAnnotation->getStartComponent()->getRootParentComponent()->getComponentInfo()->isArray()) {
        mpStartRootComponentSpinBox = createSpinBox(mpConnectionLineAnnotation->getStartComponent()->getRootParentComponent()->getComponentInfo()->getArrayIndex());
      }
    }
    mpStartComponentLabel = new Label(mpConnectionLineAnnotation->getStartComponent()->getName());
    if (mpConnectionLineAnnotation->getStartComponent()->getComponentInfo()->isArray()) {
      mpStartComponentSpinBox = createSpinBox(mpConnectionLineAnnotation->getStartComponent()->getComponentInfo()->getArrayIndex());
    }
  }
  // only create normal end connector controls if end connector is not expandable
  if (!mpEndExpandableConnectorTreeView) {
    if (mpConnectionLineAnnotation->getEndComponent()->getParentComponent()) {
      mpEndRootComponentLabel = new Label(mpConnectionLineAnnotation->getEndComponent()->getRootParentComponent()->getName());
      if (mpConnectionLineAnnotation->getEndComponent()->getRootParentComponent()->getComponentInfo()->isArray()) {
        mpEndRootComponentSpinBox = createSpinBox(mpConnectionLineAnnotation->getEndComponent()->getRootParentComponent()->getComponentInfo()->getArrayIndex());
      }
    }
    mpEndComponentLabel = new Label(mpConnectionLineAnnotation->getEndComponent()->getName());
    if (mpConnectionLineAnnotation->getEndComponent()->getComponentInfo()->isArray()) {
      mpEndComponentSpinBox = createSpinBox(mpConnectionLineAnnotation->getEndComponent()->getComponentInfo()->getArrayIndex());
    }
  }
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(createConnection()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // add buttons
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // Create a layout
  mpMainLayout = new QGridLayout;
  mpMainLayout->setAlignment(Qt::AlignTop);
  mpMainLayout->addWidget(mpHeading, 0, 0, 1, 2);
  mpMainLayout->addWidget(mpHorizontalLine, 1, 0, 1, 2);
  int row = 2;
  if (mpStartExpandableConnectorTreeView && mpEndExpandableConnectorTreeView) {
    QHBoxLayout *pExpandableTreeHorizontalLayout = new QHBoxLayout;
    pExpandableTreeHorizontalLayout->addWidget(mpStartExpandableConnectorTreeView);
    pExpandableTreeHorizontalLayout->addWidget(mpEndExpandableConnectorTreeView);
    mpMainLayout->addLayout(pExpandableTreeHorizontalLayout, row, 0, 1, 2);
    row++;
  } else if (mpStartExpandableConnectorTreeView) {
    mpMainLayout->addWidget(mpStartExpandableConnectorTreeView, row, 0, 1, 2);
    row++;
  } else if (mpEndExpandableConnectorTreeView) {
    mpMainLayout->addWidget(mpEndExpandableConnectorTreeView, row, 0, 1, 2);
    row++;
  }
  if (mpStartRootComponentSpinBox || mpStartComponentSpinBox || mpEndRootComponentSpinBox || mpEndComponentSpinBox) {
    mpMainLayout->addWidget(mpIndexesDescriptionLabel, row, 0, 1, 2);
    row++;
  }
  mpMainLayout->addWidget(new Label("connect("), row, 0);
  // connection start horizontal layout
  mpConnectionStartHorizontalLayout = new QHBoxLayout;
  mpConnectionStartHorizontalLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  if (mpStartExpandableConnectorTreeView) {
    QModelIndex modelIndex = mpStartExpandableConnectorTreeModel->findFirstEnabledItem(mpStartExpandableConnectorTreeModel->getRootExpandableConnectorTreeItem());
    QModelIndex proxyIndex = mpStartExpandableConnectorTreeProxyModel->mapFromSource(modelIndex);
    startConnectorChanged(proxyIndex, QModelIndex());
  } else {
    if (mpConnectionLineAnnotation->getStartComponent()->getParentComponent()) {
      mpConnectionStartHorizontalLayout->addWidget(mpStartRootComponentLabel);
      if (mpConnectionLineAnnotation->getStartComponent()->getRootParentComponent()->getComponentInfo()->isArray()) {
        mpConnectionStartHorizontalLayout->addWidget(mpStartRootComponentSpinBox);
      }
      mpConnectionStartHorizontalLayout->addWidget(new Label("."));
    }
    mpConnectionStartHorizontalLayout->addWidget(mpStartComponentLabel);
    if (mpConnectionLineAnnotation->getStartComponent()->getComponentInfo()->isArray()) {
      mpConnectionStartHorizontalLayout->addWidget(mpStartComponentSpinBox);
    }
    mpConnectionStartHorizontalLayout->addWidget(new Label(","));
  }
  mpMainLayout->addLayout(mpConnectionStartHorizontalLayout, row, 1, 1, 1, Qt::AlignLeft);
  row++;
  mpMainLayout->addItem(new QSpacerItem(1, 1), row, 0);
  // connection end horizontal layout
  mpConnectionEndHorizontalLayout = new QHBoxLayout;
  mpConnectionEndHorizontalLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  if (mpEndExpandableConnectorTreeView) {
    QModelIndex modelIndex = mpEndExpandableConnectorTreeModel->findFirstEnabledItem(mpEndExpandableConnectorTreeModel->getRootExpandableConnectorTreeItem());
    QModelIndex proxyIndex = mpEndExpandableConnectorTreeProxyModel->mapFromSource(modelIndex);
    endConnectorChanged(proxyIndex, QModelIndex());
  } else {
    if (mpConnectionLineAnnotation->getEndComponent()->getParentComponent()) {
      mpConnectionEndHorizontalLayout->addWidget(mpEndRootComponentLabel);
      if (mpConnectionLineAnnotation->getEndComponent()->getRootParentComponent()->getComponentInfo()->isArray()) {
        mpConnectionEndHorizontalLayout->addWidget(mpEndRootComponentSpinBox);
      }
      mpConnectionEndHorizontalLayout->addWidget(new Label("."));
    }
    mpConnectionEndHorizontalLayout->addWidget(mpEndComponentLabel);
    if (mpConnectionLineAnnotation->getEndComponent()->getComponentInfo()->isArray()) {
      mpConnectionEndHorizontalLayout->addWidget(mpEndComponentSpinBox);
    }
    mpConnectionEndHorizontalLayout->addWidget(new Label(");"));
  }
  mpMainLayout->addLayout(mpConnectionEndHorizontalLayout, row, 1, 1, 1, Qt::AlignLeft);
  row++;
  mpMainLayout->addWidget(mpButtonBox, row, 0, 1, 2, Qt::AlignRight);
  setLayout(mpMainLayout);
}

/*!
 * \brief CreateConnectionDialog::createSpinBox
 * Creates a QSpinBox with arrayIndex limit.
 * \param arrayIndex
 * \return
 */
QSpinBox* CreateConnectionDialog::createSpinBox(QString arrayIndex)
{
  QSpinBox *pSpinBox = new QSpinBox;
  pSpinBox->setPrefix("[");
  pSpinBox->setSuffix("]");
  pSpinBox->setSpecialValueText("[:]");
  arrayIndex = StringHandler::removeFirstLastCurlBrackets(arrayIndex);
  int intArrayIndex = arrayIndex.toInt();
  if (intArrayIndex > 0) {
    pSpinBox->setMaximum(intArrayIndex);
  }
  return pSpinBox;
}

/*!
 * \brief CreateConnectionDialog::createComponentNameFromLayout
 * Creates a component name from the layout controls. Used when we have expandable connectors.
 * \param pLayout
 * \return
 */
QString CreateConnectionDialog::createComponentNameFromLayout(QHBoxLayout *pLayout)
{
  QString componentName;
  int i = 0;
  while (QLayoutItem* pLayoutItem = pLayout->itemAt(i)) {
    if (dynamic_cast<Label*>(pLayoutItem->widget())) {
      Label *pLabel = dynamic_cast<Label*>(pLayoutItem->widget());
      if (pLabel->text().compare(",") != 0 && pLabel->text().compare(");") != 0) {  // "," & ");" are fixed labels so we skip them here.
        componentName += pLabel->text();
      }
    } else if (dynamic_cast<QSpinBox*>(pLayoutItem->widget())) {
      QSpinBox *pSpinBox = dynamic_cast<QSpinBox*>(pLayoutItem->widget());
      if (pSpinBox->value() > 0) {
        componentName += QString("[%1]").arg(pSpinBox->value());
      }
    } else if (dynamic_cast<QLineEdit*>(pLayoutItem->widget())) {
      QLineEdit *pLineEdit = dynamic_cast<QLineEdit*>(pLayoutItem->widget());
      if (pLineEdit->text().isEmpty()) {
        componentName += "ERROR";
      } else {
        componentName += pLineEdit->text();
      }
    }
    i++;
  }
  return componentName;
}

/*!
 * \brief CreateConnectionDialog::startConnectorChanged
 * Updates the start component name in the connection.
 * \param current
 * \param previous
 */
void CreateConnectionDialog::startConnectorChanged(const QModelIndex &current, const QModelIndex &previous)
{
  Q_UNUSED(previous);

  while (QLayoutItem* pLayoutItem = mpConnectionStartHorizontalLayout->takeAt(0)) {
    if (pLayoutItem->widget()) {
      delete pLayoutItem->widget();
    }
  }
  mStartConnectorsList.clear();

  QModelIndex currentIndex = mpStartExpandableConnectorTreeProxyModel->mapToSource(current);
  ExpandableConnectorTreeItem *pExpandableConnectorTreeItem = static_cast<ExpandableConnectorTreeItem*>(currentIndex.internalPointer());
  if (!pExpandableConnectorTreeItem) {
    return;
  }

  mStartConnectorsList.append(pExpandableConnectorTreeItem);
  while (pExpandableConnectorTreeItem->parent() && pExpandableConnectorTreeItem->parent() != mpStartExpandableConnectorTreeModel->getRootExpandableConnectorTreeItem()) {
    pExpandableConnectorTreeItem = pExpandableConnectorTreeItem->parent();
    mStartConnectorsList.prepend(pExpandableConnectorTreeItem);
  }

  for (int i = 0 ; i < mStartConnectorsList.size() ; i++) {
    if (mStartConnectorsList.at(i)->isArray()) {
      mpConnectionStartHorizontalLayout->addWidget(new Label(mStartConnectorsList.at(i)->getName()));
      mpConnectionStartHorizontalLayout->addWidget(createSpinBox(mStartConnectorsList.at(i)->getArrayIndex()));
    } else if (mStartConnectorsList.at(i)->isNewVariable()) {
      QLineEdit *pNewVariableTextBox = new QLineEdit;
      pNewVariableTextBox->setPlaceholderText(Helper::newVariable);
      mpConnectionStartHorizontalLayout->addWidget(pNewVariableTextBox);
    } else {
      mpConnectionStartHorizontalLayout->addWidget(new Label(mStartConnectorsList.at(i)->getName()));
    }
    if (i < mStartConnectorsList.size() -  1) {
      mpConnectionStartHorizontalLayout->addWidget(new Label("."));
    }
  }
  mpConnectionStartHorizontalLayout->addWidget(new Label(","));
}

/*!
 * \brief CreateConnectionDialog::endConnectorChanged
 * Updates the end component name in the connection.
 * \param current
 * \param previous
 */
void CreateConnectionDialog::endConnectorChanged(const QModelIndex &current, const QModelIndex &previous)
{
  Q_UNUSED(previous);

  while (QLayoutItem* pLayoutItem = mpConnectionEndHorizontalLayout->takeAt(0)) {
    if (pLayoutItem->widget()) {
      delete pLayoutItem->widget();
    }
  }
  mEndConnectorsList.clear();

  QModelIndex currentIndex = mpEndExpandableConnectorTreeProxyModel->mapToSource(current);
  ExpandableConnectorTreeItem *pExpandableConnectorTreeItem = static_cast<ExpandableConnectorTreeItem*>(currentIndex.internalPointer());
  if (!pExpandableConnectorTreeItem) {
    return;
  }

  mEndConnectorsList.append(pExpandableConnectorTreeItem);
  while (pExpandableConnectorTreeItem->parent() && pExpandableConnectorTreeItem->parent() != mpEndExpandableConnectorTreeModel->getRootExpandableConnectorTreeItem()) {
    pExpandableConnectorTreeItem = pExpandableConnectorTreeItem->parent();
    mEndConnectorsList.prepend(pExpandableConnectorTreeItem);
  }

  for (int i = 0 ; i < mEndConnectorsList.size() ; i++) {
    if (mEndConnectorsList.at(i)->isArray()) {
      mpConnectionEndHorizontalLayout->addWidget(new Label(mEndConnectorsList.at(i)->getName()));
      mpConnectionEndHorizontalLayout->addWidget(createSpinBox(mEndConnectorsList.at(i)->getArrayIndex()));
    } else if (mEndConnectorsList.at(i)->isNewVariable()) {
      QLineEdit *pNewVariableTextBox = new QLineEdit;
      pNewVariableTextBox->setPlaceholderText(Helper::newVariable);
      mpConnectionEndHorizontalLayout->addWidget(pNewVariableTextBox);
    } else {
      mpConnectionEndHorizontalLayout->addWidget(new Label(mEndConnectorsList.at(i)->getName()));
    }
    if (i < mEndConnectorsList.size() -  1) {
      mpConnectionEndHorizontalLayout->addWidget(new Label("."));
    }
  }
  mpConnectionEndHorizontalLayout->addWidget(new Label(");"));
}

/*!
 * \brief CreateConnectionDialog::createConnection
 * Slot activated when mpOkButton clicked SIGNAL is raised. Creates an array connection.
 */
void CreateConnectionDialog::createConnection()
{
  QString startComponentName, endComponentName;
  // set start component name
  if (mpStartExpandableConnectorTreeView) {
    startComponentName = createComponentNameFromLayout(mpConnectionStartHorizontalLayout);
  } else {
    if (mpConnectionLineAnnotation->getStartComponent()->getParentComponent()) {
      startComponentName = mpConnectionLineAnnotation->getStartComponent()->getParentComponent()->getName();
      if (mpConnectionLineAnnotation->getStartComponent()->getRootParentComponent()->getComponentInfo()->isArray()) {
        if (mpStartRootComponentSpinBox->value() > 0) {
          startComponentName += QString("[%1]").arg(mpStartRootComponentSpinBox->value());
        }
      }
      startComponentName += ".";
    }
    startComponentName += mpConnectionLineAnnotation->getStartComponent()->getName();
    if (mpConnectionLineAnnotation->getStartComponent()->getComponentInfo()->isArray()) {
      if (mpStartComponentSpinBox->value() > 0) {
        startComponentName += QString("[%1]").arg(mpStartComponentSpinBox->value());
      }
    }
  }
  // set end component name
  if (mpEndExpandableConnectorTreeView) {
    endComponentName = createComponentNameFromLayout(mpConnectionEndHorizontalLayout);
  } else {
    if (mpConnectionLineAnnotation->getEndComponent()->getParentComponent()) {
      endComponentName = mpConnectionLineAnnotation->getEndComponent()->getParentComponent()->getName();
      if (mpConnectionLineAnnotation->getEndComponent()->getRootParentComponent()->getComponentInfo()->isArray()) {
        if (mpEndRootComponentSpinBox->value() > 0) {
          endComponentName += QString("[%1]").arg(mpEndRootComponentSpinBox->value());
        }
      }
      endComponentName += ".";
    }
    endComponentName += mpConnectionLineAnnotation->getEndComponent()->getName();
    if (mpConnectionLineAnnotation->getEndComponent()->getComponentInfo()->isArray()) {
      if (mpEndComponentSpinBox->value() > 0) {
        endComponentName += QString("[%1]").arg(mpEndComponentSpinBox->value());
      }
    }
  }
  mpConnectionLineAnnotation->setStartComponentName(startComponentName);
  mpConnectionLineAnnotation->setEndComponentName(endComponentName);
  mpGraphicsView->getModelWidget()->getUndoStack()->push(new AddConnectionCommand(mpConnectionLineAnnotation, true));
  mpGraphicsView->getModelWidget()->getLibraryTreeItem()->emitConnectionAdded(mpConnectionLineAnnotation);
  mpGraphicsView->getModelWidget()->updateModelText();
  accept();
}

/*!
 * \class CreateOrEditTransitionDialog
 * \brief A dialog interface for creating and editing transitions.
 */
/*!
 * \brief CreateOrEditTransitionDialog::CreateOrEditTransitionDialog
 * \param pGraphicsView
 * \param pTransitionLineAnnotation
 * \param editCase
 * \param pParent
 */
CreateOrEditTransitionDialog::CreateOrEditTransitionDialog(GraphicsView *pGraphicsView, LineAnnotation *pTransitionLineAnnotation,
                                                           bool editCase, QWidget *pParent)
  : QDialog(pParent), mpGraphicsView(pGraphicsView), mpTransitionLineAnnotation(pTransitionLineAnnotation), mEditCase(editCase)
{
  setAttribute(Qt::WA_DeleteOnClose);
  // heading
  if (mEditCase) {
    setWindowTitle(QString("%1 - %2").arg(Helper::applicationName).arg(Helper::editTransition));
    mpHeading = Utilities::getHeadingLabel(Helper::editTransition);
  } else {
    setWindowTitle(QString("%1 - %2").arg(Helper::applicationName).arg(Helper::createTransition));
    mpHeading = Utilities::getHeadingLabel(Helper::createTransition);
  }
  // horizontal line
  mpHorizontalLine = Utilities::getHeadingLine();
  // properties groupbox
  mpPropertiesGroupBox = new QGroupBox(Helper::properties);
  // condition
  mpConditionLabel = new Label(Helper::condition);
  mpConditionTextBox = new QLineEdit(mpTransitionLineAnnotation->getCondition());
  // immediate
  mpImmediateCheckBox = new QCheckBox(Helper::immediate);
  mpImmediateCheckBox->setChecked(mpTransitionLineAnnotation->getImmediate());
  // reset
  mpResetCheckBox = new QCheckBox(Helper::reset);
  mpResetCheckBox->setChecked(mpTransitionLineAnnotation->getReset());
  // synchronize
  mpSynchronizeCheckBox = new QCheckBox(Helper::synchronize);
  mpSynchronizeCheckBox->setChecked(mpTransitionLineAnnotation->getSynchronize());
  // priority
  mpPriorityLabel = new Label(Helper::priority);
  mpPrioritySpinBox = new QSpinBox;
  mpPrioritySpinBox->setMinimum(1);
  mpPrioritySpinBox->setValue(mpTransitionLineAnnotation->getPriority());
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isSystemLibrary() || mpGraphicsView->isVisualizationView()) {
    mpOkButton->setDisabled(true);
  }
  connect(mpOkButton, SIGNAL(clicked()), SLOT(createOrEditTransition()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // add buttons
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // properties groupbox layout
  QGridLayout *pPropertiesGridLayout = new QGridLayout;
  pPropertiesGridLayout->addWidget(mpConditionLabel, 0, 0);
  pPropertiesGridLayout->addWidget(mpConditionTextBox, 0, 1);
  pPropertiesGridLayout->addWidget(mpImmediateCheckBox, 1, 1);
  pPropertiesGridLayout->addWidget(mpResetCheckBox, 2, 1);
  pPropertiesGridLayout->addWidget(mpSynchronizeCheckBox, 3, 1);
  pPropertiesGridLayout->addWidget(mpPriorityLabel, 4, 0);
  pPropertiesGridLayout->addWidget(mpPrioritySpinBox, 4, 1);
  mpPropertiesGroupBox->setLayout(pPropertiesGridLayout);
  // main layout
  QGridLayout *pMainGridLayout = new QGridLayout;
  pMainGridLayout->setAlignment(Qt::AlignTop);
  pMainGridLayout->addWidget(mpHeading, 0, 0);
  pMainGridLayout->addWidget(mpHorizontalLine, 1, 0);
  pMainGridLayout->addWidget(mpPropertiesGroupBox, 2, 0);
  pMainGridLayout->addWidget(mpButtonBox, 3, 0, Qt::AlignRight);
  setLayout(pMainGridLayout);
}

/*!
 * \brief CreateOrEditTransitionDialog::createOrEditTransition
 * Slot activated when mpOkButton clicked SIGNAL is raised. Creates a transition.
 */
void CreateOrEditTransitionDialog::createOrEditTransition()
{
  if (mpConditionTextBox->text().isEmpty()) {
    QMessageBox::critical(mpGraphicsView, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::error),
                          GUIMessages::getMessage(GUIMessages::INVALID_TRANSITION_CONDITION), Helper::ok);
    mpConditionTextBox->setFocus(Qt::ActiveWindowFocusReason);
    return;
  }
  QString oldCondition = mpTransitionLineAnnotation->getCondition();
  mpTransitionLineAnnotation->setCondition(mpConditionTextBox->text());
  bool oldImmediate = mpTransitionLineAnnotation->getImmediate();
  mpTransitionLineAnnotation->setImmediate(mpImmediateCheckBox->isChecked());
  bool oldReset = mpTransitionLineAnnotation->getReset();
  mpTransitionLineAnnotation->setReset(mpResetCheckBox->isChecked());
  bool oldSynchronize = mpTransitionLineAnnotation->getSynchronize();
  mpTransitionLineAnnotation->setSynchronize(mpSynchronizeCheckBox->isChecked());
  int oldPriority = mpTransitionLineAnnotation->getPriority();
  mpTransitionLineAnnotation->setPriority(mpPrioritySpinBox->value());
  mpTransitionLineAnnotation->getTextAnnotation()->setVisible(true);
  if (mEditCase) {
    mpGraphicsView->getModelWidget()->getUndoStack()->push(new UpdateTransitionCommand(mpTransitionLineAnnotation, oldCondition, oldImmediate,
                                                                                       oldReset, oldSynchronize, oldPriority,
                                                                                       mpTransitionLineAnnotation->getOMCShapeAnnotation(),
                                                                                       mpConditionTextBox->text(),
                                                                                       mpImmediateCheckBox->isChecked(),
                                                                                       mpResetCheckBox->isChecked(),
                                                                                       mpSynchronizeCheckBox->isChecked(),
                                                                                       mpPrioritySpinBox->value(),
                                                                                       mpTransitionLineAnnotation->getOMCShapeAnnotation()));
  } else {
    mpGraphicsView->getModelWidget()->getUndoStack()->push(new AddTransitionCommand(mpTransitionLineAnnotation, true));
    //mpGraphicsView->getModelWidget()->getLibraryTreeItem()->emitConnectionAdded(mpTransitionLineAnnotation);
  }
  mpGraphicsView->getModelWidget()->updateModelText();
  accept();
}
