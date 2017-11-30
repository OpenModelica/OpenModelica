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

#include "LibraryTreeWidget.h"
#include "MainWindow.h"
#include "Options/OptionsDialog.h"
#include "MessagesWidget.h"
#include "DocumentationWidget.h"
#include "Plotting/VariablesWidget.h"
#include "Simulation/SimulationOutputWidget.h"
#include "ModelicaClassDialog.h"
#include "Git/GitCommands.h"
#include "Git/CommitChangesDialog.h"

ItemDelegate::ItemDelegate(QObject *pParent, bool drawRichText, bool drawGrid)
  : QItemDelegate(pParent)
{
  mDrawRichText = drawRichText;
  mLastTextPos = QPoint(0, 0);
  mDrawGrid = drawGrid;
  mpParent = pParent;
}

QString ItemDelegate::formatDisplayText(QVariant variant) const
{
  QString text;
  if (variant.type() == QVariant::Double) {
    text = QLocale().toString(variant.toDouble());
  } else {
    text = variant.toString();
    /* if rich text flag is set */
    if (mDrawRichText) {
      text.replace("\n", "<br />");
      text.replace("\t", "&#9;");
    }
  }
  return text;
}

void ItemDelegate::initTextDocument(QTextDocument *pTextDocument, QFont font, int width) const
{
  QTextOption textOption = pTextDocument->defaultTextOption();
  textOption.setWrapMode(QTextOption::WordWrap);
  pTextDocument->setDefaultTextOption(textOption);
  pTextDocument->setDefaultFont(font);
  pTextDocument->setTextWidth(width);
  pTextDocument->setDocumentMargin(2);  // the default is 4
}

void ItemDelegate::paint(QPainter *painter, const QStyleOptionViewItem &option, const QModelIndex &index) const
{
  QStyleOptionViewItemV2 opt = setOptions(index, option);
  const QStyleOptionViewItemV2 *v2 = qstyleoption_cast<const QStyleOptionViewItemV2 *>(&option);
  opt.features = v2 ? v2->features : QStyleOptionViewItemV2::ViewItemFeatures(QStyleOptionViewItemV2::None);
  // prepare
  painter->save();
  // get the data and the rectangles
  QVariant value;
  QIcon icon;
  QIcon::Mode iconMode = QIcon::Normal;
  QIcon::State iconState = QIcon::On;
  QPixmap pixmap;
  QRect decorationRect;
  value = index.data(Qt::DecorationRole);
  if (value.isValid()) {
    if (value.type() == QVariant::Icon) {
      icon = qvariant_cast<QIcon>(value);
      decorationRect = QRect(QPoint(0, 0), icon.actualSize(option.decorationSize, iconMode, iconState));
    } else {
      pixmap = decoration(opt, value);
      decorationRect = QRect(QPoint(0, 0), option.decorationSize).intersected(pixmap.rect());
    }
  }
  QString text;
  QRect displayRect;
  value = index.data(Qt::DisplayRole);
  if (value.isValid()) {
    text = formatDisplayText(value);
    displayRect = textRectangle(painter, option.rect, opt.font, text);
  }
  QRect checkRect;
  Qt::CheckState checkState = Qt::Unchecked;
  value = index.data(Qt::CheckStateRole);
  if (value.isValid()) {
    checkState = static_cast<Qt::CheckState>(value.toInt());
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
    checkRect = doCheck(opt, opt.rect, value);
#else /* Qt4 */
    checkRect = check(opt, opt.rect, value);
#endif
  }
  // do the layout
  doLayout(opt, &checkRect, &decorationRect, &displayRect, false);
  /* We check if item belongs to QTreeView and QTreeView model is LibraryTreeProxyModel.
   * If LibraryTreeItem is unsaved then draw its background as Qt::darkRed.
   */
  if (parent() && qobject_cast<QTreeView*>(parent())) {
    QTreeView *pTreeView = qobject_cast<QTreeView*>(parent());
    LibraryTreeProxyModel *pLibraryTreeProxyModel = qobject_cast<LibraryTreeProxyModel*>(pTreeView->model());
    if (pLibraryTreeProxyModel) {
      QModelIndex sourceIndex = pLibraryTreeProxyModel->mapToSource(index);
      LibraryTreeItem *pLibraryTreeItem = static_cast<LibraryTreeItem*>(sourceIndex.internalPointer());
      if (pLibraryTreeItem && !pLibraryTreeItem->isSaved()) {
        opt.palette.setBrush(QPalette::Highlight, Qt::darkRed);
      }
    }
  }
  // draw background
  drawBackground(painter, opt, index);
  // hover
  /* Ticket #2245. Do not draw hover effect for items. Doesn't seem to work on few versions of Linux. */
  /*drawHover(painter, opt, index);*/
  drawCheck(painter, opt, checkRect, checkState);
  /* if draw grid flag is set */
  if (mDrawGrid) {
    QPen pen;
    if (!mGridColor.isValid()) {
      int gridHint = qApp->style()->styleHint(QStyle::SH_Table_GridLineColor, &option);
      const QColor gridColor = static_cast<QRgb>(gridHint);
      pen.setColor(gridColor);
    } else {
      pen.setColor(mGridColor);
    }
    painter->save();
    painter->setPen(pen);
    painter->drawLine(option.rect.topRight(), option.rect.bottomRight());
    painter->drawLine(option.rect.bottomLeft(), option.rect.bottomRight());
    painter->restore();
  }
  /* if rich text flag is set */
  if (mDrawRichText) {
    QAbstractTextDocumentLayout::PaintContext ctx;
    QTextDocument textDocument;
    initTextDocument(&textDocument, opt.font, option.rect.width());

    QVariant variant = index.data(Qt::ForegroundRole);
    if (variant.isValid()) {
      if (option.state & ~QStyle::State_Selected) {
        ctx.palette.setColor(QPalette::Text, variant.value<QColor>());
      }
    }
    QPalette::ColorGroup cg = option.state & QStyle::State_Enabled ? QPalette::Normal : QPalette::Disabled;
    if (cg == QPalette::Normal && !(option.state & QStyle::State_Active)) {
      cg = QPalette::Inactive;
    }
    if (option.state & QStyle::State_Selected) {
      ctx.palette.setColor(QPalette::Text, option.palette.color(cg, QPalette::HighlightedText));
    }

    textDocument.setHtml(text);
    painter->save();
    painter->translate(displayRect.left(), displayRect.top());
    QRect clip(0, 0, displayRect.width(), displayRect.height());
    painter->setClipRect(clip);
    textDocument.documentLayout()->draw(painter, ctx);
    painter->restore();
  } else {
    drawDisplay(painter, opt, displayRect, text);
  }
  if (!icon.isNull()) {
    // adjust the decorationRect for multiline items. So that icon remains at top.
    if (mDrawRichText) {
      decorationRect = QRect(decorationRect.left(), displayRect.top() + 4, decorationRect.width(), decorationRect.height());
    }
    icon.paint(painter, decorationRect, option.decorationAlignment, QIcon::Normal, QIcon::Off);
  } else {
    drawDecoration(painter, opt, decorationRect, pixmap);
  }
  if (parent() && qobject_cast<VariablesTreeView*>(parent())) {
    if ((index.column() == 1) && (index.flags() & Qt::ItemIsEditable)) {
      /* The display rect is slightly larger than the area because it include the outer line. */
      painter->drawRect(displayRect.adjusted(0, 0, -1, -1));
    }
  }
  painter->restore();
}

void ItemDelegate::drawHover(QPainter *painter, const QStyleOptionViewItem &option, const QModelIndex &index) const
{
  Q_UNUSED(index);
  if (option.state & QStyle::State_MouseOver) {
    QPalette::ColorGroup cg = option.state & QStyle::State_Enabled ? QPalette::Normal : QPalette::Disabled;
    if (cg == QPalette::Normal && !(option.state & QStyle::State_Active)) {
      cg = QPalette::Inactive;
    }
    painter->fillRect(option.rect, option.palette.brush(cg, QPalette::Highlight));
  }
}

//! Reimplementation of sizeHint function. Defines the minimum height.
QSize ItemDelegate::sizeHint(const QStyleOptionViewItem &option, const QModelIndex &index) const
{
  // if user has set the SizeHintRole then just use it.
  QVariant value = index.data(Qt::SizeHintRole);
  if (value.isValid())
    return qvariant_cast<QSize>(value);
  QSize size = QItemDelegate::sizeHint(option, index);
  /* Only calculate the height of the item based on the text for SimulationOutputTree items. Fix for multi line messages. */
  if (mDrawRichText && parent() && qobject_cast<SimulationOutputTree*>(parent())) {
    SimulationOutputTree *pSimulationOutputTree = qobject_cast<SimulationOutputTree*>(parent());
    int width = 0;
    if (pSimulationOutputTree) {
      width = pSimulationOutputTree->columnWidth(index.column()) - (pSimulationOutputTree->indentation() * pSimulationOutputTree->getDepth(index));
    }
    QVariant value = index.data(Qt::DisplayRole);
    QString text;
    if (value.isValid()) {
      text = formatDisplayText(value);
    }
    QTextDocument textDocument;
    initTextDocument(&textDocument, option.font, width);  /* we can't use option.rect.width() here since it will be empty. */
    textDocument.setHtml(text);
    size.rheight() = qMax(textDocument.size().height(), (qreal)size.height());
  }
  return size;
}

/*!
 * \brief ItemDelegate::editorEvent
 * Shows a Qt::PointingHandCursor for simulation output links.\n
 * If the link is clicked then calls the SimulationOutputWidget::openTransformationBrowser(QUrl).
 * \param event
 * \param model
 * \param option
 * \param index
 * \return
 */
bool ItemDelegate::editorEvent(QEvent *event, QAbstractItemModel *model, const QStyleOptionViewItem &option, const QModelIndex &index)
{
  if (mDrawRichText && parent() && qobject_cast<SimulationOutputTree*>(parent()) &&
      (event->type() == QEvent::MouseMove || event->type() == QEvent::MouseButtonRelease) && (option.state & QStyle::State_Enabled)) {
    QMouseEvent *pMouseEvent = dynamic_cast<QMouseEvent*>(event);
    QPointF position = pMouseEvent->pos() - option.rect.topLeft();
    QVariant variant = index.data(Qt::DisplayRole);
    QString text;
    if (variant.isValid()) {
      text = formatDisplayText(variant);
    }
    QTextDocument textDocument;
    initTextDocument(&textDocument, option.font, option.rect.width());
    textDocument.setHtml(text);
    QString anchor = textDocument.documentLayout()->anchorAt(position);
    SimulationOutputTree *pSimulationOutputTree = qobject_cast<SimulationOutputTree*>(parent());
    if (anchor.isEmpty()) {
      pSimulationOutputTree->unsetCursor();
      return true;
    } else {
      pSimulationOutputTree->setCursor(Qt::PointingHandCursor);
      if (event->type() == QEvent::MouseButtonRelease) {
        pSimulationOutputTree->getSimulationOutputWidget()->openTransformationBrowser(QUrl(anchor));
      }
      return true;
    }
  } else {
    return QItemDelegate::editorEvent(event, model, option, index);
  }
}

/*!
 * \brief ItemDelegate::createEditor
 * Creates the editor for display units in VariablesTreeView.
 * \param pParent
 * \param option
 * \param index
 * \return
 */
QWidget* ItemDelegate::createEditor(QWidget *pParent, const QStyleOptionViewItem &option, const QModelIndex &index) const
{
  if (parent() && qobject_cast<VariablesTreeView*>(parent()) && index.column() == 3) {
    VariablesTreeView *pVariablesTreeView = qobject_cast<VariablesTreeView*>(parent());
    VariableTreeProxyModel *pVariableTreeProxyModel = pVariablesTreeView->getVariablesWidget()->getVariableTreeProxyModel();
    QModelIndex sourceIndex = pVariableTreeProxyModel->mapToSource(index);
    VariablesTreeItem *pVariablesTreeItem = static_cast<VariablesTreeItem*>(sourceIndex.internalPointer());
    // create the display units combobox
    QComboBox *pComboBox = new QComboBox(pParent);
    pComboBox->setEnabled(!pVariablesTreeItem->getDisplayUnits().isEmpty());
    pComboBox->addItems(pVariablesTreeItem->getDisplayUnits());
    connect(pComboBox, SIGNAL(currentIndexChanged(QString)), SLOT(unitComboBoxChanged(QString)));
    return pComboBox;
  } else {
    return QItemDelegate::createEditor(pParent, option, index);
  }
}

/*!
 * \brief ItemDelegate::setEditorData
 * Sets the value for display unit in VariablesTreeView.
 * \param editor
 * \param index
 */
void ItemDelegate::setEditorData(QWidget *editor, const QModelIndex &index) const
{
  if (parent() && qobject_cast<VariablesTreeView*>(parent()) && index.column() == 3) {
    QString value = index.model()->data(index, Qt::DisplayRole).toString();
    QComboBox* comboBox = static_cast<QComboBox*>(editor);
    //set the index of the combo box
    comboBox->setCurrentIndex(comboBox->findText(value, Qt::MatchExactly));
  } else {
    QItemDelegate::setEditorData(editor, index);
  }
}

/*!
 * \brief ItemDelegate::unitComboBoxChanged
 * Handles the case when display unit is changed in the VariablesTreeView.
 * \param text
 */
void ItemDelegate::unitComboBoxChanged(QString text)
{
  Q_UNUSED(text);
  QComboBox *pComboBox = qobject_cast<QComboBox*>(sender());
  if (pComboBox) {
    commitData(pComboBox);
    closeEditor(pComboBox);
  }
}

/*!
 * \class LibraryTreeItem
 * \brief Contains the information about the Modelica class.
 */
/*!
 * \brief LibraryTreeItem::LibraryTreeItem
 * Used for creating the root item.
 */
LibraryTreeItem::LibraryTreeItem()
{
  mIsRootItem = true;
  mpParentLibraryTreeItem = 0;
  setLibraryType(LibraryTreeItem::Modelica);
  setSystemLibrary(false);
  setModelWidget(0);
  setName("");
  setNameStructure("");
  OMCInterface::getClassInformation_res classInformation;
  setClassInformation(classInformation);
  setFileName("");
  setReadOnly(false);
  setIsSaved(false);
  setSaveContentsType(LibraryTreeItem::SaveInOneFile);
  setPixmap(QPixmap());
  setDragPixmap(QPixmap());
  setClassTextBefore("");
  setClassText("");
  setClassTextAfter("");
  setExpanded(false);
  setNonExisting(true);
}

/*!
 * \brief LibraryTreeItem::LibraryTreeItem
 * \param type
 * \param text
 * \param nameStructure
 * \param classInformation
 * \param fileName
 * \param isSaved
 * \param pParent
 */
LibraryTreeItem::LibraryTreeItem(LibraryType type, QString text, QString nameStructure, OMCInterface::getClassInformation_res classInformation,
                                 QString fileName, bool isSaved, LibraryTreeItem *pParent)
  : mLibraryType(type), mSystemLibrary(false), mpModelWidget(0)
{
  mIsRootItem = false;
  mpParentLibraryTreeItem = pParent;
  setPixmap(QPixmap());
  setDragPixmap(QPixmap());
  setName(text);
  setNameStructure(nameStructure);
  if (type == LibraryTreeItem::Modelica) {
    setClassInformation(classInformation);
  } else {
    setFileName(fileName);
    setReadOnly(!StringHandler::isFileWritAble(fileName));
  }
  setIsSaved(isSaved);
  if (isFilePathValid() && type == LibraryTreeItem::Modelica) {
    QFileInfo fileInfo(getFileName());
    // if item has file name as package.mo and is top level then its save folder structure
    if (isTopLevel() && (fileInfo.fileName().compare("package.mo") == 0)) {
      setSaveContentsType(LibraryTreeItem::SaveFolderStructure);
    } else if (isTopLevel()) {
      setSaveContentsType(LibraryTreeItem::SaveInOneFile);
    } else {
      if (mpParentLibraryTreeItem->getFileName().compare(getFileName()) == 0) {
        setSaveContentsType(LibraryTreeItem::SaveInOneFile);
      } else if (fileInfo.fileName().compare("package.mo") == 0) {
        setSaveContentsType(LibraryTreeItem::SaveFolderStructure);
      } else {
        setSaveContentsType(LibraryTreeItem::SaveInOneFile);
      }
    }
  } else {
    setSaveContentsType(LibraryTreeItem::SaveInOneFile);
  }
  setClassTextBefore("");
  setClassText("");
  setClassTextAfter("");
  setExpanded(false);
  setNonExisting(false);
}

/*!
 * \brief LibraryTreeItem::~LibraryTreeItem
 * Destructor for LibraryTreeItem
 */
LibraryTreeItem::~LibraryTreeItem()
{
  qDeleteAll(mChildren);
  mChildren.clear();
}

/*!
 * \brief LibraryTreeItem::setClassInformation
 * Sets the OMCInterface::getClassInformation_res
 * \param classInformation
 */
void LibraryTreeItem::setClassInformation(OMCInterface::getClassInformation_res classInformation)
{
  if (mLibraryType == LibraryTreeItem::Modelica) {
    mClassInformation = classInformation;
    if (!isFilePathValid()) {
      setFileName(classInformation.fileName);
    }
    setReadOnly(classInformation.fileReadOnly);
    // handle the Access annotation
    LibraryTreeItem::Access access = getAccess();
    if (access == LibraryTreeItem::hide && mpModelWidget) {
      QMdiSubWindow *pSubWindow = MainWindow::instance()->getModelWidgetContainer()->getMdiSubWindow(mpModelWidget);
      if (pSubWindow) {
        pSubWindow->close();
      }
    }
  }
}

/*!
 * \brief LibraryTreeItem::isFilePathValid
 * Returns true if file path is valid file location and not modelica class name.
 * \return
 */
bool LibraryTreeItem::isFilePathValid() {
  if (mFileName.isEmpty()) {
    return false;
  }
  // Since now we set the fileName via loadString() & parseString() so might get filename as className/<interactive>.
  QFileInfo fileInfo(mFileName);
  /* Ticket #3723
   * The only valid path for us is the absolute because we might have file name Test.C in OMEdit's working copy and
   * then this function will return true. Because Qt thinks its a relative path.
   */
  return fileInfo.exists() && !fileInfo.isRelative();
}

/*!
 * \brief LibraryTreeItem::isDocumentationClass
 * Returns true if class OR if any of its parent contains DocumentationClass annotation.
 * \return
 */
bool LibraryTreeItem::isDocumentationClass()
{
  if (mClassInformation.isDocumentationClass) {
    return true;
  } else if (isTopLevel()) {
    return false;
  }
  return mpParentLibraryTreeItem->isDocumentationClass();
}

/*!
 * \brief LibraryTreeItem::getAccess
 * Returns the Access annotation.
 * \return
 */
LibraryTreeItem::Access LibraryTreeItem::getAccess()
{
  if (mClassInformation.access.compare("Access.hide") == 0) {
    return LibraryTreeItem::hide;
  } else if (mClassInformation.access.compare("Access.icon") == 0) {
    return LibraryTreeItem::icon;
  } else if (mClassInformation.access.compare("Access.documentation") == 0) {
    return LibraryTreeItem::documentation;
  } else if (mClassInformation.access.compare("Access.diagram") == 0) {
    return LibraryTreeItem::diagram;
  } else if (mClassInformation.access.compare("Access.nonPackageText") == 0) {
    return LibraryTreeItem::nonPackageText;
  } else if (mClassInformation.access.compare("Access.nonPackageDuplicate") == 0) {
    return LibraryTreeItem::nonPackageDuplicate;
  } else if (mClassInformation.access.compare("Access.packageText") == 0) {
    return LibraryTreeItem::packageText;
  } else if (mClassInformation.access.compare("Access.packageDuplicate") == 0) {
    return LibraryTreeItem::packageDuplicate;
  } else {
    return LibraryTreeItem::all;
  }
}

/*!
 * \brief LibraryTreeItem::getClassText
 * Returns the class text. If the class text is empty then first read it.
 * \param pLibraryTreeModel
 * \return
 */
QString LibraryTreeItem::getClassText(LibraryTreeModel *pLibraryTreeModel)
{
  if (mClassText.isEmpty()) {
    pLibraryTreeModel->readLibraryTreeItemClassText(this);
  }
  return mClassText;
}

/*!
 * \brief LibraryTreeItem::getTooltip
 * Returns the LibraryTreeItem tooltip.
 */
QString LibraryTreeItem::getTooltip() const {
  QString tooltip;
  if (mLibraryType == LibraryTreeItem::Modelica) {
    tooltip = QString("%1: %2<br />%3 %4<br />%5: %6<br />%7: %8<br />%9: %10")
        .arg(Helper::type).arg(mClassInformation.restriction)
        .arg(Helper::name).arg(mName)
        .arg(Helper::description).arg(mClassInformation.comment)
        .arg(Helper::fileLocation).arg(mFileName)
        .arg(QObject::tr("Path")).arg(mNameStructure);
  } else {
    tooltip = QString("%1 %2\n%3: %4")
        .arg(Helper::name).arg(mName)
        .arg(Helper::fileLocation).arg(mFileName);
  }
  return tooltip;
}

/*!
 * \brief LibraryTreeItem::getLibraryTreeItemIcon
 * \return QIcon - the LibraryTreeItem icon
 */
QIcon LibraryTreeItem::getLibraryTreeItemIcon() const
{
  if (mLibraryType == LibraryTreeItem::CompositeModel) {
    return QIcon(":/Resources/icons/tlm-icon.svg");
  } else if (mLibraryType == LibraryTreeItem::Modelica) {
    switch (getRestriction()) {
      case StringHandler::Model:
        return QIcon(":/Resources/icons/model-icon.svg");
      case StringHandler::Class:
        return QIcon(":/Resources/icons/class-icon.svg");
      case StringHandler::Connector:
        return QIcon(":/Resources/icons/connector-icon.svg");
      case StringHandler::ExpandableConnector:
        return QIcon(":/Resources/icons/connect-mode.svg");
      case StringHandler::Record:
        return QIcon(":/Resources/icons/record-icon.svg");
      case StringHandler::Block:
        return QIcon(":/Resources/icons/block-icon.svg");
      case StringHandler::Function:
        return QIcon(":/Resources/icons/function-icon.svg");
      case StringHandler::Package:
        return QIcon(":/Resources/icons/package-icon.svg");
      case StringHandler::Type:
      case StringHandler::Operator:
      case StringHandler::OperatorRecord:
      case StringHandler::OperatorFunction:
        return QIcon(":/Resources/icons/type-icon.svg");
      case StringHandler::Optimization:
        return QIcon(":/Resources/icons/optimization-icon.svg");
      default:
        return QIcon(":/Resources/icons/type-icon.svg");
    }
  } else {
    return QIcon();
  }
}

/*!
 * \brief LibraryTreeItem::inRange
 * Returns true if line number is in start and end range.\n
 * We only check this for Modelica LibraryTreeItems and simply returns true for other types.
 * \param lineNumber
 * \return
 */
bool LibraryTreeItem::inRange(int lineNumber)
{
  if (mLibraryType == LibraryTreeItem::Modelica) {
    return (lineNumber >= mClassInformation.lineNumberStart) && (lineNumber <= mClassInformation.lineNumberEnd);
  } else {
    return true;
  }
}

/*!
 * \brief LibraryTreeItem::isInPackageOneFile
 * Returns true if the LibraryTreeItem is nested and is set to be saved in parent's file.
 * \return
 */
bool LibraryTreeItem::isInPackageOneFile()
{
  if (!isTopLevel() && mpParentLibraryTreeItem && mpParentLibraryTreeItem->getFileName().compare(getFileName()) == 0) {
    return true;
  } else {
    return false;
  }
}

/*!
 * \brief LibraryTreeItem::insertChild
 * Inserts a child LibraryTreeItem at the given position.
 * \param position
 * \param pLibraryTreeItem
 */
void LibraryTreeItem::insertChild(int position, LibraryTreeItem *pLibraryTreeItem)
{
  mChildren.insert(position, pLibraryTreeItem);
}

/*!
 * \brief LibraryTreeItem::child
 * Returns the child LibraryTreeItem stored at given row.
 * \param row
 * \return
 */
LibraryTreeItem* LibraryTreeItem::child(int row)
{
  return mChildren.value(row);
}

/*!
 * \brief LibraryTreeItem::moveChild
 * Moves the item from to to index in the list.
 * \param from
 * \param to
 */
void LibraryTreeItem::moveChild(int from, int to)
{
  mChildren.move(from, to);
}

/*!
 * \brief LibraryTreeItem::addInheritedClass
 * Adds the inherited class and connects to its signals for notifications.
 * \param pLibraryTreeItem
 */
void LibraryTreeItem::addInheritedClass(LibraryTreeItem *pLibraryTreeItem)
{
  mInheritedClasses.append(pLibraryTreeItem);
  connect(pLibraryTreeItem, SIGNAL(loaded(LibraryTreeItem*)), this, SLOT(handleLoaded(LibraryTreeItem*)), Qt::UniqueConnection);
  connect(pLibraryTreeItem, SIGNAL(unLoaded()), this, SLOT(handleUnloaded()), Qt::UniqueConnection);
  connect(pLibraryTreeItem, SIGNAL(shapeAdded(ShapeAnnotation*,GraphicsView*)),
          this, SLOT(handleShapeAdded(ShapeAnnotation*,GraphicsView*)), Qt::UniqueConnection);
  connect(pLibraryTreeItem, SIGNAL(componentAdded(Component*)),
          this, SLOT(handleComponentAdded(Component*)), Qt::UniqueConnection);
  connect(pLibraryTreeItem, SIGNAL(connectionAdded(LineAnnotation*)),
          this, SLOT(handleConnectionAdded(LineAnnotation*)), Qt::UniqueConnection);
  connect(pLibraryTreeItem, SIGNAL(iconUpdated()), this, SLOT(handleIconUpdated()), Qt::UniqueConnection);
  connect(pLibraryTreeItem, SIGNAL(coOrdinateSystemUpdated(GraphicsView*)),
          this, SLOT(handleCoOrdinateSystemUpdated(GraphicsView*)), Qt::UniqueConnection);
}

/*!
 * \brief LibraryTreeItem::removeAllInheritedClasses
 * Removes the inherited classes and its signals.
 */
void LibraryTreeItem::removeInheritedClasses()
{
  foreach (LibraryTreeItem *pLibraryTreeItem, mInheritedClasses) {
    disconnect(pLibraryTreeItem, SIGNAL(loaded(LibraryTreeItem*)), this, SLOT(handleLoaded(LibraryTreeItem*)));
    disconnect(pLibraryTreeItem, SIGNAL(unLoaded()), this, SLOT(handleUnloaded()));
    disconnect(pLibraryTreeItem, SIGNAL(shapeAdded(ShapeAnnotation*,GraphicsView*)),
               this, SLOT(handleShapeAdded(ShapeAnnotation*,GraphicsView*)));
    disconnect(pLibraryTreeItem, SIGNAL(componentAdded(Component*)), this, SLOT(handleComponentAdded(Component*)));
    disconnect(pLibraryTreeItem, SIGNAL(connectionAdded(LineAnnotation*)), this, SLOT(handleConnectionAdded(LineAnnotation*)));
    disconnect(pLibraryTreeItem, SIGNAL(iconUpdated()), this, SLOT(handleIconUpdated()));
    disconnect(pLibraryTreeItem, SIGNAL(coOrdinateSystemUpdated(GraphicsView*)), this, SLOT(handleCoOrdinateSystemUpdated(GraphicsView*)));
  }
  mInheritedClasses.clear();
}

/*!
 * \brief LibraryTreeItem::removeChild
 * Removes the child LibraryTreeItem.
 * \param pLibraryTreeItem
 */
void LibraryTreeItem::removeChild(LibraryTreeItem *pLibraryTreeItem)
{
  mChildren.removeOne(pLibraryTreeItem);
}

/*!
 * \brief LibraryTreeItem::data
 * Returns the data stored under the given role for the item referred to by the column.
 * \param column
 * \param role
 * \return
 */
QVariant LibraryTreeItem::data(int column, int role) const
{
  switch (column) {
    case 0:
      switch (role) {
        case Qt::DisplayRole:
          return mName;
        case Qt::DecorationRole: {
          if (mLibraryType == LibraryTreeItem::Text) {
            QFileInfo fileInfo(getFileName());
            return Utilities::FileIconProvider::icon(fileInfo);
          } else {
            return mPixmap.isNull() ? getLibraryTreeItemIcon() : mPixmap;
          }
        }
        case Qt::ToolTipRole:
          return getTooltip();
        case Qt::ForegroundRole:
          return mIsSaved ? QVariant() : QColor(Qt::darkRed);
        default:
          return QVariant();
      }
    default:
      return QVariant();
  }
}

/*!
 * \brief LibraryTreeItem::row
 * Returns the row number corresponding to LibraryTreeItem.
 * \return
 */
int LibraryTreeItem::row() const
{
  if (mpParentLibraryTreeItem) {
    return mpParentLibraryTreeItem->mChildren.indexOf(const_cast<LibraryTreeItem*>(this));
  }

  return 0;
}

/*!
 * \brief LibraryTreeItem::isTopLevel
 * Checks whether the LibraryTreeItem is top level or not.
 * \return
 */
bool LibraryTreeItem::isTopLevel()
{
  if (parent()->isRootItem()) {
    return true;
  } else {
    return false;
  }
}

/*!
 * \brief LibraryTreeItem::isSimulationAllowed
 * Checks whether simulation is allowed for this item or not.
 * \return
 */
bool LibraryTreeItem::isSimulationAllowed()
{
  // if the class is partial then return false.
  if (isPartial()) {
    return false;
  }
  switch (getRestriction()) {
    case StringHandler::Model:
    case StringHandler::Class:
    case StringHandler::Block:
      return true;
    default:
      return false;
  }
}

/*!
 * \brief LibraryTreeItem::emitLoaded
 * Emits the loaded and loadedForComponent signals.
 */
void LibraryTreeItem::emitLoaded()
{
  emit loaded(this);
  emit loadedForComponent();
}

/*!
 * \brief LibraryTreeItem::emitUnLoaded
 * Emits the unLoaded and unLoadedForComponent signals.
 */
void LibraryTreeItem::emitUnLoaded()
{
  emit unLoaded();
  emit unLoadedForComponent();
}

/*!
 * \brief LibraryTreeItem::emitShapeAdded
 * Emits the shapeAdded and shapeAddedForComponent signals.
 * \param pShapeAnnotation
 * \param pGraphicsView
 */
void LibraryTreeItem::emitShapeAdded(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView)
{
  emit shapeAdded(pShapeAnnotation, pGraphicsView);
  emit shapeAddedForComponent();
}

/*!
 * \brief LibraryTreeItem::emitComponentAdded
 * Emits the componentAdded and componentAddedForComponent signals.
 * \param pComponent
 */
void LibraryTreeItem::emitComponentAdded(Component *pComponent)
{
  emit componentAdded(pComponent);
  emit componentAddedForComponent();
}

/*!
 * \brief LibraryTreeItem::handleLoaded
 * Handles the case when an undefined inherited class is loaded.
 * \param pLibraryTreeItem
 */
void LibraryTreeItem::handleLoaded(LibraryTreeItem *pLibraryTreeItem)
{
  if (mpModelWidget) {
    MainWindow *pMainWindow = MainWindow::instance();
    // if the base class need to be loaded then load it first.
    if (!pLibraryTreeItem->getModelWidget()) {
      pMainWindow->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(pLibraryTreeItem, false);
    }
    mpModelWidget->reDrawModelWidgetInheritedClasses();
    if (mpModelWidget->getDiagramGraphicsView()) {
      mpModelWidget->getDiagramGraphicsView()->removeConnectionsFromView();
    }
    mpModelWidget->getModelConnections();
    // load new icon for the class.
    pMainWindow->getLibraryWidget()->getLibraryTreeModel()->loadLibraryTreeItemPixmap(this);
    // update the icon in the libraries browser view.
    pMainWindow->getLibraryWidget()->getLibraryTreeModel()->updateLibraryTreeItem(this);
  }
  emit loaded(this);
}

/*!
 * \brief LibraryTreeItem::handleUnLoaded
 * Handles the case when a inherited class is unloaded.
 */
void LibraryTreeItem::handleUnloaded()
{
  if (mpModelWidget) {
    mpModelWidget->reDrawModelWidgetInheritedClasses();
    if (mpModelWidget->getDiagramGraphicsView()) {
      mpModelWidget->getDiagramGraphicsView()->removeConnectionsFromView();
    }
    MainWindow *pMainWindow = MainWindow::instance();
    // load new icon for the class.
    pMainWindow->getLibraryWidget()->getLibraryTreeModel()->loadLibraryTreeItemPixmap(this);
    // update the icon in the libraries browser view.
    pMainWindow->getLibraryWidget()->getLibraryTreeModel()->updateLibraryTreeItem(this);
  }
  emit unLoaded();
}

/*!
 * \brief LibraryTreeItem::handleShapeAdded
 * Handles a case when inherited class has created a new shape.
 * \param pShapeAnnotation
 * \param pGraphicsView
 */
void LibraryTreeItem::handleShapeAdded(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView)
{
  if (mpModelWidget) {
    GraphicsView *pCurrentGraphicsView = 0;
    if (pGraphicsView->getViewType() == StringHandler::Icon) {
      pCurrentGraphicsView = mpModelWidget->getIconGraphicsView();
    } else {
      pCurrentGraphicsView = mpModelWidget->getDiagramGraphicsView();
    }
    pCurrentGraphicsView->addInheritedShapeToList(mpModelWidget->createInheritedShape(pShapeAnnotation, pCurrentGraphicsView));
    pCurrentGraphicsView->reOrderShapes();
  }
  emit shapeAdded(pShapeAnnotation, pGraphicsView);
}

/*!
 * \brief LibraryTreeItem::handleComponentAdded
 * Handles a case when inherited class has created a new component.
 * \param pComponent
 */
void LibraryTreeItem::handleComponentAdded(Component *pComponent)
{
  if (mpModelWidget) {
    if (pComponent->getLibraryTreeItem() && pComponent->getLibraryTreeItem()->isConnector()) {
      mpModelWidget->getIconGraphicsView()->addInheritedComponentToList(mpModelWidget->createInheritedComponent(pComponent, mpModelWidget->getIconGraphicsView()));
    }
    mpModelWidget->getDiagramGraphicsView()->addInheritedComponentToList(mpModelWidget->createInheritedComponent(pComponent, mpModelWidget->getDiagramGraphicsView()));
  }
  emit componentAdded(pComponent);
}

/*!
 * \brief LibraryTreeItem::handleConnectionAdded
 * Handles a case when inherited class has created a new connection.
 * \param pConnectionLineAnnotation
 */
void LibraryTreeItem::handleConnectionAdded(LineAnnotation *pConnectionLineAnnotation)
{
  if (mpModelWidget) {
    mpModelWidget->getDiagramGraphicsView()->addInheritedConnectionToList(mpModelWidget->createInheritedConnection(pConnectionLineAnnotation));
  }
  emit connectionAdded(pConnectionLineAnnotation);
}

/*!
 * \brief LibraryTreeItem::handleIconUpdated
 * Handles a case when class icon update is required.
 */
void LibraryTreeItem::handleIconUpdated()
{
  MainWindow *pMainWindow = MainWindow::instance();
  // load new icon for the class.
  pMainWindow->getLibraryWidget()->getLibraryTreeModel()->loadLibraryTreeItemPixmap(this);
  // update the icon in the libraries browser view.
  pMainWindow->getLibraryWidget()->getLibraryTreeModel()->updateLibraryTreeItem(this);
  emit iconUpdated();
}

void LibraryTreeItem::handleCoOrdinateSystemUpdated(GraphicsView *pGraphicsView)
{
  if (mpModelWidget) {
    if (pGraphicsView->getViewType() == StringHandler::Icon) {
      if (!mpModelWidget->getIconGraphicsView()->mCoOrdinateSystem.isValid()) {
        mpModelWidget->drawBaseCoOrdinateSystem(mpModelWidget, mpModelWidget->getIconGraphicsView());
      }
    } else {
      if (!mpModelWidget->getDiagramGraphicsView()->mCoOrdinateSystem.isValid()) {
        mpModelWidget->drawBaseCoOrdinateSystem(mpModelWidget, mpModelWidget->getDiagramGraphicsView());
      }
    }
  }
  emit coOrdinateSystemUpdated(pGraphicsView);
}

/*!
 * \class LibraryTreeProxyModel
 * \brief A sort filter proxy model for Libraries Browser.
 */
/*!
 * \brief LibraryTreeProxyModel::LibraryTreeProxyModel
 * \param pLibraryWidget
 */
LibraryTreeProxyModel::LibraryTreeProxyModel(LibraryWidget *pLibraryWidget, bool showOnlyModelica)
  : QSortFilterProxyModel(pLibraryWidget)
{
  mpLibraryWidget = pLibraryWidget;
  mShowOnlyModelica = showOnlyModelica;
}

/*!
 * \brief LibraryTreeProxyModel::filterAcceptsRow
 * Filters the LibraryTreeItems based on the filter reguler expression.
 * Also checks if LibraryTreeItem is protected and show/hide it based on Show Protected Classes settings value.
 * \param sourceRow
 * \param sourceParent
 * \return
 */
bool LibraryTreeProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
  QModelIndex index = sourceModel()->index(sourceRow, 0, sourceParent);
  if (index.isValid()) {
    LibraryTreeItem *pLibraryTreeItem = static_cast<LibraryTreeItem*>(index.internalPointer());
    // if showOnlyModelica flag is enabled then filter out all other types of LibraryTreeItem e.g., CompositeModel & Text.
    if (mShowOnlyModelica && pLibraryTreeItem && pLibraryTreeItem->getLibraryType() != LibraryTreeItem::Modelica) {
      return false;
    }
    // if any of children matches the filter, then current index matches the filter as well
    int rows = sourceModel()->rowCount(index);
    for (int i = 0 ; i < rows ; ++i) {
      if (filterAcceptsRow(i, index)) {
        return true;
      }
    }
    // check current index itself
    if (pLibraryTreeItem) {
      if ((pLibraryTreeItem->getAccess() == LibraryTreeItem::hide)
          || (pLibraryTreeItem->isProtected() && !OptionsDialog::instance()->getGeneralSettingsPage()->getShowProtectedClasses())) {
        return false;
      } else {
        return pLibraryTreeItem->getNameStructure().contains(filterRegExp());
      }
    } else {
      return sourceModel()->data(index).toString().contains(filterRegExp());
    }
  } else {
    return QSortFilterProxyModel::filterAcceptsRow(sourceRow, sourceParent);
  }
}

/*!
 * \class LibraryTreeModel
 * \brief A model for Libraries Browser.
 */
/*!
 * \brief LibraryTreeModel::LibraryTreeModel
 * \param pLibraryWidget
 */
LibraryTreeModel::LibraryTreeModel(LibraryWidget *pLibraryWidget)
  : QAbstractItemModel(pLibraryWidget)
{
  mpLibraryWidget = pLibraryWidget;
  mpRootLibraryTreeItem = new LibraryTreeItem;
}

/*!
 * \brief LibraryTreeModel::columnCount
 * Returns the number of columns for the children of the given parent.
 * \param parent
 * \return
 */
int LibraryTreeModel::columnCount(const QModelIndex &parent) const
{
  Q_UNUSED(parent);
  return 1;
}

/*!
 * \brief LibraryTreeModel::rowCount
 * Returns the number of rows under the given parent.
 * When the parent is valid it means that rowCount is returning the number of children of parent.
 * \param parent
 * \return
 */
int LibraryTreeModel::rowCount(const QModelIndex &parent) const
{
  LibraryTreeItem *pParentLibraryTreeItem;
  if (parent.column() > 0) {
    return 0;
  }

  if (!parent.isValid()) {
    pParentLibraryTreeItem = mpRootLibraryTreeItem;
  } else {
    pParentLibraryTreeItem = static_cast<LibraryTreeItem*>(parent.internalPointer());
  }
  return pParentLibraryTreeItem->childrenSize();
}

/*!
 * \brief LibraryTreeModel::headerData
 * Returns the data for the given role and section in the header with the specified orientation.
 * \param section
 * \param orientation
 * \param role
 * \return
 */
QVariant LibraryTreeModel::headerData(int section, Qt::Orientation orientation, int role) const
{
  Q_UNUSED(section);
  if (orientation == Qt::Horizontal && role == Qt::DisplayRole) {
    return Helper::libraries;
  }
  return QVariant();
}

/*!
 * \brief LibraryTreeModel::index
 * Returns the index of the item in the model specified by the given row, column and parent index.
 * \param row
 * \param column
 * \param parent
 * \return
 */
QModelIndex LibraryTreeModel::index(int row, int column, const QModelIndex &parent) const
{
  if (!hasIndex(row, column, parent)) {
    return QModelIndex();
  }

  LibraryTreeItem *pParentLibraryTreeItem;
  if (!parent.isValid()) {
    pParentLibraryTreeItem = mpRootLibraryTreeItem;
  } else {
    pParentLibraryTreeItem = static_cast<LibraryTreeItem*>(parent.internalPointer());
  }

  LibraryTreeItem *pChildLibraryTreeItem = pParentLibraryTreeItem->child(row);
  if (pChildLibraryTreeItem) {
    return createIndex(row, column, pChildLibraryTreeItem);
  } else {
    return QModelIndex();
  }
}

/*!
 * \brief LibraryTreeModel::parent
 * Finds the parent for QModelIndex
 * \param index
 * \return
 */
QModelIndex LibraryTreeModel::parent(const QModelIndex &index) const
{
  if (!index.isValid()) {
    return QModelIndex();
  }

  LibraryTreeItem *pChildLibraryTreeItem = static_cast<LibraryTreeItem*>(index.internalPointer());
  LibraryTreeItem *pParentLibraryTreeItem = pChildLibraryTreeItem->parent();
  if (pParentLibraryTreeItem == mpRootLibraryTreeItem)
    return QModelIndex();

  return createIndex(pParentLibraryTreeItem->row(), 0, pParentLibraryTreeItem);
}

/*!
 * \brief LibraryTreeModel::data
 * Returns the LibraryTreeItem data.
 * \param index
 * \param role
 * \return
 */
QVariant LibraryTreeModel::data(const QModelIndex &index, int role) const
{
  if (!index.isValid()) {
    return QVariant();
  }


  LibraryTreeItem *pLibraryTreeItem = static_cast<LibraryTreeItem*>(index.internalPointer());
  return pLibraryTreeItem->data(index.column(), role);
}

/*!
 * \brief LibraryTreeModel::flags
 * Returns the LibraryTreeItem flags.
 * \param index
 * \return
 */
Qt::ItemFlags LibraryTreeModel::flags(const QModelIndex &index) const
{
  if (!index.isValid()) {
    return Qt::ItemIsEnabled;
  } else {
    return Qt::ItemIsEnabled | Qt::ItemIsSelectable | Qt::ItemIsDragEnabled;
  }
}

/*!
 * \brief LibraryTreeModel::findLibraryTreeItem
 * Finds the LibraryTreeItem based on the name and case sensitivity.
 * \param name
 * \param pLibraryTreeItem
 * \return
 */
LibraryTreeItem* LibraryTreeModel::findLibraryTreeItem(const QString &name, LibraryTreeItem *pLibraryTreeItem,
                                                       Qt::CaseSensitivity caseSensitivity) const
{
  if (!pLibraryTreeItem) {
    pLibraryTreeItem = mpRootLibraryTreeItem;
  }
  if (pLibraryTreeItem->getNameStructure().compare(name, caseSensitivity) == 0) {
    return pLibraryTreeItem;
  }
  for (int i = pLibraryTreeItem->childrenSize(); --i >= 0; ) {
    if (LibraryTreeItem *item = findLibraryTreeItem(name, pLibraryTreeItem->childAt(i), caseSensitivity)) {
      return item;
    }
  }
  return 0;
}

/*!
 * \brief LibraryTreeModel::findLibraryTreeItem
 * Finds the LibraryTreeItem based on the Regular Expression.
 * \param regExp
 * \param pLibraryTreeItem
 * \return
 */
LibraryTreeItem* LibraryTreeModel::findLibraryTreeItem(const QRegExp &regExp, LibraryTreeItem *pLibraryTreeItem) const
{
  if (!pLibraryTreeItem) {
    pLibraryTreeItem = mpRootLibraryTreeItem;
  }
  if (pLibraryTreeItem->getNameStructure().contains(regExp)) {
    return pLibraryTreeItem;
  }
  for (int i = pLibraryTreeItem->childrenSize(); --i >= 0; ) {
    if (LibraryTreeItem *item = findLibraryTreeItem(regExp, pLibraryTreeItem->childAt(i))) {
      return item;
    }
  }
  return 0;
}

/*!
 * \brief LibraryTreeModel::findLibraryTreeItemOneLevel
 * Finds the LibraryTreeItem based on the name and case sensitivity only in the children of pLibraryTreeItem
 * \param name
 * \param pLibraryTreeItem
 * \return
 */
LibraryTreeItem* LibraryTreeModel::findLibraryTreeItemOneLevel(const QString &name, LibraryTreeItem *pLibraryTreeItem,
                                                               Qt::CaseSensitivity caseSensitivity) const
{
  if (!pLibraryTreeItem) {
    pLibraryTreeItem = mpRootLibraryTreeItem;
  }
  for (int i = pLibraryTreeItem->childrenSize(); --i >= 0; ) {
    if (pLibraryTreeItem->childAt(i)->getNameStructure().compare(name, caseSensitivity) == 0) {
      return pLibraryTreeItem->childAt(i);
    }
  }
  return 0;
}

/*!
 * \brief LibraryTreeModel::findNonExistingLibraryTreeItem
 * Finds the non existing LibraryTreeItem based on the name and case sensitivity.
 * \param name
 * \param caseSensitivity
 * \return
 */
LibraryTreeItem* LibraryTreeModel::findNonExistingLibraryTreeItem(const QString &name, Qt::CaseSensitivity caseSensitivity) const
{
  foreach (LibraryTreeItem *pLibraryTreeItem, mNonExistingLibraryTreeItemsList) {
    if (pLibraryTreeItem->getNameStructure().compare(name, caseSensitivity) == 0) {
      return pLibraryTreeItem;
    }
  }
  return 0;
}

/*!
 * \brief LibraryTreeModel::libraryTreeItemIndex
 * Finds the QModelIndex attached to LibraryTreeItem.
 * \param pLibraryTreeItem
 * \return
 */
QModelIndex LibraryTreeModel::libraryTreeItemIndex(const LibraryTreeItem *pLibraryTreeItem) const
{
  return libraryTreeItemIndexHelper(pLibraryTreeItem, mpRootLibraryTreeItem, QModelIndex());
}

/*!
 * \brief LibraryTreeModel::addModelicaLibraries
 * Loads the user defined Modelica Libraries.
 * Automatically loads the OpenModelica as system library.
 */
void LibraryTreeModel::addModelicaLibraries()
{
  // load Modelica System Libraries.
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  pOMCProxy->loadSystemLibraries();
  QStringList systemLibs = pOMCProxy->getClassNames();
  if (OptionsDialog::instance()->getLibrariesPage()->getLoadOpenModelicaLibraryCheckBox()->isChecked()) {
    systemLibs.prepend("OpenModelica");
  }
  foreach (QString lib, systemLibs) {
    SplashScreen::instance()->showMessage(QString(Helper::loading).append(" ").append(lib), Qt::AlignRight, Qt::white);
    createLibraryTreeItem(lib, mpRootLibraryTreeItem, true, true, true);
    checkIfAnyNonExistingClassLoaded();
  }
  // load Modelica User Libraries.
  pOMCProxy->loadUserLibraries();
  QStringList userLibs = pOMCProxy->getClassNames();
  foreach (QString lib, userLibs) {
    if (systemLibs.contains(lib)) {
      continue;
    }
    SplashScreen::instance()->showMessage(QString(Helper::loading).append(" ").append(lib), Qt::AlignRight, Qt::white);
    createLibraryTreeItem(lib, mpRootLibraryTreeItem, true, false, true);
    checkIfAnyNonExistingClassLoaded();
  }
}

/*!
 * \brief LibraryTreeModel::createLibraryTreeItem
 * Creates a LibraryTreeItem
 * \param name
 * \param pParentLibraryTreeItem
 * \param isSaved
 * \param isSystemLibrary
 * \param load
 * \param row
 */
LibraryTreeItem* LibraryTreeModel::createLibraryTreeItem(QString name, LibraryTreeItem *pParentLibraryTreeItem, bool isSaved,
                                                         bool isSystemLibrary, bool load, int row)
{
  QString nameStructure = pParentLibraryTreeItem->getNameStructure().isEmpty() ? name : pParentLibraryTreeItem->getNameStructure() + "." + name;
  // check if is in non-existing classes.
  LibraryTreeItem *pLibraryTreeItem = findNonExistingLibraryTreeItem(nameStructure);
  if (pLibraryTreeItem && pLibraryTreeItem->isNonExisting()) {
    pLibraryTreeItem = createLibraryTreeItemImpl(name, pParentLibraryTreeItem, isSaved, isSystemLibrary, load, row);
  } else {
    if (row == -1) {
      row = pParentLibraryTreeItem->childrenSize();
    }
    QModelIndex index = libraryTreeItemIndex(pParentLibraryTreeItem);
    beginInsertRows(index, row, row);
    pLibraryTreeItem = createLibraryTreeItemImpl(name, pParentLibraryTreeItem, isSaved, isSystemLibrary, load, row);
    endInsertRows();
  }
  return pLibraryTreeItem;
}

/*!
 * \brief LibraryTreeModel::createNonExistingLibraryTreeItem
 * \param nameStructure
 * \return
 */
LibraryTreeItem* LibraryTreeModel::createNonExistingLibraryTreeItem(QString nameStructure)
{
  LibraryTreeItem *pLibraryTreeItem = findNonExistingLibraryTreeItem(nameStructure);
  if (pLibraryTreeItem) {
    return pLibraryTreeItem;
  }
  QString parentName = StringHandler::removeLastWordAfterDot(nameStructure);
  LibraryTreeItem *pParentLibraryTreeItem;
  if (parentName.compare(nameStructure) == 0) {
    pParentLibraryTreeItem = mpRootLibraryTreeItem;
  } else {
    pParentLibraryTreeItem = findLibraryTreeItem(parentName);
    if (!pParentLibraryTreeItem) {
      pParentLibraryTreeItem = createNonExistingLibraryTreeItem(parentName);
    }
  }
  QString name = StringHandler::getLastWordAfterDot(nameStructure);
  OMCInterface::getClassInformation_res classInformation;
  pLibraryTreeItem = new LibraryTreeItem(LibraryTreeItem::Modelica, name, nameStructure, classInformation, "", false, pParentLibraryTreeItem);
  pLibraryTreeItem->setSystemLibrary(pParentLibraryTreeItem->isSystemLibrary());
  pLibraryTreeItem->setNonExisting(true);
  addNonExistingLibraryTreeItem(pLibraryTreeItem);
  return pLibraryTreeItem;
}

/*!
 * \brief LibraryTreeModel::createLibraryTreeItem
 * Creates a LibraryTreeItem and add it to the Libraries Browser.
 * \param type
 * \param name
 * \param nameStructure
 * \param path
 * \param isSaved
 * \param pParentLibraryTreeItem
 * \param row
 * \return
 */
LibraryTreeItem* LibraryTreeModel::createLibraryTreeItem(LibraryTreeItem::LibraryType type, QString name, QString nameStructure, QString path,
                                                         bool isSaved, LibraryTreeItem *pParentLibraryTreeItem, int row)
{
  if (row == -1) {
    row = pParentLibraryTreeItem->childrenSize();
  }
  QModelIndex index = libraryTreeItemIndex(pParentLibraryTreeItem);
  beginInsertRows(index, row, row);
  LibraryTreeItem *pLibraryTreeItem = createLibraryTreeItemImpl(type, name, nameStructure, path, isSaved, pParentLibraryTreeItem, row);
  endInsertRows();
  return pLibraryTreeItem;
}

/*!
 * \brief LibraryTreeModel::createProjectLibraryTreeItems
 * Creates the LibraryTreeItems from the folder.
 * \param fileInfo
 * \param pParentLibraryTreeItem
 */
void LibraryTreeModel::createLibraryTreeItems(QFileInfo fileInfo, LibraryTreeItem *pParentLibraryTreeItem)
{
  int row = pParentLibraryTreeItem->childrenSize();
  beginInsertRows(libraryTreeItemIndex(pParentLibraryTreeItem), row, row);
  createLibraryTreeItemsImpl(fileInfo, pParentLibraryTreeItem);
  endInsertRows();
}

/*!
 * \brief LibraryTreeModel::checkIfAnyNonExistingClassLoaded
 * Checks which non-existing classes are loaded and then call loaded for them.
 */
void LibraryTreeModel::checkIfAnyNonExistingClassLoaded()
{
  int i = 0;
  while(i < mNonExistingLibraryTreeItemsList.size()) {
    LibraryTreeItem *pLibraryTreeItem = mNonExistingLibraryTreeItemsList.at(i);
    if (!pLibraryTreeItem->isNonExisting()) {
      removeNonExistingLibraryTreeItem(pLibraryTreeItem);
      pLibraryTreeItem->emitLoaded();
      i = 0;  //Restart iteration
    } else {
      i++;
    }
  }
}

/*!
 * \brief LibraryTreeModel::updateLibraryTreeItem
 * Triggers a view update for the LibraryTreeItem in the Libraries Browser.
 * \param pLibraryTreeItem
 */
void LibraryTreeModel::updateLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem)
{
  QModelIndex index = libraryTreeItemIndex(pLibraryTreeItem);
  emit dataChanged(index, index);
}

/*!
 * \brief LibraryTreeModel::updateLibraryTreeItemClassText
 * Updates the class text of LibraryTreeItem
 * Uses OMCProxy::listFile() and OMCProxy::diffModelicaFileListings() to get the correct Modelica Text.
 * \param pLibraryTreeItem
 * \sa OMCProxy::listFile()
 * \sa OMCProxy::diffModelicaFileListings()
 */
void LibraryTreeModel::updateLibraryTreeItemClassText(LibraryTreeItem *pLibraryTreeItem)
{
  // set the library node not saved.
  pLibraryTreeItem->setIsSaved(false);
  updateLibraryTreeItem(pLibraryTreeItem);
  if (pLibraryTreeItem->getLibraryType() == LibraryTreeItem::Modelica) {
    // update the containing parent LibraryTreeItem class text.
    LibraryTreeItem *pParentLibraryTreeItem = getContainingFileParentLibraryTreeItem(pLibraryTreeItem);
    // we also mark the containing parent class unsaved because it is very important for saving of single file packages.
    pParentLibraryTreeItem->setIsSaved(false);
    updateLibraryTreeItem(pParentLibraryTreeItem);
    OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
    QString before = pParentLibraryTreeItem->getClassText(this);
    QString after = pOMCProxy->listFile(pParentLibraryTreeItem->getNameStructure());
    QString contents = pOMCProxy->diffModelicaFileListings(before, after);
    pParentLibraryTreeItem->setClassText(contents);
    if (pParentLibraryTreeItem->getModelWidget()) {
      pParentLibraryTreeItem->getModelWidget()->setWindowTitle(QString(pParentLibraryTreeItem->getName()).append("*"));
      ModelicaEditor *pModelicaEditor = dynamic_cast<ModelicaEditor*>(pParentLibraryTreeItem->getModelWidget()->getEditor());
      if (pModelicaEditor) {
        pModelicaEditor->setPlainText(contents);
      }
    }
    // if we first updated the parent class then the child classes needs to be updated as well.
    if (pParentLibraryTreeItem != pLibraryTreeItem) {
      pOMCProxy->loadString(pParentLibraryTreeItem->getClassText(this), pParentLibraryTreeItem->getFileName(), Helper::utf8,
                            pParentLibraryTreeItem->getSaveContentsType() == LibraryTreeItem::SaveFolderStructure, false);
      updateChildLibraryTreeItemClassText(pParentLibraryTreeItem, contents, pParentLibraryTreeItem->getFileName());
      pParentLibraryTreeItem->setClassInformation(pOMCProxy->getClassInformation(pParentLibraryTreeItem->getNameStructure()));
    }
  }
}

/*!
 * \brief LibraryTreeModel::updateLibraryTreeItemClassTextManually
 * Updates the Parent Modelica class text after user has made changes manually in the text view.
 * \param pLibraryTreeItem
 * \param contents
 */
void LibraryTreeModel::updateLibraryTreeItemClassTextManually(LibraryTreeItem *pLibraryTreeItem, QString contents)
{
  // set the library node not saved.
  pLibraryTreeItem->setIsSaved(false);
  updateLibraryTreeItem(pLibraryTreeItem);
  // update the containing parent LibraryTreeItem class text.
  LibraryTreeItem *pParentLibraryTreeItem = getContainingFileParentLibraryTreeItem(pLibraryTreeItem);
  // we also mark the containing parent class unsaved because it is very important for saving of single file packages.
  pParentLibraryTreeItem->setIsSaved(false);
  updateLibraryTreeItem(pParentLibraryTreeItem);
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  pParentLibraryTreeItem->setClassText(contents);
  if (pParentLibraryTreeItem->getModelWidget()) {
    pParentLibraryTreeItem->getModelWidget()->setWindowTitle(QString(pParentLibraryTreeItem->getName()).append("*"));
    ModelicaEditor *pModelicaEditor = dynamic_cast<ModelicaEditor*>(pParentLibraryTreeItem->getModelWidget()->getEditor());
    if (pModelicaEditor) {
      pModelicaEditor->setPlainText(contents);
    }
  }
  // if we first updated the parent class then the child classes needs to be updated as well.
  if (pParentLibraryTreeItem != pLibraryTreeItem) {
    pOMCProxy->loadString(pParentLibraryTreeItem->getClassText(this), pParentLibraryTreeItem->getFileName(), Helper::utf8,
                          pParentLibraryTreeItem->getSaveContentsType() == LibraryTreeItem::SaveFolderStructure, false);
    updateChildLibraryTreeItemClassText(pParentLibraryTreeItem, contents, pParentLibraryTreeItem->getFileName());
    pParentLibraryTreeItem->setClassInformation(pOMCProxy->getClassInformation(pParentLibraryTreeItem->getNameStructure()));
  }
}

/*!
 * \brief LibraryTreeModel::readLibraryTreeItemClassText
 * Reads the LibraryTreeItem class text from file/OMC.
 * \param pLibraryTreeItem
 */
void LibraryTreeModel::readLibraryTreeItemClassText(LibraryTreeItem *pLibraryTreeItem)
{
  if (!pLibraryTreeItem->isFilePathValid()) {
    // If class is nested in a class and nested class is saved in the same file as parent.
    if (pLibraryTreeItem->isInPackageOneFile()) {
      updateLibraryTreeItemClassText(pLibraryTreeItem);
    } else {
      if (pLibraryTreeItem->getLibraryType() == LibraryTreeItem::Modelica) {
        pLibraryTreeItem->setClassText(MainWindow::instance()->getOMCProxy()->listFile(pLibraryTreeItem->getNameStructure()));
      }
    }
  } else {
    // If class is top level then simply read its file contents.
    if (pLibraryTreeItem->isTopLevel()) {
      pLibraryTreeItem->setClassText(readLibraryTreeItemClassTextFromFile(pLibraryTreeItem));
    } else {
      // If class is nested in a class and nested class is saved in the same file as parent.
      if (pLibraryTreeItem->isInPackageOneFile()) {
        LibraryTreeItem *pParentLibraryTreeItem = getContainingFileParentLibraryTreeItem(pLibraryTreeItem);
        if (pParentLibraryTreeItem) {
          readLibraryTreeItemClassTextFromText(pLibraryTreeItem, pParentLibraryTreeItem->getClassText(this));
        }
      } else {
        pLibraryTreeItem->setClassText(readLibraryTreeItemClassTextFromFile(pLibraryTreeItem));
      }
    }
  }
}

/*!
 * \brief LibraryTreeModel::getContainingFileParentLibraryTreeItem
 * Finds the top most LibraryTreeItem that has the same file as LibraryTreeItem. Used to find parent LibraryTreeItem for single file packages.
 * \param pLibraryTreeItem
 * \return
 */
LibraryTreeItem* LibraryTreeModel::getContainingFileParentLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem)
{
  if (pLibraryTreeItem->isTopLevel()) {
    return pLibraryTreeItem;
  }
  if (pLibraryTreeItem->parent()->getFileName().compare(pLibraryTreeItem->getFileName()) == 0) {
    pLibraryTreeItem = getContainingFileParentLibraryTreeItem(pLibraryTreeItem->parent());
  }
  return pLibraryTreeItem;
}

/*!
 * \brief LibraryTreeModel::loadLibraryTreeItemPixmap
 * Loads a pixmap for LibraryTreeItem
 * The pixmap is based on Modelica class icon representation
 * \param pLibraryTreeItem
 */
void LibraryTreeModel::loadLibraryTreeItemPixmap(LibraryTreeItem *pLibraryTreeItem)
{
  if (!pLibraryTreeItem->getModelWidget()) {
    showModelWidget(pLibraryTreeItem, false);
  }
  if (pLibraryTreeItem->getModelWidget()->getIconGraphicsView()->hasAnnotation()) {
    GraphicsView *pGraphicsView = pLibraryTreeItem->getModelWidget()->getIconGraphicsView();
    qreal left = pGraphicsView->mCoOrdinateSystem.getExtent().at(0).x();
    qreal bottom = pGraphicsView->mCoOrdinateSystem.getExtent().at(0).y();
    qreal right = pGraphicsView->mCoOrdinateSystem.getExtent().at(1).x();
    qreal top = pGraphicsView->mCoOrdinateSystem.getExtent().at(1).y();
    QRectF rectangle = QRectF(left, bottom, fabs(left - right), fabs(bottom - top));
    if (rectangle.width() < 1) {
      rectangle = QRectF(-100.0, -100.0, 200.0, 200.0);
    }
    qreal adjust = 25;
    rectangle.setX(rectangle.x() - adjust);
    rectangle.setY(rectangle.y() - adjust);
    rectangle.setWidth(rectangle.width() + adjust);
    rectangle.setHeight(rectangle.height() + adjust);
    int libraryIconSize = OptionsDialog::instance()->getGeneralSettingsPage()->getLibraryIconSizeSpinBox()->value();
    QPixmap libraryPixmap(QSize(libraryIconSize, libraryIconSize));
    libraryPixmap.fill(QColor(Qt::transparent));
    QPainter libraryPainter(&libraryPixmap);
    libraryPainter.setRenderHint(QPainter::Antialiasing);
    libraryPainter.setRenderHint(QPainter::SmoothPixmapTransform);
    libraryPainter.setWindow(rectangle.toRect());
    libraryPainter.scale(1.0, -1.0);
    // drag pixmap
    QPixmap dragPixmap(QSize(50, 50));
    dragPixmap.fill(QColor(Qt::transparent));
    QPainter dragPainter(&dragPixmap);
    dragPainter.setRenderHint(QPainter::Antialiasing);
    dragPainter.setRenderHint(QPainter::SmoothPixmapTransform);
    dragPainter.setWindow(rectangle.toRect());
    dragPainter.scale(1.0, -1.0);
    pLibraryTreeItem->getModelWidget()->getIconGraphicsView()->setRenderingLibraryPixmap(true);
    // render library pixmap
    pLibraryTreeItem->getModelWidget()->getIconGraphicsView()->scene()->render(&libraryPainter, rectangle, rectangle);
    // render drag pixmap
    pLibraryTreeItem->getModelWidget()->getIconGraphicsView()->scene()->render(&dragPainter, rectangle, rectangle);
    pLibraryTreeItem->getModelWidget()->getIconGraphicsView()->setRenderingLibraryPixmap(false);
    libraryPainter.end();
    dragPainter.end();
    pLibraryTreeItem->setPixmap(libraryPixmap);
    pLibraryTreeItem->setDragPixmap(dragPixmap);
  } else {
    pLibraryTreeItem->setPixmap(QPixmap());
    pLibraryTreeItem->setDragPixmap(QPixmap());
  }
}

/*!
 * \brief LibraryTreeModel::loadDependentLibraries
 * Since few libraries load dependent libraries automatically. So if the dependent library is not added then add it.
 * \param libraries
 */
void LibraryTreeModel::loadDependentLibraries(QStringList libraries)
{
  foreach (QString library, libraries) {
    LibraryTreeItem* pLoadedLibraryTreeItem = findLibraryTreeItem(library);
    if (!pLoadedLibraryTreeItem) {
      MainWindow::instance()->getStatusBar()->showMessage(QString("%1: %2").arg(Helper::loading).arg(library));
      createLibraryTreeItem(library, mpRootLibraryTreeItem, true, true, true);
      checkIfAnyNonExistingClassLoaded();
      MainWindow::instance()->getStatusBar()->clearMessage();
    }
  }
}

/*!
 * \brief LibraryTreeModel::getLibraryTreeItemFromFile
 * Search the LibraryTreeItem using the file name and line number.
 * \param fileName
 * \param lineNumber
 * \return
 */
LibraryTreeItem* LibraryTreeModel::getLibraryTreeItemFromFile(QString fileName, int lineNumber)
{
  return getLibraryTreeItemFromFileHelper(mpRootLibraryTreeItem, fileName, lineNumber);
}

/*!
 * \brief LibraryTreeModel::showModelWidget
 * Shows the ModelWidget
 * \param pLibraryTreeItem
 * \param text
 * \param show
 */
void LibraryTreeModel::showModelWidget(LibraryTreeItem *pLibraryTreeItem, bool show, StringHandler::ViewType viewType)
{
  QApplication::setOverrideCursor(Qt::WaitCursor);
  if (show && ((viewType == StringHandler::NoView && pLibraryTreeItem->mClassInformation.preferredView.compare("info") == 0) ||
               (viewType == StringHandler::NoView && pLibraryTreeItem->mClassInformation.preferredView.isEmpty() &&
                pLibraryTreeItem->isDocumentationClass()) ||
               (viewType == StringHandler::NoView && pLibraryTreeItem->mClassInformation.preferredView.isEmpty() &&
                OptionsDialog::instance()->getGeneralSettingsPage()->getDefaultView().compare(Helper::documentationView) == 0))) {
    MainWindow::instance()->getDocumentationWidget()->showDocumentation(pLibraryTreeItem);
    bool state = MainWindow::instance()->getDocumentationDockWidget()->blockSignals(true);
    MainWindow::instance()->getDocumentationDockWidget()->show();
    MainWindow::instance()->getDocumentationDockWidget()->blockSignals(state);
  } else {
    // only switch to modeling perspective if show is true and we are not in a debugging perspective.
    if (show && MainWindow::instance()->getPerspectiveTabBar()->currentIndex() != 3) {
      MainWindow::instance()->getPerspectiveTabBar()->setCurrentIndex(1);
    }
    if (!pLibraryTreeItem->getModelWidget()) {
      ModelWidget *pModelWidget = new ModelWidget(pLibraryTreeItem, MainWindow::instance()->getModelWidgetContainer());
      pLibraryTreeItem->setModelWidget(pModelWidget);
    }
    /* Ticket #3797
     * Only show the class Name as window title instead of full path
     */
    pLibraryTreeItem->getModelWidget()->setWindowTitle(pLibraryTreeItem->getName() + (pLibraryTreeItem->isSaved() ? "" : "*"));
    if (show) {
      MainWindow::instance()->getModelWidgetContainer()->addModelWidget(pLibraryTreeItem->getModelWidget(), true, viewType);
    } else {
      pLibraryTreeItem->getModelWidget()->hide();
    }
  }
  QApplication::restoreOverrideCursor();
}

/*!
 * \brief LibraryTreeModel::showHideProtectedClasses
 * Shows/hides the protected LibraryTreeItems by invalidating the view.
 * The LibraryTreeProxyModel shows/hides the LibraryTreeItems in LibraryTreeProxyModel::filterAcceptsRow() based on the settings value.
 */
void LibraryTreeModel::showHideProtectedClasses()
{
  /* invalidate the view so that the items show the updated values. */
  mpLibraryWidget->getLibraryTreeProxyModel()->invalidate();
}

/*!
 * \brief LibraryTreeModel::unloadClass
 * Unloads/deletes the Modelica class.
 * \param pLibraryTreeItem
 * \param askQuestion
 * \return
 */
bool LibraryTreeModel::unloadClass(LibraryTreeItem *pLibraryTreeItem, bool askQuestion)
{
  if (askQuestion) {
    QMessageBox *pMessageBox = new QMessageBox(MainWindow::instance());
    pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::question));
    pMessageBox->setIcon(QMessageBox::Question);
    pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
    if (pLibraryTreeItem->isTopLevel()) {
      pMessageBox->setText(GUIMessages::getMessage(GUIMessages::UNLOAD_CLASS_MSG).arg(pLibraryTreeItem->getNameStructure()));
    } else {
      pMessageBox->setText(GUIMessages::getMessage(GUIMessages::DELETE_CLASS_MSG).arg(pLibraryTreeItem->getNameStructure()));
    }
    pMessageBox->setStandardButtons(QMessageBox::Yes | QMessageBox::No);
    pMessageBox->setDefaultButton(QMessageBox::Yes);
    int answer = pMessageBox->exec();
    switch (answer) {
      case QMessageBox::Yes:
        // Yes was clicked. Don't return.
        break;
      case QMessageBox::No:
        // No was clicked. Return
        return false;
      default:
        // should never be reached
        return false;
    }
  }
  /* Delete the class in OMC.
   * If deleteClass is successful remove the class from Library Browser and delete the corresponding ModelWidget.
   */
  if (MainWindow::instance()->getOMCProxy()->deleteClass(pLibraryTreeItem->getNameStructure())) {
    /* QSortFilterProxy::filterAcceptRows changes the expand/collapse behavior of indexes or I am using it in some stupid way.
     * If index is expanded and we delete it then the next sibling index automatically becomes expanded.
     * The following code overcomes this issue. It stores the next index expand state and then apply it after deletion.
     */
    int row = pLibraryTreeItem->row();
    LibraryTreeItem *pNextLibraryTreeItem = 0;
    bool expandState = false;
    if (pLibraryTreeItem->parent()->childrenSize() > row + 1) {
      pNextLibraryTreeItem = pLibraryTreeItem->parent()->child(row + 1);
      QModelIndex modelIndex = libraryTreeItemIndex(pNextLibraryTreeItem);
      QModelIndex proxyIndex = mpLibraryWidget->getLibraryTreeProxyModel()->mapFromSource(modelIndex);
      expandState = mpLibraryWidget->getLibraryTreeView()->isExpanded(proxyIndex);
    }
    // remove the LibraryTreeItem from Libraries Browser
    beginRemoveRows(libraryTreeItemIndex(pLibraryTreeItem), row, row);
    // unload the LibraryTreeItem children if any and then unload the LibraryTreeItem.
    unloadClassChildren(pLibraryTreeItem);
    endRemoveRows();
    if (pNextLibraryTreeItem) {
      QModelIndex modelIndex = libraryTreeItemIndex(pNextLibraryTreeItem);
      QModelIndex proxyIndex = mpLibraryWidget->getLibraryTreeProxyModel()->mapFromSource(modelIndex);
      mpLibraryWidget->getLibraryTreeView()->setExpanded(proxyIndex, expandState);
    }
    /* Update the model switcher toolbar button. */
    MainWindow::instance()->updateModelSwitcherMenu(0);
    if (!pLibraryTreeItem->isTopLevel()) {
      LibraryTreeItem *pContainingFileParentLibraryTreeItem = getContainingFileParentLibraryTreeItem(pLibraryTreeItem);
      // if we unload in a package saved in one file strucutre then we should update its containing file item text.
      if (pContainingFileParentLibraryTreeItem != pLibraryTreeItem) {
        updateLibraryTreeItemClassText(pLibraryTreeItem);
      } else {
        // if we unload in a package saved in folder strucutre then we should mark its parent unsaved.
        pLibraryTreeItem->parent()->setIsSaved(false);
        updateLibraryTreeItem(pLibraryTreeItem->parent());
      }
    }
    return true;
  } else {
    QMessageBox::critical(MainWindow::instance(), QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED).arg(MainWindow::instance()->getOMCProxy()->getResult())
                          .append(tr(" while deleting ") + pLibraryTreeItem->getNameStructure()), Helper::ok);
    return false;
  }
}

/*!
 * \brief LibraryTreeModel::unloadCompositeModelOrTextFile
 * Unloads/deletes the CompositeModel/Text class.
 * \param pLibraryTreeItem
 * \param askQuestion
 * \return
 */
bool LibraryTreeModel::unloadCompositeModelOrTextFile(LibraryTreeItem *pLibraryTreeItem, bool askQuestion)
{
  if (askQuestion) {
    QMessageBox *pMessageBox = new QMessageBox(MainWindow::instance());
    pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::question));
    pMessageBox->setIcon(QMessageBox::Question);
    pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
    pMessageBox->setText(GUIMessages::getMessage(GUIMessages::UNLOAD_TEXT_FILE_MSG).arg(pLibraryTreeItem->getNameStructure()));
    pMessageBox->setStandardButtons(QMessageBox::Yes | QMessageBox::No);
    pMessageBox->setDefaultButton(QMessageBox::Yes);
    int answer = pMessageBox->exec();
    switch (answer) {
      case QMessageBox::Yes:
        // Yes was clicked. Don't return.
        break;
      case QMessageBox::No:
        // No was clicked. Return
        return false;
      default:
        // should never be reached
        return false;
    }
  }
  /* QSortFilterProxy::filterAcceptRows changes the expand/collapse behavior of indexes or I am using it in some stupid way.
   * If index is expanded and we delete it then the next sibling index automatically becomes expanded.
   * The following code overcomes this issue. It stores the next index expand state and then apply it after deletion.
   */
  int row = pLibraryTreeItem->row();
  LibraryTreeItem *pNextLibraryTreeItem = 0;
  bool expandState = false;
  if (pLibraryTreeItem->parent()->childrenSize() > row + 1) {
    pNextLibraryTreeItem = pLibraryTreeItem->parent()->child(row + 1);
    QModelIndex modelIndex = libraryTreeItemIndex(pNextLibraryTreeItem);
    QModelIndex proxyIndex = mpLibraryWidget->getLibraryTreeProxyModel()->mapFromSource(modelIndex);
    expandState = mpLibraryWidget->getLibraryTreeView()->isExpanded(proxyIndex);
  }
  // remove the LibraryTreeItem from Libraries Browser
  beginRemoveRows(libraryTreeItemIndex(pLibraryTreeItem), row, row);
  // unload the LibraryTreeItem children if any and then unload the LibraryTreeItem.
  unloadFileChildren(pLibraryTreeItem);
  endRemoveRows();
  if (pNextLibraryTreeItem) {
    QModelIndex modelIndex = libraryTreeItemIndex(pNextLibraryTreeItem);
    QModelIndex proxyIndex = mpLibraryWidget->getLibraryTreeProxyModel()->mapFromSource(modelIndex);
    mpLibraryWidget->getLibraryTreeView()->setExpanded(proxyIndex, expandState);
  }
  /* Update the model switcher toolbar button. */
  MainWindow::instance()->updateModelSwitcherMenu(0);
  return true;
}

/*!
 * \brief LibraryTreeModel::unloadLibraryTreeItem
 * Removes the LibraryTreeItem and deletes the Modelica class if doDeleteClass argument is true.
 * \param pLibraryTreeItem
 * \param doDeleteClass
 * \return
 */
bool LibraryTreeModel::unloadLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem, bool doDeleteClass)
{
  /* Delete the class in OMC.
   * If deleteClass is successful remove the class from Library Browser.
   */
  if (!doDeleteClass || MainWindow::instance()->getOMCProxy()->deleteClass(pLibraryTreeItem->getNameStructure())) {
    /* QSortFilterProxy::filterAcceptRows changes the expand/collapse behavior of indexes or I am using it in some stupid way.
     * If index is expanded and we delete it then the next sibling index automatically becomes expanded.
     * The following code overcomes this issue. It stores the next index expand state and then apply it after deletion.
     */
    int row = pLibraryTreeItem->row();
    LibraryTreeItem *pNextLibraryTreeItem = 0;
    bool expandState = false;
    if (pLibraryTreeItem->parent()->childrenSize() > row + 1) {
      pNextLibraryTreeItem = pLibraryTreeItem->parent()->child(row + 1);
      QModelIndex modelIndex = libraryTreeItemIndex(pNextLibraryTreeItem);
      QModelIndex proxyIndex = mpLibraryWidget->getLibraryTreeProxyModel()->mapFromSource(modelIndex);
      expandState = mpLibraryWidget->getLibraryTreeView()->isExpanded(proxyIndex);
    }
    int i = 0;
    while(i < pLibraryTreeItem->childrenSize()) {
      unloadClassChildren(pLibraryTreeItem->child(i));
      i = 0;  //Restart iteration
    }
    // make the class non existing
    pLibraryTreeItem->setNonExisting(true);
    pLibraryTreeItem->setClassText("");
    // make the class non expanded
    pLibraryTreeItem->setExpanded(false);
    pLibraryTreeItem->removeInheritedClasses();
    // notify the inherits classes
    pLibraryTreeItem->emitUnLoaded();
    addNonExistingLibraryTreeItem(pLibraryTreeItem);
    // remove the LibraryTreeItem from Libraries Browser
    row = pLibraryTreeItem->row();
    beginRemoveRows(libraryTreeItemIndex(pLibraryTreeItem), row, row);
    pLibraryTreeItem->parent()->removeChild(pLibraryTreeItem);
    endRemoveRows();
    if (pNextLibraryTreeItem) {
      QModelIndex modelIndex = libraryTreeItemIndex(pNextLibraryTreeItem);
      QModelIndex proxyIndex = mpLibraryWidget->getLibraryTreeProxyModel()->mapFromSource(modelIndex);
      mpLibraryWidget->getLibraryTreeView()->setExpanded(proxyIndex, expandState);
    }
    /* Update the model switcher toolbar button. */
    MainWindow::instance()->updateModelSwitcherMenu(0);
    return true;
  } else {
    QMessageBox::critical(MainWindow::instance(), QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED).arg(MainWindow::instance()->getOMCProxy()->getResult())
                          .append(tr(" while deleting ") + pLibraryTreeItem->getNameStructure()), Helper::ok);
    return false;
  }
}

/*!
 * \brief LibraryTreeModel::removeLibraryTreeItem
 * Removes the LibraryTreeItem.
 * \param pLibraryTreeItem
 * \return
 */
bool LibraryTreeModel::removeLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem)
{
  /* QSortFilterProxy::filterAcceptRows changes the expand/collapse behavior of indexes or I am using it in some stupid way.
   * If index is expanded and we delete it then the next sibling index automatically becomes expanded.
   * The following code overcomes this issue. It stores the next index expand state and then apply it after deletion.
   */
  int row = pLibraryTreeItem->row();
  LibraryTreeItem *pNextLibraryTreeItem = 0;
  bool expandState = false;
  if (pLibraryTreeItem->parent()->childrenSize() > row + 1) {
    pNextLibraryTreeItem = pLibraryTreeItem->parent()->child(row + 1);
    QModelIndex modelIndex = libraryTreeItemIndex(pNextLibraryTreeItem);
    QModelIndex proxyIndex = mpLibraryWidget->getLibraryTreeProxyModel()->mapFromSource(modelIndex);
    expandState = mpLibraryWidget->getLibraryTreeView()->isExpanded(proxyIndex);
  }
  unloadClassChildren(pLibraryTreeItem);
  if (pNextLibraryTreeItem) {
    QModelIndex modelIndex = libraryTreeItemIndex(pNextLibraryTreeItem);
    QModelIndex proxyIndex = mpLibraryWidget->getLibraryTreeProxyModel()->mapFromSource(modelIndex);
    mpLibraryWidget->getLibraryTreeView()->setExpanded(proxyIndex, expandState);
  }
  /* Update the model switcher toolbar button. */
  MainWindow::instance()->updateModelSwitcherMenu(0);
  return true;
}

/*!
 * \brief LibraryTreeModel::deleteTextFile
 * Deletes the Text LibraryTreeItem.
 * \param pLibraryTreeItem
 * \param askQuestion
 * \return
 */
bool LibraryTreeModel::deleteTextFile(LibraryTreeItem *pLibraryTreeItem, bool askQuestion)
{
  if (askQuestion) {
    QMessageBox *pMessageBox = new QMessageBox(MainWindow::instance());
    pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::question));
    pMessageBox->setIcon(QMessageBox::Question);
    pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
    pMessageBox->setText(GUIMessages::getMessage(GUIMessages::DELETE_TEXT_FILE_MSG).arg(pLibraryTreeItem->getNameStructure()));
    pMessageBox->setStandardButtons(QMessageBox::Yes | QMessageBox::No);
    pMessageBox->setDefaultButton(QMessageBox::Yes);
    int answer = pMessageBox->exec();
    switch (answer) {
      case QMessageBox::Yes:
        // Yes was clicked. Don't return.
        break;
      case QMessageBox::No:
        // No was clicked. Return
        return false;
      default:
        // should never be reached
        return false;
    }
  }
  /* QSortFilterProxy::filterAcceptRows changes the expand/collapse behavior of indexes or I am using it in some stupid way.
   * If index is expanded and we delete it then the next sibling index automatically becomes expanded.
   * The following code overcomes this issue. It stores the next index expand state and then apply it after deletion.
   */
  int row = pLibraryTreeItem->row();
  LibraryTreeItem *pNextLibraryTreeItem = 0;
  bool expandState = false;
  if (pLibraryTreeItem->parent()->childrenSize() > row + 1) {
    pNextLibraryTreeItem = pLibraryTreeItem->parent()->child(row + 1);
    QModelIndex modelIndex = libraryTreeItemIndex(pNextLibraryTreeItem);
    QModelIndex proxyIndex = mpLibraryWidget->getLibraryTreeProxyModel()->mapFromSource(modelIndex);
    expandState = mpLibraryWidget->getLibraryTreeView()->isExpanded(proxyIndex);
  }
  // remove the LibraryTreeItem from Libraries Browser
  beginRemoveRows(libraryTreeItemIndex(pLibraryTreeItem), row, row);
  // Deletes the LibraryTreeItem children if any and then deletes the LibraryTreeItem.
  deleteFileChildren(pLibraryTreeItem);
  endRemoveRows();
  if (pNextLibraryTreeItem) {
    QModelIndex modelIndex = libraryTreeItemIndex(pNextLibraryTreeItem);
    QModelIndex proxyIndex = mpLibraryWidget->getLibraryTreeProxyModel()->mapFromSource(modelIndex);
    mpLibraryWidget->getLibraryTreeView()->setExpanded(proxyIndex, expandState);
  }
  /* Update the model switcher toolbar button. */
  MainWindow::instance()->updateModelSwitcherMenu(0);
  return true;
}

/*!
 * \brief LibraryTreeModel::moveClassUpDown
 * Moves the class one level up/down.
 * \param pLibraryTreeItem
 * \param up
 */
void LibraryTreeModel::moveClassUpDown(LibraryTreeItem *pLibraryTreeItem, bool up)
{
  LibraryTreeItem *pParentLibraryTreeItem = pLibraryTreeItem->parent();
  QModelIndex parentIndex = libraryTreeItemIndex(pParentLibraryTreeItem);
  int row = pLibraryTreeItem->row();
  bool update = false;
  if (up && row > 0) {
    if (MainWindow::instance()->getOMCProxy()->moveClass(pLibraryTreeItem->getNameStructure(), -1)) {
      if (beginMoveRows(parentIndex, row, row, parentIndex, row - 1)) {
        pParentLibraryTreeItem->moveChild(row, row - 1);
        endMoveRows();
        update = true;
      }
    }
  } else if (!up && row < pParentLibraryTreeItem->childrenSize() - 1) {
    if (MainWindow::instance()->getOMCProxy()->moveClass(pLibraryTreeItem->getNameStructure(), 1)) {
      if (beginMoveRows(parentIndex, row, row, parentIndex, row + 2)) {
        pParentLibraryTreeItem->moveChild(row, row + 1);
        endMoveRows();
        update = true;
      }
    }
  }
  if (update) {
    LibraryTreeItem *pContainingFileParentLibraryTreeItem = getContainingFileParentLibraryTreeItem(pLibraryTreeItem);
    // if we order in a package saved in one file strucutre then we should update its containing file item text.
    if (pContainingFileParentLibraryTreeItem != pLibraryTreeItem) {
      if (pLibraryTreeItem->getModelWidget()) {
        pLibraryTreeItem->getModelWidget()->updateModelText();
      } else {
        updateLibraryTreeItemClassText(pLibraryTreeItem);
      }
    } else {
      // if we order in a package saved in folder structure then we should mark its parent unsaved so new package.order can be saved.
      pParentLibraryTreeItem->setIsSaved(false);
      updateLibraryTreeItem(pParentLibraryTreeItem);
      if (pParentLibraryTreeItem->getModelWidget()) {
        pParentLibraryTreeItem->getModelWidget()->setWindowTitle(QString(pParentLibraryTreeItem->getName()).append("*"));
      }
    }
  }
}

/*!
 * \brief LibraryTreeModel::moveClassTopBottom
 * Moves the class to top or to bottom.
 * \param pLibraryTreeItem
 * \param top
 */
void LibraryTreeModel::moveClassTopBottom(LibraryTreeItem *pLibraryTreeItem, bool top)
{
  LibraryTreeItem *pParentLibraryTreeItem = pLibraryTreeItem->parent();
  QModelIndex parentIndex = libraryTreeItemIndex(pParentLibraryTreeItem);
  int row = pLibraryTreeItem->row();
  bool update = false;
  if (top && row > 0) {
    if (MainWindow::instance()->getOMCProxy()->moveClassToTop(pLibraryTreeItem->getNameStructure())) {
      if (beginMoveRows(parentIndex, row, row, parentIndex, 0)) {
        pParentLibraryTreeItem->moveChild(row, 0);
        endMoveRows();
        update = true;
      }
    }
  } else if (!top && row < pParentLibraryTreeItem->childrenSize() - 1) {
    if (MainWindow::instance()->getOMCProxy()->moveClassToBottom(pLibraryTreeItem->getNameStructure())) {
      if (beginMoveRows(parentIndex, row, row, parentIndex, pParentLibraryTreeItem->childrenSize())) {
        pParentLibraryTreeItem->moveChild(row, pParentLibraryTreeItem->childrenSize() - 1);
        endMoveRows();
        update = true;
      }
    }
  }
  if (update) {
    LibraryTreeItem *pContainingFileParentLibraryTreeItem = getContainingFileParentLibraryTreeItem(pLibraryTreeItem);
    // if we order in a package saved in one file strucutre then we should update its containing file item text.
    if (pContainingFileParentLibraryTreeItem != pLibraryTreeItem) {
      if (pLibraryTreeItem->getModelWidget()) {
        pLibraryTreeItem->getModelWidget()->updateModelText();
      } else {
        updateLibraryTreeItemClassText(pLibraryTreeItem);
      }
    } else {
      // if we order in a package saved in folder strucutre then we should mark its parent unsaved so new package.order can be saved.
      pParentLibraryTreeItem->setIsSaved(false);
      updateLibraryTreeItem(pParentLibraryTreeItem);
      if (pParentLibraryTreeItem->getModelWidget()) {
        pParentLibraryTreeItem->getModelWidget()->setWindowTitle(QString(pParentLibraryTreeItem->getName()).append("*"));
      }
    }
  }
}

/*!
 * \brief LibraryTreeModel::updateBindings
 * Updates the bindings.
 * \param pLibraryTreeItem
 */
void LibraryTreeModel::updateBindings(LibraryTreeItem *pLibraryTreeItem)
{
  if (MainWindow::instance()->getOMCProxy()->inferBindings(pLibraryTreeItem->getNameStructure())) {
    if (pLibraryTreeItem->getModelWidget()) {
      pLibraryTreeItem->getModelWidget()->updateModelText();
    } else {
      updateLibraryTreeItemClassText(pLibraryTreeItem);
    }
  }
}

/*!
 * \brief LibraryTreeModel::generateVerificationScenarios
 * \param pLibraryTreeItem
 */
void LibraryTreeModel::generateVerificationScenarios(LibraryTreeItem *pLibraryTreeItem)
{
  if (MainWindow::instance()->getOMCProxy()->generateVerificationScenarios(pLibraryTreeItem->getNameStructure())) {
    if (pLibraryTreeItem->getModelWidget()) {
      pLibraryTreeItem->getModelWidget()->updateModelText();
    } else {
      updateLibraryTreeItemClassText(pLibraryTreeItem);
    }
    /* generateVerificationScenarios deletes everything from the class and creates new scenario classes.
     * Remove the LibraryTreeItems
     * Load the newly created scenrario classes.
     */
    int i = 0;
    while(i < pLibraryTreeItem->childrenSize()) {
      unloadClassChildren(pLibraryTreeItem->child(i));
      i = 0;  //Restart iteration
    }
    createLibraryTreeItems(pLibraryTreeItem);
    updateLibraryTreeItem(pLibraryTreeItem);
  }
}

/*!
 * \brief LibraryTreeModel::getUniqueTopLevelItemName
 * Finds the unique name for a new top level LibraryTreeItem based on the suggested name.
 * \param name
 * \param number
 * \return
 */
QString LibraryTreeModel::getUniqueTopLevelItemName(QString name, int number)
{
  QString newItemName = QString(name).append(QString::number(number));
  for (int i = 0; i < mpRootLibraryTreeItem->childrenSize(); ++i) {
    LibraryTreeItem *pLibraryTreeItem = mpRootLibraryTreeItem->child(i);
    if (pLibraryTreeItem->getNameStructure().compare(newItemName, Qt::CaseSensitive) == 0) {
      newItemName = getUniqueTopLevelItemName(name, ++number);
      break;
    }
  }
  return newItemName;
}

/*!
 * \brief LibraryTreeModel::libraryTreeItemIndexHelper
 * Helper function for LibraryTreeModel::libraryTreeItemIndex()
 * \param pLibraryTreeItem
 * \param pParentLibraryTreeItem
 * \param parentIndex
 * \return
 */
QModelIndex LibraryTreeModel::libraryTreeItemIndexHelper(const LibraryTreeItem *pLibraryTreeItem,
                                                         const LibraryTreeItem *pParentLibraryTreeItem, const QModelIndex &parentIndex) const
{
  if (pLibraryTreeItem == pParentLibraryTreeItem) {
    return parentIndex;
  }
  for (int i = pParentLibraryTreeItem->childrenSize(); --i >= 0; ) {
    const LibraryTreeItem *childItem = pParentLibraryTreeItem->childAt(i);
    QModelIndex childIndex = index(i, 0, parentIndex);
    QModelIndex index = libraryTreeItemIndexHelper(pLibraryTreeItem, childItem, childIndex);
    if (index.isValid()) {
      return index;
    }
  }
  return QModelIndex();
}

/*!
 * \brief LibraryTreeModel::getLibraryTreeItemFromFileHelper
 * Helper function for LibraryTreeModel::getLibraryTreeItemFromFile()
 * \param pLibraryTreeItem
 * \param fileName
 * \param lineNumber
 * \return
 */
LibraryTreeItem* LibraryTreeModel::getLibraryTreeItemFromFileHelper(LibraryTreeItem *pLibraryTreeItem, QString fileName, int lineNumber)
{
  LibraryTreeItem *pFoundLibraryTreeItem = 0;
  for (int i = 0; i < pLibraryTreeItem->childrenSize(); i++) {
    LibraryTreeItem *pChildLibraryTreeItem = pLibraryTreeItem->child(i);
    if ((pChildLibraryTreeItem->getFileName().compare(fileName) == 0) && pChildLibraryTreeItem->inRange(lineNumber)) {
      return pChildLibraryTreeItem;
    }
  }
  for (int i = 0; i < pLibraryTreeItem->childrenSize(); i++) {
    pFoundLibraryTreeItem = getLibraryTreeItemFromFileHelper(pLibraryTreeItem->child(i), fileName, lineNumber);
    if (pFoundLibraryTreeItem) {
      return pFoundLibraryTreeItem;
    }
  }
  return 0;
}

/*!
 * \brief LibraryTreeModel::updateChildLibraryTreeItemClassText
 * Updates the class text of child LibraryTreeItems
 * \param pLibraryTreeItem
 * \param contents
 * \param fileName
 */
void LibraryTreeModel::updateChildLibraryTreeItemClassText(LibraryTreeItem *pLibraryTreeItem, QString contents, QString fileName)
{
  for (int i = 0; i < pLibraryTreeItem->childrenSize(); i++) {
    LibraryTreeItem *pChildLibraryTreeItem = pLibraryTreeItem->child(i);
    if (pChildLibraryTreeItem && pChildLibraryTreeItem->getFileName().compare(fileName) == 0) {
      pChildLibraryTreeItem->setClassInformation(MainWindow::instance()->getOMCProxy()->getClassInformation(pChildLibraryTreeItem->getNameStructure()));
      readLibraryTreeItemClassTextFromText(pChildLibraryTreeItem, contents);
      if (pChildLibraryTreeItem->getModelWidget()) {
        ModelicaEditor *pModelicaEditor = dynamic_cast<ModelicaEditor*>(pChildLibraryTreeItem->getModelWidget()->getEditor());
        if (pModelicaEditor) {
          pModelicaEditor->setPlainText(pChildLibraryTreeItem->getClassText(this));
          if (pModelicaEditor->isVisible()) {
            pModelicaEditor->getPlainTextEdit()->getLineNumberArea()->update();
          }
        }
      }
      if (pChildLibraryTreeItem->childrenSize() > 0) {
        updateChildLibraryTreeItemClassText(pChildLibraryTreeItem, contents, fileName);
      }
    }
  }
}

/*!
 * \brief LibraryTreeModel::readLibraryTreeItemClassTextFromText
 * Reads the contents of the Modelica class nested in another class.
 * \param pLibraryTreeItem
 * \param contents
 */
void LibraryTreeModel::readLibraryTreeItemClassTextFromText(LibraryTreeItem *pLibraryTreeItem, QString contents)
{
  QString before, text, after;
  QTextStream textStream(&contents);
  int lineNumber = 1;
  while (!textStream.atEnd()) {
    QString currentLine = textStream.readLine();
    if (lineNumber < pLibraryTreeItem->mClassInformation.lineNumberStart) {
      before += currentLine + "\n";
    } else if (lineNumber > pLibraryTreeItem->mClassInformation.lineNumberEnd) {
      after += currentLine + "\n";
    } else if (pLibraryTreeItem->inRange(lineNumber)) {
      /* Ticket #4233
       * We could have code like this,
       *
       * package P
       *   package Q
       *       model M1
       *      end M1;
       *
       *      model M2
       *      end M2; end Q;
       *   end P;
       *
       * So we need to conside column start and end.
       */
      if (lineNumber == pLibraryTreeItem->mClassInformation.lineNumberStart) {
        QString leftStr = currentLine.left(pLibraryTreeItem->mClassInformation.columnNumberStart - 1);
        int nonSpaceIndex = TabSettings::firstNonSpace(leftStr);
        /* If there is no other text on the first line of class then take the whole line.
         */
        if (nonSpaceIndex >= pLibraryTreeItem->mClassInformation.columnNumberStart - 1) {
          text += currentLine + "\n";
        } else {
          before += currentLine.left(pLibraryTreeItem->mClassInformation.columnNumberStart - 1);
          text += currentLine.mid(pLibraryTreeItem->mClassInformation.columnNumberStart - 1) + "\n";
        }
      } else if (lineNumber == pLibraryTreeItem->mClassInformation.lineNumberEnd) {
        text += currentLine.left(pLibraryTreeItem->mClassInformation.columnNumberEnd);
        after += currentLine.mid(pLibraryTreeItem->mClassInformation.columnNumberEnd) + "\n";
      } else {
        text += currentLine + "\n";
      }
    }
    lineNumber++;
  }
  pLibraryTreeItem->setClassTextBefore(before);
  pLibraryTreeItem->setClassText(text);
  pLibraryTreeItem->setClassTextAfter(after);
}

/*!
 * \brief LibraryTreeModel::readLibraryTreeItemClassTextFromFile
 * Reads the contents of the Modelica file.
 * \return
 */
QString LibraryTreeModel::readLibraryTreeItemClassTextFromFile(LibraryTreeItem *pLibraryTreeItem)
{
  QString contents = "";
  QFile file(pLibraryTreeItem->getFileName());
  if (!file.open(QIODevice::ReadOnly)) {
    QMessageBox::critical(MainWindow::instance(), QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::ERROR_OPENING_FILE).arg(pLibraryTreeItem->getFileName())
                          .arg(file.errorString()), Helper::ok);
  } else {
    contents = QString(file.readAll());
    file.close();
  }
  return contents;
}

/*!
 * \brief LibraryTreeModel::createLibraryTreeItems
 * Creates all the nested Library items.
 * \param pLibraryTreeItem
 */
void LibraryTreeModel::createLibraryTreeItems(LibraryTreeItem *pLibraryTreeItem)
{
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  QStringList libs = pOMCProxy->getClassNames(pLibraryTreeItem->getNameStructure(), true, true);
  if (!libs.isEmpty()) {
    libs.removeFirst();
  }
  LibraryTreeItem *pParentLibraryTreeItem = 0;
  foreach (QString lib, libs) {
    /* $Code is a special OpenModelica keyword. No API command will work if we use it. */
    if (lib.contains("$Code")) {
      continue;
    }
    QString name = StringHandler::getLastWordAfterDot(lib);
    QString parentName = StringHandler::removeLastWordAfterDot(lib);
    if (!(pParentLibraryTreeItem && pParentLibraryTreeItem->getNameStructure().compare(parentName) == 0)) {
      pParentLibraryTreeItem = findLibraryTreeItem(parentName, pLibraryTreeItem);
    }
    if (pParentLibraryTreeItem) {
      createLibraryTreeItemImpl(name, pParentLibraryTreeItem, pParentLibraryTreeItem->isSaved(), false, false);
    }
  }
}

/*!
 * \brief LibraryTreeModel::createLibraryTreeItemImpl
 * Creates a LibraryTreeItem.
 * \param name
 * \param pParentLibraryTreeItem
 * \param isSaved
 * \param isSystemLibrary
 * \param load
 * \param row
 * \return
 */
LibraryTreeItem* LibraryTreeModel::createLibraryTreeItemImpl(QString name, LibraryTreeItem *pParentLibraryTreeItem, bool isSaved,
                                                             bool isSystemLibrary, bool load, int row)
{
  QString nameStructure = pParentLibraryTreeItem->getNameStructure().isEmpty() ? name : pParentLibraryTreeItem->getNameStructure() + "." + name;
  // check if is in non-existing classes.
  LibraryTreeItem *pLibraryTreeItem = findNonExistingLibraryTreeItem(nameStructure);
  if (pLibraryTreeItem && pLibraryTreeItem->isNonExisting()) {
    pLibraryTreeItem->setSystemLibrary(pParentLibraryTreeItem == mpRootLibraryTreeItem ? isSystemLibrary : pParentLibraryTreeItem->isSystemLibrary());
    createNonExistingLibraryTreeItem(pLibraryTreeItem, pParentLibraryTreeItem, isSaved, row);
    if (load) {
      // create library tree items
      createLibraryTreeItems(pLibraryTreeItem);
      // load the LibraryTreeItem pixmap
      loadLibraryTreeItemPixmap(pLibraryTreeItem);
    }
    updateLibraryTreeItem(pLibraryTreeItem);
  } else {
    OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
    OMCInterface::getClassInformation_res classInformation = pOMCProxy->getClassInformation(nameStructure);
    pLibraryTreeItem = new LibraryTreeItem(LibraryTreeItem::Modelica, name, nameStructure, classInformation, "", isSaved, pParentLibraryTreeItem);
    pLibraryTreeItem->setSystemLibrary(pParentLibraryTreeItem == mpRootLibraryTreeItem ? isSystemLibrary : pParentLibraryTreeItem->isSystemLibrary());
    if (row == -1) {
      row = pParentLibraryTreeItem->childrenSize();
    }
    pParentLibraryTreeItem->insertChild(row, pLibraryTreeItem);
    if (load) {
      // create library tree items
      createLibraryTreeItems(pLibraryTreeItem);
      // load the LibraryTreeItem pixmap
      loadLibraryTreeItemPixmap(pLibraryTreeItem);
    }
  }
  return pLibraryTreeItem;
}

/*!
 * \brief LibraryTreeModel::createNonExistingLibraryTreeItem
 * \param pLibraryTreeItem
 * \param pParentLibraryTreeItem
 * \param isSaved
 * \param row
 */
void LibraryTreeModel::createNonExistingLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem, LibraryTreeItem *pParentLibraryTreeItem,
                                                        bool isSaved, int row)
{
  pLibraryTreeItem->setParent(pParentLibraryTreeItem);
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  pLibraryTreeItem->setFileName("");
  pLibraryTreeItem->setClassInformation(pOMCProxy->getClassInformation(pLibraryTreeItem->getNameStructure()));
  pLibraryTreeItem->setIsSaved(isSaved);
  if (row == -1) {
    row = pParentLibraryTreeItem->childrenSize();
  }
  QModelIndex index = libraryTreeItemIndex(pParentLibraryTreeItem);
  beginInsertRows(index, row, row);
  pParentLibraryTreeItem->insertChild(row, pLibraryTreeItem);
  endInsertRows();
  pLibraryTreeItem->setNonExisting(false);
}

/*!
 * \brief LibraryTreeModel::createLibraryTreeItemsImpl
 * Creates the LibraryTreeItems for a folder structure.
 * \param fileInfo
 * \param pParentLibraryTreeItem
 */
void LibraryTreeModel::createLibraryTreeItemsImpl(QFileInfo fileInfo, LibraryTreeItem *pParentLibraryTreeItem)
{
  // create root project folder
  LibraryTreeItem *pLibraryTreeItem = createLibraryTreeItemImpl(LibraryTreeItem::Text, fileInfo.fileName(), fileInfo.absoluteFilePath(),
                                                                fileInfo.absoluteFilePath(), true, pParentLibraryTreeItem);
  // get the files in the directory
  if (fileInfo.isDir()) {
    QDir directory(fileInfo.absoluteFilePath());
    QFileInfoList files = directory.entryInfoList(QDir::Dirs | QDir::Files | QDir::NoSymLinks | QDir::NoDotAndDotDot,
                                                  QDir::Name | QDir::DirsFirst | QDir::IgnoreCase);
    foreach (QFileInfo file, files) {
      createLibraryTreeItemsImpl(file, pLibraryTreeItem);
    }
  }
}

/*!
 * \brief LibraryTreeModel::createLibraryTreeItemImpl
 * Creates the LibraryTreeItem
 * \param type
 * \param name
 * \param nameStructure
 * \param path
 * \param isSaved
 * \param pParentLibraryTreeItem
 * \param row
 * \return
 */
LibraryTreeItem* LibraryTreeModel::createLibraryTreeItemImpl(LibraryTreeItem::LibraryType type, QString name, QString nameStructure,
                                                             QString path, bool isSaved, LibraryTreeItem *pParentLibraryTreeItem, int row)
{
  OMCInterface::getClassInformation_res classInformation;
  LibraryTreeItem *pLibraryTreeItem = new LibraryTreeItem(type, name, nameStructure, classInformation, path, isSaved, pParentLibraryTreeItem);
  if (row == -1) {
    row = pParentLibraryTreeItem->childrenSize();
  }
  pParentLibraryTreeItem->insertChild(row, pLibraryTreeItem);
  return pLibraryTreeItem;
}

/*!
 * \brief LibraryTreeModel::unloadClassHelper
 * Helper function for unloading/deleting the LibraryTreeItem.
 * \param pLibraryTreeItem
 * \param pParentLibraryTreeItem
 */
void LibraryTreeModel::unloadClassHelper(LibraryTreeItem *pLibraryTreeItem, LibraryTreeItem *pParentLibraryTreeItem)
{
  MainWindow *pMainWindow = MainWindow::instance();
  /* close the ModelWidget of LibraryTreeItem. */
  if (pLibraryTreeItem->getModelWidget()) {
    QMdiSubWindow *pMdiSubWindow = pMainWindow->getModelWidgetContainer()->getMdiSubWindow(pLibraryTreeItem->getModelWidget());
    if (pMdiSubWindow) {
      pMdiSubWindow->close();
      pMdiSubWindow->deleteLater();
    }
    pLibraryTreeItem->getModelWidget()->clearGraphicsViews();
    pLibraryTreeItem->getModelWidget()->deleteLater();
    pLibraryTreeItem->setModelWidget(0);
  }
  // make the class non existing
  pLibraryTreeItem->setNonExisting(true);
  pLibraryTreeItem->setClassText("");
  // make the class non expanded
  pLibraryTreeItem->setExpanded(false);
  pLibraryTreeItem->removeInheritedClasses();
  // notify the inherits classes
  pLibraryTreeItem->emitUnLoaded();
  addNonExistingLibraryTreeItem(pLibraryTreeItem);
  pParentLibraryTreeItem->removeChild(pLibraryTreeItem);
}

/*!
 * \brief LibraryTreeModel::unloadClassChildren
 * Unloads/deletes the LibraryTreeItem childrens.
 * \param pLibraryTreeItem
 */
void LibraryTreeModel::unloadClassChildren(LibraryTreeItem *pLibraryTreeItem)
{
  int i = 0;
  while(i < pLibraryTreeItem->childrenSize()) {
    unloadClassChildren(pLibraryTreeItem->child(i));
    i = 0;  //Restart iteration
  }
  unloadClassHelper(pLibraryTreeItem, pLibraryTreeItem->parent());
}

/*!
 * \brief LibraryTreeModel::unloadFileHelper
 * Helper function for unloading the LibraryTreeItem.
 * \param pLibraryTreeItem
 * \param pParentLibraryTreeItem
 */
void LibraryTreeModel::unloadFileHelper(LibraryTreeItem *pLibraryTreeItem, LibraryTreeItem *pParentLibraryTreeItem)
{
  // remove the ModelWidget of LibraryTreeItem and remove the QMdiSubWindow from MdiArea and delete it.
  if (pLibraryTreeItem->getModelWidget()) {
    QMdiSubWindow *pMdiSubWindow = MainWindow::instance()->getModelWidgetContainer()->getMdiSubWindow(pLibraryTreeItem->getModelWidget());
    if (pMdiSubWindow) {
      pMdiSubWindow->close();
      pMdiSubWindow->deleteLater();
    }
    pLibraryTreeItem->getModelWidget()->deleteLater();
  }
  pParentLibraryTreeItem->removeChild(pLibraryTreeItem);
  pLibraryTreeItem->deleteLater();
}

/*!
 * \brief LibraryTreeModel::unloadFileChildren
 * Unloads the LibraryTreeItem childrens.
 * \param pLibraryTreeItem
 */
void LibraryTreeModel::unloadFileChildren(LibraryTreeItem *pLibraryTreeItem)
{
  int i = 0;
  while(i < pLibraryTreeItem->childrenSize()) {
    unloadFileChildren(pLibraryTreeItem->child(i));
    i = 0;  //Restart iteration
  }
  unloadFileHelper(pLibraryTreeItem, pLibraryTreeItem->parent());
}

/*!
 * \brief LibraryTreeModel::deleteFileHelper
 * Helper function for deleting the LibraryTreeItem.
 * \param pLibraryTreeItem
 * \param pParentLibraryTreeItem
 */
void LibraryTreeModel::deleteFileHelper(LibraryTreeItem *pLibraryTreeItem, LibraryTreeItem *pParentLibraryTreeItem)
{
  // remove the ModelWidget of LibraryTreeItem and remove the QMdiSubWindow from MdiArea and delete it.
  if (pLibraryTreeItem->getModelWidget()) {
    QMdiSubWindow *pMdiSubWindow = MainWindow::instance()->getModelWidgetContainer()->getMdiSubWindow(pLibraryTreeItem->getModelWidget());
    if (pMdiSubWindow) {
      pMdiSubWindow->close();
      pMdiSubWindow->deleteLater();
    }
    pLibraryTreeItem->getModelWidget()->deleteLater();
  }
  pParentLibraryTreeItem->removeChild(pLibraryTreeItem);
  QFileInfo fileInfo(pLibraryTreeItem->getFileName());
  // delete the file/folder
  bool fail = false;
  if (fileInfo.isDir()) {
    fail = !QDir().rmdir(fileInfo.absoluteFilePath());
  } else {
    fail = !QFile::remove(fileInfo.absoluteFilePath());
  }
  if (fail) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                          GUIMessages::getMessage(GUIMessages::UNABLE_TO_DELETE_FILE)
                                                          .arg(fileInfo.absoluteFilePath()), Helper::scriptingKind, Helper::errorLevel));
  }
  pLibraryTreeItem->deleteLater();
}

/*!
 * \brief LibraryTreeModel::deleteFileChildren
 * Deletes the LibraryTreeItem childrens.
 * \param pLibraryTreeItem
 */
void LibraryTreeModel::deleteFileChildren(LibraryTreeItem *pLibraryTreeItem)
{
  int i = 0;
  while(i < pLibraryTreeItem->childrenSize()) {
    deleteFileChildren(pLibraryTreeItem->child(i));
    i = 0;  //Restart iteration
  }
  deleteFileHelper(pLibraryTreeItem, pLibraryTreeItem->parent());
}

/*!
 * \brief LibraryTreeModel::supportedDropActions
 * \return
 */
Qt::DropActions LibraryTreeModel::supportedDropActions() const
{
  return Qt::CopyAction;
}

/*!
 * \brief LibraryTreeView::LibraryTreeView
 * \param pLibraryWidget
 */
LibraryTreeView::LibraryTreeView(LibraryWidget *pLibraryWidget)
  : QTreeView(pLibraryWidget), mpLibraryWidget(pLibraryWidget)
{
  setItemDelegate(new ItemDelegate(this));
  setTextElideMode(Qt::ElideMiddle);
  setIndentation(Helper::treeIndentation);
  setDragEnabled(true);
  int libraryIconSize = OptionsDialog::instance()->getGeneralSettingsPage()->getLibraryIconSizeSpinBox()->value();
  setIconSize(QSize(libraryIconSize, libraryIconSize));
  setContextMenuPolicy(Qt::CustomContextMenu);
  setExpandsOnDoubleClick(false);
  setUniformRowHeights(true);
  createActions();
  connect(this, SIGNAL(expanded(QModelIndex)), SLOT(libraryTreeItemExpanded(QModelIndex)));
  connect(this, SIGNAL(customContextMenuRequested(QPoint)), SLOT(showContextMenu(QPoint)));
}

/*!
 * \brief LibraryTreeView::createActions
 * Creates the context menu actions.
 */
void LibraryTreeView::createActions()
{
  // open class action
  mpOpenClassAction = new QAction(QIcon(":/Resources/icons/modeling.png"), Helper::openClass, this);
  mpOpenClassAction->setStatusTip(Helper::openClassTip);
  connect(mpOpenClassAction, SIGNAL(triggered()), SLOT(openClass()));
  // view icon Action
  mpViewIconAction = new QAction(QIcon(":/Resources/icons/model.svg"), Helper::viewIcon, this);
  mpViewIconAction->setStatusTip(Helper::viewIconTip);
  connect(mpViewIconAction, SIGNAL(triggered()), SLOT(viewIcon()));
  // view diagram Action
  mpViewDiagramAction = new QAction(QIcon(":/Resources/icons/modeling.png"), Helper::viewDiagram, this);
  mpViewDiagramAction->setStatusTip(Helper::viewDiagramTip);
  connect(mpViewDiagramAction, SIGNAL(triggered()), SLOT(viewDiagram()));
  // view text Action
  mpViewTextAction = new QAction(QIcon(":/Resources/icons/modeltext.svg"), Helper::viewText, this);
  mpViewTextAction->setStatusTip(Helper::viewTextTip);
  connect(mpViewTextAction, SIGNAL(triggered()), SLOT(viewText()));
  // view documentation Action
  mpViewDocumentationAction = new QAction(QIcon(":/Resources/icons/info-icon.svg"), Helper::viewDocumentation, this);
  mpViewDocumentationAction->setStatusTip(Helper::viewDocumentationTip);
  connect(mpViewDocumentationAction, SIGNAL(triggered()), SLOT(viewDocumentation()));
  // information Action
  mpInformationAction = new QAction(Helper::information, this);
  mpInformationAction->setStatusTip(tr("Opens the class information dialog"));
  connect(mpInformationAction, SIGNAL(triggered()), SLOT(openInformationDialog()));
  // new Modelica Class Action
  mpNewModelicaClassAction = new QAction(QIcon(":/Resources/icons/new.svg"), Helper::newModelicaClass, this);
  mpNewModelicaClassAction->setStatusTip(Helper::createNewModelicaClass);
  connect(mpNewModelicaClassAction, SIGNAL(triggered()), SLOT(createNewModelicaClass()));
  // new Modelica Class Empty Action
  mpNewModelicaClassEmptyAction = new QAction(QIcon(":/Resources/icons/new.svg"), Helper::newModelicaClass, this);
  mpNewModelicaClassEmptyAction->setStatusTip(Helper::createNewModelicaClass);
  connect(mpNewModelicaClassEmptyAction, SIGNAL(triggered()), SLOT(createNewModelicaClassEmpty()));
  // save Action
  mpSaveAction = new QAction(QIcon(":/Resources/icons/save.svg"), Helper::save, this);
  mpSaveAction->setStatusTip(Helper::saveTip);
  connect(mpSaveAction, SIGNAL(triggered()), SLOT(saveClass()));
  // save as file action
  mpSaveAsAction = new QAction(QIcon(":/Resources/icons/saveas.svg"), Helper::saveAs, this);
  mpSaveAsAction->setStatusTip(Helper::saveAsTip);
  connect(mpSaveAsAction, SIGNAL(triggered()), SLOT(saveAsClass()));
  // Save Total action
  mpSaveTotalAction = new QAction(Helper::saveTotal, this);
  mpSaveTotalAction->setStatusTip(Helper::saveTotalTip);
  connect(mpSaveTotalAction, SIGNAL(triggered()), SLOT(saveTotalClass()));
  // Move class up action
  mpMoveUpAction = new QAction(QIcon(":/Resources/icons/up.svg"), Helper::moveUp, this);
  mpMoveUpAction->setShortcut(QKeySequence("Ctrl+Up"));
  mpMoveUpAction->setStatusTip(tr("Moves the class one level up"));
  connect(mpMoveUpAction, SIGNAL(triggered()), SLOT(moveClassUp()));
  // Move class down action
  mpMoveDownAction = new QAction(QIcon(":/Resources/icons/down.svg"), Helper::moveDown, this);
  mpMoveDownAction->setShortcut(QKeySequence("Ctrl+Down"));
  mpMoveDownAction->setStatusTip(tr("Moves the class one level down"));
  connect(mpMoveDownAction, SIGNAL(triggered()), SLOT(moveClassDown()));
  // Move class top action
  mpMoveTopAction = new QAction(QIcon(":/Resources/icons/top.svg"), tr("Move to Top"), this);
  mpMoveTopAction->setShortcut(QKeySequence("Ctrl+PgUp"));
  mpMoveTopAction->setStatusTip(tr("Moves the class to top"));
  connect(mpMoveTopAction, SIGNAL(triggered()), SLOT(moveClassTop()));
  // Move class bottom action
  mpMoveBottomAction = new QAction(QIcon(":/Resources/icons/bottom.svg"), tr("Move to Bottom"), this);
  mpMoveBottomAction->setShortcut(QKeySequence("Ctrl+PgDown"));
  mpMoveBottomAction->setStatusTip(tr("Moves the class to bottom"));
  connect(mpMoveBottomAction, SIGNAL(triggered()), SLOT(moveClassBottom()));
  // Order Menu
  mpOrderMenu = new QMenu(tr("Order"), this);
  mpOrderMenu->setIcon(QIcon(":/Resources/icons/order.svg"));
  // add the move action to order menu
  mpOrderMenu->addAction(mpMoveUpAction);
  mpOrderMenu->addAction(mpMoveDownAction);
  mpOrderMenu->addSeparator();
  mpOrderMenu->addAction(mpMoveTopAction);
  mpOrderMenu->addAction(mpMoveBottomAction);
  // instantiate Model Action
  mpInstantiateModelAction = new QAction(QIcon(":/Resources/icons/flatmodel.svg"), Helper::instantiateModel, this);
  mpInstantiateModelAction->setStatusTip(Helper::instantiateModelTip);
  connect(mpInstantiateModelAction, SIGNAL(triggered()), SLOT(instantiateModel()));
  // check Model Action
  mpCheckModelAction = new QAction(QIcon(":/Resources/icons/check.svg"), Helper::checkModel, this);
  mpCheckModelAction->setStatusTip(Helper::checkModelTip);
  connect(mpCheckModelAction, SIGNAL(triggered()), SLOT(checkModel()));
  // check all Models Action
  mpCheckAllModelsAction = new QAction(QIcon(":/Resources/icons/check-all.svg"), Helper::checkAllModels, this);
  mpCheckAllModelsAction->setStatusTip(Helper::checkAllModelsTip);
  connect(mpCheckAllModelsAction, SIGNAL(triggered()), SLOT(checkAllModels()));
  // simulate Action
  mpSimulateAction = new QAction(QIcon(":/Resources/icons/simulate.svg"), Helper::simulate, this);
  mpSimulateAction->setStatusTip(Helper::simulateTip);
  connect(mpSimulateAction, SIGNAL(triggered()), SLOT(simulate()));
  // simulate with transformational debugger Action
  mpSimulateWithTransformationalDebuggerAction = new QAction(QIcon(":/Resources/icons/simulate-equation.svg"), Helper::simulateWithTransformationalDebugger, this);
  mpSimulateWithTransformationalDebuggerAction->setStatusTip(Helper::simulateWithTransformationalDebuggerTip);
  connect(mpSimulateWithTransformationalDebuggerAction, SIGNAL(triggered()), SLOT(simulateWithTransformationalDebugger()));
  // simulate with algorithmic debugger Action
  mpSimulateWithAlgorithmicDebuggerAction = new QAction(QIcon(":/Resources/icons/simulate-debug.svg"), Helper::simulateWithAlgorithmicDebugger, this);
  mpSimulateWithAlgorithmicDebuggerAction->setStatusTip(Helper::simulateWithAlgorithmicDebuggerTip);
  connect(mpSimulateWithAlgorithmicDebuggerAction, SIGNAL(triggered()), SLOT(simulateWithAlgorithmicDebugger()));
#if !defined(WITHOUT_OSG)
  // simulate with animation Action
  mpSimulateWithAnimationAction = new QAction(QIcon(":/Resources/icons/simulate-animation.svg"), Helper::simulateWithAnimation, this);
  mpSimulateWithAnimationAction->setStatusTip(Helper::simulateWithAnimationTip);
  connect(mpSimulateWithAnimationAction, SIGNAL(triggered()), SLOT(simulateWithAnimation()));
#endif
  // simulation setup Action
  mpSimulationSetupAction = new QAction(QIcon(":/Resources/icons/simulation-center.svg"), Helper::simulationSetup, this);
  mpSimulationSetupAction->setStatusTip(Helper::simulationSetupTip);
  connect(mpSimulationSetupAction, SIGNAL(triggered()), SLOT(simulationSetup()));
  // Duplicate action
  /* Ticket #3265
   * Changed the name from Copy to Duplicate.
   */
  mpDuplicateClassAction = new QAction(QIcon(":/Resources/icons/duplicate.svg"), Helper::duplicate, this);
  mpDuplicateClassAction->setStatusTip(Helper::duplicateTip);
  connect(mpDuplicateClassAction, SIGNAL(triggered()), SLOT(duplicateClass()));
  // unload Action
  mpUnloadClassAction = new QAction(QIcon(":/Resources/icons/delete.svg"), Helper::unloadClass, this);
  mpUnloadClassAction->setShortcut(QKeySequence::Delete);
  mpUnloadClassAction->setStatusTip(Helper::unloadClassTip);
  connect(mpUnloadClassAction, SIGNAL(triggered()), SLOT(unloadClass()));
  // unload CompositeModel/Text file Action
  mpUnloadCompositeModelFileAction = new QAction(QIcon(":/Resources/icons/delete.svg"), Helper::unloadClass, this);
  mpUnloadCompositeModelFileAction->setShortcut(QKeySequence::Delete);
  mpUnloadCompositeModelFileAction->setStatusTip(Helper::unloadCompositeModelOrTextTip);
  connect(mpUnloadCompositeModelFileAction, SIGNAL(triggered()), SLOT(unloadCompositeModelOrTextFile()));
  // new file Action
  mpNewFileAction = new QAction(QIcon(":/Resources/icons/new.svg"), tr("New File"), this);
  mpNewFileAction->setStatusTip(tr("Creates a new file"));
  connect(mpNewFileAction, SIGNAL(triggered()), SLOT(createNewFile()));
  // new file empty Action
  mpNewFileEmptyAction = new QAction(QIcon(":/Resources/icons/new.svg"), tr("New File"), this);
  mpNewFileEmptyAction->setStatusTip(tr("Creates a new file"));
  connect(mpNewFileEmptyAction, SIGNAL(triggered()), SLOT(createNewFileEmpty()));
  // new file Action
  mpNewFolderAction = new QAction(tr("New Folder"), this);
  mpNewFolderAction->setStatusTip(tr("Creates a new folder"));
  connect(mpNewFolderAction, SIGNAL(triggered()), SLOT(createNewFolder()));
  // new file empty Action
  mpNewFolderEmptyAction = new QAction(tr("New Folder"), this);
  mpNewFolderEmptyAction->setStatusTip(tr("Creates a new folder"));
  connect(mpNewFolderEmptyAction, SIGNAL(triggered()), SLOT(createNewFolderEmpty()));
  // rename Action
  mpRenameAction = new QAction(Helper::rename, this);
  mpRenameAction->setStatusTip(Helper::renameTip);
  connect(mpRenameAction, SIGNAL(triggered()), SLOT(renameLibraryTreeItem()));
  // Delete Action
  mpDeleteAction = new QAction(QIcon(":/Resources/icons/delete.svg"), Helper::deleteStr, this);
  mpDeleteAction->setStatusTip(tr("Deletes the file"));
  connect(mpDeleteAction, SIGNAL(triggered()), SLOT(deleteTextFile()));
  // Export FMU Action
  mpExportFMUAction = new QAction(QIcon(":/Resources/icons/export-fmu.svg"), Helper::exportFMU, this);
  mpExportFMUAction->setStatusTip(Helper::exportFMUTip);
  connect(mpExportFMUAction, SIGNAL(triggered()), SLOT(exportModelFMU()));
  // Export XML Action
  mpExportXMLAction = new QAction(QIcon(":/Resources/icons/export-xml.svg"), Helper::exportXML, this);
  mpExportXMLAction->setStatusTip(Helper::exportXMLTip);
  connect(mpExportXMLAction, SIGNAL(triggered()), SLOT(exportModelXML()));
  // Export Figaro Action
  mpExportFigaroAction = new QAction(QIcon(":/Resources/icons/console.svg"), Helper::exportFigaro, this);
  mpExportFigaroAction->setStatusTip(Helper::exportFigaroTip);
  connect(mpExportFigaroAction, SIGNAL(triggered()), SLOT(exportModelFigaro()));
  // Update Bindings Action
  mpUpdateBindingsAction = new QAction(tr("Update Bindings"), this);
  mpUpdateBindingsAction->setStatusTip(tr("updates the bindings"));
  connect(mpUpdateBindingsAction, SIGNAL(triggered()), SLOT(updateBindings()));
  // Generate Verification Scenarios Action
  mpGenerateVerificationScenariosAction = new QAction(tr("Generate Verification Scenarios"), this);
  mpGenerateVerificationScenariosAction->setStatusTip(tr("Generates the verification scenarios"));
  connect(mpGenerateVerificationScenariosAction, SIGNAL(triggered()), SLOT(generateVerificationScenarios()));
  // fetch interface data
  mpFetchInterfaceDataAction = new QAction(QIcon(":/Resources/icons/interface-data.svg"), Helper::fetchInterfaceData, this);
  mpFetchInterfaceDataAction->setStatusTip(Helper::fetchInterfaceDataTip);
  connect(mpFetchInterfaceDataAction, SIGNAL(triggered()), SLOT(fetchInterfaceData()));
  // TLM co-simulation action
  mpTLMCoSimulationAction = new QAction(QIcon(":/Resources/icons/tlm-simulate.svg"), Helper::tlmCoSimulationSetup, this);
  mpTLMCoSimulationAction->setStatusTip(Helper::tlmCoSimulationSetupTip);
  connect(mpTLMCoSimulationAction, SIGNAL(triggered()), SLOT(TLMSimulate()));
}

/*!
 * \brief LibraryTreeView::getSelectedLibraryTreeItem
 * Returns the first selected LibraryTreeItem if any.
 * \return
 */
LibraryTreeItem* LibraryTreeView::getSelectedLibraryTreeItem()
{
  const QModelIndexList modelIndexes = selectedIndexes();
  if (!modelIndexes.isEmpty()) {
    QModelIndex index = modelIndexes.at(0);
    index = mpLibraryWidget->getLibraryTreeProxyModel()->mapToSource(index);
    return static_cast<LibraryTreeItem*>(index.internalPointer());
  }
  return 0;
}

/*!
 * \brief LibraryTreeView::libraryTreeItemExpanded
 * Expands the LibraryTreeItem
 * \param pLibraryTreeItem
 */
void LibraryTreeView::libraryTreeItemExpanded(LibraryTreeItem *pLibraryTreeItem)
{
  if (!pLibraryTreeItem->isExpanded()) {
    // set the range for progress bar.
    int progressValue = 0;
    MainWindow::instance()->getProgressBar()->setRange(0, pLibraryTreeItem->childrenSize());
    MainWindow::instance()->showProgressBar();
    pLibraryTreeItem->setExpanded(true);
    for (int i = 0; i < pLibraryTreeItem->childrenSize(); i++) {
      LibraryTreeItem *pChildLibraryTreeItem = pLibraryTreeItem->child(i);
      MainWindow::instance()->getStatusBar()->showMessage(QString(Helper::loading).append(": ").append(pChildLibraryTreeItem->getNameStructure()));
      mpLibraryWidget->getLibraryTreeModel()->loadLibraryTreeItemPixmap(pChildLibraryTreeItem);
      MainWindow::instance()->getStatusBar()->clearMessage();
      MainWindow::instance()->getProgressBar()->setValue(++progressValue);
    }
    MainWindow::instance()->hideProgressBar();
  }
}

/*!
 * \brief LibraryTreeView::libraryTreeItemExpanded
 * Calls the function that expands the LibraryTreeItem
 * \param index
 */
void LibraryTreeView::libraryTreeItemExpanded(QModelIndex index)
{
  // since expanded SIGNAL is triggered when tree has expanded the index so we must collapse it first and then load data and expand it back.
  collapse(index);
  QModelIndex sourceIndex = mpLibraryWidget->getLibraryTreeProxyModel()->mapToSource(index);
  LibraryTreeItem *pLibraryTreeItem = static_cast<LibraryTreeItem*>(sourceIndex.internalPointer());
  if (pLibraryTreeItem->getLibraryType() == LibraryTreeItem::Modelica) {
    libraryTreeItemExpanded(pLibraryTreeItem);
  }
  bool state = blockSignals(true);
  expand(index);
  blockSignals(state);
}

/*!
 * \brief LibraryTreeView::showContextMenu
 * Displays the context menu.
 * \param point
 */
void LibraryTreeView::showContextMenu(QPoint point)
{
  QMenu menu(this);
  if (indexAt(point).isValid()) {
    QModelIndex index = mpLibraryWidget->getLibraryTreeProxyModel()->mapToSource(indexAt(point));
    LibraryTreeItem *pLibraryTreeItem = static_cast<LibraryTreeItem*>(index.internalPointer());
    if (pLibraryTreeItem) {
      QFileInfo fileInfo(pLibraryTreeItem->getFileName());
      switch (pLibraryTreeItem->getLibraryType()) {
        case LibraryTreeItem::Modelica:
        default:
          menu.addAction(mpOpenClassAction);
          menu.addAction(mpViewIconAction);
          menu.addAction(mpViewDiagramAction);
          menu.addAction(mpViewTextAction);
          menu.addAction(mpViewDocumentationAction);
          menu.addAction(mpInformationAction);
          if (!pLibraryTreeItem->isSystemLibrary()) {
            menu.addSeparator();
            menu.addAction(mpNewModelicaClassAction);
            if (!pLibraryTreeItem->isTopLevel()) {
              menu.addMenu(mpOrderMenu);
            }
            menu.addSeparator();
            menu.addAction(mpSaveAction);
            menu.addAction(mpSaveAsAction);
            menu.addAction(mpSaveTotalAction);
          } else {
            menu.addSeparator();
            menu.addAction(mpSaveTotalAction);
          }
          menu.addSeparator();
          menu.addAction(mpInstantiateModelAction);
          menu.addAction(mpCheckModelAction);
          menu.addAction(mpCheckAllModelsAction);
          /* Ticket #3040.
           * Only show the simulation actions for Modelica types on which the simulation is allowed.
           */
          if (pLibraryTreeItem->isSimulationAllowed()) {
            menu.addAction(mpSimulateAction);
            menu.addAction(mpSimulateWithTransformationalDebuggerAction);
            menu.addAction(mpSimulateWithAlgorithmicDebuggerAction);
  #if !defined(WITHOUT_OSG)
            menu.addAction(mpSimulateWithAnimationAction);
  #endif
            menu.addAction(mpSimulationSetupAction);
          }
          /* If item is OpenModelica or part of it then don't show the duplicate menu item for it. */
          if (!(StringHandler::getFirstWordBeforeDot(pLibraryTreeItem->getNameStructure()).compare("OpenModelica") == 0)) {
            menu.addSeparator();
            menu.addAction(mpDuplicateClassAction);
          }
          if (pLibraryTreeItem->isTopLevel()) {
            mpUnloadClassAction->setText(Helper::unloadClass);
            mpUnloadClassAction->setStatusTip(Helper::unloadClassTip);
          } else {
            mpUnloadClassAction->setText(Helper::deleteStr);
            mpUnloadClassAction->setStatusTip(tr("Deletes the Modelica class"));
          }
          // only add unload/delete option for top level system libraries
          if (!pLibraryTreeItem->isSystemLibrary()) {
            menu.addAction(mpUnloadClassAction);
          } else if (pLibraryTreeItem->isSystemLibrary() && pLibraryTreeItem->isTopLevel()) {
            menu.addAction(mpUnloadClassAction);
          }
          menu.addSeparator();
          menu.addAction(mpExportFMUAction);
          menu.addAction(mpExportXMLAction);
          menu.addAction(mpExportFigaroAction);
          if (pLibraryTreeItem->isSimulationAllowed()) {
            menu.addSeparator();
            menu.addAction(mpUpdateBindingsAction);
          }
          if (pLibraryTreeItem->getRestriction() == StringHandler::Package) {
            menu.addSeparator();
            menu.addAction(mpGenerateVerificationScenariosAction);
          }
          break;
        case LibraryTreeItem::Text:
          if (fileInfo.isDir()) {
            menu.addAction(mpNewFileAction);
            menu.addAction(mpNewFolderAction);
            menu.addSeparator();
          }
          menu.addAction(mpRenameAction);
          menu.addAction(mpDeleteAction);
          if (pLibraryTreeItem->isTopLevel()) {
            menu.addSeparator();
            menu.addAction(mpUnloadCompositeModelFileAction);
          }
          break;
        case LibraryTreeItem::CompositeModel:
          menu.addAction(mpFetchInterfaceDataAction);
          menu.addAction(mpTLMCoSimulationAction);
          menu.addSeparator();
          menu.addAction(mpUnloadCompositeModelFileAction);
          break;
      }
    }
  } else {
    menu.addAction(mpNewModelicaClassEmptyAction);
    menu.addSeparator();
    menu.addAction(mpNewFileEmptyAction);
    menu.addAction(mpNewFolderEmptyAction);
  }
  menu.exec(viewport()->mapToGlobal(point));
}

/*!
 * \brief LibraryTreeView::openClass
 * Shows the class view of the selected LibraryTreeItem.
 */
void LibraryTreeView::openClass()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    mpLibraryWidget->getLibraryTreeModel()->showModelWidget(pLibraryTreeItem);
  }
}

/*!
 * \brief LibraryTreeView::viewIcon
 * Shows the icon view of the selected LibraryTreeItem.
 */
void LibraryTreeView::viewIcon()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    mpLibraryWidget->getLibraryTreeModel()->showModelWidget(pLibraryTreeItem, true, StringHandler::Icon);
  }
}

/*!
 * \brief LibraryTreeView::viewDiagram
 * Shows the diagram view of the selected LibraryTreeItem.
 */
void LibraryTreeView::viewDiagram()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    mpLibraryWidget->getLibraryTreeModel()->showModelWidget(pLibraryTreeItem, true, StringHandler::Diagram);
  }
}

/*!
 * \brief LibraryTreeView::viewText
 * Shows the text view of the selected LibraryTreeItem.
 */
void LibraryTreeView::viewText()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    mpLibraryWidget->getLibraryTreeModel()->showModelWidget(pLibraryTreeItem, true, StringHandler::ModelicaText);
  }
}

/*!
 * \brief LibraryTreeView::viewDocumentation
 * Shows the documentation view of the selected LibraryTreeItem.
 */
void LibraryTreeView::viewDocumentation()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    MainWindow::instance()->getDocumentationWidget()->showDocumentation(pLibraryTreeItem);
    bool state = MainWindow::instance()->getDocumentationDockWidget()->blockSignals(true);
    MainWindow::instance()->getDocumentationDockWidget()->show();
    MainWindow::instance()->getDocumentationDockWidget()->blockSignals(state);
  }
}

/*!
 * \brief LibraryTreeView::openInformationDialog
 * Opens the dialog to display the class information like version, version date etc.
 */
void LibraryTreeView::openInformationDialog()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    QDialog *pInformationDialog = new QDialog(MainWindow::instance());
    pInformationDialog->setAttribute(Qt::WA_DeleteOnClose);
    pInformationDialog->setWindowTitle(QString("%1 - %2 - %3").arg(Helper::applicationName, pLibraryTreeItem->getNameStructure(), Helper::information));
    pInformationDialog->setMinimumWidth(300);
    Label *pHeadingLabel = Utilities::getHeadingLabel(pLibraryTreeItem->getNameStructure());
    pHeadingLabel->setElideMode(Qt::ElideMiddle);
    QVBoxLayout *pLayout = new QVBoxLayout;
    pLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
    pLayout->addWidget(pHeadingLabel);
    pLayout->addWidget(new Label(tr("Version : %1").arg(MainWindow::instance()->getOMCProxy()->getVersion(pLibraryTreeItem->getNameStructure()))));
    pLayout->addWidget(new Label(tr("Version Date : %1").arg(MainWindow::instance()->getOMCProxy()->getVersionDateAnnotation(pLibraryTreeItem->getNameStructure()))));
    pLayout->addWidget(new Label(tr("Version Build : %1").arg(MainWindow::instance()->getOMCProxy()->getVersionBuildAnnotation(pLibraryTreeItem->getNameStructure()))));
    pInformationDialog->setLayout(pLayout);
    pInformationDialog->exec();
  }
}

/*!
 * \brief LibraryTreeView::createNewModelicaClass
 * Opens the create new ModelicaClassDialog for creating a new nested class in the selected LibraryTreeItem.
 */
void LibraryTreeView::createNewModelicaClass()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    ModelicaClassDialog *pModelicaClassDialog = new ModelicaClassDialog(MainWindow::instance());
    pModelicaClassDialog->getParentClassTextBox()->setText(pLibraryTreeItem->getNameStructure());
    pModelicaClassDialog->exec();
  }
}

/*!
 * \brief LibraryTreeView::createNewModelicaClassEmpty
 * Opens the create new ModelicaClassDialog for creating a new top level class.
 */
void LibraryTreeView::createNewModelicaClassEmpty()
{
  ModelicaClassDialog *pModelicaClassDialog = new ModelicaClassDialog(MainWindow::instance());
  pModelicaClassDialog->exec();
}

/*!
 * \brief LibraryTreeView::saveClass
 * Saves the class.
 */
void LibraryTreeView::saveClass()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    mpLibraryWidget->saveLibraryTreeItem(pLibraryTreeItem);
  }
}

/*!
 * \brief LibraryTreeView::saveAsClass
 * Save a copy of the class in a new file.
 */
void LibraryTreeView::saveAsClass()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    mpLibraryWidget->saveAsLibraryTreeItem(pLibraryTreeItem);
  }
}

/*!
 * \brief LibraryTreeView::saveTotalClass
 * Save class with all used classes.
 */
void LibraryTreeView::saveTotalClass()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    mpLibraryWidget->saveTotalLibraryTreeItem(pLibraryTreeItem);
  }
}

/*!
 * \brief LibraryTreeView::moveClassUp
 * Moves the class one level up.
 */
void LibraryTreeView::moveClassUp()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    mpLibraryWidget->getLibraryTreeModel()->moveClassUpDown(pLibraryTreeItem, true);
  }
}

/*!
 * \brief LibraryTreeView::moveClassDown
 * Moves the class one level down.
 */
void LibraryTreeView::moveClassDown()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    mpLibraryWidget->getLibraryTreeModel()->moveClassUpDown(pLibraryTreeItem, false);
  }
}

/*!
 * \brief LibraryTreeView::moveClassTop
 * Moves the class to top.
 */
void LibraryTreeView::moveClassTop()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    mpLibraryWidget->getLibraryTreeModel()->moveClassTopBottom(pLibraryTreeItem, true);
  }
}

/*!
 * \brief LibraryTreeView::moveClassBottom
 * Moves the class to bottom.
 */
void LibraryTreeView::moveClassBottom()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    mpLibraryWidget->getLibraryTreeModel()->moveClassTopBottom(pLibraryTreeItem, false);
  }
}

/*!
 * \brief LibraryTreeView::instantiateModel
 * Instantiates the selected LibraryTreeItem.
 */
void LibraryTreeView::instantiateModel()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    MainWindow::instance()->instantiateModel(pLibraryTreeItem);
  }
}

/*!
 * \brief LibraryTreeView::checkModel
 * Checks the selected LibraryTreeItem.
 */
void LibraryTreeView::checkModel()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    MainWindow::instance()->checkModel(pLibraryTreeItem);
  }
}

/*!
 * \brief LibraryTreeView::checkModel
 * Checks the selected LibraryTreeItem and all its nested LibraryTreeItems.
 */
void LibraryTreeView::checkAllModels()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    MainWindow::instance()->checkAllModels(pLibraryTreeItem);
  }
}

/*!
 * \brief LibraryTreeView::simulate
 * Simulates the selected LibraryTreeItem.
 */
void LibraryTreeView::simulate()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    MainWindow::instance()->simulate(pLibraryTreeItem);
  }
}

/*!
 * \brief LibraryTreeView::simulateWithTransformationalDebugger
 * Simulates the selected LibraryTreeItem with the Transformational Debugger.
 */
void LibraryTreeView::simulateWithTransformationalDebugger()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    MainWindow::instance()->simulateWithTransformationalDebugger(pLibraryTreeItem);
  }
}

/*!
 * \brief LibraryTreeView::simulateWithAlgorithmicDebugger
 * Simulates the selected LibraryTreeItem with the Algorithmic Debugger.
 */
void LibraryTreeView::simulateWithAlgorithmicDebugger()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    MainWindow::instance()->simulateWithAlgorithmicDebugger(pLibraryTreeItem);
  }
}

/*!
 * \brief LibraryTreeView::simulate
 * Simulates the selected LibraryTreeItem.
 */
void LibraryTreeView::simulateWithAnimation()
{
#if !defined(WITHOUT_OSG)
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    MainWindow::instance()->simulateWithAnimation(pLibraryTreeItem);
  }
#else
  assert(0);
#endif
}

/*!
 * \brief LibraryTreeView::simulationSetup
 * Opens the simulation setup dialog for the selected LibraryTreeItem.
 */
void LibraryTreeView::simulationSetup()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    MainWindow::instance()->simulationSetup(pLibraryTreeItem);
  }
}

/*!
 * \brief LibraryTreeView::duplicateClass
 * Opens the DuplicateClassDialog.
 */
void LibraryTreeView::duplicateClass()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    DuplicateClassDialog *pCopyClassDialog = new DuplicateClassDialog(false, pLibraryTreeItem, MainWindow::instance());
    pCopyClassDialog->exec();
  }
}

/*!
 * \brief LibraryTreeView::unloadClass
 * Unloads/Deletes the Modelica LibraryTreeItem.
 */
void LibraryTreeView::unloadClass()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    mpLibraryWidget->getLibraryTreeModel()->unloadClass(pLibraryTreeItem);
  }
}

/*!
 * \brief LibraryTreeView::unloadCompositeModelOrTextFile
 * Unloads the CompositeModel/Text LibraryTreeItem.
 */
void LibraryTreeView::unloadCompositeModelOrTextFile()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    mpLibraryWidget->getLibraryTreeModel()->unloadCompositeModelOrTextFile(pLibraryTreeItem);
  }
}

/*!
 * \brief LibraryTreeView::createNewFile
 * Creates a new file.
 */
void LibraryTreeView::createNewFile()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (!pLibraryTreeItem) {
    return;
  }
  CreateNewItemDialog *pCreateNewItemDialog = new CreateNewItemDialog(pLibraryTreeItem->getFileName(), true, MainWindow::instance());
  pCreateNewItemDialog->exec();
}

/*!
 * \brief LibraryTreeView::createNewFileEmpty
 * Creates a new file. Needs to provide path.
 */
void LibraryTreeView::createNewFileEmpty()
{
  CreateNewItemDialog *pCreateNewItemDialog = new CreateNewItemDialog("", true, MainWindow::instance());
  pCreateNewItemDialog->exec();
}

/*!
 * \brief LibraryTreeView::createNewFolder
 * Creates a new folder.
 */
void LibraryTreeView::createNewFolder()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (!pLibraryTreeItem) {
    return;
  }
  CreateNewItemDialog *pCreateNewItemDialog = new CreateNewItemDialog(pLibraryTreeItem->getFileName(), false, MainWindow::instance());
  pCreateNewItemDialog->exec();
}
/*!
 * \brief LibraryTreeView::createNewFolderEmpty
 * Creates a new folder. Needs to provide path.
 */
void LibraryTreeView::createNewFolderEmpty()
{
  CreateNewItemDialog *pCreateNewItemDialog = new CreateNewItemDialog("", false, MainWindow::instance());
  pCreateNewItemDialog->exec();
}

/*!
 * \brief LibraryTreeView::renameLibraryTreeItem
 * Renames the LibraryTreeItem.
 */
void LibraryTreeView::renameLibraryTreeItem()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (!pLibraryTreeItem) {
    return;
  }
  RenameItemDialog *pRenameItemDialog = new RenameItemDialog(pLibraryTreeItem, MainWindow::instance());
  pRenameItemDialog->exec();
}

/*!
 * \brief LibraryTreeView::deleteTextFile
 * Deletes the Text LibraryTreeItem.
 */
void LibraryTreeView::deleteTextFile()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    mpLibraryWidget->getLibraryTreeModel()->deleteTextFile(pLibraryTreeItem);
  }
}

/*!
 * \brief LibraryTreeView::exportModelFMU
 * Exports the selected LibraryTreeItem to FMU.
 */
void LibraryTreeView::exportModelFMU()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    MainWindow::instance()->exportModelFMU(pLibraryTreeItem);
  }
}

/*!
 * \brief LibraryTreeView::exportModelXML
 * Exports the selected LibraryTreeItem to XML.
 */
void LibraryTreeView::exportModelXML()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    MainWindow::instance()->exportModelXML(pLibraryTreeItem);
  }
}

/*!
 * \brief LibraryTreeView::exportModelFigaro
 * Exports the selected LibraryTreeItem to Figaro Model.
 */
void LibraryTreeView::exportModelFigaro()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    MainWindow::instance()->exportModelFigaro(pLibraryTreeItem);
  }
}

/*!
 * \brief LibraryTreeView::updateBindings
 * Updates the bindings.
 */
void LibraryTreeView::updateBindings()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    mpLibraryWidget->getLibraryTreeModel()->updateBindings(pLibraryTreeItem);
  }
}

/*!
 * \brief LibraryTreeView::generateVerificationScenarios
 * Generate verification scenarios
 */
void LibraryTreeView::generateVerificationScenarios()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    mpLibraryWidget->getLibraryTreeModel()->generateVerificationScenarios(pLibraryTreeItem);
  }
}

/*!
 * \brief LibraryTreeView::fetchInterfaceData
 * Slot activated when mpFetchInterfaceDataAction triggered signal is raised.
 * Calls the function that fetches the interface data.
 */
void LibraryTreeView::fetchInterfaceData()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    MainWindow::instance()->fetchInterfaceData(pLibraryTreeItem);
  }
}

/*!
 * \brief LibraryTreeView::TLMSimulate
 * Opens the TLM co-simulation dialog for the selected LibraryTreeItem.
 */
void LibraryTreeView::TLMSimulate()
{
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    MainWindow::instance()->TLMSimulate(pLibraryTreeItem);
  }
}

/*!
 * \brief LibraryTreeView::mouseDoubleClickEvent
 * Reimplementation of QTreeView::mouseDoubleClickEvent(). Opens the ModelWidget of the selected LibraryTreeItem.
 * \param event
 */
void LibraryTreeView::mouseDoubleClickEvent(QMouseEvent *event)
{
  if (!indexAt(event->pos()).isValid()) {
    return;
  }
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    if (pLibraryTreeItem->getLibraryType() == LibraryTreeItem::Text) {
      QFileInfo fileInfo(pLibraryTreeItem->getFileName());
      if (fileInfo.isDir()) {
        setExpandsOnDoubleClick(true);
        QTreeView::mouseDoubleClickEvent(event);
        setExpandsOnDoubleClick(false);
        return;
      }
    }
    mpLibraryWidget->getLibraryTreeModel()->showModelWidget(pLibraryTreeItem);
  }
  QTreeView::mouseDoubleClickEvent(event);
}

/*!
 * \brief LibraryTreeView::startDrag
 * Starts the drag operation for LibraryTreeItem.
 * \param supportedActions
 */
void LibraryTreeView::startDrag(Qt::DropActions supportedActions)
{
  QModelIndex index = currentIndex();
  index = mpLibraryWidget->getLibraryTreeProxyModel()->mapToSource(index);
  LibraryTreeItem *pLibraryTreeItem = static_cast<LibraryTreeItem*>(index.internalPointer());
  if (pLibraryTreeItem) {
    QByteArray itemData;
    QDataStream dataStream(&itemData, QIODevice::WriteOnly);
    dataStream << pLibraryTreeItem->getNameStructure();
    QMimeData *mimeData = new QMimeData;
    mimeData->setData(Helper::modelicaComponentFormat, itemData);
    qreal adjust = 35;
    QDrag *drag = new QDrag(this);
    drag->setMimeData(mimeData);
    // if we have component pixmap
    if (!pLibraryTreeItem->getDragPixmap().isNull()) {
      QPixmap pixmap = pLibraryTreeItem->getDragPixmap();
      drag->setPixmap(pixmap);
      drag->setHotSpot(QPoint((drag->hotSpot().x() + adjust), (drag->hotSpot().y() + adjust)));
    }
    drag->exec(supportedActions);
  }
}

/*!
 * \brief LibraryTreeView::keyPressEvent
 * Reimplementation of keypressevent.
 * \param event
 */
void LibraryTreeView::keyPressEvent(QKeyEvent *event)
{
  bool controlModifier = event->modifiers().testFlag(Qt::ControlModifier);
  LibraryTreeItem *pLibraryTreeItem = getSelectedLibraryTreeItem();
  if (pLibraryTreeItem) {
    bool isModelicaLibraryType = pLibraryTreeItem->getLibraryType() == LibraryTreeItem::Modelica ? true : false;
    bool isTopLevel = pLibraryTreeItem->isTopLevel() ? true : false;
    if (controlModifier && event->key() == Qt::Key_Up && isModelicaLibraryType && !isTopLevel) {
      moveClassUp();
    } else if (controlModifier && event->key() == Qt::Key_Down && isModelicaLibraryType && !isTopLevel) {
      moveClassDown();
    } else if (controlModifier && event->key() == Qt::Key_PageUp && isModelicaLibraryType && !isTopLevel) {
      moveClassTop();
    } else if (controlModifier && event->key() == Qt::Key_PageDown && isModelicaLibraryType && !isTopLevel) {
      moveClassBottom();
    } else if (controlModifier && event->key() == Qt::Key_C) {
      QApplication::clipboard()->setText(pLibraryTreeItem->getNameStructure());
    } else if (event->key() == Qt::Key_Delete) {
      if (isModelicaLibraryType) {
        unloadClass();
      } else  if (isTopLevel) {
        unloadCompositeModelOrTextFile();
      }
    } else if (event->key() == Qt::Key_Enter || event->key() == Qt::Key_Return) {
      if (pLibraryTreeItem->getLibraryType() == LibraryTreeItem::Text) {
        QFileInfo fileInfo(pLibraryTreeItem->getFileName());
        if (fileInfo.isFile()) {
          mpLibraryWidget->getLibraryTreeModel()->showModelWidget(pLibraryTreeItem);
        }
      } else {
        mpLibraryWidget->getLibraryTreeModel()->showModelWidget(pLibraryTreeItem);
      }
    } else {
      QTreeView::keyPressEvent(event);
    }
  } else {
    QTreeView::keyPressEvent(event);
  }
}

/*!
 * \class LibraryWidget
 * \brief A widget for Libraries Browser.
 */
/*!
 * \brief LibraryWidget::LibraryWidget
 * \param pParent
 */
LibraryWidget::LibraryWidget(QWidget *pParent)
  : QWidget(pParent)
{
  setMinimumWidth(175);
  // tree search filters
  mpTreeSearchFilters = new TreeSearchFilters(this);
  mpTreeSearchFilters->getFilterTextBox()->setPlaceholderText(Helper::filterClasses);
  connect(mpTreeSearchFilters->getFilterTextBox(), SIGNAL(returnPressed()), SLOT(searchClasses()));
  connect(mpTreeSearchFilters->getFilterTextBox(), SIGNAL(textEdited(QString)), SLOT(searchClasses()));
  connect(mpTreeSearchFilters->getCaseSensitiveCheckBox(), SIGNAL(toggled(bool)), SLOT(searchClasses()));
  connect(mpTreeSearchFilters->getSyntaxComboBox(), SIGNAL(currentIndexChanged(int)), SLOT(searchClasses()));
  mpTreeSearchFilters->getExpandAllButton()->hide();
  mpTreeSearchFilters->getCollapseAllButton()->hide();
  // create tree view
  mpLibraryTreeModel = new LibraryTreeModel(this);
  mpLibraryTreeProxyModel = new LibraryTreeProxyModel(this, false);
  mpLibraryTreeProxyModel->setDynamicSortFilter(true);
  mpLibraryTreeProxyModel->setSourceModel(mpLibraryTreeModel);
  mpLibraryTreeView = new LibraryTreeView(this);
  mpLibraryTreeView->setModel(mpLibraryTreeProxyModel);
  connect(mpLibraryTreeModel, SIGNAL(rowsInserted(QModelIndex,int,int)), mpLibraryTreeProxyModel, SLOT(invalidate()));
  connect(mpLibraryTreeModel, SIGNAL(rowsRemoved(QModelIndex,int,int)), mpLibraryTreeProxyModel, SLOT(invalidate()));
  // create the layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(mpTreeSearchFilters, 0, 0);
  pMainLayout->addWidget(mpLibraryTreeView, 1, 0);
  setLayout(pMainLayout);
}

/*!
 * \brief LibraryWidget::openFile
 * Opens a file.
 * \param fileName
 * \param encoding
 * \param showProgress
 * \param checkFileExists
 * \param loadExternalModel
 */
void LibraryWidget::openFile(QString fileName, QString encoding, bool showProgress, bool checkFileExists, bool loadExternalModel)
{
  /* if the file doesn't exist then remove it from the recent files list. */
  QFileInfo fileInfo(fileName);
  if (checkFileExists) {
    if (!fileInfo.exists()) {
      QMessageBox::information(MainWindow::instance(), QString(Helper::applicationName).append(" - ").append(Helper::information),
                               GUIMessages::getMessage(GUIMessages::FILE_NOT_FOUND).arg(fileName), Helper::ok);
      QSettings *pSettings = Utilities::getApplicationSettings();
      QList<QVariant> files = pSettings->value("recentFilesList/files").toList();
      // remove the RecentFile instance from the list.
      foreach (QVariant file, files) {
        RecentFile recentFile = qvariant_cast<RecentFile>(file);
        if (recentFile.fileName.compare(fileName) == 0) {
          files.removeOne(file);
        }
      }
      pSettings->setValue("recentFilesList/files", files);
      MainWindow::instance()->updateRecentFileActions();
      return;
    }
  }
  if (fileInfo.suffix().compare("mo") == 0 && !loadExternalModel) {
    openModelicaFile(fileName, encoding, showProgress);
  } else if (fileInfo.isDir()) {
    openDirectory(fileInfo, showProgress);
  } else {
    openCompositeModelOrTextFile(fileInfo, showProgress);
  }
}

/*!
 * \brief LibraryWidget::openModelicaFile
 * Opens a Modelica file and creates a LibraryTreeItem for it.
 * \param fileName
 * \param encoding
 * \param showProgress
 */
void LibraryWidget::openModelicaFile(QString fileName, QString encoding, bool showProgress)
{
  // get the class names now to check if they are already loaded or not
  QStringList existingmodelsList;
  if (showProgress) {
    MainWindow::instance()->getStatusBar()->showMessage(QString(Helper::loading).append(": ").append(fileName));
  }
  QStringList classesList = MainWindow::instance()->getOMCProxy()->parseFile(fileName, encoding);
  if (!classesList.isEmpty()) {
    /*
      Only allow loading of files that has just one nonstructured entity.
      From Modelica specs section 13.2.2.2,
      "A nonstructured entity [e.g. the file A.mo] shall contain only a stored-definition that defines a class [A] with a name
       matching the name of the nonstructured entity."
      */
    if (classesList.size() > 1) {
      QMessageBox *pMessageBox = new QMessageBox(MainWindow::instance());
      pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::error));
      pMessageBox->setIcon(QMessageBox::Critical);
      pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
      pMessageBox->setText(QString(GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_FILE).arg(fileName)));
      pMessageBox->setInformativeText(QString(GUIMessages::getMessage(GUIMessages::MULTIPLE_TOP_LEVEL_CLASSES)).arg(fileName)
                                      .arg(classesList.join(",")));
      pMessageBox->setStandardButtons(QMessageBox::Ok);
      pMessageBox->exec();
      if (showProgress) {
        MainWindow::instance()->getStatusBar()->clearMessage();
      }
      return;
    }
    bool existModel = false;
    // check if the model already exists
    foreach(QString model, classesList) {
      if (mpLibraryTreeModel->findLibraryTreeItemOneLevel(model)) {
        existingmodelsList.append(model);
        existModel = true;
      }
    }
    // if existModel is true, show user an error message
    if (existModel) {
      QMessageBox *pMessageBox = new QMessageBox(MainWindow::instance());
      pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::information));
      pMessageBox->setIcon(QMessageBox::Information);
      pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
      pMessageBox->setText(QString(GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_FILE).arg(fileName)));
      pMessageBox->setInformativeText(QString(GUIMessages::getMessage(GUIMessages::REDEFINING_EXISTING_CLASSES))
                                      .arg(existingmodelsList.join(",")).append("\n")
                                      .append(GUIMessages::getMessage(GUIMessages::DELETE_AND_LOAD).arg(fileName)));
      pMessageBox->setStandardButtons(QMessageBox::Ok);
      pMessageBox->exec();
    } else { // if no conflicting model found then just load the file simply
      // load the file in OMC
      if (MainWindow::instance()->getOMCProxy()->loadFile(fileName, encoding)) {
        // create library tree nodes for loaded models
        int progressvalue = 0;
        if (showProgress) {
          MainWindow::instance()->getProgressBar()->setRange(0, classesList.size());
          MainWindow::instance()->showProgressBar();
        }
        foreach (QString model, classesList) {
          mpLibraryTreeModel->createLibraryTreeItem(model, mpLibraryTreeModel->getRootLibraryTreeItem(), true, false, true);
          mpLibraryTreeModel->checkIfAnyNonExistingClassLoaded();
          if (showProgress) {
            MainWindow::instance()->getProgressBar()->setValue(++progressvalue);
          }
        }
        MainWindow::instance()->addRecentFile(fileName, encoding);
        mpLibraryTreeModel->loadDependentLibraries(MainWindow::instance()->getOMCProxy()->getClassNames());
        if (showProgress) {
          MainWindow::instance()->hideProgressBar();
        }
      }
    }
  }
  if (showProgress) {
    MainWindow::instance()->getStatusBar()->clearMessage();
  }
}

/*!
 * \brief LibraryWidget::openCompositeModelOrTextFile
 * Opens a CompositeModel/Text file and creates a LibraryTreeItem for it.
 * \param fileInfo
 * \param showProgress
 */
void LibraryWidget::openCompositeModelOrTextFile(QFileInfo fileInfo, bool showProgress)
{
  if (showProgress) {
    MainWindow::instance()->getStatusBar()->showMessage(QString(Helper::loading).append(": ").append(fileInfo.absoluteFilePath()));
  }
  // check if the file is already loaded.
  for (int i = 0; i < mpLibraryTreeModel->getRootLibraryTreeItem()->childrenSize(); ++i) {
    LibraryTreeItem *pLibraryTreeItem = mpLibraryTreeModel->getRootLibraryTreeItem()->child(i);
    if (pLibraryTreeItem && pLibraryTreeItem->getFileName().compare(fileInfo.absoluteFilePath()) == 0) {
      QMessageBox *pMessageBox = new QMessageBox(MainWindow::instance());
      pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::information));
      pMessageBox->setIcon(QMessageBox::Information);
      pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
      pMessageBox->setText(QString(GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_FILE).arg(fileInfo.absoluteFilePath())));
      pMessageBox->setInformativeText(QString(GUIMessages::getMessage(GUIMessages::REDEFINING_EXISTING_CLASSES))
                                      .arg(fileInfo.fileName()).append("\n")
                                      .append(GUIMessages::getMessage(GUIMessages::DELETE_AND_LOAD).arg(fileInfo.absoluteFilePath())));
      pMessageBox->setStandardButtons(QMessageBox::Ok);
      pMessageBox->exec();
      if (showProgress) {
        MainWindow::instance()->getStatusBar()->clearMessage();
      }
      return;
    }
  }
  // create a LibraryTreeItem for new loaded file.
  LibraryTreeItem *pLibraryTreeItem = 0;
  QString compositeModelName;
  if (fileInfo.suffix().compare("xml") == 0) {
    if (parseCompositeModelFile(fileInfo, &compositeModelName)) {
      pLibraryTreeItem = mpLibraryTreeModel->createLibraryTreeItem(LibraryTreeItem::CompositeModel, compositeModelName,
                                                                   fileInfo.absoluteFilePath(), fileInfo.absoluteFilePath(), true,
                                                                   mpLibraryTreeModel->getRootLibraryTreeItem());
    }
  } else {
    pLibraryTreeItem = mpLibraryTreeModel->createLibraryTreeItem(LibraryTreeItem::Text, fileInfo.fileName(), fileInfo.absoluteFilePath(),
                                                                 fileInfo.absoluteFilePath(), true,
                                                                 mpLibraryTreeModel->getRootLibraryTreeItem());
  }
  if (pLibraryTreeItem) {
    mpLibraryTreeModel->readLibraryTreeItemClassText(pLibraryTreeItem);
    MainWindow::instance()->addRecentFile(fileInfo.absoluteFilePath(), Helper::utf8);
  }
  if (showProgress) {
    MainWindow::instance()->getStatusBar()->clearMessage();
  }
}

/*!
 * \brief LibraryWidget::openDirectory
 * Opens the directory and starts creating LibraryTreeItems for it.
 * \param fileInfo
 * \param showProgress
 */
void LibraryWidget::openDirectory(QFileInfo fileInfo, bool showProgress)
{
  if (showProgress) {
    MainWindow::instance()->getStatusBar()->showMessage(QString(Helper::loading).append(": ").append(fileInfo.absoluteFilePath()));
  }
  // check if the file is already loaded.
  for (int i = 0; i < mpLibraryTreeModel->getRootLibraryTreeItem()->childrenSize(); ++i) {
    LibraryTreeItem *pLibraryTreeItem = mpLibraryTreeModel->getRootLibraryTreeItem()->child(i);
    if (pLibraryTreeItem && pLibraryTreeItem->getName().compare(fileInfo.fileName()) == 0) {
      QMessageBox *pMessageBox = new QMessageBox(MainWindow::instance());
      pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::information));
      pMessageBox->setIcon(QMessageBox::Information);
      pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
      pMessageBox->setText(QString(GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_FILE).arg(fileInfo.absoluteFilePath())));
      pMessageBox->setInformativeText(QString(GUIMessages::getMessage(GUIMessages::REDEFINING_EXISTING_CLASSES))
                                      .arg(fileInfo.fileName()).append("\n")
                                      .append(GUIMessages::getMessage(GUIMessages::DELETE_AND_LOAD).arg(fileInfo.absoluteFilePath())));
      pMessageBox->setStandardButtons(QMessageBox::Ok);
      pMessageBox->exec();
      if (showProgress) {
        MainWindow::instance()->getStatusBar()->clearMessage();
      }
      return;
    }
  }
  // create a LibraryTreeItem for new loaded file.
  mpLibraryTreeModel->createLibraryTreeItems(fileInfo, mpLibraryTreeModel->getRootLibraryTreeItem());
  MainWindow::instance()->addRecentFile(fileInfo.absoluteFilePath(), Helper::utf8);
  if (showProgress) {
    MainWindow::instance()->getStatusBar()->clearMessage();
  }
}

/*!
 * \brief LibraryWidget::parseCompositeModelFile
 * Parses the CompositeModel file.
 * \param fileInfo
 * \return
 */
bool LibraryWidget::parseCompositeModelFile(QFileInfo fileInfo, QString *pCompositeModelName)
{
  QString contents = "";
  QFile file(fileInfo.absoluteFilePath());
  if (!file.open(QIODevice::ReadOnly)) {
    QMessageBox::critical(MainWindow::instance(), QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::ERROR_OPENING_FILE).arg(fileInfo.absoluteFilePath()).arg(file.errorString()),
                          Helper::ok);
    return false;
  } else {
    contents = QString(file.readAll());
    file.close();

    MessageHandler *pMessageHandler = new MessageHandler;
    Utilities::parseCompositeModelText(pMessageHandler, contents);
    if (pMessageHandler->isFailed()) {
      QTextDocument document;
      document.setHtml(pMessageHandler->statusMessage());
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, fileInfo.absoluteFilePath(), false, pMessageHandler->line(),
                                                            pMessageHandler->column(), 0, 0, document.toPlainText(), Helper::scriptingKind,
                                                            Helper::errorLevel));
      delete pMessageHandler;
      return false;
    } else {
      // if there are no errors with the document then read the Model Name attribute.
      QDomDocument xmlDocument;
      if (!xmlDocument.setContent(&file)) {
        QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                              tr("Error reading the xml file"), Helper::ok);
      }
      // read the file
      QDomNodeList nodes = xmlDocument.elementsByTagName("Model");
      for (int i = 0; i < nodes.size(); i++) {
        QDomElement node = nodes.at(i).toElement();
        *pCompositeModelName = node.attribute("Name");
        break;
      }
      delete pMessageHandler;
      return true;
    }
  }
}

/*!
 * \brief LibraryWidget::parseAndLoadModelicaText
 * Parses and loads the Modelica text and creates a LibraryTreeItems based on the text.
 * \param modelText
 */
void LibraryWidget::parseAndLoadModelicaText(QString modelText)
{
  QStringList classNames = MainWindow::instance()->getOMCProxy()->parseString(modelText, "");
  if (classNames.size() == 0) {
    return;
  }
  // if user is defining multiple top level classes.
  if (classNames.size() > 1) {
    QMessageBox::critical(MainWindow::instance(), QString(Helper::applicationName).append(" - ").append(Helper::error),
                          QString(GUIMessages::getMessage(GUIMessages::MULTIPLE_TOP_LEVEL_CLASSES)).arg("").arg(classNames.join(",")),
                          Helper::ok);
    return;
  }
  QString className = classNames.at(0);
  bool existModel = mpLibraryTreeModel->findLibraryTreeItemOneLevel(className);
  // check if existModel is true
  if (existModel) {
    QMessageBox *pMessageBox = new QMessageBox(MainWindow::instance());
    pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::information));
    pMessageBox->setIcon(QMessageBox::Information);
    pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
    pMessageBox->setText(QString(GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_MODEL).arg("")));
    pMessageBox->setInformativeText(QString(GUIMessages::getMessage(GUIMessages::REDEFINING_EXISTING_CLASSES))
                                    .arg(className).append("\n")
                                    .append(GUIMessages::getMessage(GUIMessages::DELETE_AND_LOAD).arg("")));
    pMessageBox->setStandardButtons(QMessageBox::Ok);
    pMessageBox->exec();
  } else {  // if no conflicting model found then just load the file simply
    // load the model text in OMC
    if (MainWindow::instance()->getOMCProxy()->loadString(modelText, className)) {
      QString modelName = StringHandler::getLastWordAfterDot(className);
      QString parentName = StringHandler::removeLastWordAfterDot(className);
      LibraryTreeItem *pParentLibraryTreeItem = 0;
      if (parentName.isEmpty() || (modelName.compare(parentName) == 0)) {
        pParentLibraryTreeItem = mpLibraryTreeModel->getRootLibraryTreeItem();
      } else {
        pParentLibraryTreeItem = mpLibraryTreeModel->findLibraryTreeItem(parentName);
      }
      mpLibraryTreeModel->createLibraryTreeItem(modelName, pParentLibraryTreeItem, false, false, true);
      mpLibraryTreeModel->checkIfAnyNonExistingClassLoaded();
    }
  }
}

/*!
 * \brief LibraryWidget::saveFile
 * Saves the file with contents.
 * \param fileName
 * \param contents
 * \return
 */
bool LibraryWidget::saveFile(QString fileName, QString contents)
{
  // set the BOM settings
  QComboBox *pBOMComboBox = OptionsDialog::instance()->getTextEditorPage()->getBOMComboBox();
  Utilities::BomMode bomMode = (Utilities::BomMode)pBOMComboBox->itemData(pBOMComboBox->currentIndex()).toInt();
  bool bom = false;
  switch (bomMode) {
    case Utilities::AlwaysAddBom:
      bom = true;
      break;
    case Utilities::KeepBom:
      bom = Utilities::detectBOM(fileName);
      break;
    case Utilities::AlwaysDeleteBom:
    default:
      bom = false;
      break;
  }
  // set the line ending format
  QString newContents;
  QComboBox *pLineEndingComboBox = OptionsDialog::instance()->getTextEditorPage()->getLineEndingComboBox();
  Utilities::LineEndingMode lineEndingMode = (Utilities::LineEndingMode)pLineEndingComboBox->itemData(pLineEndingComboBox->currentIndex()).toInt();
  QTextStream crlfTextStream(&contents);
  switch (lineEndingMode) {
    case Utilities::CRLFLineEnding:
      while (!crlfTextStream.atEnd()) {
        newContents += crlfTextStream.readLine() + "\r\n";
      }
      break;
    case Utilities::LFLineEnding:
      newContents = contents;
      newContents.replace(QLatin1String("\r\n"), QLatin1String("\n"));
    default:
      break;
  }
  // open the file for writing
  QFile file(fileName);
  if (file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
    QTextStream textStream(&file);
    // set to UTF-8
    textStream.setCodec(Helper::utf8.toStdString().data());
    textStream.setGenerateByteOrderMark(bom);
    textStream << newContents;
    file.close();
    return true;
  } else {
    QString msg = GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED)
        .arg(GUIMessages::getMessage(GUIMessages::UNABLE_TO_SAVE_FILE)
             .arg(fileName).arg(file.errorString()));
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, msg, Helper::scriptingKind,
                                                          Helper::errorLevel));
    return false;
  }
}

/*!
 * \brief LibraryWidget::saveLibraryTreeItem
 * Saves the LibraryTreeItem
 * \param pLibraryTreeItem
 * \return
 */
bool LibraryWidget::saveLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem)
{
  bool result = false;
  MainWindow::instance()->getStatusBar()->showMessage(tr("Saving %1").arg(pLibraryTreeItem->getNameStructure()));
  MainWindow::instance()->showProgressBar();
  if (pLibraryTreeItem->getLibraryType() == LibraryTreeItem::Modelica) {
    /* if user has done some changes in the Modelica text view then save & validate it in the AST before saving it to file. */
    if (pLibraryTreeItem->getModelWidget() && !pLibraryTreeItem->getModelWidget()->validateText(&pLibraryTreeItem)) {
      return false;
    }
    result = saveModelicaLibraryTreeItem(pLibraryTreeItem);
  } else if (pLibraryTreeItem->getLibraryType() == LibraryTreeItem::CompositeModel) {
    result = saveCompositeModelLibraryTreeItem(pLibraryTreeItem);
  } else if (pLibraryTreeItem->getLibraryType() == LibraryTreeItem::Text) {
    result = saveTextLibraryTreeItem(pLibraryTreeItem);
  } else {
    QMessageBox::information(this, Helper::applicationName + " - " + Helper::error, GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED)
                             .arg(tr("Unable to save the file, unknown library type.")), Helper::ok);
    result = false;
  }
  MainWindow::instance()->getStatusBar()->clearMessage();
  MainWindow::instance()->hideProgressBar();
  return result;
}

/*!
 * \brief LibraryWidget::saveAsLibraryTreeItem
 * Save a copy of the class in a new file.
 * \param pLibraryTreeItem
 * \return
 */
void LibraryWidget::saveAsLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem)
{
  /* if user has done some changes in the Modelica text view then save & validate it in the AST before saving it to file. */
  if (pLibraryTreeItem->getModelWidget() && !pLibraryTreeItem->getModelWidget()->validateText(&pLibraryTreeItem)) {
    return;
  }
  if (pLibraryTreeItem->getLibraryType() == LibraryTreeItem::Modelica) {
    DuplicateClassDialog *pDuplicateClassDialog = new DuplicateClassDialog(true, pLibraryTreeItem, MainWindow::instance());
    pDuplicateClassDialog->exec();
  } else if (pLibraryTreeItem->getLibraryType() == LibraryTreeItem::CompositeModel) {
    saveAsCompositeModelLibraryTreeItem(pLibraryTreeItem);
  } else {
    QMessageBox::information(this, Helper::applicationName + " - " + Helper::error, GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED)
                             .arg(tr("Unable to save the file, unknown library type.")), Helper::ok);
  }
}

/*!
 * \brief LibraryWidget::saveTotalLibraryTreeItem
 * Save class with all used classes.
 * \param pLibraryTreeItem
 * \return
 */
bool LibraryWidget::saveTotalLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem)
{
  MainWindow::instance()->getStatusBar()->showMessage(tr("Saving %1").arg(pLibraryTreeItem->getNameStructure()));
  MainWindow::instance()->showProgressBar();
  bool result = saveTotalLibraryTreeItemHelper(pLibraryTreeItem);
  MainWindow::instance()->getStatusBar()->clearMessage();
  MainWindow::instance()->hideProgressBar();
  return result;
}

/*!
 * \brief LibraryWidget::openLibraryTreeItem
 * Opens a ModelWidget associated with the LibraryTreeItem.
 * \param nameStructure
 */
void LibraryWidget::openLibraryTreeItem(QString nameStructure)
{
  LibraryTreeItem *pLibraryTreeItem = mpLibraryTreeModel->findLibraryTreeItem(nameStructure);
  if (!pLibraryTreeItem) {
    return;
  } else {
    mpLibraryTreeModel->showModelWidget(pLibraryTreeItem);
  }
}

/*!
 * \brief LibraryWidget::saveModelicaLibraryTreeItem
 * Saves a Modelica LibraryTreeItem.
 * \param pLibraryTreeItem
 * \return
 */
bool LibraryWidget::saveModelicaLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem)
{
  bool result = false;
  // if some file within folder structure package is changed and has valid file path then we should only save it.
  pLibraryTreeItem = mpLibraryTreeModel->getContainingFileParentLibraryTreeItem(pLibraryTreeItem);
  if (pLibraryTreeItem->isFilePathValid() && mpLibraryTreeModel->getContainingFileParentLibraryTreeItem(pLibraryTreeItem) == pLibraryTreeItem) {
    result = saveModelicaLibraryTreeItemHelper(pLibraryTreeItem);
  } else {
    QString topLevelClassName = StringHandler::getFirstWordBeforeDot(pLibraryTreeItem->getNameStructure());
    LibraryTreeItem *pTopLevelLibraryTreeItem = mpLibraryTreeModel->findLibraryTreeItem(topLevelClassName);
    result = saveModelicaLibraryTreeItemHelper(pTopLevelLibraryTreeItem);
  }
  //  if (result) {
  //    /* We need to load the file again so that the line number information for model_info.json is correct.
  //     * Update to AST (makes source info WRONG), saving it (source info STILL WRONG), reload it (and omc knows the new lines)
  //     * In order to get rid of it save API should update omc with new line information.
  //     */
  //    mpMainWindow->getOMCProxy()->loadFile(pLibraryTreeItem->getFileName());
  //  }
  return result;
}

/*!
 * \brief LibraryWidget::saveModelicaLibraryTreeItemHelper
 * Helper function for LibraryWidget::saveModelicaLibraryTreeItem()
 * \param pLibraryTreeItem
 * \return
 */
bool LibraryWidget::saveModelicaLibraryTreeItemHelper(LibraryTreeItem *pLibraryTreeItem)
{
  bool result = false;
  if (pLibraryTreeItem->getSaveContentsType() == LibraryTreeItem::SaveInOneFile) {
    result = saveModelicaLibraryTreeItemOneFile(pLibraryTreeItem);
    if (result) {
      saveChildLibraryTreeItemsOneFile(pLibraryTreeItem);
    }
  } else {
    result = saveModelicaLibraryTreeItemFolder(pLibraryTreeItem);
    if (result) {
      for (int i = 0; i < pLibraryTreeItem->childrenSize(); i++) {
        // if any child is saved in package.mo then only mark it saved and update its information because it should be already saved.
        LibraryTreeItem *pChildLibraryTreeItem = pLibraryTreeItem->child(i);
        if (pLibraryTreeItem->getFileName().compare(pChildLibraryTreeItem->getFileName()) == 0) {
          saveChildLibraryTreeItemsOneFileHelper(pChildLibraryTreeItem);
          saveChildLibraryTreeItemsOneFile(pChildLibraryTreeItem);
        } else {
          saveModelicaLibraryTreeItemHelper(pChildLibraryTreeItem);
        }
      }
    }
  }
  return result;
}

/*!
 * \brief LibraryWidget::saveModelicaLibraryTreeItemOneFile
 * Saves a Modelica LibraryTreeItem in one file.
 * \param pLibraryTreeItem
 * \return
 */
bool LibraryWidget::saveModelicaLibraryTreeItemOneFile(LibraryTreeItem *pLibraryTreeItem)
{
  if (pLibraryTreeItem->isSaved()) {
    return true;
  }
  MainWindow::instance()->getStatusBar()->showMessage(tr("Saving %1").arg(pLibraryTreeItem->getNameStructure()));
  QString fileName;
  if (pLibraryTreeItem->isTopLevel() && !pLibraryTreeItem->isFilePathValid()) {
    QString name = pLibraryTreeItem->getName();
    fileName = StringHandler::getSaveFileName(this, tr("%1 - Save %2 %3 as Modelica File").arg(Helper::applicationName)
                                              .arg(pLibraryTreeItem->mClassInformation.restriction).arg(pLibraryTreeItem->getName()), NULL,
                                              Helper::omFileTypes, NULL, "mo", &name);
    if (fileName.isEmpty()) { // if user press ESC
      return false;
    }
  } else if (pLibraryTreeItem->isFilePathValid()) {
    fileName = pLibraryTreeItem->getFileName();
  } else {
    QFileInfo fileInfo(pLibraryTreeItem->parent()->getFileName());
    fileName = QString("%1/%2.mo").arg(fileInfo.absoluteDir().absolutePath()).arg(pLibraryTreeItem->getName());
  }
  /* if user has done some changes in the Modelica text view then save & validate it in the AST before saving it to file. */
  if (pLibraryTreeItem->getModelWidget() && !pLibraryTreeItem->getModelWidget()->validateText(&pLibraryTreeItem)) {
    return false;
  }
  // save the class
  QString contents;
  if (pLibraryTreeItem->getModelWidget() && pLibraryTreeItem->getModelWidget()->getEditor()) {
    contents = pLibraryTreeItem->getModelWidget()->getEditor()->getPlainTextEdit()->toPlainText();
  } else {
    contents = pLibraryTreeItem->getClassText(mpLibraryTreeModel);
  }
  if (saveFile(fileName, contents)) {
    /* mark the file as saved and update the labels. */
    pLibraryTreeItem->setIsSaved(true);
    pLibraryTreeItem->setFileName(fileName);
    pLibraryTreeItem->mClassInformation.fileName = fileName;
    MainWindow::instance()->getOMCProxy()->setSourceFile(pLibraryTreeItem->getNameStructure(), fileName);
    if (pLibraryTreeItem->getModelWidget() && pLibraryTreeItem->getModelWidget()->isLoadedWidgetComponents()) {
      pLibraryTreeItem->getModelWidget()->setWindowTitle(pLibraryTreeItem->getName());
      pLibraryTreeItem->getModelWidget()->setModelFilePathLabel(fileName);
    }
    mpLibraryTreeModel->updateLibraryTreeItem(pLibraryTreeItem);
    /* Save the traceabiliy information and send to Daemon. */
    if(GitCommands::instance()->isSavedUnderGitRepository(pLibraryTreeItem->getFileName()) && OptionsDialog::instance()->getTraceabilityPage()->getTraceabilityGroupBox()->isChecked() ){
      MainWindow::instance()->getCommitChangesDialog()->commitAndGenerateTraceabilityURI(pLibraryTreeItem->getFileName());
    }
  } else {
     return false;
  }
  return true;
}

/*!
 * \brief LibraryWidget::saveChildLibraryTreeItemsOneFile
 * Updates the LibraryTreeItem children to be saved in one file as their parent.
 * \param pLibraryTreeItem
 */
void LibraryWidget::saveChildLibraryTreeItemsOneFile(LibraryTreeItem *pLibraryTreeItem)
{
  for (int i = 0; i < pLibraryTreeItem->childrenSize(); i++) {
    LibraryTreeItem *pChildLibraryTreeItem = pLibraryTreeItem->child(i);
    saveChildLibraryTreeItemsOneFileHelper(pChildLibraryTreeItem);
    saveChildLibraryTreeItemsOneFile(pChildLibraryTreeItem);
  }
}

/*!
 * \brief LibraryWidget::saveChildLibraryTreeItemsOneFileHelper
 * Helper function for LibraryWidget::saveChildLibraryTreeItemsOneFile()
 * \param pLibraryTreeItem
 */
void LibraryWidget::saveChildLibraryTreeItemsOneFileHelper(LibraryTreeItem *pLibraryTreeItem)
{
  pLibraryTreeItem->setIsSaved(true);
  pLibraryTreeItem->setFileName(pLibraryTreeItem->parent()->getFileName());
  pLibraryTreeItem->mClassInformation.fileName = pLibraryTreeItem->parent()->getFileName();
  MainWindow::instance()->getOMCProxy()->setSourceFile(pLibraryTreeItem->getNameStructure(), pLibraryTreeItem->parent()->getFileName());
  if (pLibraryTreeItem->getModelWidget() && pLibraryTreeItem->getModelWidget()->isLoadedWidgetComponents()) {
    pLibraryTreeItem->getModelWidget()->setWindowTitle(pLibraryTreeItem->getName());
    pLibraryTreeItem->getModelWidget()->setModelFilePathLabel(pLibraryTreeItem->parent()->getFileName());
  }
  mpLibraryTreeModel->updateLibraryTreeItem(pLibraryTreeItem);
}

/*!
 * \brief LibraryWidget::saveModelicaLibraryTreeItemFolder
 * Saves a Modelica LibraryTreeItem in folder structure.
 * \param pLibraryTreeItem
 * \return
 */
bool LibraryWidget::saveModelicaLibraryTreeItemFolder(LibraryTreeItem *pLibraryTreeItem)
{
  if (!pLibraryTreeItem->isSaved()) {
    MainWindow::instance()->getStatusBar()->showMessage(tr("Saving %1").arg(pLibraryTreeItem->getNameStructure()));
    QString directoryName;
    QString fileName;
    if (pLibraryTreeItem->isTopLevel() && !pLibraryTreeItem->isFilePathValid()) {
      QString name = pLibraryTreeItem->getName();
      directoryName = StringHandler::getSaveFolderName(this, tr("%1 - Save %2 %3 as Modelica Directorty").arg(Helper::applicationName)
                                                       .arg(pLibraryTreeItem->mClassInformation.restriction).arg(pLibraryTreeItem->getName()),
                                                       NULL, "Directory Files (*)", NULL, &name);
      if (directoryName.isEmpty()) {  // if user press ESC
        return false;
      }
      directoryName = directoryName.replace("\\", "/");
      fileName = QString("%1/package.mo").arg(directoryName);
    } else if (pLibraryTreeItem->isFilePathValid()) {
      fileName = pLibraryTreeItem->getFileName();
      QFileInfo fileInfo(fileName);
      directoryName = fileInfo.absoluteDir().absolutePath();
    } else {
      QFileInfo fileInfo(pLibraryTreeItem->parent()->getFileName());
      directoryName = QString("%1/%2").arg(fileInfo.absoluteDir().absolutePath()).arg(pLibraryTreeItem->getName());
      fileName = QString("%1/package.mo").arg(directoryName);
    }
    /* if user has done some changes in the Modelica text view then save & validate it in the AST before saving it to file. */
    if (pLibraryTreeItem->getModelWidget() && !pLibraryTreeItem->getModelWidget()->validateText(&pLibraryTreeItem)) {
      return false;
    }
    // create the folder
    if (!QDir().exists(directoryName)) {
      QDir().mkpath(directoryName);
    }
    // save the class
    QString contents;
    if (pLibraryTreeItem->getModelWidget()->getEditor()) {
      contents = pLibraryTreeItem->getModelWidget()->getEditor()->getPlainTextEdit()->toPlainText();
    } else {
      contents = pLibraryTreeItem->getClassText(mpLibraryTreeModel);
    }
    if (saveFile(fileName, contents)) {
      /* mark the file as saved and update the labels. */
      pLibraryTreeItem->setIsSaved(true);
      pLibraryTreeItem->setFileName(fileName);
      pLibraryTreeItem->mClassInformation.fileName = fileName;
      MainWindow::instance()->getOMCProxy()->setSourceFile(pLibraryTreeItem->getNameStructure(), fileName);
      if (pLibraryTreeItem->getModelWidget() && pLibraryTreeItem->getModelWidget()->isLoadedWidgetComponents()) {
        pLibraryTreeItem->getModelWidget()->setWindowTitle(pLibraryTreeItem->getName());
        pLibraryTreeItem->getModelWidget()->setModelFilePathLabel(fileName);
      }
      mpLibraryTreeModel->updateLibraryTreeItem(pLibraryTreeItem);
    } else {
      return false;
    }
  }
  // read the package.order file if it already exists and rename any removed classes as class.bak-mo
  QFileInfo fileInfo(pLibraryTreeItem->getFileName());
  QFile file(QString("%1/package.order").arg(fileInfo.absoluteDir().absolutePath()));
  if (file.open(QIODevice::ReadOnly)) {
    QTextStream textStream(&file);
    while (!textStream.atEnd()) {
      QString currentLine = textStream.readLine();
      bool classExists = false;
      for (int i = 0; i < pLibraryTreeItem->childrenSize(); i++) {
        if (pLibraryTreeItem->child(i)->getName().compare(currentLine) == 0) {
          classExists = true;
          break;
        }
      }
      if (!classExists) {
        if (QDir().exists(QString("%1/%2").arg(fileInfo.absoluteDir().absolutePath()).arg(currentLine))) {
          QFile::rename(QString("%1/%2/package.mo").arg(fileInfo.absoluteDir().absolutePath()).arg(currentLine),
                        QString("%1/%2/package.bak-mo").arg(fileInfo.absoluteDir().absolutePath()).arg(currentLine));
        } else {
          QFile::rename(QString("%1/%2.mo").arg(fileInfo.absoluteDir().absolutePath()).arg(currentLine),
                        QString("%1/%2.bak-mo").arg(fileInfo.absoluteDir().absolutePath()).arg(currentLine));
        }
      }
    }
    file.close();
  }
  // create a package.order file
  QString contents = "";
  /* Ticket #4152. package.order should contain constants and classes.*/
  QStringList childClasses = MainWindow::instance()->getOMCProxy()->getClassNames(pLibraryTreeItem->getNameStructure(), false,
                                                                                  false, false, false, true, true);
  for (int i = 0; i < childClasses.size(); i++) {
    contents.append(childClasses.at(i)).append("\n");
  }
  // create a new package.order file
  saveFile(QString("%1/package.order").arg(fileInfo.absoluteDir().absolutePath()), contents);
  return true;
}

/*!
 * \brief LibraryWidget::saveTextLibraryTreeItem
 * Saves a Text LibraryTreeItem.
 * \param pLibraryTreeItem
 * \return
 */
bool LibraryWidget::saveTextLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem)
{
  QString fileName;
  if (pLibraryTreeItem->getFileName().isEmpty()) {
    QString name = pLibraryTreeItem->getName();
    fileName = StringHandler::getSaveFileName(this, QString(Helper::applicationName).append(" - ").append(tr("Save File")), NULL,
                                              Helper::txtFileTypes, NULL, "txt", &name);
    if (fileName.isEmpty()) { // if user press ESC
      return false;
    }
  } else {
    fileName = pLibraryTreeItem->getFileName();
  }

  if (saveFile(fileName, pLibraryTreeItem->getModelWidget()->getEditor()->getPlainTextEdit()->toPlainText())) {
    /* mark the file as saved and update the labels. */
    pLibraryTreeItem->setIsSaved(true);
    pLibraryTreeItem->setFileName(fileName);
    if (pLibraryTreeItem->getModelWidget()) {
      pLibraryTreeItem->getModelWidget()->setWindowTitle(pLibraryTreeItem->getName());
      pLibraryTreeItem->getModelWidget()->setModelFilePathLabel(fileName);
    }
    mpLibraryTreeModel->updateLibraryTreeItem(pLibraryTreeItem);
  } else {
    return false;
  }
  return true;
}

/*!
 * \brief LibraryWidget::saveCompositeModelLibraryTreeItem
 * Saves a CompositeModel LibraryTreeItem.
 * \param pLibraryTreeItem
 * \return
 */
bool LibraryWidget::saveCompositeModelLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem)
{
  if (pLibraryTreeItem->getFileName().isEmpty()) {
    return saveAsCompositeModelLibraryTreeItem(pLibraryTreeItem);
  } else {
    return saveCompositeModelLibraryTreeItem(pLibraryTreeItem, pLibraryTreeItem->getFileName());
  }
}

/*!
 * \brief LibraryWidget::saveAsCompositeModelLibraryTreeItem
 * Save a copy of the CompositeModel in a new file.
 * \param pLibraryTreeItem
 * \return
 */
bool LibraryWidget::saveAsCompositeModelLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem)
{
  QString fileName;
  QString name = pLibraryTreeItem->getName();
  fileName = StringHandler::getSaveFileName(this, QString(Helper::applicationName).append(" - ").append(tr("Save File")), NULL,
                                            Helper::xmlFileTypes, NULL, "xml", &name);
  if (fileName.isEmpty()) {   // if user press ESC
    return false;
  }
  return saveCompositeModelLibraryTreeItem(pLibraryTreeItem, fileName);
}

/*!
 * \brief LibraryWidget::saveCompositeModelLibraryTreeItem
 * Saves a CompositeModel LibraryTreeItem.
 * \param pLibraryTreeItem
 * \return
 */
bool LibraryWidget::saveCompositeModelLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem, QString fileName)
{
  if (saveFile(fileName, pLibraryTreeItem->getModelWidget()->getEditor()->getPlainTextEdit()->toPlainText())) {
    /* mark the file as saved and update the labels. */
    pLibraryTreeItem->setIsSaved(true);
    QString oldCompositeModelFile = pLibraryTreeItem->getFileName();
    pLibraryTreeItem->setFileName(fileName);
    if (pLibraryTreeItem->getModelWidget()) {
      pLibraryTreeItem->getModelWidget()->setWindowTitle(pLibraryTreeItem->getName());
      pLibraryTreeItem->getModelWidget()->setModelFilePathLabel(fileName);
    }
    mpLibraryTreeModel->updateLibraryTreeItem(pLibraryTreeItem);
    // Create folders for the submodels and copy there source file in them.
    CompositeModelEditor *pCompositeModelEditor = dynamic_cast<CompositeModelEditor*>(pLibraryTreeItem->getModelWidget()->getEditor());
    GraphicsView *pGraphicsView = pLibraryTreeItem->getModelWidget()->getDiagramGraphicsView();
    QDomNodeList subModels = pCompositeModelEditor->getSubModels();
    for (int i = 0; i < subModels.size(); i++) {
      QDomElement subModel = subModels.at(i).toElement();
      QString directoryName = subModel.attribute("Name");
      Component *pComponent = pGraphicsView->getComponentObject(directoryName);
      QString modelFile;
      if (pComponent && pComponent->getLibraryTreeItem()) {
        modelFile = pComponent->getLibraryTreeItem()->getFileName();
      } else {
        QFileInfo fileInfo(oldCompositeModelFile);
        modelFile = QString("%1/%2/%3").arg(fileInfo.absolutePath()).arg(directoryName).arg(subModel.attribute("ModelFile"));
      }
      // create directory for submodel
      QFileInfo fileInfo(fileName);
      QString directoryPath = fileInfo.absoluteDir().absolutePath() + "/" + directoryName;
      if (!QDir().exists(directoryPath)) {
        QDir().mkpath(directoryPath);
      }
      // copy the submodel file to the created directory
      QFileInfo modelFileInfo(modelFile);
      QString newModelFilePath = directoryPath + "/" + modelFileInfo.fileName();
      if (modelFileInfo.absoluteFilePath().compare(newModelFilePath) != 0) {
        // first try to remove the file because QFile::copy will not override the file.
        QFile::remove(newModelFilePath);
      }
      QFile::copy(modelFileInfo.absoluteFilePath(), newModelFilePath);
      // copy the geomtry file to the created directory
      if (pComponent && !pComponent->getComponentInfo()->getGeometryFile().isEmpty()) {
        QFileInfo geometryFileInfo(pComponent->getComponentInfo()->getGeometryFile());
        QString newGeometryFilePath = directoryPath + "/" + geometryFileInfo.fileName();
        if (geometryFileInfo.absoluteFilePath().compare(newGeometryFilePath) != 0) {
          // first try to remove the file because QFile::copy will not override the file.
          QFile::remove(newGeometryFilePath);
        }
        QFile::copy(geometryFileInfo.absoluteFilePath(), newGeometryFilePath);
        pComponent->getComponentInfo()->setGeometryFile(newGeometryFilePath);
      }
    }
  } else {
    return false;
  }
  return true;
}


/*!
 * \brief LibraryWidget::saveTotalLibraryTreeItemHelper
 * Helper function for LibraryWidget::saveTotalLibraryTreeItem()
 * \param pLibraryTreeItem
 * \return
 */
bool LibraryWidget::saveTotalLibraryTreeItemHelper(LibraryTreeItem *pLibraryTreeItem)
{
  bool result = false;
  /* if user has done some changes in the Modelica text view then save & validate it in the AST before saving it to file. */
  if (pLibraryTreeItem->getModelWidget() && !pLibraryTreeItem->getModelWidget()->validateText(&pLibraryTreeItem)) {
    return false;
  }
  QString fileName;
  QString name = QString("%1Total").arg(pLibraryTreeItem->getName());
  fileName = StringHandler::getSaveFileName(this, tr("%1 - Save %2 %3 as Total File").arg(Helper::applicationName)
                                            .arg(pLibraryTreeItem->mClassInformation.restriction).arg(pLibraryTreeItem->getName()), NULL,
                                            Helper::omFileTypes, NULL, "mo", &name);
  if (fileName.isEmpty()) { // if user press ESC
    return false;
  }
  // save the model through OMC
  result = MainWindow::instance()->getOMCProxy()->saveTotalModel(fileName, pLibraryTreeItem->getNameStructure());
  return result;
}

/*!
 * \brief LibraryWidget::searchClasses
 * Searches the classes in the Libraries Browser.
 */
void LibraryWidget::searchClasses()
{
  QString searchText = mpTreeSearchFilters->getFilterTextBox()->text();
  QRegExp::PatternSyntax syntax = QRegExp::PatternSyntax(mpTreeSearchFilters->getSyntaxComboBox()->itemData(mpTreeSearchFilters->getSyntaxComboBox()->currentIndex()).toInt());
  Qt::CaseSensitivity caseSensitivity = mpTreeSearchFilters->getCaseSensitiveCheckBox()->isChecked() ? Qt::CaseSensitive: Qt::CaseInsensitive;
  QRegExp regExp(searchText, caseSensitivity, syntax);
  mpLibraryTreeProxyModel->setFilterRegExp(regExp);
}
