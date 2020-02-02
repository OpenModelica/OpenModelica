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

#ifndef LINEANNOTATION_H
#define LINEANNOTATION_H

#include "ShapeAnnotation.h"
#include "OMSimulator.h"

#include <QTreeView>
#include <QSortFilterProxyModel>
#include <QSpinBox>
#include <QUndoCommand>
#include<functional>

class Label;
class Element;
class TextAnnotation;

class LineAnnotation : public ShapeAnnotation
{
  Q_OBJECT
public:
  enum LineType {
    ComponentType,    /* Line is within Component. */
    ConnectionType,   /* Line is a connection. */
    TransitionType,   /* Line is a transition. */
    InitialStateType, /* Line is an initial state. */
    ShapeType         /* Line is a custom shape. */
  };
  // Used for icon/diagram shape
  LineAnnotation(QString annotation, GraphicsView *pGraphicsView);
  // Used for shape inside a component
  LineAnnotation(ShapeAnnotation *pShapeAnnotation, Element *pParent);
  // Used for icon/diagram inherited shape
  LineAnnotation(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView);
  // Used for creating connection/transition
  LineAnnotation(LineAnnotation::LineType lineType, Element *pStartComponent, GraphicsView *pGraphicsView);
  // Used for reading a connection
  LineAnnotation(QString annotation, Element *pStartComponent, Element *pEndComponent, GraphicsView *pGraphicsView);
  // Used for reading a transition
  LineAnnotation(QString annotation, QString text, Element *pStartComponent, Element *pEndComponent, QString condition, QString immediate,
                 QString reset, QString synchronize, QString priority, GraphicsView *pGraphicsView);
  // Used for reading an initial state
  LineAnnotation(QString annotation, Element *pComponent, GraphicsView *pGraphicsView);
  // Used for non-exisiting component
  LineAnnotation(Element *pParent);
  // Used for non-existing class
  LineAnnotation(GraphicsView *pGraphicsView);
  void parseShapeAnnotation(QString annotation) override;
  QPainterPath getShape() const;
  QRectF boundingRect() const override;
  QPainterPath shape() const override;
  void paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget = 0) override;
  void drawLineAnnotaion(QPainter *painter);
  void drawArrow(QPainter *painter, QPointF startPos, QPointF endPos, qreal size, int arrowType) const;
  QPolygonF perpendicularLine(QPointF startPos, QPointF endPos, qreal size) const;
  QString getOMCShapeAnnotation() override;
  QString getOMCShapeAnnotationWithShapeName() override;
  QString getShapeAnnotation() override;
  QString getCompositeModelShapeAnnotation();
  void addPoint(QPointF point) override;
  void removePoint(int index);
  void clearPoints() override;
  void updateStartPoint(QPointF point);
  void updateEndPoint(QPointF point);
  void updateTransitionTextPosition();
  void setLineType(LineType lineType) {mLineType = lineType;}
  LineType getLineType() {return mLineType;}
  void setStartComponent(Element *pStartComponent) {mpStartComponent = pStartComponent;}
  Element* getStartComponent() {return mpStartComponent;}
  void setStartComponentName(QString name) {mStartComponentName = name;}
  QString getStartComponentName() {return mStartComponentName;}
  void setEndComponent(Element *pEndComponent) {mpEndComponent = pEndComponent;}
  Element* getEndComponent() {return mpEndComponent;}
  void setEndComponentName(QString name) {mEndComponentName = name;}
  QString getEndComponentName() {return mEndComponentName;}
  void setCondition(QString condition) {mCondition = condition;}
  QString getCondition() {return mCondition;}
  void setImmediate(bool immediate) {mImmediate = immediate;}
  bool getImmediate() {return mImmediate;}
  void setReset(bool reset) {mReset = reset;}
  bool getReset() {return mReset;}
  void setSynchronize(bool synchronize) {mSynchronize = synchronize;}
  bool getSynchronize() {return mSynchronize;}
  void setPriority(int priority) {mPriority = priority;}
  int getPriority() {return mPriority;}
  TextAnnotation* getTextAnnotation() {return mpTextAnnotation;}
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
  void setOMSConnectionType(oms_connection_type_enu_t connectionType) {mOMSConnectionType = connectionType;}
  oms_connection_type_enu_t getOMSConnectionType() {return mOMSConnectionType;}
  void setActiveState(bool activeState) {mActiveState = activeState;}
  bool isActiveState() {return mActiveState;}
  void setShapeFlags(bool enable) override;
  void updateShape(ShapeAnnotation *pShapeAnnotation) override;
  void setAligned(bool aligned);
  void updateOMSConnection();
  void updateToolTip();
  void showOMSConnection();
  void updateTransistion(const QString& condition, const bool immediate, const bool rest, const bool synchronize, const int priority);
  void setProperties(const QString& condition, const bool immediate, const bool rest, const bool synchronize, const int priority);

  static QColor findLineColorForConnection(Element *pComponent);
protected:
  QVariant itemChange(GraphicsItemChange change, const QVariant &value) override;

  private:
  LineType mLineType;
  Element *mpStartComponent;
  QString mStartComponentName;
  Element *mpEndComponent;
  QString mEndComponentName;
  QString mCondition;
  bool mImmediate;
  bool mReset;
  bool mSynchronize;
  int mPriority;
  TextAnnotation *mpTextAnnotation;
  // MetaModel attributes
  QString mOldAnnotation;
  // CompositeModel attributes
  QString mDelay;
  QString mZf;
  QString mZfr;
  QString mAlpha;
  oms_connection_type_enu_t mOMSConnectionType;
  bool mActiveState;
public slots:
  void handleComponentMoved();
  void updateConnectionAnnotation();
  void updateConnectionTransformation();
  void updateTransitionAnnotation(QString oldCondition, bool oldImmediate, bool oldReset, bool oldSynchronize, int oldPriority);
  void redraw(const QString& annotation, std::function<void()> updateAnnotationFunction);
  void updateInitialStateAnnotation();
  void duplicate() override;
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
  int columnCount(const QModelIndex &parent = QModelIndex()) const override;
  int rowCount(const QModelIndex &parent = QModelIndex()) const override;
  QVariant headerData(int section, Qt::Orientation orientation, int role = Qt::DisplayRole) const override;
  QModelIndex index(int row, int column, const QModelIndex &parent = QModelIndex()) const override;
  QModelIndex parent(const QModelIndex & index) const override;
  QVariant data(const QModelIndex & index, int role = Qt::DisplayRole) const override;
  Qt::ItemFlags flags(const QModelIndex &index) const override;
  QModelIndex findFirstEnabledItem(ExpandableConnectorTreeItem *pExpandableConnectorTreeItem);
  QModelIndex expandableConnectorTreeItemIndex(const ExpandableConnectorTreeItem *pExpandableConnectorTreeItem) const;
  void createExpandableConnectorTreeItem(Element *pComponent, ExpandableConnectorTreeItem *pParentExpandableConnectorTreeItem);
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
  Element *mpStartComponent;
  Element *mpStartRootComponent;
  Element *mpEndComponent;
  Element *mpEndRootComponent;
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
  static QString createComponentNameFromLayout(QHBoxLayout *pLayout);
  static QString getComponentConnectionName(GraphicsView *pGraphicsView, ExpandableConnectorTreeView *pExpandableConnectorTreeView, QHBoxLayout *pConnectionHorizontalLayout,
                                            Element *pComponent1, Element *pRootComponent1, QSpinBox *pComponentSpinBox1, QSpinBox *pRootComponentSpinBox1,
                                            Element *pComponent2, Element *pRootComponent2, QSpinBox *pComponentSpinBox2, QSpinBox *pRootComponentSpinBox2);
public slots:
  void startConnectorChanged(const QModelIndex &current, const QModelIndex &previous);
  void endConnectorChanged(const QModelIndex &current, const QModelIndex &previous);
  void createConnection();
};

class CreateOrEditTransitionDialog : public QDialog
{
  Q_OBJECT
public:
  CreateOrEditTransitionDialog(GraphicsView *pGraphicsView, LineAnnotation *pTransitionLineAnnotation, bool editCase, QWidget *pParent = 0);
private:
  GraphicsView *mpGraphicsView;
  LineAnnotation *mpTransitionLineAnnotation;
  bool mEditCase;
  Label *mpHeading;
  QFrame *mpHorizontalLine;
  QGroupBox *mpPropertiesGroupBox;
  Label *mpConditionLabel;
  QLineEdit *mpConditionTextBox;
  QCheckBox *mpImmediateCheckBox;
  QCheckBox *mpResetCheckBox;
  QCheckBox *mpSynchronizeCheckBox;
  Label *mpPriorityLabel;
  QSpinBox *mpPrioritySpinBox;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
public slots:
  void createOrEditTransition();
};

#endif // LINEANNOTATION_H
