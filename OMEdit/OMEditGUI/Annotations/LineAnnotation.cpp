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
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
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
 *
 * @author Adeel Asghar <adeel.asghar@liu.se>
 *
 * RCS: $Id$
 *
 */

#include "LineAnnotation.h"

LineAnnotation::LineAnnotation(QString annotation, Component *pParent)
  : ShapeAnnotation(pParent)
{
  mLineType = LineAnnotation::ComponentType;
  mpStartComponent = 0;
  mpEndComponent = 0;
  // set the default values
  GraphicItem::setDefaults();
  ShapeAnnotation::setDefaults();
  parseShapeAnnotation(annotation);
  setPos(mOrigin);
}

LineAnnotation::LineAnnotation(QString annotation, GraphicsView *pGraphicsView)
  : ShapeAnnotation(pGraphicsView, 0)
{
  setFlag(QGraphicsItem::ItemIsSelectable);
  mLineType = LineAnnotation::ShapeType;
  mpStartComponent = 0;
  mpEndComponent = 0;
  // set the default values
  GraphicItem::setDefaults();
  ShapeAnnotation::setDefaults();
  // set users default value by reading the settings file.
  ShapeAnnotation::setUserDefaults();
  parseShapeAnnotation(annotation);
  /* Only set the ItemIsMovable flag on shape if the class is not a system library class. */
  if (!mpGraphicsView->getModelWidget()->getLibraryTreeNode()->isSystemLibrary())
    setFlag(QGraphicsItem::ItemIsMovable);
  mpGraphicsView->addShapeObject(this);
  mpGraphicsView->scene()->addItem(this);
  connect(this, SIGNAL(updateClassAnnotation()), mpGraphicsView, SLOT(addClassAnnotation()));
}

LineAnnotation::LineAnnotation(Component *pStartComponent, GraphicsView *pGraphicsView)
  : ShapeAnnotation(pGraphicsView, 0)
{
  setFlag(QGraphicsItem::ItemIsSelectable);
  mLineType = LineAnnotation::ConnectionType;
  setZValue(-1.0);
  // set the default values
  GraphicItem::setDefaults();
  ShapeAnnotation::setDefaults();
  // set the graphics view
  mpGraphicsView->scene()->addItem(this);
  // set the start component
  setStartComponent(pStartComponent);
}

LineAnnotation::LineAnnotation(QString annotation, Component *pStartComponent, Component *pEndComponent, GraphicsView *pGraphicsView)
  : ShapeAnnotation(pGraphicsView, 0)
{
  setFlag(QGraphicsItem::ItemIsSelectable);
  mLineType = LineAnnotation::ConnectionType;
  setZValue(-1.0);
  // set the default values
  GraphicItem::setDefaults();
  ShapeAnnotation::setDefaults();
  // set the start component
  setStartComponent(pStartComponent);
  // set the end component
  setEndComponent(pEndComponent);
  parseShapeAnnotation(annotation);
  // set the graphics view
  mpGraphicsView->scene()->addItem(this);
}

void LineAnnotation::parseShapeAnnotation(QString annotation)
{
  GraphicItem::parseShapeAnnotation(annotation);
  // parse the shape to get the list of attributes of Line.
  QStringList list = StringHandler::getStrings(annotation);
  if (list.size() < 10)
    return;
  // 4th item of list contains the points.
  QStringList pointsList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(3)));
  foreach (QString point, pointsList)
  {
    QStringList linePoints = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(point));
    if (linePoints.size() >= 2)
      addPoint(QPointF(linePoints.at(0).toFloat(), linePoints.at(1).toFloat()));
  }
  // 5th item of list contains the color.
  QStringList colorList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(4)));
  if (colorList.size() >= 3)
  {
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
  if (arrowList.size() >= 2)
  {
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
  if (mPoints.size() > 0)
  {
    if (mSmooth)
    {
      for (int i = 0 ; i < mPoints.size() ; i++)
      {
  QPointF point3 = mPoints.at(i);
  if (i == 0)
    path.moveTo(point3);
  else
  {
    // if points are only two then spline acts as simple line
    if (i < 2)
    {
      if (mPoints.size() < 3)
        path.lineTo(point3);
    }
    else
    {
      // calculate middle points for bezier curves
      QPointF point2 = mPoints.at(i - 1);
      QPointF point1 = mPoints.at(i - 2);
      QPointF point12((point1.x() + point2.x())/2, (point1.y() + point2.y())/2);
      QPointF point23((point2.x() + point3.x())/2, (point2.y() + point3.y())/2);
      path.lineTo(point12);
      path.cubicTo(point12, point2, point23);
      // if its the last point
      if (i == mPoints.size() - 1)
        path.lineTo(point3);
    }
  }
      }
    }
    else
    {
      for (int i = 0 ; i < mPoints.size() ; i++)
      {
  QPointF point1 = mPoints.at(i);
  if (i == 0)
    path.moveTo(point1);
  else
    path.lineTo(point1);
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
  if (mVisible)
    drawLineAnnotaion(painter);
}

void LineAnnotation::drawLineAnnotaion(QPainter *painter)
{
  applyLinePattern(painter);
  // draw start arrow
  if (mPoints.size() > 1)
  {
    if (mArrow.at(0) == StringHandler::ArrowFilled)
    {
      painter->save();
      painter->setBrush(QBrush(mLineColor, Qt::SolidPattern));
      painter->drawPolygon(drawArrow(mPoints.at(0), mPoints.at(1), mArrowSize, mArrow.at(0)));
      painter->restore();
    }
    else
    {
      painter->drawPolygon(drawArrow(mPoints.at(0), mPoints.at(1), mArrowSize, mArrow.at(0)));
    }
  }
  painter->drawPath(getShape());
  // draw end arrow
  if (mPoints.size() > 1)
  {
    if (mArrow.at(1) == StringHandler::ArrowFilled)
    {
      painter->save();
      painter->setBrush(QBrush(mLineColor, Qt::SolidPattern));
      painter->drawPolygon(drawArrow(mPoints.at(mPoints.size() - 1), mPoints.at(mPoints.size() - 2), mArrowSize, mArrow.at(1)));
      painter->restore();
    }
    else
    {
      painter->drawPolygon(drawArrow(mPoints.at(mPoints.size() - 1), mPoints.at(mPoints.size() - 2), mArrowSize, mArrow.at(1)));
    }
  }
}

QPolygonF LineAnnotation::drawArrow(QPointF startPos, QPointF endPos, qreal size, int arrowType) const
{
  double xA = size / 2;
  double yA = size * sqrt(3) / 2;
  double xB = -xA;
  double yB = yA;
  switch (arrowType)
  {
    case StringHandler::ArrowFilled:
      break;
    case StringHandler::ArrowHalf:
      xB = 0;
      break;
    case StringHandler::ArrowNone:
      return QPolygonF();
    case StringHandler::ArrowOpen:
      break;
  }
  double angle = 0.0f;
  if (endPos.x() - startPos.x() == 0)
  {
    if (endPos.y() - startPos.y() >= 0)
      angle = 0;
    else
      angle = M_PI;
  }
  else
  {
    angle = -(M_PI / 2 - (atan((endPos.y() - startPos.y())/(endPos.x() - startPos.x()))));
    if(startPos.x() > endPos.x())
      angle += M_PI;
  }
  qreal m11, m12, m13, m21, m22, m23, m31, m32, m33;
  m11 = cos(angle);
  m12 = -sin(angle);
  m13 = startPos.x();
  m21 = sin(angle);
  m22 = cos(angle);
  m23 = startPos.y();
  m31 = 0;
  m32 = 0;
  m33 = 1;
  QTransform t1(m11, m12, m13, m21, m22, m23, m31, m32, m33);
  QTransform t2(xA, 1, 1, yA, 1, 1, 1, 1, 1);
  QTransform t3 = t1 * t2;
  QPolygonF polygon;
  polygon << startPos;
  polygon << QPointF(t3.m11(), t3.m21());
  t2.setMatrix(xB, 1, 1, yB, 1, 1, 1, 1, 1);
  t3 = t1 * t2;
  polygon << QPointF(t3.m11(), t3.m21());
  polygon << startPos;
  return polygon;
}

QString LineAnnotation::getShapeAnnotation()
{
  QStringList annotationString;
  annotationString.append(GraphicItem::getShapeAnnotation());
  // get points
  QString pointsString;
  if (mPoints.size() > 0)
    pointsString.append("points={");
  for (int i = 0 ; i < mPoints.size() ; i++)
  {
    pointsString.append("{").append(QString::number(mPoints[i].x())).append(",");
    pointsString.append(QString::number(mPoints[i].y())).append("}");
    if (i < mPoints.size() - 1)
      pointsString.append(",");
  }
  if (mPoints.size() > 0)
  {
    pointsString.append("}");
    annotationString.append(pointsString);
  }
  // get the line color
  if (mLineColor != Qt::black)
  {
    QString colorString;
    colorString.append("color={");
    colorString.append(QString::number(mLineColor.red())).append(",");
    colorString.append(QString::number(mLineColor.green())).append(",");
    colorString.append(QString::number(mLineColor.blue()));
    colorString.append("}");
    annotationString.append(colorString);
  }
  // get the line pattern
  if (mLinePattern != StringHandler::LineSolid)
    annotationString.append(QString("pattern=").append(StringHandler::getLinePatternString(mLinePattern)));
  // get the thickness
  if (mLineThickness != 0.25)
    annotationString.append(QString("thickness=").append(QString::number(mLineThickness)));
  // get the start and end arrow
  if ((mArrow.at(0) != StringHandler::ArrowNone) || (mArrow.at(1) != StringHandler::ArrowNone))
  {
    QString arrowString;
    arrowString.append("arrow=");
    arrowString.append("{").append(StringHandler::getArrowString(mArrow.at(0))).append(",");
    arrowString.append(StringHandler::getArrowString(mArrow.at(1))).append("}");
    annotationString.append(arrowString);
  }
  // get the arrow size
  if (mArrowSize != 3)
    annotationString.append(QString("arrowSize=").append(QString::number(mArrowSize)));
  // get the smooth
  if (mSmooth != StringHandler::SmoothNone)
    annotationString.append(QString("smooth=").append(StringHandler::getSmoothString(mSmooth)));
  return QString("Line(").append(annotationString.join(",")).append(")");
}

void LineAnnotation::setStartComponent(Component *pStartComponent)
{
  mpStartComponent = pStartComponent;
}

Component* LineAnnotation::getStartComponent()
{
  return mpStartComponent;
}

void LineAnnotation::setEndComponent(Component *pEndComponent)
{
  mpEndComponent = pEndComponent;
}

Component* LineAnnotation::getEndComponent()
{
  return mpEndComponent;
}

void LineAnnotation::addPoint(QPointF point)
{
  mPoints.append(point);
  qreal startAngle = 0;
  switch (mLineType)
  {
    case LineAnnotation::ConnectionType:
      if (mpStartComponent)
  startAngle = StringHandler::getNormalizedAngle(mpStartComponent->getRootParentComponent()->getTransformation()->getRotateAngle());
      if(mPoints.size() <= 2 && (startAngle >= 0 && startAngle < 90))
      {
  mGeometries.push_back(LineAnnotation::Horizontal);
      }
      else if(mPoints.size() <= 2 && (startAngle >= 90 && startAngle < 180))
      {
  mGeometries.push_back(LineAnnotation::Vertical);
      }
      else if(mPoints.size() <= 2 && (startAngle >= 180 && startAngle < 270))
      {
  mGeometries.push_back(LineAnnotation::Horizontal);
      }
      else if(mPoints.size() <= 2 && (startAngle >= 270 && startAngle < 360))
      {
  mGeometries.push_back(LineAnnotation::Vertical);
      }
      else if (mPoints.size() <= 2)
      {
  mGeometries.push_back(LineAnnotation::Horizontal);
      }
      else if(mPoints.size() > 2 && mGeometries.back() == LineAnnotation::Horizontal)
      {
  mGeometries.push_back(LineAnnotation::Vertical);
      }
      else if(mPoints.size() > 2 && mGeometries.back() == LineAnnotation::Vertical)
      {
  mGeometries.push_back(LineAnnotation::Horizontal);
      }
      else if(mPoints.size() > 2 && mGeometries.back() == LineAnnotation::Diagonal)
      {
  mGeometries.push_back(LineAnnotation::Diagonal);
  //Give new line correct angle!
      }
      break;
    default:
      break;
  }
}

//! Updates the first point of the connection, and adjusts the second point accordingly depending on the geometry list.
//! @param point is the new start point.
//! @see updateEndPoint(QPointF point)
void LineAnnotation::updateStartPoint(QPointF point)
{
  if (mPoints.size() == 0)
    mPoints.push_back(point);
  else
    mPoints[0] = point;
  /* update the 1st CornerItem */
  if (mCornerItemsList.size() > 0)
    mCornerItemsList[0]->setPos(point);
  /* update the 2nd point */
  if (mPoints.size() != 1)
  {
    if (mGeometries[0] == LineAnnotation::Horizontal)
      mPoints[1] = QPointF(mPoints[1].x(),mPoints[0].y());
    else if (mGeometries[0] == LineAnnotation::Vertical)
      mPoints[1] = QPointF(mPoints[0].x(),mPoints[1].y());
    /* updated the 2nd CornerItem */
    if (mCornerItemsList.size() > 1)
      mCornerItemsList[1]->setPos(mPoints[1]);
  }
}

void LineAnnotation::updateEndPoint(QPointF point)
{
  mPoints.back() = point;
  switch (mLineType)
  {
    case LineAnnotation::ConnectionType:
      /* updated the last CornerItem */
      if (mCornerItemsList.size() > (mPoints.size() - 1))
  mCornerItemsList[mPoints.size() - 1]->setPos(point);
      /* update the 2nd last point */
      if (mGeometries.back() == LineAnnotation::Horizontal)
  mPoints[mPoints.size() - 2] = QPointF(mPoints[mPoints.size() - 2].x(),point.y());
      else if (mGeometries.back() == LineAnnotation::Vertical)
  mPoints[mPoints.size() - 2] = QPointF(point.x(),mPoints[mPoints.size() - 2].y());
      /* updated the 2nd last CornerItem */
      if (mCornerItemsList.size() > (mPoints.size() - 2))
  mCornerItemsList[mPoints.size() - 2]->setPos(mPoints[mPoints.size() - 2]);
      break;
    default:
      break;
  }
}

void LineAnnotation::moveAllPoints(qreal offsetX, qreal offsetY)
{
  for(int i = 0 ; i < mPoints.size() ; i++)
  {
    mPoints[i] = QPointF(mPoints[i].x()+offsetX, mPoints[i].y()+offsetY);
    /* updated the corresponding the CornerItem */
    if (mCornerItemsList.size() > i)
      mCornerItemsList[i]->setPos(mPoints[i]);
  }
}

LineAnnotation::LineType LineAnnotation::getLineType()
{
  return mLineType;
}

void LineAnnotation::setStartComponentName(QString name)
{
  mStartComponentName = name;
}

QString LineAnnotation::getStartComponentName()
{
  return mStartComponentName;
}

void LineAnnotation::setEndComponentName(QString name)
{
  mEndComponentName = name;
}

QString LineAnnotation::getEndComponentName()
{
  return mEndComponentName;
}

void LineAnnotation::handleComponentMoved()
{
  if (mPoints.size() < 2)
    return;
  // if both the components are moved then move the whole connection
  if (mpStartComponent && mpEndComponent)
  {
    if (mpStartComponent->getRootParentComponent()->isSelected() && mpEndComponent->getRootParentComponent()->isSelected())
    {
      moveAllPoints(mpStartComponent->mapToScene(mpStartComponent->boundingRect().center()).x() - mPoints[0].x(),
              mpStartComponent->mapToScene(mpStartComponent->boundingRect().center()).y() - mPoints[0].y());
    }
    else
    {
      Component *pComponent = qobject_cast<Component*>(sender());
      if (pComponent == mpStartComponent->getRootParentComponent())
  updateStartPoint(mpStartComponent->mapToScene(mpStartComponent->boundingRect().center()));
      else if (pComponent == mpEndComponent->getRootParentComponent())
  updateEndPoint(mpEndComponent->mapToScene(mpEndComponent->boundingRect().center()));
    }
  }
  else if (mpStartComponent)
  {
    Component *pComponent = qobject_cast<Component*>(sender());
    if (pComponent == mpStartComponent->getRootParentComponent())
      updateStartPoint(mpStartComponent->mapToScene(mpStartComponent->boundingRect().center()));
  }
  else if (mpEndComponent)
  {
    Component *pComponent = qobject_cast<Component*>(sender());
    if (pComponent == mpEndComponent->getRootParentComponent())
      updateEndPoint(mpEndComponent->mapToScene(mpEndComponent->boundingRect().center()));
  }
  update();
}

void LineAnnotation::handleComponentRotation()
{
  if (mPoints.size() < 2)
    return;
  if (mpStartComponent)
  {
    Component *pComponent = qobject_cast<Component*>(sender());
    if (pComponent == mpStartComponent->getRootParentComponent())
      updateStartPoint(mpStartComponent->mapToScene(mpStartComponent->boundingRect().center()));
  }
  if (mpEndComponent)
  {
    Component *pComponent = qobject_cast<Component*>(sender());
    if (pComponent == mpEndComponent->getRootParentComponent())
      updateEndPoint(mpEndComponent->mapToScene(mpEndComponent->boundingRect().center()));
  }
  update();
}

void LineAnnotation::updateConnectionAnnotation()
{
  // get the connection line annotation.
  QString annotationString = QString("annotate=").append(getShapeAnnotation());
  // update the connection
  OMCProxy *pOMCProxy = mpGraphicsView->getModelWidget()->getModelWidgetContainer()->getMainWindow()->getOMCProxy();
  pOMCProxy->updateConnection(getStartComponentName(), getEndComponentName(),
                        mpGraphicsView->getModelWidget()->getLibraryTreeNode()->getNameStructure(), annotationString);
}

ConnectionArray::ConnectionArray(GraphicsView *pGraphicsView, LineAnnotation *pConnectionLineAnnotation, QWidget *pParent)
  : QDialog(pParent, Qt::WindowTitleHint), mpGraphicsView(pGraphicsView), mpConnectionLineAnnotation(pConnectionLineAnnotation)
{
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::connectArray));
  setAttribute(Qt::WA_DeleteOnClose);
  setModal(true);
  // heading
  mpHeading = new Label(Helper::connectArray);
  mpHeading->setFont(QFont(Helper::systemFontInfo.family(), Helper::headingFontSize));
  mpHeading->setAlignment(Qt::AlignTop);
  // horizontal line
  mpHorizontalLine = new QFrame();
  mpHorizontalLine->setFrameShape(QFrame::HLine);
  mpHorizontalLine->setFrameShadow(QFrame::Sunken);
  // Description text
  QString startComponentDescription = QString("<b>").append(pConnectionLineAnnotation->getStartComponent()->getParentComponent()->getName())
      .append(".").append(pConnectionLineAnnotation->getStartComponent()->getName()).append("</b>");
  if (pConnectionLineAnnotation->getStartComponent()->getComponentInfo()->isArray())
    startComponentDescription.append("<b>[index]</b>");
  QString endComponentDescription = QString("<b>").append(pConnectionLineAnnotation->getEndComponent()->getParentComponent()->getName())
      .append(".").append(pConnectionLineAnnotation->getEndComponent()->getName()).append("</b>");
  if (pConnectionLineAnnotation->getEndComponent()->getComponentInfo()->isArray())
    endComponentDescription.append("<b>[index]</b>");
  mpDescriptionLabel = new Label(QString("Connect ").append(startComponentDescription).append(" with ").append(endComponentDescription));
  // start component
  QIntValidator *pIntValidator = new QIntValidator(this);
  pIntValidator->setBottom(0);
  mpStartComponentLabel = new Label(tr("Enter <b>index</b> value for <b>").append(pConnectionLineAnnotation->getStartComponent()->getParentComponent()->getName())
                              .append(".").append(pConnectionLineAnnotation->getStartComponent()->getName()).append("<b>"));
  mpStartComponentTextBox = new QLineEdit;
  mpStartComponentTextBox->setValidator(pIntValidator);
  // start component
  mpEndComponentLabel = new Label(tr("Enter <b>index</b> value for <b>").append(pConnectionLineAnnotation->getEndComponent()->getParentComponent()->getName())
                            .append(".").append(pConnectionLineAnnotation->getEndComponent()->getComponentInfo()->getName()).append("</b>"));
  mpEndComponentTextBox = new QLineEdit;
  mpEndComponentTextBox->setValidator(pIntValidator);
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(saveArrayIndex()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(cancelArrayIndex()));
  // add buttons
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // Create a layout
  QGridLayout *mainLayout = new QGridLayout;
  mainLayout->addWidget(mpHeading, 0, 0);
  mainLayout->addWidget(mpHorizontalLine, 1, 0);
  mainLayout->addWidget(mpDescriptionLabel, 2, 0);
  int i = 3;
  if (pConnectionLineAnnotation->getStartComponent()->getComponentInfo()->isArray())
  {
    mainLayout->addWidget(mpStartComponentLabel, i, 0);
    mainLayout->addWidget(mpStartComponentTextBox, i+1, 0);
    i = i + 2;
  }
  if (pConnectionLineAnnotation->getEndComponent()->getComponentInfo()->isArray())
  {
    mainLayout->addWidget(mpEndComponentLabel, i, 0);
    mainLayout->addWidget(mpEndComponentTextBox, i+1, 0);
    i = i + 2;
  }
  mainLayout->addWidget(mpButtonBox, i, 0);
  setLayout(mainLayout);
}

void ConnectionArray::saveArrayIndex()
{
  QString startComponentName, endComponentName;
  // set start component name
  if (mpConnectionLineAnnotation->getStartComponent()->getComponentInfo()->isArray())
  {
    startComponentName = QString(mpConnectionLineAnnotation->getStartComponent()->getParentComponent()->getName()).append(".")
  .append(mpConnectionLineAnnotation->getStartComponent()->getName());
    if (mpStartComponentTextBox->text().isEmpty())
    {
      QMessageBox::critical(mpGraphicsView->getModelWidget()->getModelWidgetContainer()->getMainWindow(),
                      QString(Helper::applicationName).append(" - ").append(Helper::error),
                      GUIMessages::getMessage(GUIMessages::ENTER_VALID_INTEGER).arg(startComponentName), Helper::ok);
      return;
    }
    startComponentName = QString(startComponentName).append("[").append(mpStartComponentTextBox->text()).append("]");
  }
  else
  {
    startComponentName = QString(mpConnectionLineAnnotation->getStartComponent()->getParentComponent()->getName()).append(".")
  .append(mpConnectionLineAnnotation->getStartComponent()->getName());
  }
  // set end component name
  if (mpConnectionLineAnnotation->getEndComponent()->getComponentInfo()->isArray())
  {
    endComponentName = QString(mpConnectionLineAnnotation->getEndComponent()->getParentComponent()->getName()).append(".")
  .append(mpConnectionLineAnnotation->getEndComponent()->getName());
    if (mpEndComponentTextBox->text().isEmpty())
    {
      QMessageBox::critical(mpGraphicsView->getModelWidget()->getModelWidgetContainer()->getMainWindow(),
                      QString(Helper::applicationName).append(" - ").append(Helper::error),
                      GUIMessages::getMessage(GUIMessages::ENTER_VALID_INTEGER).arg(endComponentName), Helper::ok);
      return;
    }
    endComponentName = QString(endComponentName).append("[").append(mpEndComponentTextBox->text()).append("]");
  }
  else
  {
    endComponentName = QString(mpConnectionLineAnnotation->getEndComponent()->getParentComponent()->getName()).append(".")
  .append(mpConnectionLineAnnotation->getEndComponent()->getName());
  }
  mpGraphicsView->createConnection(startComponentName, endComponentName);
  accept();
}

void ConnectionArray::cancelArrayIndex()
{
  mpGraphicsView->removeConnection();
  reject();
}
