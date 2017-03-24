/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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

#ifndef LINEANNOTATION_H
#define LINEANNOTATION_H

#include "ShapeAnnotation.h"

#include <QTreeView>
#include <QSortFilterProxyModel>
#include <QSpinBox>
#include <QUndoCommand>

class Label;
class Component;
class LineAnnotation : public ShapeAnnotation
{
  Q_OBJECT
public:
  enum LineType {
    ComponentType,  /* Line is within Component. */
    ConnectionType,  /* Line is a connection. */
    ShapeType  /* Line is a custom shape. */
  };
  // Used for icon/diagram shape
  LineAnnotation(QString annotation, GraphicsView *pGraphicsView);
  // Used for shape inside a component
  LineAnnotation(ShapeAnnotation *pShapeAnnotation, Component *pParent);
  // Used for icon/diagram inherited shape
  LineAnnotation(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView);
  // Used for creating connection
  LineAnnotation(Component *pStartComponent, GraphicsView *pGraphicsView);
  // Used for reading a connection
  LineAnnotation(QString annotation, Component *pStartComponent, Component *pEndComponent, GraphicsView *pGraphicsView);
  // Used for non-exisiting component
  LineAnnotation(Component *pParent);
  // Used for non-existing class
  LineAnnotation(GraphicsView *pGraphicsView);
  void parseShapeAnnotation(QString annotation);
  QPainterPath getShape() const;
  QRectF boundingRect() const;
  QPainterPath shape() const;
  void paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget = 0);
  void drawLineAnnotaion(QPainter *painter);
  void drawArrow(QPainter *painter, QPointF startPos, QPointF endPos, qreal size, int arrowType) const;
  QString getOMCShapeAnnotation();
  QString getShapeAnnotation();
  QString getCompositeModelShapeAnnotation();
  void addPoint(QPointF point);
  void removePoint(int index);
  void clearPoints();
  void updateStartPoint(QPointF point);
  void updateEndPoint(QPointF point);
  void moveAllPoints(qreal offsetX, qreal offsetY);
  void setLineType(LineType lineType) {mLineType = lineType;}
  LineType getLineType() {return mLineType;}
  void setStartComponent(Component *pStartComponent) {mpStartComponent = pStartComponent;}
  Component* getStartComponent() {return mpStartComponent;}
  void setStartComponentName(QString name) {mStartComponentName = name;}
  QString getStartComponentName() {return mStartComponentName;}
  void setEndComponent(Component *pEndComponent) {mpEndComponent = pEndComponent;}
  Component* getEndComponent() {return mpEndComponent;}
  void setEndComponentName(QString name) {mEndComponentName = name;}
  QString getEndComponentName() {return mEndComponentName;}
  void setOldAnnotation(QString oldAnnotation) {mOldAnnotation = oldAnnotation;}
  QString getOldAnnotation() {return mOldAnnotation;}
  void setDelay(QString delay) {mDelay = delay;}
  QString getDelay() {return mDelay;}
  void setZf(QString zf) {mZf = zf;}
  QString getZf() {return mZf;}
  void setZfr(QString zfr) {mZfr = zfr;}
  QString getZfr() {return mZfr;}
  void setAlpha(QString alpha) {mAlpha = alpha;}
  QString getAlpha() {return mAlpha;}
  void setShapeFlags(bool enable);
  void updateShape(ShapeAnnotation *pShapeAnnotation);
  void setAligned(bool aligned);
protected:
  QVariant itemChange(GraphicsItemChange change, const QVariant &value);

  private:
  LineType mLineType;
  Component *mpStartComponent;
  QString mStartComponentName;
  Component *mpEndComponent;
  QString mEndComponentName;
  QString mOldAnnotation;
  // CompositeModel attributes
  QString mDelay;
  QString mZf;
  QString mZfr;
  QString mAlpha;
public slots:
  void handleComponentMoved();
  void updateConnectionAnnotation();
  void updateConnectionTransformation(QUndoCommand *pUndoCommand);
  void duplicate();
};

class ExpandableConnectorTreeItem : public QObject
{
  Q_OBJECT
public:
  ExpandableConnectorTreeItem();
  ExpandableConnectorTreeItem(QString name, bool array, QString arrayIndex, StringHandler::ModelicaClasses restriction, bool newVariable,
                              ExpandableConnectorTreeItem *pParentExpandableConnectorTreeItem);
  ~ExpandableConnectorTreeItem();
  bool isRootItem() {return mIsRootItem;}
  QList<ExpandableConnectorTreeItem*> getChildren() const {return mChildren;}
  void setName(QString name) {mName = name;}
  const QString& getName() const {return mName;}
  void setArray(bool array) {mArray = array;}
  bool isArray() {return mArray;}
  void setArrayIndex(QString arrayIndex) {mArrayIndex = arrayIndex;}
  const QString& getArrayIndex() const {return mArrayIndex;}
  void setRestriction(StringHandler::ModelicaClasses restriction) {mRestriction = restriction;}
  StringHandler::ModelicaClasses getRestriction() {return mRestriction;}
  void setNewVariable(bool newVariable) {mNewVariable = newVariable;}
  bool isNewVariable() {return mNewVariable;}
  void insertChild(int position, ExpandableConnectorTreeItem *pExpandableConnectorTreeItem) {mChildren.insert(position, pExpandableConnectorTreeItem);}
  ExpandableConnectorTreeItem* child(int row) {return mChildren.value(row);}
  QVariant data(int column, int role = Qt::DisplayRole) const;
  int row() const;
  ExpandableConnectorTreeItem* parent() {return mpParentExpandableConnectorTreeItem;}
private:
  bool mIsRootItem;
  ExpandableConnectorTreeItem *mpParentExpandableConnectorTreeItem;
  QList<ExpandableConnectorTreeItem*> mChildren;
  QString mName;
  bool mArray;
  QString mArrayIndex;
  StringHandler::ModelicaClasses mRestriction;
  bool mNewVariable;
};

class CreateConnectionDialog;

class ExpandableConnectorTreeProxyModel : public QSortFilterProxyModel
{
  Q_OBJECT
public:
  ExpandableConnectorTreeProxyModel(CreateConnectionDialog *pCreateConnectionDialog);
private:
  CreateConnectionDialog *mpCreateConnectionDialog;
};

class ExpandableConnectorTreeModel : public QAbstractItemModel
{
  Q_OBJECT
public:
  ExpandableConnectorTreeModel(CreateConnectionDialog *pCreateConnectionDialog);
  ExpandableConnectorTreeItem* getRootExpandableConnectorTreeItem() {return mpRootExpandableConnectorTreeItem;}
  int columnCount(const QModelIndex &parent = QModelIndex()) const;
  int rowCount(const QModelIndex &parent = QModelIndex()) const;
  QVariant headerData(int section, Qt::Orientation orientation, int role = Qt::DisplayRole) const;
  QModelIndex index(int row, int column, const QModelIndex &parent = QModelIndex()) const;
  QModelIndex parent(const QModelIndex & index) const;
  QVariant data(const QModelIndex & index, int role = Qt::DisplayRole) const;
  Qt::ItemFlags flags(const QModelIndex &index) const;
  QModelIndex findFirstEnabledItem(ExpandableConnectorTreeItem *pExpandableConnectorTreeItem);
  QModelIndex expandableConnectorTreeItemIndex(const ExpandableConnectorTreeItem *pExpandableConnectorTreeItem) const;
  void createExpandableConnectorTreeItem(Component *pComponent, ExpandableConnectorTreeItem *pParentExpandableConnectorTreeItem);
private:
  CreateConnectionDialog *mpCreateConnectionDialog;
  ExpandableConnectorTreeItem *mpRootExpandableConnectorTreeItem;

  QModelIndex expandableConnectorTreeItemIndexHelper(const ExpandableConnectorTreeItem *pExpandableConnectorTreeItem,
                                                     const ExpandableConnectorTreeItem *pParentExpandableConnectorTreeItem,
                                                     const QModelIndex &parentIndex) const;
};

class ExpandableConnectorTreeView : public QTreeView
{
  Q_OBJECT
public:
  ExpandableConnectorTreeView(CreateConnectionDialog *pCreateConnectionDialog);
private:
  CreateConnectionDialog *mpCreateConnectionDialog;
};

class CreateConnectionDialog : public QDialog
{
  Q_OBJECT
public:
  CreateConnectionDialog(GraphicsView *pGraphicsView, LineAnnotation *pConnectionLineAnnotation, QWidget *pParent = 0);
private:
  GraphicsView *mpGraphicsView;
  LineAnnotation *mpConnectionLineAnnotation;
  Label *mpHeading;
  QFrame *mpHorizontalLine;
  ExpandableConnectorTreeModel *mpStartExpandableConnectorTreeModel;
  ExpandableConnectorTreeProxyModel *mpStartExpandableConnectorTreeProxyModel;
  ExpandableConnectorTreeView *mpStartExpandableConnectorTreeView;
  QList<ExpandableConnectorTreeItem*> mStartConnectorsList;
  ExpandableConnectorTreeModel *mpEndExpandableConnectorTreeModel;
  ExpandableConnectorTreeProxyModel *mpEndExpandableConnectorTreeProxyModel;
  ExpandableConnectorTreeView *mpEndExpandableConnectorTreeView;
  QList<ExpandableConnectorTreeItem*> mEndConnectorsList;
  Label *mpIndexesDescriptionLabel;
  Label *mpStartRootComponentLabel;
  QSpinBox *mpStartRootComponentSpinBox;
  Label *mpStartComponentLabel;
  QSpinBox *mpStartComponentSpinBox;
  Label *mpEndRootComponentLabel;
  QSpinBox *mpEndRootComponentSpinBox;
  Label *mpEndComponentLabel;
  QSpinBox *mpEndComponentSpinBox;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
  QGridLayout *mpMainLayout;
  QHBoxLayout *mpConnectionStartHorizontalLayout;
  QHBoxLayout *mpConnectionEndHorizontalLayout;

  QSpinBox* createSpinBox(QString arrayIndex);
  QString createComponentNameFromLayout(QHBoxLayout *pLayout);
public slots:
  void startConnectorChanged(const QModelIndex &current, const QModelIndex &previous);
  void endConnectorChanged(const QModelIndex &current, const QModelIndex &previous);
  void createConnection();
};

#endif // LINEANNOTATION_H
