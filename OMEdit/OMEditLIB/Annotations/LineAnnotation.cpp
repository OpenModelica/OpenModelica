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
#include "Util/ResourceCache.h"

#include <QMessageBox>

LineAnnotation::LineAnnotation(QString annotation, GraphicsView *pGraphicsView)
  : ShapeAnnotation(false, pGraphicsView, 0, 0)
{
  mpOriginItem = new OriginItem(this);
  mpOriginItem->setPassive();
  setLineType(LineAnnotation::ShapeType);
  setStartElement(0);
  setStartElementName("");
  setEndElement(0);
  setEndElementName("");
  mStartAndEndElementsSelected = false;
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

LineAnnotation::LineAnnotation(ModelInstance::Line *pLine, bool inherited, GraphicsView *pGraphicsView)
  : ShapeAnnotation(inherited, pGraphicsView, 0, 0)
{
  mpOriginItem = new OriginItem(this);
  mpOriginItem->setPassive();
  mpLine = pLine;
  setLineType(LineAnnotation::ShapeType);
  setStartElement(0);
  setStartElementName("");
  setEndElement(0);
  setEndElementName("");
  mStartAndEndElementsSelected = false;
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
  parseShapeAnnotation();
  setShapeFlags(true);
}

LineAnnotation::LineAnnotation(ShapeAnnotation *pShapeAnnotation, Element *pParent)
  : ShapeAnnotation(pShapeAnnotation, pParent)
{
  mpOriginItem = 0;
  updateShape(pShapeAnnotation);
  setLineType(LineAnnotation::ComponentType);
  setStartElement(0);
  setStartElementName("");
  setEndElement(0);
  setEndElementName("");
  mStartAndEndElementsSelected = false;
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
  applyTransformation();
}

LineAnnotation::LineAnnotation(ModelInstance::Line *pLine, Element *pParent)
  : ShapeAnnotation(pParent)
{
  mpOriginItem = 0;
  mpLine = pLine;
  setLineType(LineAnnotation::ComponentType);
  setStartElement(0);
  setStartElementName("");
  setEndElement(0);
  setEndElementName("");
  mStartAndEndElementsSelected = false;
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
  parseShapeAnnotation();
  applyTransformation();
}

LineAnnotation::LineAnnotation(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView)
  : ShapeAnnotation(true, pGraphicsView, pShapeAnnotation, 0)
{
  mpOriginItem = new OriginItem(this);
  mpOriginItem->setPassive();
  updateShape(pShapeAnnotation);
  setShapeFlags(true);
  mpGraphicsView->addItem(this);
  mpGraphicsView->addItem(mpOriginItem);
}

LineAnnotation::LineAnnotation(LineAnnotation::LineType lineType, Element *pStartElement, GraphicsView *pGraphicsView)
  : ShapeAnnotation(false, pGraphicsView, 0, 0)
{
  mpOriginItem = 0;
  mLineType = lineType;
  setZValue(1000);
  // set the default values
  GraphicItem::setDefaults();
  ShapeAnnotation::setDefaults();
  // set the start component
  setStartElement(pStartElement);
  setStartElementName("");
  setEndElement(0);
  setEndElementName("");
  mStartAndEndElementsSelected = false;
  setCondition("");
  setImmediate(true);
  setReset(true);
  setSynchronize(false);
  setPriority(1);
  setOMSConnectionType(oms_connection_single);
  setActiveState(false);
  if (mLineType == LineAnnotation::ConnectionType) {
    setZValue(3000);
    /* Use the linecolor of the first shape of the start element for the connection line.
     * If there is no shape then look in the inherited shapes.
     * Or use black color if no shape is found even in inheritance.
     * Dymola is doing it the way explained above. The Modelica specification doesn't say anything about it.
     */
    if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
      if (pStartElement->getShapesList().size() > 0) {
        mLineColor = pStartElement->getShapesList().at(0)->getLineColor();
      } else {
        mLineColor = findLineColorForConnection(pStartElement);
      }
    }
    mpTextAnnotation = 0;
  } else if (mLineType == LineAnnotation::TransitionType) {
    /* From Modelica Spec 33revision1,
     * The recommended color is {175,175,175} for transition lines.
     */
    mLineColor = QColor(175, 175, 175);
    mSmooth = StringHandler::SmoothBezier;
    QString textShape = "true, {0.0, 0.0}, 0, {95, 95, 95}, {0, 0, 0}, LinePattern.Solid, FillPattern.None, 0.25, {{-4, 4}, {-4, 10}}, \"%condition\", 10, {-1, -1, -1}, "", {TextStyle.Bold}, TextAlignment.Right";
    mpTextAnnotation = new TextAnnotation(textShape, this);
  }
  // set the graphics view
  mpGraphicsView->addItem(this);
  setOldAnnotation("");

  ElementInfo *pInfo = getStartElement()->getElementInfo();
  if (pInfo) {
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
}

LineAnnotation::LineAnnotation(QString annotation, Element *pStartComponent, Element *pEndComponent, GraphicsView *pGraphicsView)
  : ShapeAnnotation(false, pGraphicsView, 0, 0)
{
  mpOriginItem = 0;
  setFlag(QGraphicsItem::ItemIsSelectable);
  mLineType = LineAnnotation::ConnectionType;
  setZValue(3000);
  // set the default values
  GraphicItem::setDefaults();
  ShapeAnnotation::setDefaults();
  // set the start component
  setStartElement(pStartComponent);
  setStartElementName("");
  // set the end component
  setEndElement(pEndComponent);
  setEndElementName("");
  mStartAndEndElementsSelected = false;
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
  QVector<QPointF> points;
  for (int i = 0 ; i < mPoints.size() ; i++) {
    QPointF point = mOrigin + mPoints[i];
    points.append(point);
  }
  mPoints = points;
  mOrigin = QPointF(0, 0);
  // set the graphics view
  mpGraphicsView->addItem(this);
}

LineAnnotation::LineAnnotation(ModelInstance::Connection *pConnection, Element *pStartComponent, Element *pEndComponent, bool inherited, GraphicsView *pGraphicsView)
  : ShapeAnnotation(inherited, pGraphicsView, 0, 0)
{
  mpOriginItem = 0;
  setFlag(QGraphicsItem::ItemIsSelectable);
  mLineType = LineAnnotation::ConnectionType;
  setZValue(3000);
  mpLine = pConnection->getAnnotation()->getLine();
  // set the default values
  GraphicItem::setDefaults();
  ShapeAnnotation::setDefaults();
  // set the start component
  setStartElement(pStartComponent);
  setStartElementName(pConnection->getStartConnector()->getName());
  // set the end component
  setEndElement(pEndComponent);
  setEndElementName(pConnection->getEndConnector()->getName());
  mStartAndEndElementsSelected = false;
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
  parseShapeAnnotation();
  /* make the points relative to origin */
  QVector<QPointF> points;
  for (int i = 0 ; i < mPoints.size() ; i++) {
    QPointF point = mOrigin + mPoints[i];
    points.append(point);
  }
  mPoints = points;
  mOrigin = QPointF(0, 0);
  // set the graphics view
  mpGraphicsView->addItem(this);
}

LineAnnotation::LineAnnotation(QString annotation, QString text, Element *pStartComponent, Element *pEndComponent, QString condition,
                               QString immediate, QString reset, QString synchronize, QString priority, GraphicsView *pGraphicsView)
  : ShapeAnnotation(false, pGraphicsView, 0, 0)
{
  mpOriginItem = 0;
  setFlag(QGraphicsItem::ItemIsSelectable);
  mLineType = LineAnnotation::TransitionType;
  setZValue(1000);
  // set the default values
  GraphicItem::setDefaults();
  ShapeAnnotation::setDefaults();
  // set the start component
  setStartElement(pStartComponent);
  setStartElementName("");
  // set the end component
  setEndElement(pEndComponent);
  setEndElementName("");
  mStartAndEndElementsSelected = false;
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
  QVector<QPointF> points;
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

LineAnnotation::LineAnnotation(ModelInstance::Transition *pTransition, Element *pStartComponent, Element *pEndComponent, bool inherited, GraphicsView *pGraphicsView)
  : ShapeAnnotation(inherited, pGraphicsView, 0, 0)
{
  mpOriginItem = 0;
  setFlag(QGraphicsItem::ItemIsSelectable);
  mLineType = LineAnnotation::TransitionType;
  setZValue(1000);
  mpLine = pTransition->getAnnotation()->getLine();
  // set the default values
  GraphicItem::setDefaults();
  ShapeAnnotation::setDefaults();
  // set the start component
  setStartElement(pStartComponent);
  setStartElementName(pTransition->getStartConnector()->getName());
  // set the end component
  setEndElement(pEndComponent);
  setEndElementName(pTransition->getEndConnector()->getName());
  mStartAndEndElementsSelected = false;
  setCondition(pTransition->getCondition() ? "true" : "false");
  setImmediate(pTransition->getImmediate());
  setReset(pTransition->getReset());
  setSynchronize(pTransition->getSynchronize());
  setPriority(pTransition->getPriority());
  setOldAnnotation("");
  setDelay("");
  setZf("");
  setZfr("");
  setAlpha("");
  setOMSConnectionType(oms_connection_single);
  setActiveState(false);
  parseShapeAnnotation();
  /* make the points relative to origin */
  QVector<QPointF> points;
  for (int i = 0 ; i < mPoints.size() ; i++) {
    QPointF point = mOrigin + mPoints[i];
    points.append(point);
  }
  mPoints = points;
  mOrigin = QPointF(0, 0);
  if (pTransition->getAnnotation()->getText()) {
    mpTextAnnotation = new TextAnnotation(pTransition->getAnnotation()->getText(), this);
  } else {
    mpTextAnnotation = 0;
  }
  // set the graphics view
  mpGraphicsView->addItem(this);
}

LineAnnotation::LineAnnotation(QString annotation, Element *pComponent, GraphicsView *pGraphicsView)
  : ShapeAnnotation(false, pGraphicsView, 0, 0)
{
  mpOriginItem = 0;
  setFlag(QGraphicsItem::ItemIsSelectable);
  mLineType = LineAnnotation::InitialStateType;
  setZValue(1000);
  // set the default values
  GraphicItem::setDefaults();
  ShapeAnnotation::setDefaults();
  // set the start component
  setStartElement(pComponent);
  setStartElementName("");
  // set the end component
  setEndElement(0);
  setEndElementName("");
  mStartAndEndElementsSelected = false;
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
  QVector<QPointF> points;
  for (int i = 0 ; i < mPoints.size() ; i++) {
    QPointF point = mOrigin + mPoints[i];
    points.append(point);
  }
  mPoints = points;
  mOrigin = QPointF(0, 0);
  // set the graphics view
  mpGraphicsView->addItem(this);
}

LineAnnotation::LineAnnotation(ModelInstance::InitialState *pInitialState, Element *pComponent, bool inherited, GraphicsView *pGraphicsView)
  : ShapeAnnotation(inherited, pGraphicsView, 0, 0)
{
  mpOriginItem = 0;
  setFlag(QGraphicsItem::ItemIsSelectable);
  mLineType = LineAnnotation::InitialStateType;
  setZValue(1000);
  mpLine = pInitialState->getAnnotation()->getLine();
  // set the default values
  GraphicItem::setDefaults();
  ShapeAnnotation::setDefaults();
  // set the start component
  setStartElement(pComponent);
  setStartElementName(pInitialState->getStartConnector()->getName());
  // set the end component
  setEndElement(0);
  setEndElementName("");
  mStartAndEndElementsSelected = false;
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
  parseShapeAnnotation();
  /* make the points relative to origin */
  QVector<QPointF> points;
  for (int i = 0 ; i < mPoints.size() ; i++) {
    QPointF point = mOrigin + mPoints[i];
    points.append(point);
  }
  mPoints = points;
  mOrigin = QPointF(0, 0);
  // set the graphics view
  mpGraphicsView->addItem(this);
}

LineAnnotation::LineAnnotation(Element *pParent)
  : ShapeAnnotation(0, pParent)
{
  mpOriginItem = 0;
  setLineType(LineAnnotation::ComponentType);
  setStartElement(0);
  setStartElementName("");
  setEndElement(0);
  setEndElementName("");
  mStartAndEndElementsSelected = false;
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
  : ShapeAnnotation(true, pGraphicsView, 0, 0)
{
  mpOriginItem = 0;
  setLineType(LineAnnotation::ShapeType);
  setStartElement(0);
  setStartElementName("");
  setEndElement(0);
  setEndElementName("");
  mStartAndEndElementsSelected = false;
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
  mPoints.parse(list.at(3));
  // add geometries for points
  for (int i = 0 ; i < mPoints.size() ; i++) {
    addGeometry();
  }
  // 5th item of list contains the color.
  mLineColor.parse(list.at(4));
  // 6th item of list contains the Line Pattern.
  mLinePattern = StringHandler::getLinePatternType(stripDynamicSelect(list.at(5)));
  // 7th item of list contains the Line thickness.
  mLineThickness.parse(list.at(6));
  // 8th item of list contains the Line Arrows.
  QStringList arrowList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(stripDynamicSelect(list.at(7))));
  if (arrowList.size() >= 2) {
    mArrow.replace(0, StringHandler::getArrowType(arrowList.at(0)));
    mArrow.replace(1, StringHandler::getArrowType(arrowList.at(1)));
  }
  // 9th item of list contains the Line Arrow Size.
  mArrowSize.parse(list.at(8));
  // 10th item of list contains the smooth.
  mSmooth = StringHandler::getSmoothType(stripDynamicSelect(list.at(9)));
}

void LineAnnotation::parseShapeAnnotation()
{
  GraphicItem::parseShapeAnnotation(mpLine);

  mPoints = mpLine->getPoints();
  // add geometries for points
  for (int i = 0 ; i < mPoints.size() ; i++) {
    addGeometry();
  }
  mPoints.evaluate(mpLine->getParentModel());
  mLineColor = mpLine->getColor();
  mLineColor.evaluate(mpLine->getParentModel());
  mLinePattern = mpLine->getPattern();
  mLinePattern.evaluate(mpLine->getParentModel());
  mLineThickness = mpLine->getThickness();
  mLineThickness.evaluate(mpLine->getParentModel());
  mArrow = mpLine->getArrow();
  mArrow.evaluate(mpLine->getParentModel());
  mArrowSize = mpLine->getArrowSize();
  mArrowSize.evaluate(mpLine->getParentModel());
  mSmooth = mpLine->getSmooth();
  mSmooth.evaluate(mpLine->getParentModel());
}

QPainterPath LineAnnotation::getShape() const
{
  PointArrayAnnotation points = mPoints;
  QPainterPath path;
  if (points.size() > 0) {
    // mPoints.size() is at least 1
    path.moveTo(points.at(0));
    if (mSmooth) {
      if (points.size() == 2) {
        // if points are only two then spline acts as simple line
        path.lineTo(points.at(1));
      } else {
        for (int i = 2 ; i < points.size() ; i++) {
          QPointF point3 = points.at(i);
          // calculate middle points for bezier curves
          QPointF point2 = points.at(i - 1);
          QPointF point1 = points.at(i - 2);
          QPointF point12((point1.x() + point2.x())/2, (point1.y() + point2.y())/2);
          QPointF point23((point2.x() + point3.x())/2, (point2.y() + point3.y())/2);
          path.lineTo(point12);
          path.cubicTo(point12, point2, point23);
          // if its the last point
          if (i == points.size() - 1) {
            path.lineTo(point3);
          }
        }
      }
    } else {
      for (int i = 1 ; i < points.size() ; i++) {
        path.lineTo(points.at(i));
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
  if (mVisible) {
    if (mLineType == LineAnnotation::TransitionType && mpGraphicsView->isVisualizationView()) {
      if (isActiveState()) {
        painter->setOpacity(1.0);
      } else {
        painter->setOpacity(0.3);
      }
    } else if (mLineType == LineAnnotation::ConnectionType) {
      if ((mpStartElement && mpStartElement->getModelComponent() && !mpStartElement->getModelComponent()->getCondition())
          || (mpEndElement && mpEndElement->getModelComponent() && !mpEndElement->getModelComponent()->getCondition())) {
        painter->setOpacity(0.3);
      }
    }
    drawAnnotation(painter);
    /* issue #9557
     * Redraw the connectors which collides with connection.
     */
    if (mLineType == LineAnnotation::ConnectionType) {
      // redraw colliding connectors
      foreach (Element *pElement, mCollidingConnectorElements) {
        if (pElement) {
          painter->save();
          pElement->reDrawConnector(painter);
          painter->restore();
        }
      }
      // draw nodes on colliding connections
      foreach (LineAnnotation *pConnection, mCollidingConnections) {
        if (pConnection) {
          PointArrayAnnotation points = pConnection->getPoints();
          if (mPoints.size() > 1 && points.size() > 1) {
            const QPointF firstPoint1 = mPoints.at(0);
            const QPointF lastPoint1 = mPoints.at(mPoints.size() - 1);
            const QPointF firstPoint2 = points.at(0);
            const QPointF lastPoint2 = points.at(points.size() - 1);
            for (int i = 0; i < mPoints.size(); ++i) {
              for (int j = 0; j < points.size(); ++j) {
                if ((mPoints.size() > i + 1) && (points.size() > j + 1)) {
                  QLineF line1(mPoints.at(i), mPoints.at(i + 1));
                  QLineF line2(points.at(j), points.at(j + 1));
                  QPointF intersectionPoint;
    #if (QT_VERSION >= QT_VERSION_CHECK(5, 14, 0))
                  QLineF::IntersectionType type = line1.intersects(line2, &intersectionPoint);
    #else // < Qt 5.14
                  QLineF::IntersectType type = line1.intersect(line2, &intersectionPoint);
    #endif // QT_VERSION_CHECK
                  /* Issue #12399. Exclude first and last points.
                   * Do not draw the node on colliding connection when the intersectionPoint is same as first or last point of connection.
                   */
                  if (type == QLineF::BoundedIntersection
                      && intersectionPoint != firstPoint1
                      && intersectionPoint != lastPoint1
                      && intersectionPoint != firstPoint2
                      && intersectionPoint != lastPoint2) {
                    painter->save();
                    painter->setPen(Qt::NoPen);
                    painter->setBrush(QBrush(mLineColor));
                    painter->drawEllipse(intersectionPoint, 0.75, 0.75);
                    painter->restore();
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

/*!
 * \brief LineAnnotation::drawAnnotation
 * Draws the line.
 * \param painter
 */
void LineAnnotation::drawAnnotation(QPainter *painter)
{
  applyLinePattern(painter);

  QPainterPath path = getShape();
  PointArrayAnnotation points = adjustPointsForDrawing();

  // draw highlight for connections
  if (mLineType == LineAnnotation::ConnectionType) {
    qreal strokeWidth = 1.0;
    QColor strokeColor = Qt::white;
    if (isSelected()) {
      strokeWidth = 2.0;
      strokeColor = QColor(255, 255, 128);
    }

    if (isSelected() || mSmooth != StringHandler::SmoothBezier) {
      QPainterPathStroker stroker;
      stroker.setWidth(strokeWidth);
      stroker.setCapStyle(Qt::SquareCap);
      stroker.setJoinStyle(Qt::MiterJoin);
      QPainterPath strokedPath = stroker.createStroke(path);
      QPen pen(strokeColor);
      pen.setCosmetic(true);
      painter->save();
      painter->setPen(Qt::NoPen);
      painter->setBrush(QBrush(strokeColor));
      painter->drawPath(strokedPath);
      painter->restore();
    }
  }

  // draw start arrow
  if (points.size() > 1) {
    /* If line is a initial state then we need to draw filled arrow.
     * From Modelica Spec 33revision1,
     * The initialState line has a filled arrow head and a bullet at the opposite end of the initial state [ as shown above ].
     */
    if (mLineType == LineAnnotation::InitialStateType) {
      drawArrow(painter, points.at(0), points.at(1), mArrowSize, StringHandler::ArrowFilled);
    } else {
      /* If line is a transition then we need to draw starting fork if needed.
       * From Modelica Spec 33revision1,
       * For synchronize=true, an inverse "fork" symbol is used in the beginning of the arrow [ See the rightmost transition above. ].
       */
      if (mLineType == LineAnnotation::TransitionType) {
        if (mSynchronize) {
          painter->save();
          QPolygonF polygon1 = perpendicularLine(points.at(0), points.at(1), 4.0);
          QPointF midPoint = (polygon1.at(0) +  polygon1.at(1)) / 2;
          QPolygonF polygon2 = perpendicularLine(midPoint, points.at(0), 4.0);
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
          polygon = perpendicularLine(points.at(points.size() - 1), points.at(points.size() - 2), 5.0);
        } else {
          polygon = perpendicularLine(points.at(0), points.at(1), 5.0);
        }
        QPen pen = painter->pen();
        pen.setWidth(2);
        painter->setPen(pen);
        painter->drawLine(polygon.at(0), polygon.at(1));
        painter->restore();
      }
      drawArrow(painter, points.at(0), points.at(1), mArrowSize, mArrow.at(0));
    }
  }

  painter->drawPath(path);

  // draw end arrow
  if (points.size() > 1) {
    /* If line is a transition then we need to draw ending arrow in any case.
     * From Modelica Spec 33revision1,
     * If reset=true, a filled arrow head is used otherwise an open arrow head.
     */
    if (mLineType == LineAnnotation::TransitionType) {
      drawArrow(painter, points.at(points.size() - 1), points.at(points.size() - 2), mArrowSize,
                mReset ? StringHandler::ArrowFilled : StringHandler::ArrowOpen);
    } else if (mLineType == LineAnnotation::InitialStateType) {
      /* If line is a initial state then we need to draw bullet.
       * From Modelica Spec 33revision1,
       * The initialState line has a filled arrow head and a bullet at the opposite end of the initial state [ as shown above ].
       */
      painter->save();
      painter->setBrush(QBrush(mLineColor, Qt::SolidPattern));
      painter->drawEllipse(points.at(points.size() - 1), 2, 2);
      painter->restore();
    } else {
      drawArrow(painter, points.at(points.size() - 1), points.at(points.size() - 2), mArrowSize, mArrow.at(1));
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
  annotationString.append(mPoints.toQString());
  // get the line color
  annotationString.append(mLineColor.toQString());
  // get the line pattern
  annotationString.append(mLinePattern.toQString());
  // get the thickness
  annotationString.append(mLineThickness.toQString());
  // get the start and end arrow
  annotationString.append(mArrow.toQString());
  // get the arrow size
  annotationString.append(mArrowSize.toQString());
  // get the smooth
  annotationString.append(mSmooth.toQString());
  return annotationString.join(",");
}

/*!
 * \brief LineAnnotation::getOMCShapeAnnotationWithShapeName
 * Returns Line annotation in format as returned by OMC wrapped in Line keyword.
 * \return
 */
QString LineAnnotation::getOMCShapeAnnotationWithShapeName()
{
  return QString("Line(%1)").arg(getOMCShapeAnnotation());
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
  if (mPoints.size() > 0) {
    annotationString.append(QString("points=%1").arg(mPoints.toQString()));
  }
  // get the line color
  if (mLineColor.isDynamicSelectExpression() || mLineColor.toQString().compare(QStringLiteral("{0,0,0}")) != 0) {
    annotationString.append(QString("color=%1").arg(mLineColor.toQString()));
  }
  // get the line pattern
  if (mLinePattern.isDynamicSelectExpression() || mLinePattern.toQString().compare(QStringLiteral("LinePattern.Solid")) != 0) {
    annotationString.append(QString("pattern=%1").arg(mLinePattern.toQString()));
  }
  // get the thickness
  if (mLineThickness.isDynamicSelectExpression() || mLineThickness.toQString().compare(QStringLiteral("0.25")) != 0) {
    annotationString.append(QString("thickness=%1").arg(mLineThickness.toQString()));
  }
  // get the start and end arrow
  if (mArrow.isDynamicSelectExpression() || mArrow.toQString().compare(QStringLiteral("{Arrow.None,Arrow.None}")) != 0) {
    annotationString.append(QString("arrow=%1").arg(mArrow.toQString()));
  }
  // get the arrow size
  if (mArrowSize.isDynamicSelectExpression() || mArrowSize.toQString().compare(QStringLiteral("3")) != 0) {
    annotationString.append(QString("arrowSize=%1").arg(mArrowSize.toQString()));
  }
  // get the smooth
  if (mSmooth.isDynamicSelectExpression() || mSmooth.toQString().compare(QStringLiteral("Smooth.None")) != 0) {
    annotationString.append(QString("smooth=%1").arg(mSmooth.toQString()));
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
  addGeometry();
}

void LineAnnotation::addGeometry()
{
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
    mPoints.setPoint(0, point);
    updateCornerItem(0);
  }
  /* update the 2nd point */
  if (mPoints.size() > 1) {
    if (mGeometries[0] == ShapeAnnotation::HorizontalLine) {
      mPoints.setPoint(1, QPointF(mPoints[1].x(), mPoints[1].y() + dy));
    } else if (mGeometries[0] == ShapeAnnotation::VerticalLine) {
      mPoints.setPoint(1, QPointF(mPoints[1].x() + dx, mPoints[1].y()));
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
      manhattanizeShape(false);
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
    if (mPoints.size() == 2 && mpEndElement) {
      // just check if additional points are really needed or not.
      if (secondLastIndex < mGeometries.size() && ((mGeometries.at(secondLastIndex) == ShapeAnnotation::HorizontalLine && mPoints.at(lastIndex).y() != point.y()) ||
                                                   (mGeometries.at(secondLastIndex) == ShapeAnnotation::VerticalLine && mPoints.at(lastIndex).x() != point.x()))) {
        insertPointsGeometriesAndCornerItems(lastIndex);
        setCornerItemsActiveOrPassive();
        lastIndex = mPoints.size() - 1;
        secondLastIndex = mPoints.size() - 2;
      }
    }
    /* update the last point */
    if (mPoints.size() > 1) {
      mPoints.setPoint(mPoints.size() - 1, point);
      updateCornerItem(lastIndex);
      /* update the 2nd point */
      if (secondLastIndex < mGeometries.size()) {
        if (mGeometries.at(secondLastIndex) == ShapeAnnotation::HorizontalLine) {
          mPoints.setPoint(secondLastIndex, QPointF(mPoints.at(secondLastIndex).x(), mPoints.at(secondLastIndex).y() + dy));
        } else if (mGeometries.at(secondLastIndex) == ShapeAnnotation::VerticalLine) {
          mPoints.setPoint(secondLastIndex, QPointF(mPoints.at(secondLastIndex).x() + dx, mPoints.at(secondLastIndex).y()));
        }
        updateCornerItem(secondLastIndex);
      }
    }
    if (!mpGraphicsView->isCreatingConnection() && !mpGraphicsView->isCreatingTransition()) {
      removeRedundantPointsGeometriesAndCornerItems();
    }
  } else {
    mPoints.setPoint(mPoints.size() - 1, point);
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
        mpTextAnnotation->setPos(mPoints.at(mPoints.size() - 1));
      } else {
        mpTextAnnotation->setPos(mPoints.at(0));
      }
    }
  }
}

/*!
 * \brief LineAnnotation::setShapeFlags
 * Sets the shape flags.
 * \param enable
 */
void LineAnnotation::setShapeFlags(bool enable)
{
  if ((mLineType == LineAnnotation::ConnectionType || mLineType == LineAnnotation::TransitionType
       || mLineType == LineAnnotation::InitialStateType || mLineType == LineAnnotation::ShapeType)
      && mpGraphicsView) {
    /* Only set the ItemIsMovable & ItemSendsGeometryChanges flags on Line if the class is not a system library class
     * AND not a visualization view
     * AND Line is not an inherited Line AND Line type is not ConnectionType.
     */
    bool isSystemLibrary = mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isSystemLibrary();
    if (!isSystemLibrary && !mpGraphicsView->isVisualizationView() && !isInheritedShape() && mLineType != LineAnnotation::ConnectionType &&
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
  setStartElement(pLineAnnotation->getStartElement());
  setStartElementName(pLineAnnotation->getStartElementName());
  setEndElement(pLineAnnotation->getEndElement());
  setEndElementName(pLineAnnotation->getEndElementName());
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
  QVector<QPointF> points = pShapeAnnotation->getPoints();
  for (int i = 0 ; i < points.size() ; i++) {
    addPoint(points[i]);
  }
  updateTransitionTextPosition();
  ShapeAnnotation::setDefaults(pShapeAnnotation);
}

ModelInstance::Extend *LineAnnotation::getExtend() const
{
  return mpLine->getParentExtend();
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
  QVector<QPointF> points = mPoints;
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

  OMSProxy::instance()->setConnectionGeometry(mpStartElement->getLibraryTreeItem()->getNameStructure(), mpEndElement->getLibraryTreeItem()->getNameStructure(), &connectionGeometry);
}

void LineAnnotation::updateToolTip()
{
  if (mLineType == LineAnnotation::ConnectionType) {
    setToolTip(QString("<b>connect</b>(%1, %2)").arg(getStartElementName()).arg(getEndElementName()));
  } else if (mLineType == LineAnnotation::TransitionType) {
    setToolTip(QString("<b>transition</b>(%1, %2, %3, %4, %5, %6, %7)")
               .arg(getStartElementName())
               .arg(getEndElementName())
               .arg(getCondition())
               .arg(getImmediate() ? "true" : "false")
               .arg(getReset() ? "true" : "false")
               .arg(getSynchronize() ? "true" : "false")
               .arg(getPriority()));
  } else if (mLineType == LineAnnotation::InitialStateType) {
    setToolTip(QString("<b>initialState</b>(%1)").arg(getStartElementName()));
  }
}

void LineAnnotation::showOMSConnection()
{
  if ((mpStartElement && mpStartElement->getLibraryTreeItem()->getOMSBusConnector())
      && (mpEndElement && mpEndElement->getLibraryTreeItem()->getOMSBusConnector())) {
    BusConnectionDialog *pBusConnectionDialog = new BusConnectionDialog(mpGraphicsView, this, false);
    pBusConnectionDialog->exec();
  } else if ((mpStartElement && mpStartElement->getLibraryTreeItem()->getOMSTLMBusConnector())
             && (mpEndElement && mpEndElement->getLibraryTreeItem()->getOMSTLMBusConnector())) {
    TLMConnectionDialog *pTLMBusConnectionDialog = new TLMConnectionDialog(mpGraphicsView, this, false);
    pTLMBusConnectionDialog->exec();
  }
}

/*!
 * \brief LineAnnotation::findLineColorForConnection
 * Finds the line color for the connection from the shapes of the start component.
 * \param pComponent
 * \return
 */
QColor LineAnnotation::findLineColorForConnection(Element *pComponent)
{
  QColor lineColor(0, 0, 0);
  foreach (Element *pInheritedComponent, pComponent->getInheritedElementsList()) {
    if (pInheritedComponent->getShapesList().size() > 0) {
      return pInheritedComponent->getShapesList().at(0)->getLineColor();
    } else {
      lineColor = findLineColorForConnection(pInheritedComponent);
    }
  }
  return lineColor;
}

/*!
 * \brief LineAnnotation::clearCollidingConnections
 * Clears the colliding connector elements and connections lists.
 */
void LineAnnotation::clearCollidingConnections()
{
  mCollidingConnectorElements.clear();
  mCollidingConnections.clear();
}

/*!
 * \brief LineAnnotation::handleCollidingConnections
 * Detect the colliding connections.\n
 * Make a list of colliding connector elements and connections.\
 * These lists will be used in the paint event to draw connectors and connection nodes.
 */
void LineAnnotation::handleCollidingConnections()
{
  QList<QGraphicsItem*> items = collidingItems(Qt::IntersectsItemShape);
  for (int i = 0; i < items.size(); ++i) {
    if (Element *pElement = dynamic_cast<Element*>(items.at(i))) {
      if ((mpGraphicsView->getModelWidget()->isNewApi() && pElement->getModel() && pElement->getModel()->isConnector())
          || (pElement->getLibraryTreeItem() && pElement->getLibraryTreeItem()->isConnector())) {
        mCollidingConnectorElements.append(pElement);
      }
    } else if (LineAnnotation *pConnectionAnnotation = dynamic_cast<LineAnnotation*>(items.at(i))) {
      if (mSmooth != StringHandler::SmoothBezier && pConnectionAnnotation->getSmooth() != StringHandler::SmoothBezier && pConnectionAnnotation->isConnection()
          && (mpStartElement == pConnectionAnnotation->getStartElement() || mpStartElement == pConnectionAnnotation->getEndElement()
              || mpEndElement == pConnectionAnnotation->getStartElement() || mpEndElement == pConnectionAnnotation->getEndElement())) {
        mCollidingConnections.append(pConnectionAnnotation);
      }
    }
  }
}

/*!
 * \brief LineAnnotation::adjustPointsForDrawing
 * Adjusts the start and end points of the connection to the center of start and end connectors.
 * This only updates the points for drawing and does not modify the actual values for Modelica code.
 * \return
 */
PointArrayAnnotation LineAnnotation::adjustPointsForDrawing() const
{
  PointArrayAnnotation points = mPoints;
  if (isConnection()) {
    if (mpStartElement && (points.size() > 0) && qFuzzyCompare(mpStartElement->sceneBoundingRect().width(), mpStartElement->sceneBoundingRect().height())) {
      points.setPoint(0, mpStartElement->sceneBoundingRect().center());
    }
    if (mpEndElement && (points.size() > 1) && qFuzzyCompare(mpEndElement->sceneBoundingRect().width(), mpEndElement->sceneBoundingRect().height())) {
      points.setPoint(points.size() - 1, mpEndElement->sceneBoundingRect().center());
    }
  }
  return points;
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
 * If the component associated with the connection is moved then update the connection accordingly.
 * \param positionChanged
 */
void LineAnnotation::handleComponentMoved(bool positionChanged)
{
  if (mPoints.size() < 2) {
    return;
  }
  prepareGeometryChange();
  // if both start and end component are selected and positionChanged is true
  if (positionChanged && mpStartElement && mpStartElement->getRootParentElement()->isSelected() && mpEndElement && mpEndElement->getRootParentElement()->isSelected()) {
    if (mpStartElement) {
      QPointF offset = mpStartElement->mapToScene(mpStartElement->boundingRect().center()) - mPoints[0];
      for (int i = 0 ; i < mPoints.size() ; i++) {
        mPoints.setPoint(i, QPointF(mPoints[i].x() + offset.x(), mPoints[i].y() + offset.y()));
        updateCornerItem(i);
      }
    }
  } else {
    if (mpStartElement) {
      Element *pElement = qobject_cast<Element*>(sender());
      if (pElement == mpStartElement->getRootParentElement()) {
        updateStartPoint(mpGraphicsView->roundPoint(mpStartElement->mapToScene(mpStartElement->boundingRect().center())));
        if (mLineType == LineAnnotation::TransitionType) {
          QRectF sceneRectF = mpStartElement->sceneBoundingRect();
          QList<QPointF> newPos = Utilities::liangBarskyClipper(sceneRectF.topLeft().x(), sceneRectF.topLeft().y(),
                                                                sceneRectF.bottomRight().x(), sceneRectF.bottomRight().y(),
                                                                mPoints.at(0).x(), mPoints.at(0).y(),
                                                                mPoints.at(1).x(), mPoints.at(1).y());
          updateStartPoint(mpGraphicsView->roundPoint(newPos.at(1)));
          updateTransitionTextPosition();
        } else if (mLineType == LineAnnotation::InitialStateType) {
          QRectF sceneRectF = mpStartElement->sceneBoundingRect();
          QList<QPointF> newPos = Utilities::liangBarskyClipper(sceneRectF.topLeft().x(), sceneRectF.topLeft().y(),
                                                                sceneRectF.bottomRight().x(), sceneRectF.bottomRight().y(),
                                                                mPoints.at(0).x(), mPoints.at(0).y(),
                                                                mPoints.at(1).x(), mPoints.at(1).y());
          updateStartPoint(mpGraphicsView->roundPoint(newPos.at(1)));
        }
      }
    }
    if (mpEndElement) {
      Element *pElement = qobject_cast<Element*>(sender());
      if (pElement == mpEndElement->getRootParentElement()) {
        updateEndPoint(mpGraphicsView->roundPoint(mpEndElement->mapToScene(mpEndElement->boundingRect().center())));
        if (mLineType == LineAnnotation::TransitionType) {
          QRectF sceneRectF = mpEndElement->sceneBoundingRect();
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
  } else {
    // get the connection line annotation.
    QString annotationString = QString("annotate=$annotation(%1)").arg(getShapeAnnotation());
    // update the connection
    OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
    pOMCProxy->updateConnection(mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure(), getStartElementName(), getEndElementName(), annotationString);
  }
}

/*!
 * \brief LineAnnotation::updateConnectionTransformation
 * Slot activated when Component transformChanging SIGNAL is emitted.\n
 * Updates the connection.
 */
void LineAnnotation::updateConnectionTransformation()
{
  /* If both start and end component are selected then this function is called twice.
   * we use the flag mStartAndEndComponentSelected to make sure that we only use this function once in such case.
   */
  if (mpStartElement && mpStartElement->getRootParentElement()->isSelected()
      && mpEndElement && mpEndElement->getRootParentElement()->isSelected()
      && mpStartElement->getRootParentElement() != mpEndElement->getRootParentElement() && !mStartAndEndElementsSelected) {
      mStartAndEndElementsSelected = true;
      return;
  } else if (mStartAndEndElementsSelected) {
    mStartAndEndElementsSelected = false;
  }

  if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
    updateOMSConnection();
  } else {
    if (!mOldAnnotation.isEmpty()) {
      if (mLineType == LineAnnotation::ConnectionType) {
        mpGraphicsView->getModelWidget()->getUndoStack()->push(new UpdateConnectionCommand(this, mOldAnnotation, getOMCShapeAnnotation()));
      } else if (mLineType == LineAnnotation::TransitionType) {
        mpGraphicsView->getModelWidget()->getUndoStack()->push(new UpdateTransitionCommand(this, mCondition, mImmediate, mReset, mSynchronize, mPriority, mOldAnnotation,
                                                                                           mCondition, mImmediate, mReset, mSynchronize, mPriority, getOMCShapeAnnotation()));
      } else if (mLineType == LineAnnotation::InitialStateType) {
        mpGraphicsView->getModelWidget()->getUndoStack()->push(new UpdateInitialStateCommand(this, mOldAnnotation, getOMCShapeAnnotation()));
      }
    }
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
  pOMCProxy->updateTransition(mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure(), getStartElementName(),
                              getEndElementName(), oldCondition, oldImmediate, oldReset, oldSynchronize, oldPriority, getCondition(),
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
  pOMCProxy->updateInitialState(mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure(), getStartElementName(), annotationString);
}

/*!
 * \brief LineAnnotation::duplicate
 * Duplicates the shape.
 */
void LineAnnotation::duplicate()
{
  LineAnnotation *pLineAnnotation = new LineAnnotation("", mpGraphicsView);
  pLineAnnotation->updateShape(this);
  QPointF gridStep(mpGraphicsView->mMergedCoOrdinateSystem.getHorizontalGridStep() * 5,
                   mpGraphicsView->mMergedCoOrdinateSystem.getVerticalGridStep() * 5);
  pLineAnnotation->setOrigin(mOrigin + gridStep);
  pLineAnnotation->drawCornerItems();
  pLineAnnotation->setCornerItemsActiveOrPassive();
  pLineAnnotation->applyTransformation();
  pLineAnnotation->update();
  mpGraphicsView->getModelWidget()->getUndoStack()->push(new AddShapeCommand(pLineAnnotation));
  mpGraphicsView->getModelWidget()->getLibraryTreeItem()->emitShapeAdded(pLineAnnotation, mpGraphicsView);
  setSelected(false);
  pLineAnnotation->setSelected(true);
}

void LineAnnotation::redraw(const QString& annotation, std::function<void()> updateAnnotationFunction)
{
  prepareGeometryChange();
  parseShapeAnnotation(annotation);
  removeCornerItems();
  drawCornerItems();
  applyTransformation();
  adjustGeometries();
  setCornerItemsActiveOrPassive();
  emitChanged();
  updateAnnotationFunction();
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
  setArrayIndexes(QStringList());
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
ExpandableConnectorTreeItem::ExpandableConnectorTreeItem(QString name, bool array, QStringList arrayIndexes, StringHandler::ModelicaClasses restriction, bool newVariable,
                                                         ExpandableConnectorTreeItem *pParentExpandableConnectorTreeItem)
{
  mIsRootItem = false;
  mpParentExpandableConnectorTreeItem = pParentExpandableConnectorTreeItem;
  setName(name);
  setArray(array);
  setArrayIndexes(arrayIndexes);
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
              return ResourceCache::getIcon(":/Resources/icons/connect-mode.svg");
              break;
            case StringHandler::Connector:
              return ResourceCache::getIcon(":/Resources/icons/connector-icon.svg");
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
    return Qt::ItemFlags();
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

/*!
 * \brief ExpandableConnectorTreeModel::createExpandableConnectorTreeItem
 * Creates the ExpandableConnectorTreeItem
 * \param pModelElement
 * \param pParentExpandableConnectorTreeItem
 */
void ExpandableConnectorTreeModel::createExpandableConnectorTreeItem(ModelInstance::Component *pModelComponent, ExpandableConnectorTreeItem *pParentExpandableConnectorTreeItem)
{
  StringHandler::ModelicaClasses restriction = StringHandler::Model;
  if (pModelComponent->getModel()) {
    restriction = StringHandler::getModelicaClassType(pModelComponent->getModel()->getRestriction());
  }
  ExpandableConnectorTreeItem *pExpandableConnectorTreeItem = new ExpandableConnectorTreeItem(pModelComponent->getName(), pModelComponent->getDimensions().isArray(),
                                                                                              pModelComponent->getDimensions().getTypedDimensions(),
                                                                                              restriction, false, pParentExpandableConnectorTreeItem);
  int row = pParentExpandableConnectorTreeItem->getChildren().size();
  QModelIndex index = expandableConnectorTreeItemIndex(pParentExpandableConnectorTreeItem);
  beginInsertRows(index, row, row);
  pParentExpandableConnectorTreeItem->insertChild(row, pExpandableConnectorTreeItem);
  endInsertRows();
  if (pModelComponent->getModel()) {
    QList<ModelInstance::Element*> elements = pModelComponent->getModel()->getElements();
    foreach (auto pChildModelElement, elements) {
      if (pChildModelElement->isComponent()) {
        auto pChildModelComponent = dynamic_cast<ModelInstance::Component*>(pChildModelElement);
        createExpandableConnectorTreeItem(pChildModelComponent, pExpandableConnectorTreeItem);
      }
    }
  }
  // create add variable item only if item is expandable connector
  if (pExpandableConnectorTreeItem->getRestriction() == StringHandler::ExpandableConnector) {
    ExpandableConnectorTreeItem *pNewVariableExpandableConnectorTreeItem = new ExpandableConnectorTreeItem(Helper::newVariable, false, QStringList(), StringHandler::Model,
                                                                                                           true, pExpandableConnectorTreeItem);
    int row = pExpandableConnectorTreeItem->getChildren().size();
    QModelIndex index = expandableConnectorTreeItemIndex(pExpandableConnectorTreeItem);
    beginInsertRows(index, row, row);
    pExpandableConnectorTreeItem->insertChild(row, pNewVariableExpandableConnectorTreeItem);
    endInsertRows();
  }
}

/*!
 * \brief ExpandableConnectorTreeModel::createExpandableConnectorTreeItem
 * Creates the ExpandableConnectorTreeItem
 * \param pElement
 * \param pParentExpandableConnectorTreeItem
 */
void ExpandableConnectorTreeModel::createExpandableConnectorTreeItem(Element *pElement, ExpandableConnectorTreeItem *pParentExpandableConnectorTreeItem)
{
  StringHandler::ModelicaClasses restriction = StringHandler::Model;
  if (pElement->getLibraryTreeItem()) {
    restriction = pElement->getLibraryTreeItem()->getRestriction();
  }
  ExpandableConnectorTreeItem *pExpandableConnectorTreeItem = new ExpandableConnectorTreeItem(pElement->getName(), pElement->isArray(), pElement->getTypedArrayIndexes(), restriction,
                                                                                              false, pParentExpandableConnectorTreeItem);
  int row = pParentExpandableConnectorTreeItem->getChildren().size();
  QModelIndex index = expandableConnectorTreeItemIndex(pParentExpandableConnectorTreeItem);
  beginInsertRows(index, row, row);
  pParentExpandableConnectorTreeItem->insertChild(row, pExpandableConnectorTreeItem);
  endInsertRows();
  if (pElement->getLibraryTreeItem() && pElement->getLibraryTreeItem()->getModelWidget()) {
    foreach (Element *pChildElement, pElement->getLibraryTreeItem()->getModelWidget()->getDiagramGraphicsView()->getElementsList()) {
      createExpandableConnectorTreeItem(pChildElement, pExpandableConnectorTreeItem);
    }
  }
  // create add variable item only if item is expandable connector
  if (pExpandableConnectorTreeItem->getRestriction() == StringHandler::ExpandableConnector) {
    ExpandableConnectorTreeItem *pNewVariableExpandableConnectorTreeItem = new ExpandableConnectorTreeItem(Helper::newVariable, false, QStringList(), StringHandler::Model,
                                                                                                           true, pExpandableConnectorTreeItem);
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
CreateConnectionDialog::CreateConnectionDialog(GraphicsView *pGraphicsView, LineAnnotation *pConnectionLineAnnotation, bool createConnector, QWidget *pParent)
    : QDialog(pParent), mpGraphicsView(pGraphicsView), mpConnectionLineAnnotation(pConnectionLineAnnotation), mCreateConnector(createConnector)
{
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::createConnection));
  setAttribute(Qt::WA_DeleteOnClose);
  // heading
  mpHeading = Utilities::getHeadingLabel(Helper::createConnection);
  // horizontal line
  mpHorizontalLine = Utilities::getHeadingLine();
  // Start expandable connector treeview
  mpStartExpandableConnectorTreeView = 0;
  mpStartElement = mpConnectionLineAnnotation->getStartElement();
  mpStartRootElement = mpStartElement->getParentElement() ? mpStartElement->getRootParentElement() : mpStartElement;
  if (mpStartElement->isExpandableConnector() || (mpStartRootElement && mpStartRootElement->isExpandableConnector())) {
    mpStartExpandableConnectorTreeModel = new ExpandableConnectorTreeModel(this);
    mpStartExpandableConnectorTreeProxyModel = new ExpandableConnectorTreeProxyModel(this);
    mpStartExpandableConnectorTreeProxyModel->setDynamicSortFilter(true);
    mpStartExpandableConnectorTreeProxyModel->setSourceModel(mpStartExpandableConnectorTreeModel);
    mpStartExpandableConnectorTreeView = new ExpandableConnectorTreeView(this);
    mpStartExpandableConnectorTreeView->setModel(mpStartExpandableConnectorTreeProxyModel);
    if (mpGraphicsView->getModelWidget()->isNewApi()) {
      mpStartExpandableConnectorTreeModel->createExpandableConnectorTreeItem(mpStartElement->getRootParentElement()->getModelComponent(),
                                                                             mpStartExpandableConnectorTreeModel->getRootExpandableConnectorTreeItem());
    } else {
      mpStartExpandableConnectorTreeModel->createExpandableConnectorTreeItem(mpStartElement->getRootParentElement(),
                                                                             mpStartExpandableConnectorTreeModel->getRootExpandableConnectorTreeItem());
    }
    mpStartExpandableConnectorTreeView->expandAll();
    mpStartExpandableConnectorTreeView->setSortingEnabled(true);
    mpStartExpandableConnectorTreeView->sortByColumn(0, Qt::AscendingOrder);
    connect(mpStartExpandableConnectorTreeView->selectionModel(), SIGNAL(currentChanged(QModelIndex,QModelIndex)), SLOT(startConnectorChanged(QModelIndex,QModelIndex)));
  }
  // End expandable connector treeview
  mpEndElement = mpConnectionLineAnnotation->getEndElement();
  mpEndRootElement = mpEndElement->getParentElement() ? mpEndElement->getRootParentElement() : mpEndElement;
  mpEndExpandableConnectorTreeView = 0;
  if (mpEndElement->isExpandableConnector() || (mpEndRootElement && mpEndRootElement->isExpandableConnector())) {
    mpEndExpandableConnectorTreeModel = new ExpandableConnectorTreeModel(this);
    mpEndExpandableConnectorTreeProxyModel = new ExpandableConnectorTreeProxyModel(this);
    mpEndExpandableConnectorTreeProxyModel->setDynamicSortFilter(true);
    mpEndExpandableConnectorTreeProxyModel->setSourceModel(mpEndExpandableConnectorTreeModel);
    mpEndExpandableConnectorTreeView = new ExpandableConnectorTreeView(this);
    mpEndExpandableConnectorTreeView->setModel(mpEndExpandableConnectorTreeProxyModel);
    if (mpGraphicsView->getModelWidget()->isNewApi()) {
      mpEndExpandableConnectorTreeModel->createExpandableConnectorTreeItem(mpEndElement->getRootParentElement()->getModelComponent(),
                                                                           mpEndExpandableConnectorTreeModel->getRootExpandableConnectorTreeItem());
    } else {
      mpEndExpandableConnectorTreeModel->createExpandableConnectorTreeItem(mpEndElement->getRootParentElement(),
                                                                           mpEndExpandableConnectorTreeModel->getRootExpandableConnectorTreeItem());
    }
    mpEndExpandableConnectorTreeView->expandAll();
    mpEndExpandableConnectorTreeView->setSortingEnabled(true);
    mpEndExpandableConnectorTreeView->sortByColumn(0, Qt::AscendingOrder);
    connect(mpEndExpandableConnectorTreeView->selectionModel(), SIGNAL(currentChanged(QModelIndex,QModelIndex)), SLOT(endConnectorChanged(QModelIndex,QModelIndex)));
  }
  // Indexes Description text
  mpIndexesDescriptionLabel = new Label(tr("Specify the indexes below to connect to the parts of the connectors."));
  mStartRootElementSpinBoxList.clear();
  mStartElementSpinBoxList.clear();
  mEndRootElementSpinBoxList.clear();
  mEndElementSpinBoxList.clear();
  // only create normal start connector controls if start connector is not expandable
  if (!mpStartExpandableConnectorTreeView) {
    if (mpStartElement->getParentElement()) {
      mpStartRootElementLabel = new Label(mpStartRootElement->getName());
      if (mpStartRootElement->isArray() && !mpStartRootElement->isConnectorSizing()) {
        mStartRootElementSpinBoxList = createSpinBoxes(mpStartRootElement);
      }
    }
    mpStartElementLabel = new Label(mpStartElement->getName());
    if (mpStartElement->isArray() && !mpStartElement->isConnectorSizing()) {
      mStartElementSpinBoxList = createSpinBoxes(mpStartElement);
    }
  }
  // only create normal end connector controls if end connector is not expandable
  if (!mpEndExpandableConnectorTreeView) {
    if (mpEndElement->getParentElement()) {
      mpEndRootElementLabel = new Label(mpEndRootElement->getName());
      if (mpEndRootElement->isArray() && !mpEndRootElement->isConnectorSizing()) {
        mEndRootElementSpinBoxList = createSpinBoxes(mpEndRootElement);
      }
    }
    mpEndElementLabel = new Label(mpEndElement->getName());
    if (mpEndElement->isArray() && !mpEndElement->isConnectorSizing()) {
      mEndElementSpinBoxList = createSpinBoxes(mpEndElement);
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
  if (!mStartRootElementSpinBoxList.isEmpty() || !mStartElementSpinBoxList.isEmpty() || !mEndRootElementSpinBoxList.isEmpty() || !mEndElementSpinBoxList.isEmpty()) {
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
    if (mpStartElement->getParentElement()) {
      mpConnectionStartHorizontalLayout->addWidget(mpStartRootElementLabel);
      if (mpStartRootElement->isArray() && !mpStartRootElement->isConnectorSizing()) {
        foreach (QSpinBox *pSpinBox, mStartRootElementSpinBoxList) {
          mpConnectionStartHorizontalLayout->addWidget(pSpinBox);
        }
      }
      mpConnectionStartHorizontalLayout->addWidget(new Label("."));
    }
    mpConnectionStartHorizontalLayout->addWidget(mpStartElementLabel);
    if (mpStartElement->isArray() && !mpStartElement->isConnectorSizing()) {
      foreach (QSpinBox *pSpinBox, mStartElementSpinBoxList) {
        mpConnectionStartHorizontalLayout->addWidget(pSpinBox);
      }
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
    if (mpEndElement->getParentElement()) {
      mpConnectionEndHorizontalLayout->addWidget(mpEndRootElementLabel);
      if (mpEndRootElement->isArray() && !mpEndRootElement->isConnectorSizing()) {
        foreach (QSpinBox *pSpinBox, mEndRootElementSpinBoxList) {
          mpConnectionEndHorizontalLayout->addWidget(pSpinBox);
        }
      }
      mpConnectionEndHorizontalLayout->addWidget(new Label("."));
    }
    mpConnectionEndHorizontalLayout->addWidget(mpEndElementLabel);
    if (mpEndElement->isArray() && !mpEndElement->isConnectorSizing()) {
      foreach (QSpinBox *pSpinBox, mEndElementSpinBoxList) {
        mpConnectionEndHorizontalLayout->addWidget(pSpinBox);
      }
    }
    mpConnectionEndHorizontalLayout->addWidget(new Label(");"));
  }
  mpMainLayout->addLayout(mpConnectionEndHorizontalLayout, row, 1, 1, 1, Qt::AlignLeft);
  row++;
  mpMainLayout->addWidget(mpButtonBox, row, 0, 1, 2, Qt::AlignRight);
  setLayout(mpMainLayout);
}

/*!
 * \brief CreateConnectionDialog::createSpinBoxes
 * Creates a list of spinboxes.
 * \param pElement
 * \return
 */
QList<QSpinBox *> CreateConnectionDialog::createSpinBoxes(Element *pElement)
{
  return createSpinBoxes(pElement->getTypedArrayIndexes());
}

/*!
 * \brief CreateConnectionDialog::createSpinBoxes
 * Creates a list of spinboxes.
 * \param arrayIndexes
 * \return
 */
QList<QSpinBox *> CreateConnectionDialog::createSpinBoxes(const QStringList &arrayIndexes)
{
  QList<QSpinBox*> spinBoxesList;
  for (int i = 0; i < arrayIndexes.size(); ++i) {
    spinBoxesList.append(createSpinBox(arrayIndexes[i], i, arrayIndexes.size()));
  }
  return spinBoxesList;
}

/*!
 * \brief CreateConnectionDialog::createSpinBox
 * Creates a QSpinBox with arrayIndex limit.
 * \param arrayIndex
 * \param position
 * \param length
 * \return
 */
QSpinBox* CreateConnectionDialog::createSpinBox(QString arrayIndex, int position, int length)
{
  QSpinBox *pSpinBox = new QSpinBox;
  QString start = "";
  QString end = "";
  if (position == 0 || length == 1) {
    start = "[";
    pSpinBox->setPrefix(start);
  }
  if (length == 1 || position + 1 == length) {
    end = "]";
  } else {
    end = ",";
  }
  pSpinBox->setSuffix(end);
  pSpinBox->setSpecialValueText(QString("%1:%2").arg(start, end));
  int intArrayIndex = arrayIndex.toInt();
  if (intArrayIndex > 0) {
    pSpinBox->setMaximum(intArrayIndex);
  }
  return pSpinBox;
}

/*!
 * \brief CreateConnectionDialog::createComponentNameFromLayout
 * Creates a element name from the layout controls. Used when we have expandable connectors.
 * \param pLayout
 * \return
 */
QString CreateConnectionDialog::createElementNameFromLayout(QHBoxLayout *pLayout)
{
  QString elementName;
  bool spinbox = false;
  int i = 0;
  while (QLayoutItem* pLayoutItem = pLayout->itemAt(i)) {
    if (dynamic_cast<Label*>(pLayoutItem->widget()) || dynamic_cast<QLineEdit*>(pLayoutItem->widget())) {
      if (spinbox) {
        elementName += QString("]");
        spinbox = false;
      }
      if (dynamic_cast<Label*>(pLayoutItem->widget())) {
        Label *pLabel = dynamic_cast<Label*>(pLayoutItem->widget());
        if (pLabel->text().compare(",") != 0 && pLabel->text().compare(");") != 0) {  // "," & ");" are fixed labels so we skip them here.
          elementName += pLabel->text();
        }
      } else if (dynamic_cast<QLineEdit*>(pLayoutItem->widget())) {
        QLineEdit *pLineEdit = dynamic_cast<QLineEdit*>(pLayoutItem->widget());
        if (pLineEdit->text().isEmpty()) {
          elementName += "ERROR";
        } else {
          elementName += pLineEdit->text();
        }
      }
    } else if (dynamic_cast<QSpinBox*>(pLayoutItem->widget())) {
      QSpinBox *pSpinBox = dynamic_cast<QSpinBox*>(pLayoutItem->widget());
      if (pSpinBox->value() > 0) {
        if (spinbox) {
          elementName += QString(",%1").arg(pSpinBox->value());
        } else {
          spinbox = true;
          elementName += QString("[%1").arg(pSpinBox->value());
        }
      }
    }
    i++;
  }
  return elementName;
}

QStringList getElementIndexes(QList<QSpinBox*> spinBoxList)
{
  QStringList elementIndexes;
  foreach (QSpinBox *pSpinBox, spinBoxList) {
    if (pSpinBox->value() > 0) {
      elementIndexes.append(QString::number(pSpinBox->value()));
    }
  }
  return elementIndexes;
}

/*!
 * \brief CreateConnectionDialog::getElementConnectionName
 * Checks if element1 is array then make an array connection.
 * If element1 is an array with connectorSizing then connect to element2.
 * If element2 is also an array use its size to define the connectorSizing on element1.
 * \param pGraphicsView
 * \param pExpandableConnectorTreeView
 * \param pConnectionHorizontalLayout
 * \param pElement1
 * \param pRootElement1
 * \param pElementSpinBox1
 * \param pRootElementSpinBox1
 * \param pElement2
 * \param pRootElement2
 * \param pElementSpinBox2
 * \param pRootElementSpinBox2
 * \return
 */
QString CreateConnectionDialog::getElementConnectionName(GraphicsView *pGraphicsView, ExpandableConnectorTreeView *pExpandableConnectorTreeView,
                                                         QHBoxLayout *pConnectionHorizontalLayout, Element *pElement1, Element *pRootElement1, QList<QSpinBox*> elementSpinBoxList1,
                                                         QList<QSpinBox*> rootElementSpinBoxList1, Element *pElement2, Element *pRootElement2, QList<QSpinBox*> elementSpinBoxList2,
                                                         QList<QSpinBox*> rootElementSpinBoxList2)
{
  QString elementName;
  if (pExpandableConnectorTreeView) {
    elementName = CreateConnectionDialog::createElementNameFromLayout(pConnectionHorizontalLayout);
  } else {
    /* if element1 is an array try to make an array connection.
     * Parent element can't be connectorSizing.
     */
    if (pElement1->getParentElement()) {
      elementName = pElement1->getRootParentElement()->getName();
      if (pRootElement1->isArray()) {
        QStringList rootElementIndexes = getElementIndexes(rootElementSpinBoxList1);
        if (!rootElementIndexes.isEmpty()) {
          elementName += QString("[%1]").arg(rootElementIndexes.join(","));
        }
      }
      elementName += ".";
    }
    elementName += pElement1->getName();
    // If the element1 is an array and not connectorSizing then try to make array connection.
    if (pElement1->isArray() && !pElement1->isConnectorSizing()) {
      QStringList elementIndexes = getElementIndexes(elementSpinBoxList1);
      if (!elementIndexes.isEmpty()) {
        elementName += QString("[%1]").arg(elementIndexes.join(","));
      }
    } else if (pElement1->isConnectorSizing()) {  // If the element1 is a connectorSizing then use the element2 to find the connectorSizing value.
      int numberOfElementConnections = pGraphicsView->numberOfElementConnections(pElement1);
      if (pElement2->isExpandableConnector()) {
        elementName += QString("[%1]").arg(++numberOfElementConnections);
      } else if (pElement2->getParentElement() && pRootElement2->isArray() && !pRootElement2->isConnectorSizing()) {
        if ((!rootElementSpinBoxList2.isEmpty() && rootElementSpinBoxList2.at(0)->value() > 0) || pRootElement2->getArrayIndexAsNumber() == 0) {
          elementName += QString("[%1]").arg(++numberOfElementConnections);
        } else {
          int endConnectionIndex = numberOfElementConnections + pRootElement2->getArrayIndexAsNumber();
          elementName += QString("[%1:%2]").arg(++numberOfElementConnections).arg(endConnectionIndex);
        }
      } else if (pElement2->isArray() && !pElement2->isConnectorSizing()) {
        if ((!elementSpinBoxList2.isEmpty() && elementSpinBoxList2.at(0)->value() > 0) || pElement2->getArrayIndexAsNumber() == 0) {
          elementName += QString("[%1]").arg(++numberOfElementConnections);
        } else {
          int endConnectionIndex = numberOfElementConnections + pElement2->getArrayIndexAsNumber();
          elementName += QString("[%1:%2]").arg(++numberOfElementConnections).arg(endConnectionIndex);
        }
      }
    }
  }
  return elementName;
}

/*!
 * \brief CreateConnectionDialog::startConnectorChanged
 * Updates the start element name in the connection.
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
    /* Issue #12150. When nothing inside expandable connector is enabled so we end up here because of invalid QModelIndex.
     * In that case just use the connector name.
     * The same is done in CreateConnectionDialog::endConnectorChanged for end connector.
     */
    mpConnectionStartHorizontalLayout->addWidget(new Label(mpGraphicsView->getConnectorName(mpStartElement)));
  } else {
    mStartConnectorsList.append(pExpandableConnectorTreeItem);
    while (pExpandableConnectorTreeItem->parent() && pExpandableConnectorTreeItem->parent() != mpStartExpandableConnectorTreeModel->getRootExpandableConnectorTreeItem()) {
      pExpandableConnectorTreeItem = pExpandableConnectorTreeItem->parent();
      mStartConnectorsList.prepend(pExpandableConnectorTreeItem);
    }
  }

  for (int i = 0 ; i < mStartConnectorsList.size() ; i++) {
    if (mStartConnectorsList.at(i)->isArray()) {
      mpConnectionStartHorizontalLayout->addWidget(new Label(mStartConnectorsList.at(i)->getName()));
      QList<QSpinBox *> spinBoxes = createSpinBoxes(mStartConnectorsList.at(i)->getArrayIndexes());
      foreach (QSpinBox *pSpinBox, spinBoxes) {
        mpConnectionStartHorizontalLayout->addWidget(pSpinBox);
      }
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
 * Updates the end element name in the connection.
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
    // Issue #12150. See the comment in CreateConnectionDialog::startConnectorChanged.
    mpConnectionEndHorizontalLayout->addWidget(new Label(mpGraphicsView->getConnectorName(mpEndElement)));
  } else {
    mEndConnectorsList.append(pExpandableConnectorTreeItem);
    while (pExpandableConnectorTreeItem->parent() && pExpandableConnectorTreeItem->parent() != mpEndExpandableConnectorTreeModel->getRootExpandableConnectorTreeItem()) {
      pExpandableConnectorTreeItem = pExpandableConnectorTreeItem->parent();
      mEndConnectorsList.prepend(pExpandableConnectorTreeItem);
    }
  }

  for (int i = 0 ; i < mEndConnectorsList.size() ; i++) {
    if (mEndConnectorsList.at(i)->isArray()) {
      mpConnectionEndHorizontalLayout->addWidget(new Label(mEndConnectorsList.at(i)->getName()));
      QList<QSpinBox *> spinBoxes = createSpinBoxes(mEndConnectorsList.at(i)->getArrayIndexes());
      foreach (QSpinBox *pSpinBox, spinBoxes) {
        mpConnectionEndHorizontalLayout->addWidget(pSpinBox);
      }
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
  // set start element name
  QString startElementName = CreateConnectionDialog::getElementConnectionName(mpGraphicsView, mpStartExpandableConnectorTreeView, mpConnectionStartHorizontalLayout,
                                                                              mpStartElement, mpStartRootElement, mStartElementSpinBoxList, mStartRootElementSpinBoxList,
                                                                              mpEndElement, mpEndRootElement, mEndElementSpinBoxList, mEndRootElementSpinBoxList);
  // set end element name
  QString endElementName = CreateConnectionDialog::getElementConnectionName(mpGraphicsView, mpEndExpandableConnectorTreeView, mpConnectionEndHorizontalLayout,
                                                                            mpEndElement, mpEndRootElement, mEndElementSpinBoxList, mEndRootElementSpinBoxList,
                                                                            mpStartElement, mpStartRootElement, mStartElementSpinBoxList, mStartRootElementSpinBoxList);
  mpConnectionLineAnnotation->setStartElementName(startElementName);
  mpConnectionLineAnnotation->setEndElementName(endElementName);
  if (mpGraphicsView->getModelWidget()->isNewApi()) {
    /* Issue #12163. Do not check connection validity when called from GraphicsView::createConnector
     * GraphicsView::createConnector creates an incomplete connector. We do this for performance reasons. Avoid calling getModelInstance API.
     * We know for sure that both connectors are compatible in this case so its okay not to check for validity.
     */
    if (mCreateConnector) {
      mpConnectionLineAnnotation->drawCornerItems();
      mpConnectionLineAnnotation->setCornerItemsActiveOrPassive();
      mpGraphicsView->addConnectionToView(mpConnectionLineAnnotation, false);
      mpGraphicsView->addConnectionToClass(mpConnectionLineAnnotation);
    } else if (mpGraphicsView->getModelWidget()->getModelInstance()->isValidConnection(startElementName, endElementName)) {
      mpGraphicsView->getModelWidget()->getUndoStack()->push(new AddConnectionCommand(mpConnectionLineAnnotation, true));
      mpGraphicsView->getModelWidget()->updateModelText();
    } else {
      QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                            GUIMessages::getMessage(GUIMessages::MISMATCHED_CONNECTORS_IN_CONNECT).arg(startElementName, endElementName), Helper::ok);
      reject();
    }
  } else {
    mpGraphicsView->getModelWidget()->getUndoStack()->push(new AddConnectionCommand(mpConnectionLineAnnotation, true));
    mpGraphicsView->getModelWidget()->getLibraryTreeItem()->emitConnectionAdded(mpConnectionLineAnnotation);
    mpGraphicsView->getModelWidget()->updateModelText();
  }
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
  if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isSystemLibrary()) {
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

void LineAnnotation::setProperties(const QString& condition, const bool immediate, const bool rest, const bool synchronize, const int priority)
{
  setCondition(condition);
  setImmediate(immediate);
  setReset(rest);
  setSynchronize(synchronize);
  setPriority(priority);
  getTextAnnotation()->setTextString("%condition");
}

void LineAnnotation::updateTransistion(const QString& condition, const bool immediate, const bool rest, const bool synchronize, const int priority)
{
  getTextAnnotation()->updateTextString();
  updateTransitionTextPosition();
  updateTransitionAnnotation(condition, immediate, rest, synchronize, priority);
  updateToolTip();
}
