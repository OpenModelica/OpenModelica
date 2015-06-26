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
 *
 * @author Adeel Asghar <adeel.asghar@liu.se>
 *
 * RCS: $Id$
 *
 */

#include "LibraryTreeWidget.h"
#include "VariablesWidget.h"
#include "SimulationOutputWidget.h"

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
    checkRect = check(opt, opt.rect, value);
  }
  // do the layout
  doLayout(opt, &checkRect, &decorationRect, &displayRect, false);
  // draw the item
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
  if (option.state & QStyle::State_MouseOver)
  {
    QPalette::ColorGroup cg = option.state & QStyle::State_Enabled ? QPalette::Normal : QPalette::Disabled;
    if (cg == QPalette::Normal && !(option.state & QStyle::State_Active))
      cg = QPalette::Inactive;
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
    size.rheight() = qMax(textDocument.size().height(), (qreal)24.0);
  } else if (parent() && qobject_cast<LibraryTreeWidget*>(parent())) {
    size.rheight() = size.height() + 2;
  } else {
    size.rheight() = qMax(size.height(), 24);
  }
  return size;
}

/*!
  Shows a Qt::PointingHandCursor for simulation output links.\n
  If the link is clicked then calls the SimulationOutputWidget::openTransformationBrowser(QUrl).
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

SearchClassWidget::SearchClassWidget(MainWindow *pMainWindow)
  : QWidget(pMainWindow)
{
  mpMainWindow = pMainWindow;
  mpSearchClassTextBox = new QLineEdit;
  mpSearchClassTextBox->setPlaceholderText(Helper::searchModelicaClass);
  connect(mpSearchClassTextBox, SIGNAL(returnPressed()), SLOT(searchClasses()));
  mpSearchClassButton = new QPushButton(Helper::search);
  connect(mpSearchClassButton, SIGNAL(clicked()), SLOT(searchClasses()));
  mpFindInModelicaTextCheckBox = new QCheckBox(tr("Within Modelica text"));
  mpNoModelicaClassFoundLabel = new Label(tr("Sorry, no Modelica class found."));
  mpNoModelicaClassFoundLabel->setVisible(false);
  mpLibraryTreeWidget = new LibraryTreeWidget(true, pMainWindow);
  // set grid layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(mpSearchClassTextBox, 0, 0);
  pMainLayout->addWidget(mpSearchClassButton, 0, 1);
  pMainLayout->addWidget(mpFindInModelicaTextCheckBox, 1, 0, 1, 2);
  pMainLayout->addWidget(mpNoModelicaClassFoundLabel, 2, 0, 1, 2);
  pMainLayout->addWidget(mpLibraryTreeWidget, 3, 0, 1, 2);
  setLayout(pMainLayout);
}

QLineEdit* SearchClassWidget::getSearchClassTextBox()
{
  return mpSearchClassTextBox;
}

void SearchClassWidget::searchClasses()
{
  // Remove the searched classes first
  int i = 0;
  while(i < mpLibraryTreeWidget->topLevelItemCount()) {
    qDeleteAll(mpLibraryTreeWidget->topLevelItem(i)->takeChildren());
    delete mpLibraryTreeWidget->topLevelItem(i);
    i = 0;   //Restart iteration
  }
  if (mpSearchClassTextBox->text().isEmpty() || (mpSearchClassTextBox->text().compare(Helper::searchModelicaClass) == 0)) {
    return;
  }
  /* search classes in OMC */
  QStringList searchedClasses = mpMainWindow->getOMCProxy()->searchClassNames(mpSearchClassTextBox->text(),
                                                                              mpFindInModelicaTextCheckBox->isChecked());
  if (searchedClasses.isEmpty()) {
    mpNoModelicaClassFoundLabel->setVisible(true);
    return;
  } else {
    mpNoModelicaClassFoundLabel->setVisible(false);
  }
  /* Load the searched classes */
  int progressValue = 0;
  mpMainWindow->getProgressBar()->setRange(0, searchedClasses.size());
  mpMainWindow->showProgressBar();
  for (int j = 0 ; j < searchedClasses.size() ; j++) {
    mpMainWindow->getStatusBar()->showMessage(QString(Helper::loading).append(": ").append(searchedClasses[j]));
    LibraryTreeNode *pNewLibraryTreeNode;
    OMCInterface::getClassInformation_res classInformation = mpMainWindow->getOMCProxy()->getClassInformation(searchedClasses[j]);
    pNewLibraryTreeNode = new LibraryTreeNode(LibraryTreeNode::Modelica, searchedClasses[j], "", searchedClasses[j], classInformation, "",
                                              true, mpLibraryTreeWidget);
    bool isDocumentationClass = mpMainWindow->getOMCProxy()->getDocumentationClassAnnotation(searchedClasses[j]);
    pNewLibraryTreeNode->setIsDocumentationClass(isDocumentationClass);
    mpLibraryTreeWidget->loadLibraryComponent(pNewLibraryTreeNode);
    mpLibraryTreeWidget->addTopLevelItem(pNewLibraryTreeNode);
    mpMainWindow->getProgressBar()->setValue(++progressValue);
    mpMainWindow->getStatusBar()->clearMessage();
  }
  mpMainWindow->hideProgressBar();
}

LibraryTreeNode::LibraryTreeNode(LibraryType type, QString text, QString parentName, QString nameStructure,
                                 OMCInterface::getClassInformation_res classInformation, QString fileName, bool isSaved,
                                 LibraryTreeWidget *pParent)
  : mLibraryType(type), mSystemLibrary(false), mpModelWidget(0), mpLibraryTreeWidget(pParent)
{
  setName(text);
  setParentName(parentName);
  setNameStructure(nameStructure);
  if (type == LibraryTreeNode::Modelica) {
    setClassInformation(classInformation);
  } else {
    setFileName(fileName);
    setReadOnly(!mpLibraryTreeWidget->isFileWritAble(fileName));
  }
  setIsSaved(isSaved);
  setIsProtected(false);
  setIsDocumentationClass(false);
  setSaveContentsType(LibraryTreeNode::SaveUnspecified);
  updateAttributes();
}

void LibraryTreeNode::setClassInformation(OMCInterface::getClassInformation_res classInformation)
{
  if (mLibraryType == LibraryTreeNode::Modelica) {
    mClassInformation = classInformation;
    setFileName(classInformation.fileName);
    setReadOnly(classInformation.fileReadOnly);
  }
}

/*!
 * \brief LibraryTreeNode::setFileName
 * \param fileName
 * Sets the LibraryTreeNode file name.
 */
void LibraryTreeNode::setFileName(QString fileName)
{
  if (mLibraryType == LibraryTreeNode::Modelica) {
    /* Since now we set the fileName via loadString() & parseString() so might get filename as className/<interactive>.
     * We only set the fileName field if returned value is really a file path.
     */
    mFileName = fileName.endsWith(".mo") ? fileName : "";
    mFileName = mFileName.replace('\\', '/');
  } else {
    mFileName = fileName;
  }
}

/*!
 * \brief LibraryTreeNode::updateAttributes
 * Updates the LibraryTreeNode icon, text and tooltip.
 */
void LibraryTreeNode::updateAttributes() {
  setIcon(0, getModelicaNodeIcon());
  setText(0, mName);
  /* Do not remove the line below. It is required by LibraryBrowseDialog::useModelicaClass */
  setData(0, Qt::UserRole, mNameStructure);
  QString tooltip;
  if (mLibraryType == LibraryTreeNode::Modelica) {
    tooltip = QString("%1: %2<br />%3: %4<br />%5: %6<br />%7: %8<br />%9: %10")
        .arg(Helper::type).arg(mClassInformation.restriction)
        .arg(Helper::name).arg(mName)
        .arg(Helper::description).arg(mClassInformation.comment)
        .arg(Helper::fileLocation).arg(mFileName)
        .arg(QObject::tr("Path")).arg(mNameStructure);
  } else {
    tooltip = QString("%1: %2<br />%3: %4")
        .arg(Helper::name).arg(mName)
        .arg(Helper::fileLocation).arg(mFileName);
  }
  setToolTip(0,tooltip);
}

/*!
 * \brief LibraryTreeNode::getModelicaNodeIcon
 * \return QIcon - the LibraryTreeNode icon
 */
QIcon LibraryTreeNode::getModelicaNodeIcon()
{
  if (mLibraryType == LibraryTreeNode::Text) {
    return QIcon(":/Resources/icons/txt.svg");
  } else if (mLibraryType == LibraryTreeNode::TLM) {
    return QIcon(":/Resources/icons/tlm-icon.svg");
  } else {
    switch (getRestriction()) {
      case StringHandler::Model:
        return QIcon(":/Resources/icons/model-icon.svg");
      case StringHandler::Class:
        return QIcon(":/Resources/icons/class-icon.svg");
      case StringHandler::Connector:
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
  }
}

LibraryTreeWidget::LibraryTreeWidget(bool isSearchTree, MainWindow *pParent)
  : QTreeWidget(pParent)
{
  mpMainWindow = pParent;
  setObjectName("TreeWithBranches");
  setMinimumWidth(175);
  setItemDelegate(new ItemDelegate(this));
  setTextElideMode(Qt::ElideMiddle);
  setIsSearchedTree(isSearchTree);
  setHeaderLabel(isSearchTree ? tr("Searched Items") : Helper::libraries);
  setIndentation(Helper::treeIndentation);
  setDragEnabled(true);
  int libraryIconSize = mpMainWindow->getOptionsDialog()->getGeneralSettingsPage()->getLibraryIconSizeSpinBox()->value();
  setIconSize(QSize(libraryIconSize, libraryIconSize));
  setColumnCount(1);
  setExpandsOnDoubleClick(false);
  setContextMenuPolicy(Qt::CustomContextMenu);
  createActions();
  connect(this, SIGNAL(itemExpanded(QTreeWidgetItem*)), SLOT(expandLibraryTreeNode(QTreeWidgetItem*)));
  connect(this, SIGNAL(customContextMenuRequested(QPoint)), SLOT(showContextMenu(QPoint)));
}

LibraryTreeWidget::~LibraryTreeWidget()
{
  // delete all the loaded components
  foreach (LibraryComponent *libraryComponent, mLibraryComponentsList)
  {
    delete libraryComponent;
  }
  // delete all the items in the tree
  for (int i = 0; i < topLevelItemCount(); ++i)
  {
    qDeleteAll(topLevelItem(i)->takeChildren());
    delete topLevelItem(i);
  }
}

MainWindow* LibraryTreeWidget::getMainWindow()
{
  return mpMainWindow;
}

void LibraryTreeWidget::setIsSearchedTree(bool isSearchTree)
{
  mIsSearchTree = isSearchTree;
}

bool LibraryTreeWidget::isSearchedTree()
{
  return mIsSearchTree;
}

void LibraryTreeWidget::addToExpandedLibraryTreeNodesList(LibraryTreeNode *pLibraryTreeNode)
{
  mExpandedLibraryTreeNodesList.append(pLibraryTreeNode);
}

void LibraryTreeWidget::removeFromExpandedLibraryTreeNodesList(LibraryTreeNode *pLibraryTreeNode)
{
  mExpandedLibraryTreeNodesList.removeOne(pLibraryTreeNode);
}

void LibraryTreeWidget::createActions()
{
  // show Model Action
  mpViewClassAction = new QAction(QIcon(":/Resources/icons/modeling.png"), Helper::viewClass, this);
  mpViewClassAction->setStatusTip(Helper::viewClassTip);
  connect(mpViewClassAction, SIGNAL(triggered()), SLOT(showModelWidget()));
  // view documentation Action
  mpViewDocumentationAction = new QAction(QIcon(":/Resources/icons/info-icon.svg"), Helper::viewDocumentation, this);
  mpViewDocumentationAction->setStatusTip(Helper::viewDocumentationTip);
  connect(mpViewDocumentationAction, SIGNAL(triggered()), SLOT(viewDocumentation()));
  // new Modelica Class Action
  mpNewModelicaClassAction = new QAction(QIcon(":/Resources/icons/new.svg"), Helper::newModelicaClass, this);
  mpNewModelicaClassAction->setStatusTip(Helper::createNewModelicaClass);
  connect(mpNewModelicaClassAction, SIGNAL(triggered()), SLOT(createNewModelicaClass()));
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
  mpSimulateAction->setShortcut(QKeySequence("Ctrl+b"));
  connect(mpSimulateAction, SIGNAL(triggered()), SLOT(simulate()));
  // simulate with transformational debugger Action
  mpSimulateWithTransformationalDebuggerAction = new QAction(QIcon(":/Resources/icons/simulate-equation.svg"), Helper::simulateWithTransformationalDebugger, this);
  mpSimulateWithTransformationalDebuggerAction->setStatusTip(Helper::simulateWithTransformationalDebuggerTip);
  connect(mpSimulateWithTransformationalDebuggerAction, SIGNAL(triggered()), SLOT(simulateWithTransformationalDebugger()));
  // simulate with algorithmic debugger Action
  mpSimulateWithAlgorithmicDebuggerAction = new QAction(QIcon(":/Resources/icons/simulate-debug.svg"), Helper::simulateWithAlgorithmicDebugger, this);
  mpSimulateWithAlgorithmicDebuggerAction->setStatusTip(Helper::simulateWithAlgorithmicDebuggerTip);
  connect(mpSimulateWithAlgorithmicDebuggerAction, SIGNAL(triggered()), SLOT(simulateWithAlgorithmicDebugger()));
  // simulation setup Action
  mpSimulationSetupAction = new QAction(QIcon(":/Resources/icons/simulation-center.svg"), Helper::simulationSetup, this);
  mpSimulationSetupAction->setStatusTip(Helper::simulationSetupTip);
  connect(mpSimulationSetupAction, SIGNAL(triggered()), SLOT(simulationSetup()));
  // copy action
  /* Ticket #3265
   * Changed the name from Copy to Duplicate.
   */
  mpDuplicateClassAction = new QAction(QIcon(":/Resources/icons/duplicate.svg"), Helper::duplicate, this);
  mpDuplicateClassAction->setStatusTip(Helper::duplicateTip);
  connect(mpDuplicateClassAction, SIGNAL(triggered()), SLOT(duplicateClass()));
  // unload Action
  mpUnloadClassAction = new QAction(QIcon(":/Resources/icons/delete.svg"), Helper::unloadClass, this);
  mpUnloadClassAction->setStatusTip(Helper::unloadClassTip);
  connect(mpUnloadClassAction, SIGNAL(triggered()), SLOT(unloadClass()));
  // unload text file Action
  mpUnloadTextFileAction = new QAction(QIcon(":/Resources/icons/delete.svg"), Helper::unloadClass, this);
  mpUnloadTextFileAction->setStatusTip(Helper::unloadClassTip);
  connect(mpUnloadTextFileAction, SIGNAL(triggered()), SLOT(unloadTextFile()));
  // unload xml file Action
  mpUnloadTLMFileAction = new QAction(QIcon(":/Resources/icons/delete.svg"), Helper::unloadClass, this);
  mpUnloadTLMFileAction->setStatusTip(Helper::unloadXMLTip);
  connect(mpUnloadTLMFileAction, SIGNAL(triggered()), SLOT(unloadTLMFile()));
  // refresh Action
  mpRefreshAction = new QAction(QIcon(":/Resources/icons/refresh.svg"), Helper::refresh, this);
  mpRefreshAction->setStatusTip(tr("Refresh the Modelica class"));
  connect(mpRefreshAction, SIGNAL(triggered()), SLOT(refresh()));
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
  // fetch interface data
  mpFetchInterfaceDataAction = new QAction(QIcon(":/Resources/icons/interface-data.svg"), Helper::fetchInterfaceData, this);
  mpFetchInterfaceDataAction->setStatusTip(Helper::fetchInterfaceDataTip);
  connect(mpFetchInterfaceDataAction, SIGNAL(triggered()), SLOT(fetchInterfaceData()));
  // TLM co-simulation action
  mpTLMCoSimulationAction = new QAction(QIcon(":/Resources/icons/tlm-simulate.svg"), Helper::tlmCoSimulationSetup, this);
  mpTLMCoSimulationAction->setStatusTip(Helper::tlmCoSimulationSetupTip);
  connect(mpTLMCoSimulationAction, SIGNAL(triggered()), SLOT(TLMSimulate()));
}

//! Let the user add the OM Standard Library to library widget.
void LibraryTreeWidget::addModelicaLibraries(QSplashScreen *pSplashScreen)
{
  // load Modelica System Libraries.
  mpMainWindow->getOMCProxy()->loadSystemLibraries(pSplashScreen);
  pSplashScreen->showMessage(tr("Creating Components"), Qt::AlignRight, Qt::white);
  QStringList systemLibs = mpMainWindow->getOMCProxy()->getClassNames();
  systemLibs.prepend("OpenModelica");
  systemLibs.sort();
  foreach (QString lib, systemLibs) {
    OMCInterface::getClassInformation_res classInformation = mpMainWindow->getOMCProxy()->getClassInformation(lib);
    LibraryTreeNode *pNewLibraryTreeNode = new LibraryTreeNode(LibraryTreeNode::Modelica, lib, "", lib, classInformation, "", true, this);
    pNewLibraryTreeNode->setSystemLibrary(true);
    bool isDocumentationClass = mpMainWindow->getOMCProxy()->getDocumentationClassAnnotation(lib);
    pNewLibraryTreeNode->setIsDocumentationClass(isDocumentationClass);
    // get the Icon for Modelica tree node
    loadLibraryComponent(pNewLibraryTreeNode);
    addTopLevelItem(pNewLibraryTreeNode);
    mLibraryTreeNodesList.append(pNewLibraryTreeNode);
    createLibraryTreeNodes(pNewLibraryTreeNode);
  }
  // load Modelica User Libraries.
  mpMainWindow->getOMCProxy()->loadUserLibraries(pSplashScreen);
  QStringList userLibs = mpMainWindow->getOMCProxy()->getClassNames();
  foreach (QString lib, userLibs) {
    if (systemLibs.contains(lib)) {
      continue;
    }
    OMCInterface::getClassInformation_res classInformation = mpMainWindow->getOMCProxy()->getClassInformation(lib);
    LibraryTreeNode *pNewLibraryTreeNode = new LibraryTreeNode(LibraryTreeNode::Modelica, lib, "", lib, classInformation, "", true, this);
    bool isDocumentationClass = mpMainWindow->getOMCProxy()->getDocumentationClassAnnotation(lib);
    pNewLibraryTreeNode->setIsDocumentationClass(isDocumentationClass);
    // get the Icon for Modelica tree node
    loadLibraryComponent(pNewLibraryTreeNode);
    addTopLevelItem(pNewLibraryTreeNode);
    mLibraryTreeNodesList.append(pNewLibraryTreeNode);
    createLibraryTreeNodes(pNewLibraryTreeNode);
  }
}

void LibraryTreeWidget::createLibraryTreeNodes(LibraryTreeNode *pLibraryTreeNode)
{
  QStringList libs = mpMainWindow->getOMCProxy()->getClassNames(pLibraryTreeNode->getNameStructure(), true);
  if (!libs.isEmpty()) {
    libs.removeFirst();
  }
  QList<LibraryTreeNode*> nodes;
  foreach (QString lib, libs) {
    /* $Code is a special OpenModelica keyword. No API command will work if we use it. */
    if (lib.contains("$Code")) {
      continue;
    }
    QString name = StringHandler::getLastWordAfterDot(lib);
    QString parentName = StringHandler::removeLastWordAfterDot(lib);
    OMCInterface::getClassInformation_res classInformation = mpMainWindow->getOMCProxy()->getClassInformation(lib);
    LibraryTreeNode *pNewLibraryTreeNode = new LibraryTreeNode(LibraryTreeNode::Modelica, name, parentName, lib, classInformation, "",
                                                               pLibraryTreeNode->isSaved(), this);
    pNewLibraryTreeNode->setSystemLibrary(pLibraryTreeNode->isSystemLibrary());
    LibraryTreeNode *pParentLibraryTreeNode = getLibraryTreeNode(parentName);
    if (pParentLibraryTreeNode->isDocumentationClass()) {
      pNewLibraryTreeNode->setIsDocumentationClass(true);
    } else {
      bool isDocumentationClass = mpMainWindow->getOMCProxy()->getDocumentationClassAnnotation(lib);
      pNewLibraryTreeNode->setIsDocumentationClass(isDocumentationClass);
    }
    nodes.append(pNewLibraryTreeNode);
    mLibraryTreeNodesList.append(pNewLibraryTreeNode);
  }
  addLibraryTreeNodes(nodes);
}

void LibraryTreeWidget::expandLibraryTreeNode(LibraryTreeNode *pLibraryTreeNode)
{
  // set the range for progress bar.
  int progressValue = 0;
  mpMainWindow->getProgressBar()->setRange(0, pLibraryTreeNode->childCount());
  mpMainWindow->showProgressBar();
  for (int i = 0 ; i < pLibraryTreeNode->childCount() ; i++) {
    loadLibraryTreeNode(pLibraryTreeNode, dynamic_cast<LibraryTreeNode*>(pLibraryTreeNode->child(i)));
    mpMainWindow->getProgressBar()->setValue(++progressValue);
  }
  mpMainWindow->hideProgressBar();
}

void LibraryTreeWidget::loadLibraryTreeNode(LibraryTreeNode *pParentLibraryTreeNode, LibraryTreeNode *pLibraryTreeNode)
{
  QString className = pLibraryTreeNode->getNameStructure();
  QString parentName = pParentLibraryTreeNode->getNameStructure();
  QString name = pLibraryTreeNode->getName();
  mpMainWindow->getStatusBar()->showMessage(QString(Helper::loading).append(": ").append(className));
  pLibraryTreeNode->setClassInformation(mpMainWindow->getOMCProxy()->getClassInformation(className));
  pLibraryTreeNode->setIsSaved(pParentLibraryTreeNode->isSaved());
  pLibraryTreeNode->setIsProtected(mpMainWindow->getOMCProxy()->isProtectedClass(parentName, name));
  // update LibraryTreeNode attributes
  pLibraryTreeNode->updateAttributes();
  if (pLibraryTreeNode->isProtected()) {
    pLibraryTreeNode->setHidden(!getMainWindow()->getOptionsDialog()->getGeneralSettingsPage()->getShowProtectedClasses());
  }
  // load the library icon
  loadLibraryComponent(pLibraryTreeNode);
}

void LibraryTreeWidget::addLibraryTreeNodes(QList<LibraryTreeNode *> libraryTreeNodes)
{
  foreach (LibraryTreeNode *pLibraryTreeNode, libraryTreeNodes)
  {
    if (pLibraryTreeNode->getParentName().isEmpty())
    {
      addTopLevelItem(pLibraryTreeNode);
    }
    else
    {
      QString parentName = StringHandler::removeLastWordAfterDot(pLibraryTreeNode->getNameStructure());
      for (int i = 0 ; i < mLibraryTreeNodesList.size() ; i++)
      {
        if (mLibraryTreeNodesList[i]->getNameStructure().compare(parentName) == 0)
        {
          mLibraryTreeNodesList[i]->addChild(pLibraryTreeNode);
          break;
        }
      }
    }
  }
}

bool LibraryTreeWidget::isLibraryTreeNodeExpanded(QTreeWidgetItem *item)
{
  foreach (LibraryTreeNode *pLibraryTreeNode, mExpandedLibraryTreeNodesList)
  {
    LibraryTreeNode *pItem = dynamic_cast<LibraryTreeNode*>(item);
    if (pLibraryTreeNode == pItem)
      return true;
  }
  return false;
}

bool LibraryTreeWidget::sortNodesAscending(const LibraryTreeNode *node1, const LibraryTreeNode *node2)
{
  return node1->getName().toLower() < node2->getName().toLower();
}

LibraryTreeNode* LibraryTreeWidget::addLibraryTreeNode(QString name, QString parentName, bool isSaved, int insertIndex)
{
  LibraryTreeNode *pNewLibraryTreeNode;
  QString className = parentName.isEmpty() ? name : QString(parentName).append(".").append(name);
  mpMainWindow->getStatusBar()->showMessage(QString(Helper::loading).append(": ").append(className));
  OMCInterface::getClassInformation_res classInformation = mpMainWindow->getOMCProxy()->getClassInformation(className);
  pNewLibraryTreeNode = new LibraryTreeNode(LibraryTreeNode::Modelica, name, parentName, className, classInformation, "", isSaved, this);
  if (parentName.isEmpty()) {
    if (insertIndex == 0) {
      addTopLevelItem(pNewLibraryTreeNode);
    } else {
      insertTopLevelItem(insertIndex, pNewLibraryTreeNode);
    }
    bool isDocumentationClass = mpMainWindow->getOMCProxy()->getDocumentationClassAnnotation(className);
    pNewLibraryTreeNode->setIsDocumentationClass(isDocumentationClass);
  } else {
    LibraryTreeNode *pLibraryTreeNode = getLibraryTreeNode(parentName);
    if (insertIndex == 0) {
      pLibraryTreeNode->addChild(pNewLibraryTreeNode);
    } else {
      pLibraryTreeNode->insertChild(insertIndex, pNewLibraryTreeNode);
    }
    if (pLibraryTreeNode->isDocumentationClass()) {
      pNewLibraryTreeNode->setIsDocumentationClass(true);
    } else {
      bool isDocumentationClass = mpMainWindow->getOMCProxy()->getDocumentationClassAnnotation(className);
      pNewLibraryTreeNode->setIsDocumentationClass(isDocumentationClass);
    }
  }
  // load the models icon
  loadLibraryComponent(pNewLibraryTreeNode);
  mLibraryTreeNodesList.append(pNewLibraryTreeNode);
  mpMainWindow->getStatusBar()->clearMessage();
  return pNewLibraryTreeNode;
}

/*!
 * \brief LibraryTreeWidget::addLibraryTreeNode
 * Adds the LibraryTreeNode to the Libraries Browser.
 * \param type
 * \param name
 * \param isSaved
 * \param insertIndex
 * \return
 */
LibraryTreeNode* LibraryTreeWidget::addLibraryTreeNode(LibraryTreeNode::LibraryType type, QString name, bool isSaved, int insertIndex)
{
  LibraryTreeNode *pLibraryTreeNode = getLibraryTreeNode(name);
  if (pLibraryTreeNode) {
    mpMainWindow->getMessagesWidget()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                                 QString(GUIMessages::getMessage(GUIMessages::REDEFINING_EXISTING_CLASSES))
                                                                 .arg(name), Helper::scriptingKind, Helper::errorLevel));
    return 0;
  }
  mpMainWindow->getStatusBar()->showMessage(QString(Helper::loading).append(": ").append(name));
  OMCInterface::getClassInformation_res classInformation;
  LibraryTreeNode *pNewLibraryTreeNode = new LibraryTreeNode(type, name, "", name, classInformation, "", isSaved, this);
  pNewLibraryTreeNode->setIsDocumentationClass(false);
  if (insertIndex == 0) {
    addTopLevelItem(pNewLibraryTreeNode);
  } else {
    insertTopLevelItem(insertIndex, pNewLibraryTreeNode);
  }
  mLibraryTreeNodesList.append(pNewLibraryTreeNode);
  mpMainWindow->getStatusBar()->clearMessage();
  return pNewLibraryTreeNode;
}

/*!
 * \brief LibraryTreeWidget::getLibraryTreeNode
 * Search the LibraryTreeNode using the qualified path.
 * \param nameStructure
 * \param caseSensitivity
 * \return
 */
LibraryTreeNode* LibraryTreeWidget::getLibraryTreeNode(QString nameStructure, Qt::CaseSensitivity caseSensitivity)
{
  /* In order to make the search a bit quicker we search in toplevel items first.
   * If no item is found then we search inside the items.
   */
  LibraryTreeNode *pLibraryTreeNode;
  for (int i = 0 ; i < topLevelItemCount(); i++) {
    pLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(topLevelItem(i));
    if (pLibraryTreeNode->getNameStructure().compare(nameStructure, caseSensitivity) == 0) {
      return pLibraryTreeNode;
    }
  }
  // search all items
  for (int i = 0 ; i < mLibraryTreeNodesList.size() ; i++) {
    if (mLibraryTreeNodesList[i]->getNameStructure().compare(nameStructure, caseSensitivity) == 0) {
      return mLibraryTreeNodesList[i];
    }
  }
  return 0;
}

QList<LibraryTreeNode*> LibraryTreeWidget::getLibraryTreeNodesList()
{
  return mLibraryTreeNodesList;
}

void LibraryTreeWidget::addLibraryComponentObject(LibraryComponent *libraryComponent)
{
  mLibraryComponentsList.append(libraryComponent);
}

Component* LibraryTreeWidget::getComponentObject(QString className)
{
  foreach (LibraryComponent *pLibraryComponent, mLibraryComponentsList) {
    if (pLibraryComponent->mClassName == className) {
      return pLibraryComponent->mpComponent;
    }
  }
  return 0;
}

LibraryComponent* LibraryTreeWidget::getLibraryComponentObject(QString className)
{
  foreach (LibraryComponent *pLibraryComponent, mLibraryComponentsList) {
    if (pLibraryComponent->mClassName == className) {
      return pLibraryComponent;
    }
  }
  return 0;
}

bool LibraryTreeWidget::isFileWritAble(QString filePath)
{
  QFile file(filePath);
  if (file.exists()) {
    return file.permissions().testFlag(QFile::WriteUser);
  } else {
    return true;
  }
}

void LibraryTreeWidget::showProtectedClasses(bool enable)
{
  for (int i = 0 ; i < mLibraryTreeNodesList.size() ; i++)
  {
    if (mLibraryTreeNodesList[i]->isProtected())
      mLibraryTreeNodesList[i]->setHidden(!enable);
  }
}

/*!
 * \brief LibraryTreeWidget::unloadClass
 * Helper function for unloading/deleting the Modelica class.
 * \param pLibraryTreeNode
 * \param askQuestion
 * \return
 */
bool LibraryTreeWidget::unloadClass(LibraryTreeNode *pLibraryTreeNode, bool askQuestion)
{
  if (askQuestion) {
    QMessageBox *pMessageBox = new QMessageBox(mpMainWindow);
    pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::question));
    pMessageBox->setIcon(QMessageBox::Question);
    pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
    if (pLibraryTreeNode->getParentName().isEmpty()) {
      pMessageBox->setText(GUIMessages::getMessage(GUIMessages::UNLOAD_CLASS_MSG).arg(pLibraryTreeNode->getNameStructure()));
    } else {
      pMessageBox->setText(GUIMessages::getMessage(GUIMessages::DELETE_CLASS_MSG).arg(pLibraryTreeNode->getNameStructure()));
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
  /*
    Delete the class in OMC.
    If deleteClass is successfull remove the class from Library Browser and delete the corresponding ModelWidget.
    */
  if (mpMainWindow->getOMCProxy()->deleteClass(pLibraryTreeNode->getNameStructure())) {
    /* remove the child nodes first */
    unloadClassHelper(pLibraryTreeNode);
    mpMainWindow->getOMCProxy()->removeCachedOMCCommand(pLibraryTreeNode->getNameStructure());
    unloadLibraryTreeNodeAndModelWidget(pLibraryTreeNode);
    return true;
  } else {
    QMessageBox::critical(mpMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED).arg(mpMainWindow->getOMCProxy()->getResult())
                          .append(tr("while deleting ") + pLibraryTreeNode->getNameStructure()), Helper::ok);
    return false;
  }
}

bool LibraryTreeWidget::unloadTextFile(LibraryTreeNode *pLibraryTreeNode, bool askQuestion)
{
  if (askQuestion)
  {
    QMessageBox *pMessageBox = new QMessageBox(mpMainWindow);
    pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::question));
    pMessageBox->setIcon(QMessageBox::Question);
    pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
    pMessageBox->setText(GUIMessages::getMessage(GUIMessages::DELETE_TEXT_FILE_MSG).arg(pLibraryTreeNode->getNameStructure()));
    pMessageBox->setStandardButtons(QMessageBox::Yes | QMessageBox::No);
    pMessageBox->setDefaultButton(QMessageBox::Yes);
    int answer = pMessageBox->exec();
    switch (answer)
    {
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
  unloadLibraryTreeNodeAndModelWidget(pLibraryTreeNode);
  return true;
}

bool LibraryTreeWidget::unloadTLMFile(LibraryTreeNode *pLibraryTreeNode, bool askQuestion)
{
  if (askQuestion)
  {
    QMessageBox *pMessageBox = new QMessageBox(mpMainWindow);
    pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::question));
    pMessageBox->setIcon(QMessageBox::Question);
    pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
    pMessageBox->setText(GUIMessages::getMessage(GUIMessages::DELETE_TEXT_FILE_MSG).arg(pLibraryTreeNode->getNameStructure()));
    pMessageBox->setStandardButtons(QMessageBox::Yes | QMessageBox::No);
    pMessageBox->setDefaultButton(QMessageBox::Yes);
    int answer = pMessageBox->exec();
    switch (answer)
    {
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
  unloadLibraryTreeNodeAndModelWidget(pLibraryTreeNode);
  return true;
}

void LibraryTreeWidget::unloadClassHelper(LibraryTreeNode *pLibraryTreeNode)
{
  for (int i = 0 ; i < pLibraryTreeNode->childCount(); i++)
  {
    LibraryTreeNode *pChildLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(pLibraryTreeNode->child(i));
    /* remove the ModelWidget of LibraryTreeNode and remove the QMdiSubWindow from MdiArea and delete it. */
    if (pChildLibraryTreeNode->getModelWidget())
    {
      QMdiSubWindow *pMdiSubWindow = mpMainWindow->getModelWidgetContainer()->getMdiSubWindow(pChildLibraryTreeNode->getModelWidget());
      if (pMdiSubWindow)
      {
        pMdiSubWindow->close();
        pMdiSubWindow->deleteLater();
      }
      pChildLibraryTreeNode->getModelWidget()->deleteLater();
    }
    mpMainWindow->getOMCProxy()->removeCachedOMCCommand(pChildLibraryTreeNode->getNameStructure());
    mLibraryTreeNodesList.removeOne(pChildLibraryTreeNode);
    mExpandedLibraryTreeNodesList.removeOne(pChildLibraryTreeNode);
    LibraryComponent *pLibraryComponent = getLibraryComponentObject(pChildLibraryTreeNode->getNameStructure());
    if (pLibraryComponent) {
      mLibraryComponentsList.removeOne(pLibraryComponent);
    }
    unloadClassHelper(pChildLibraryTreeNode);
  }
}

bool LibraryTreeWidget::saveLibraryTreeNode(LibraryTreeNode *pLibraryTreeNode)
{
  bool result = false;
  mpMainWindow->getStatusBar()->showMessage(tr("Saving %1").arg(pLibraryTreeNode->getNameStructure()));
  mpMainWindow->showProgressBar();
  if (pLibraryTreeNode->getLibraryType() == LibraryTreeNode::Modelica) {
    result = saveModelicaLibraryTreeNode(pLibraryTreeNode);
  } else if (pLibraryTreeNode->getLibraryType() == LibraryTreeNode::TLM) {
    result = saveTLMLibraryTreeNode(pLibraryTreeNode);
  } else if (pLibraryTreeNode->getLibraryType() == LibraryTreeNode::Text) {
    result = saveTextLibraryTreeNode(pLibraryTreeNode);
  } else {
    QMessageBox::information(this, Helper::applicationName + " - " + Helper::error, GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED)
                             .arg(tr("Unable to save the file, unknown library type.")), Helper::ok);
    result = false;
  }
  mpMainWindow->getStatusBar()->clearMessage();
  mpMainWindow->hideProgressBar();
  return result;
}

LibraryTreeNode* LibraryTreeWidget::findParentLibraryTreeNodeSavedInSameFile(LibraryTreeNode *pLibraryTreeNode, QFileInfo fileInfo)
{
  LibraryTreeNode *pParentLibraryTreeNode = getLibraryTreeNode(pLibraryTreeNode->getParentName());
  if (pParentLibraryTreeNode)
  {
    QFileInfo libraryTreeNodeFileInfo(pParentLibraryTreeNode->getFileName());
    if (fileInfo.absoluteFilePath().compare(libraryTreeNodeFileInfo.absoluteFilePath()) == 0)
      return findParentLibraryTreeNodeSavedInSameFile(pParentLibraryTreeNode, fileInfo);
    else
      return pLibraryTreeNode;
  }
  else
  {
    return pLibraryTreeNode;
  }
}

/*!
 * \brief LibraryTreeWidget::getUniqueLibraryTreeNodeName
 * Finds the unique name for a new LibraryTreeNode based on the name suggested.
 * \param name
 * \param number
 * \return
 */
QString LibraryTreeWidget::getUniqueLibraryTreeNodeName(QString name, int number)
{
  QString newMetaModelName = QString(name).append(QString::number(number));
  for (int i = 0; i < topLevelItemCount(); ++i) {
    LibraryTreeNode *pLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(topLevelItem(i));
    if (pLibraryTreeNode && pLibraryTreeNode->getName().compare(newMetaModelName, Qt::CaseSensitive) == 0) {
      newMetaModelName = getUniqueLibraryTreeNodeName(name, ++number);
      break;
    }
  }
  return newMetaModelName;
}

bool LibraryTreeWidget::isSimulationAllowed(LibraryTreeNode *pLibraryTreeNode)
{
  if (pLibraryTreeNode) {
    // if the class is partial then return false.
    if (pLibraryTreeNode->isPartial()) {
      return false;
    }
    switch (pLibraryTreeNode->getRestriction()) {
      case StringHandler::Model:
      case StringHandler::Class:
      case StringHandler::Block:
        return true;
      default:
        return false;
    }
  } else {
    return false;
  }
}
/*!
 * \brief Since few libraries load dependent libraries automatically. So if the dependent library is not added then add it.
 * \param libraries
 */
void LibraryTreeWidget::loadDependentLibraries(QStringList libraries)
{
  foreach (QString library, libraries) {
    LibraryTreeNode* pLoadedLibraryTreeNode = getLibraryTreeNode(library);
    if (!pLoadedLibraryTreeNode) {
      LibraryTreeNode *pLibraryTreeNode = addLibraryTreeNode(library);
      if (pLibraryTreeNode) {
        pLibraryTreeNode->setSystemLibrary(true);
        /* since LibraryTreeWidget::addLibraryTreeNode clears the status bar message, so we should set it one more time. */
        mpMainWindow->getStatusBar()->showMessage(tr("Parsing").append(": ").append(library));
        // create library tree nodes
        createLibraryTreeNodes(pLibraryTreeNode);
      }
    }
  }
}

/*!
 * \brief LibraryTreeWidget::getLibraryTreeNodeFromFile
 * Search the LibraryTreeNode using the file name and line number.
 * \param fileName
 * \param lineNumber
 * \return LibraryTreeNode
 */
LibraryTreeNode* LibraryTreeWidget::getLibraryTreeNodeFromFile(QString fileName, int lineNumber)
{
  /* In order to make the search a bit quicker we search in toplevel items first.
   * If no item is found then we search inside the items.
   */
  LibraryTreeNode *pLibraryTreeNode;
  for (int i = 0 ; i < topLevelItemCount(); i++) {
    pLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(topLevelItem(i));
    if (pLibraryTreeNode && pLibraryTreeNode->getFileName().compare(fileName) == 0 && pLibraryTreeNode->inRange(lineNumber)) {
      return pLibraryTreeNode;
    }
  }
  // search all items
  for (int i = 0 ; i < mLibraryTreeNodesList.size() ; i++) {
    if (mLibraryTreeNodesList[i]->getFileName().compare(fileName) == 0 && mLibraryTreeNodesList[i]->inRange(lineNumber)) {
      return mLibraryTreeNodesList[i];
    }
  }
  return 0;
}

bool LibraryTreeWidget::saveModelicaLibraryTreeNode(LibraryTreeNode *pLibraryTreeNode)
{
  bool result = false;
  if (pLibraryTreeNode->getParentName().isEmpty() && pLibraryTreeNode->childCount() == 0) {
    /*
      A root model with no sub models.
      If it is a package then check whether save contents type. Otherwise simply save it to file.
      */
    if (pLibraryTreeNode->getRestriction() == StringHandler::Package && pLibraryTreeNode->getSaveContentsType() == LibraryTreeNode::SaveInOneFile) {
      result = saveLibraryTreeNodeOneFileHelper(pLibraryTreeNode);
    } else if (pLibraryTreeNode->getRestriction() == StringHandler::Package && pLibraryTreeNode->getSaveContentsType() == LibraryTreeNode::SaveFolderStructure) {
      result = saveLibraryTreeNodeFolderHelper(pLibraryTreeNode);
    } else {
      result = saveLibraryTreeNodeHelper(pLibraryTreeNode);
    }
    if (result) {
      getMainWindow()->addRecentFile(pLibraryTreeNode->getFileName(), Helper::utf8);
      /* We need to load the file again so that the line number information for model_info.xml is correct.
       * Update to AST (makes source info WRONG), saving it (source info STILL WRONG), reload it (and omc knows the new lines)
       * In order to get rid of it save API should update omc with new line information.
       */
      mpMainWindow->getOMCProxy()->loadFile(pLibraryTreeNode->getFileName());
    }
  } else if (pLibraryTreeNode->getParentName().isEmpty() && pLibraryTreeNode->childCount() > 0) {
    /* A root model with sub models.
     * If its a new model then its fileName is <interactive> then check its mSaveContentsType.
     * If mSaveContentsType is LibraryTreeNode::SaveInOneFile then we save all sub models in one file
     */
    if (pLibraryTreeNode->getFileName().isEmpty() && pLibraryTreeNode->getSaveContentsType() == LibraryTreeNode::SaveInOneFile) {
      result = saveLibraryTreeNodeOneFileHelper(pLibraryTreeNode);
    } else if (pLibraryTreeNode->getFileName().isEmpty() && pLibraryTreeNode->getSaveContentsType() == LibraryTreeNode::SaveFolderStructure) {
      /* A root model with sub models.
       * If its a new model then its fileName is <interactive> then check its mSaveContentsType.
       * If mSaveContentsType is LibraryTreeNode::SaveFolderStructure then we save sub models in folder structure
       */
      result = saveLibraryTreeNodeFolderHelper(pLibraryTreeNode);
    } else {
      result = saveLibraryTreeNodeOneFileOrFolderHelper(pLibraryTreeNode);
    }
    if (result) {
      getMainWindow()->addRecentFile(pLibraryTreeNode->getFileName(), Helper::utf8);
      /* We need to load the file again so that the line number information for model_info.xml is correct.
       * Update to AST (makes source info WRONG), saving it (source info STILL WRONG), reload it (and omc knows the new lines)
       * In order to get rid of it save API should update omc with new line information.
       */
      mpMainWindow->getOMCProxy()->loadFile(pLibraryTreeNode->getFileName());
    }
  } else if (!pLibraryTreeNode->getParentName().isEmpty()) {
    /* A sub model contained inside some other model.
     * Find its root model.
     * If the root model fileName is <interactive> then check its mSaveContentsType.
     * If mSaveContentsType is LibraryTreeNode::SaveInOneFile then we save all sub models in one file.
     */
    pLibraryTreeNode = getLibraryTreeNode(StringHandler::getFirstWordBeforeDot(pLibraryTreeNode->getNameStructure()));
    if (pLibraryTreeNode->getFileName().isEmpty() && pLibraryTreeNode->getSaveContentsType() == LibraryTreeNode::SaveInOneFile) {
      result = saveLibraryTreeNodeOneFileHelper(pLibraryTreeNode);
    }
    /* If mSaveContentsType is LibraryTreeNode::SaveFolderStructure then we save sub models in folder structure
     */
    else if (pLibraryTreeNode->getFileName().isEmpty() && pLibraryTreeNode->getSaveContentsType() == LibraryTreeNode::SaveFolderStructure) {
      result = saveLibraryTreeNodeFolderHelper(pLibraryTreeNode);
    } else {
      result = saveLibraryTreeNodeOneFileOrFolderHelper(pLibraryTreeNode);
    }
    if (result) {
      getMainWindow()->addRecentFile(pLibraryTreeNode->getFileName(), Helper::utf8);
      /* We need to load the file again so that the line number information for model_info.xml is correct.
       * Update to AST (makes source info WRONG), saving it (source info STILL WRONG), reload it (and omc knows the new lines)
       * In order to get rid of it save API should update omc with new line information.
       */
      mpMainWindow->getOMCProxy()->loadFile(pLibraryTreeNode->getFileName());
    }
  }
  return result;
}

bool LibraryTreeWidget::saveTextLibraryTreeNode(LibraryTreeNode *pLibraryTreeNode)
{
  QString fileName;
  if (pLibraryTreeNode->getFileName().isEmpty()) {
    QString name = pLibraryTreeNode->getName();
    fileName = StringHandler::getSaveFileName(this, QString(Helper::applicationName).append(" - ").append(tr("Save File")), NULL,
                                              Helper::txtFileTypes, NULL, "txt", &name);
    if (fileName.isEmpty()) { // if user press ESC
      return false;
    }
  } else {
    fileName = pLibraryTreeNode->getFileName();
  }

  QFile file(fileName);
  if (file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
    QTextStream textStream(&file);
    textStream.setCodec(Helper::utf8.toStdString().data());
    textStream.setGenerateByteOrderMark(false);
    textStream << pLibraryTreeNode->getModelWidget()->getEditor()->getPlainTextEdit()->toPlainText();
    file.close();
    /* mark the file as saved and update the labels. */
    pLibraryTreeNode->setIsSaved(true);
    pLibraryTreeNode->setFileName(fileName);
    if (pLibraryTreeNode->getModelWidget()) {
      pLibraryTreeNode->getModelWidget()->setWindowTitle(pLibraryTreeNode->getNameStructure());
      pLibraryTreeNode->getModelWidget()->setModelFilePathLabel(fileName);
    }
  } else {
    QMessageBox::information(this, Helper::applicationName + " - " + Helper::error, GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED)
                             .arg(GUIMessages::getMessage(GUIMessages::UNABLE_TO_SAVE_FILE).arg(file.errorString())), Helper::ok);
    return false;
  }
  return true;
}

bool LibraryTreeWidget::saveTLMLibraryTreeNode(LibraryTreeNode *pLibraryTreeNode)
{
  QString fileName;
  if (pLibraryTreeNode->getFileName().isEmpty()) {
    QString name = pLibraryTreeNode->getName();
    fileName = StringHandler::getSaveFileName(this, QString(Helper::applicationName).append(" - ").append(tr("Save File")), NULL,
                                              Helper::xmlFileTypes, NULL, "xml", &name);
    if (fileName.isEmpty())   // if user press ESC
      return false;
  } else {
    fileName = pLibraryTreeNode->getFileName();
  }

  QFile file(fileName);
  if (file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
    QTextStream textStream(&file);
    textStream.setCodec(Helper::utf8.toStdString().data());
    textStream.setGenerateByteOrderMark(false);
    textStream << pLibraryTreeNode->getModelWidget()->getEditor()->getPlainTextEdit()->toPlainText();
    file.close();
    /* mark the file as saved and update the labels. */
    pLibraryTreeNode->setIsSaved(true);
    pLibraryTreeNode->setFileName(fileName);
    if (pLibraryTreeNode->getModelWidget()) {
      pLibraryTreeNode->getModelWidget()->setWindowTitle(pLibraryTreeNode->getNameStructure());
      pLibraryTreeNode->getModelWidget()->setModelFilePathLabel(fileName);
    }
    // Create folders for the submodels and copy there source file in them.
    TLMEditor *pTLMEditor = dynamic_cast<TLMEditor*>(pLibraryTreeNode->getModelWidget()->getEditor());
    GraphicsView *pGraphicsView = pLibraryTreeNode->getModelWidget()->getDiagramGraphicsView();
    QDomNodeList subModels = pTLMEditor->getSubModels();
    for (int i = 0; i < subModels.size(); i++) {
      QDomElement subModel = subModels.at(i).toElement();
      QString directoryName = subModel.attribute("Name");
      Component *pComponent = pGraphicsView->getComponentObject(directoryName);
      if (pComponent) {
        // create directory for submodel
        QFileInfo fileInfo(fileName);
        QString directoryPath = fileInfo.absoluteDir().absolutePath() + "/" + directoryName;
        if (!QDir().exists(directoryPath)) {
          QDir().mkpath(directoryPath);
        }
        // copy the submodel file to the created directory
        QString modelFile = pComponent->getFileName();
        QFileInfo modelFileInfo(modelFile);
        QString newFileName = directoryPath + "/" + modelFileInfo.fileName();
        if (modelFileInfo.absoluteFilePath().compare(newFileName) != 0) {
          // first try to remove the file because QFile::copy will not override the file.
          QFile::remove(newFileName);
        }
        QFile::copy(modelFileInfo.absoluteFilePath(), newFileName);
      }
    }
  } else {
    QMessageBox::information(this, Helper::applicationName + " - " + Helper::error, GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED)
                             .arg(GUIMessages::getMessage(GUIMessages::UNABLE_TO_SAVE_FILE).arg(file.errorString())), Helper::ok);
    return false;
  }
  getMainWindow()->addRecentFile(pLibraryTreeNode->getFileName(), Helper::utf8);
  return true;
}

bool LibraryTreeWidget::saveLibraryTreeNodeHelper(LibraryTreeNode *pLibraryTreeNode)
{
  mpMainWindow->getStatusBar()->showMessage(QString(tr("Saving")).append(" ").append(pLibraryTreeNode->getNameStructure()));
  QString fileName;
  if (pLibraryTreeNode->getFileName().isEmpty()) {
    QString name = pLibraryTreeNode->getName();
    fileName = StringHandler::getSaveFileName(this, QString(Helper::applicationName).append(" - ").append(tr("Save File")), NULL,
                                              Helper::omFileTypes, NULL, "mo", &name);
    if (fileName.isEmpty()) { // if user press ESC
      return false;
    }
  } else {
    fileName = pLibraryTreeNode->getFileName();
  }
  /* if user has done some changes in the Modelica text view then save & validate it in the AST before saving it to file. */
  if (pLibraryTreeNode->getModelWidget()) {
    ModelicaTextEditor *pModelicaTextEditor = dynamic_cast<ModelicaTextEditor*>(pLibraryTreeNode->getModelWidget()->getEditor());
    if (pModelicaTextEditor && !pModelicaTextEditor->validateModelicaText()) {
      return false;
    }
  }
  mpMainWindow->getOMCProxy()->setSourceFile(pLibraryTreeNode->getNameStructure(), fileName);
  // save the model through OMC
  if (mpMainWindow->getOMCProxy()->save(pLibraryTreeNode->getNameStructure())) {
    pLibraryTreeNode->setIsSaved(true);
    pLibraryTreeNode->setFileName(fileName);
    if (pLibraryTreeNode->getModelWidget()) {
      pLibraryTreeNode->getModelWidget()->setWindowTitle(pLibraryTreeNode->getNameStructure());
      pLibraryTreeNode->getModelWidget()->setModelFilePathLabel(fileName);
    }
    return true;
  }
  return false;
}

bool LibraryTreeWidget::saveLibraryTreeNodeOneFileHelper(LibraryTreeNode *pLibraryTreeNode)
{
  mpMainWindow->getStatusBar()->showMessage(QString(tr("Saving")).append(" ").append(pLibraryTreeNode->getNameStructure()));
  QString fileName;
  if (pLibraryTreeNode->getFileName().isEmpty()) {
    QString name = pLibraryTreeNode->getName();
    fileName = StringHandler::getSaveFileName(this, QString(Helper::applicationName).append(" - ").append(tr("Save File")), NULL,
                                              Helper::omFileTypes, NULL, "mo", &name);
    if (fileName.isEmpty()) { // if user press ESC
      return false;
    }
  } else {
    fileName = pLibraryTreeNode->getFileName();
  }
  // set the fileName for the model.
  mpMainWindow->getOMCProxy()->setSourceFile(pLibraryTreeNode->getNameStructure(), fileName);
  // set the fileName for the sub models
  if (!setSubModelsFileNameOneFileHelper(pLibraryTreeNode, fileName)) {
    return false;
  }
  // save the model through OMC
  if (mpMainWindow->getOMCProxy()->save(pLibraryTreeNode->getNameStructure())) {
    pLibraryTreeNode->setIsSaved(true);
    pLibraryTreeNode->setFileName(fileName);
    if (pLibraryTreeNode->getModelWidget()) {
      pLibraryTreeNode->getModelWidget()->setWindowTitle(pLibraryTreeNode->getNameStructure());
      pLibraryTreeNode->getModelWidget()->setModelFilePathLabel(fileName);
    }
    setSubModelsSavedOneFileHelper(pLibraryTreeNode);
    return true;
  } else {
    mpMainWindow->getOMCProxy()->printMessagesStringInternal();
    return false;
  }
}

bool LibraryTreeWidget::setSubModelsFileNameOneFileHelper(LibraryTreeNode *pLibraryTreeNode, QString filePath)
{
  /* if user has done some changes in the Modelica text view then save & validate it in the AST before saving it to file. */
  if (pLibraryTreeNode->getModelWidget()) {
    ModelicaTextEditor *pModelicaTextEditor = dynamic_cast<ModelicaTextEditor*>(pLibraryTreeNode->getModelWidget()->getEditor());
    if (pModelicaTextEditor && !pModelicaTextEditor->validateModelicaText()) {
      return false;
    }
  }
  for (int i = 0 ; i < pLibraryTreeNode->childCount(); i++) {
    LibraryTreeNode *pChildLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(pLibraryTreeNode->child(i));
    if (pChildLibraryTreeNode->childCount() > 0) {
      if (!setSubModelsFileNameOneFileHelper(pChildLibraryTreeNode, filePath))
        return false;
    } else {
      /* if user has done some changes in the Modelica text view then save & validate it in the AST before saving it to file. */
      if (pChildLibraryTreeNode->getModelWidget()) {
        ModelicaTextEditor *pModelicaTextEditor = dynamic_cast<ModelicaTextEditor*>(pChildLibraryTreeNode->getModelWidget()->getEditor());
        if (pModelicaTextEditor && !pModelicaTextEditor->validateModelicaText()) {
          return false;
        }
      }
    }
    mpMainWindow->getStatusBar()->showMessage(QString(tr("Saving")).append(" ").append(pChildLibraryTreeNode->getNameStructure()));
    mpMainWindow->getOMCProxy()->setSourceFile(pChildLibraryTreeNode->getNameStructure(), filePath);
    pChildLibraryTreeNode->setFileName(filePath);
  }
  return true;
}

void LibraryTreeWidget::setSubModelsSavedOneFileHelper(LibraryTreeNode *pLibraryTreeNode)
{
  for (int i = 0 ; i < pLibraryTreeNode->childCount(); i++) {
    LibraryTreeNode *pChildLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(pLibraryTreeNode->child(i));
    if (pChildLibraryTreeNode->childCount() > 0) {
      setSubModelsSavedOneFileHelper(pChildLibraryTreeNode);
    }
    pChildLibraryTreeNode->setIsSaved(true);
    if (pChildLibraryTreeNode->getModelWidget()) {
      pChildLibraryTreeNode->getModelWidget()->setWindowTitle(pChildLibraryTreeNode->getNameStructure());
      pChildLibraryTreeNode->getModelWidget()->setModelFilePathLabel(pChildLibraryTreeNode->getFileName());
    }
  }
}

bool LibraryTreeWidget::saveLibraryTreeNodeFolderHelper(LibraryTreeNode *pLibraryTreeNode)
{
  mpMainWindow->getStatusBar()->showMessage(QString(tr("Saving")).append(" ").append(pLibraryTreeNode->getNameStructure()));
  QString directoryName;
  QString fileName;
  if (pLibraryTreeNode->getFileName().isEmpty()) {
    directoryName = StringHandler::getExistingDirectory(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseDirectory), NULL);
    if (directoryName.isEmpty()) {  // if user press ESC
      return false;
    }
    directoryName = directoryName.replace("\\", "/");
    // set the fileName for the model.
    fileName = QString(directoryName).append("/package.mo");
  } else {
    fileName = pLibraryTreeNode->getFileName();
    QFileInfo fileInfo(fileName);
    directoryName = fileInfo.absoluteDir().absolutePath();
  }
  /* if user has done some changes in the Modelica text view then save & validate it in the AST before saving it to file. */
  if (pLibraryTreeNode->getModelWidget()) {
    ModelicaTextEditor *pModelicaTextEditor = dynamic_cast<ModelicaTextEditor*>(pLibraryTreeNode->getModelWidget()->getEditor());
    if (pModelicaTextEditor && !pModelicaTextEditor->validateModelicaText()) {
      return false;
    }
  }
  mpMainWindow->getOMCProxy()->setSourceFile(pLibraryTreeNode->getNameStructure(), fileName);
  // save the model through OMC
  if (mpMainWindow->getOMCProxy()->save(pLibraryTreeNode->getNameStructure())) {
    pLibraryTreeNode->setIsSaved(true);
    pLibraryTreeNode->setFileName(fileName);
    if (pLibraryTreeNode->getModelWidget()) {
      pLibraryTreeNode->getModelWidget()->setWindowTitle(pLibraryTreeNode->getNameStructure());
      pLibraryTreeNode->getModelWidget()->setModelFilePathLabel(fileName);
    }
    if (!saveSubModelsFolderHelper(pLibraryTreeNode, directoryName)) {
      return false;
    }
    return true;
  } else {
    mpMainWindow->getOMCProxy()->printMessagesStringInternal();
    return false;
  }
}

bool LibraryTreeWidget::saveSubModelsFolderHelper(LibraryTreeNode *pLibraryTreeNode, QString directoryName)
{
  for (int i = 0 ; i < pLibraryTreeNode->childCount(); i++) {
    LibraryTreeNode *pChildLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(pLibraryTreeNode->child(i));
    /* if user has done some changes in the Modelica text view then save & validate it in the AST before saving it to file. */
    if (pChildLibraryTreeNode->getModelWidget()) {
      ModelicaTextEditor *pModelicaTextEditor = dynamic_cast<ModelicaTextEditor*>(pChildLibraryTreeNode->getModelWidget()->getEditor());
      if (pModelicaTextEditor && !pModelicaTextEditor->validateModelicaText()) {
        return false;
      }
    }
    QString directory;
    if (pChildLibraryTreeNode->getRestriction() != StringHandler::Package) {
      directory = directoryName;
      mpMainWindow->getStatusBar()->showMessage(QString(tr("Saving")).append(" ").append(pChildLibraryTreeNode->getNameStructure()));
      QString fileName = QString(directory).append("/").append(pChildLibraryTreeNode->getName()).append(".mo");
      mpMainWindow->getOMCProxy()->setSourceFile(pChildLibraryTreeNode->getNameStructure(), fileName);
      if (mpMainWindow->getOMCProxy()->save(pChildLibraryTreeNode->getNameStructure())) {
        pChildLibraryTreeNode->setIsSaved(true);
        pChildLibraryTreeNode->setFileName(fileName);
        if (pChildLibraryTreeNode->getModelWidget()) {
          pChildLibraryTreeNode->getModelWidget()->setWindowTitle(pChildLibraryTreeNode->getNameStructure());
          pChildLibraryTreeNode->getModelWidget()->setModelFilePathLabel(fileName);
        }
      } else {
        mpMainWindow->getOMCProxy()->printMessagesStringInternal();
        return false;
      }
    } else {
      directory = QString(directoryName).append("/").append(pChildLibraryTreeNode->getName());
      if (!QDir().exists(directory)) {
        QDir().mkpath(directory);
      }
      if (QDir().exists(directory)) {
        mpMainWindow->getStatusBar()->showMessage(QString(tr("Saving")).append(" ").append(pChildLibraryTreeNode->getNameStructure()));
        QString fileName = QString(directory).append("/package.mo");
        mpMainWindow->getOMCProxy()->setSourceFile(pChildLibraryTreeNode->getNameStructure(), fileName);
        if (mpMainWindow->getOMCProxy()->save(pChildLibraryTreeNode->getNameStructure())) {
          pChildLibraryTreeNode->setIsSaved(true);
          pChildLibraryTreeNode->setFileName(fileName);
          if (pChildLibraryTreeNode->getModelWidget()) {
            pChildLibraryTreeNode->getModelWidget()->setWindowTitle(pChildLibraryTreeNode->getNameStructure());
            pChildLibraryTreeNode->getModelWidget()->setModelFilePathLabel(fileName);
          }
        } else {
          mpMainWindow->getOMCProxy()->printMessagesStringInternal();
          return false;
        }
      }
    }
    if (pChildLibraryTreeNode->childCount() > 0) {
      saveSubModelsFolderHelper(pChildLibraryTreeNode, directory);
    }
  }
  return true;
}

bool LibraryTreeWidget::saveLibraryTreeNodeOneFileOrFolderHelper(LibraryTreeNode *pLibraryTreeNode)
{
  QFileInfo fileInfo(pLibraryTreeNode->getFileName());
  /* if library is folder structure */
  if (fileInfo.fileName().compare("package.mo") == 0) {
    return saveLibraryTreeNodeFolderHelper(pLibraryTreeNode);
  } else {
    return saveLibraryTreeNodeOneFileHelper(pLibraryTreeNode);
  }
}

/*!
  Deletes the LibraryTreeNode.
  Deletes the ModelWidget of LibraryTreeNode and remove the QMdiSubWindow from MdiArea and delete it.
  */
void LibraryTreeWidget::unloadLibraryTreeNodeAndModelWidget(LibraryTreeNode *pLibraryTreeNode)
{
  if (pLibraryTreeNode->getModelWidget())
  {
    QMdiSubWindow *pMdiSubWindow = mpMainWindow->getModelWidgetContainer()->getMdiSubWindow(pLibraryTreeNode->getModelWidget());
    if (pMdiSubWindow)
    {
      pMdiSubWindow->close();
      pMdiSubWindow->deleteLater();
    }
    pLibraryTreeNode->getModelWidget()->deleteLater();
  }
  /* delete the complete LibraryTreeNode */
  qDeleteAll(pLibraryTreeNode->takeChildren());
  mLibraryTreeNodesList.removeOne(pLibraryTreeNode);
  mExpandedLibraryTreeNodesList.removeOne(pLibraryTreeNode);
  LibraryComponent *pLibraryComponent = getLibraryComponentObject(pLibraryTreeNode->getNameStructure());
  if (pLibraryComponent) {
    mLibraryComponentsList.removeOne(pLibraryComponent);
  }
  /* Update the model switcher toolbar button. */
  mpMainWindow->updateModelSwitcherMenu(0);
  delete pLibraryTreeNode;
}

//! Makes a library expand.
//! @param item is the library to show.
void LibraryTreeWidget::expandLibraryTreeNode(QTreeWidgetItem *item)
{
  blockSignals(true);
  collapseItem(item);
  blockSignals(false);
  if (!isLibraryTreeNodeExpanded(item)) {
    LibraryTreeNode *pLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(item);
    addToExpandedLibraryTreeNodesList(pLibraryTreeNode);
    QApplication::setOverrideCursor(Qt::WaitCursor);
    expandLibraryTreeNode(pLibraryTreeNode);
    mpMainWindow->getStatusBar()->clearMessage();
    QApplication::restoreOverrideCursor();
  }
  blockSignals(true);
  expandItem(item);
  blockSignals(false);
}

void LibraryTreeWidget::showContextMenu(QPoint point)
{
  int adjust = 24;
  LibraryTreeNode *pLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(itemAt(point));
  if (pLibraryTreeNode) {
    QMenu menu(this);
    switch (pLibraryTreeNode->getLibraryType()) {
      case LibraryTreeNode::Modelica:
      default:
        menu.addAction(mpViewClassAction);
        menu.addAction(mpViewDocumentationAction);
        if (!(pLibraryTreeNode->isSystemLibrary() || isSearchedTree())) {
          menu.addSeparator();
          menu.addAction(mpNewModelicaClassAction);
        }
        menu.addSeparator();
        menu.addAction(mpInstantiateModelAction);
        menu.addAction(mpCheckModelAction);
        menu.addAction(mpCheckAllModelsAction);
        /*
          Ticket #3040.
          Only show the simulation actions for Modelica types on which the simulation is allowed.
          */
        if (isSimulationAllowed(pLibraryTreeNode)) {
          menu.addAction(mpSimulateAction);
          menu.addAction(mpSimulateWithTransformationalDebuggerAction);
          menu.addAction(mpSimulateWithAlgorithmicDebuggerAction);
          menu.addAction(mpSimulationSetupAction);
        }
        /* If item is OpenModelica or part of it or is search tree item then don't show the unload for it. */
        if (!((StringHandler::getFirstWordBeforeDot(pLibraryTreeNode->getNameStructure()).compare("OpenModelica") == 0)  || isSearchedTree())) {
          menu.addSeparator();
          menu.addAction(mpDuplicateClassAction);
          if (pLibraryTreeNode->getParentName().isEmpty()) {
            mpUnloadClassAction->setText(Helper::unloadClass);
            mpUnloadClassAction->setStatusTip(Helper::unloadClassTip);
          } else {
            mpUnloadClassAction->setText(Helper::deleteStr);
            mpUnloadClassAction->setStatusTip(tr("Deletes the Modelica class"));
          }
          menu.addAction(mpUnloadClassAction);
          /* Only used for development testing. */
          /*menu.addAction(mpRefreshAction);*/
        }
        menu.addSeparator();
        menu.addAction(mpExportFMUAction);
        menu.addAction(mpExportXMLAction);
        menu.addAction(mpExportFigaroAction);
        break;
      case LibraryTreeNode::Text:
        menu.addAction(mpUnloadTextFileAction);
        break;
      case LibraryTreeNode::TLM:
        menu.addAction(mpFetchInterfaceDataAction);
        menu.addAction(mpTLMCoSimulationAction);
        menu.addSeparator();
        menu.addAction(mpUnloadTLMFileAction);
        break;
    }
    point.setY(point.y() + adjust);
    menu.exec(mapToGlobal(point));
  }
}

void LibraryTreeWidget::createNewModelicaClass()
{
  QList<QTreeWidgetItem*> selectedItemsList = selectedItems();
  if (selectedItemsList.isEmpty())
    return;
  LibraryTreeNode *pLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(selectedItemsList.at(0));
  if (pLibraryTreeNode)
  {
    ModelicaClassDialog *pModelicaClassDialog = new ModelicaClassDialog(mpMainWindow);
    pModelicaClassDialog->getParentClassTextBox()->setText(pLibraryTreeNode->getNameStructure());
    pModelicaClassDialog->show();
  }
}

void LibraryTreeWidget::viewDocumentation()
{
  QList<QTreeWidgetItem*> selectedItemsList = selectedItems();
  if (selectedItemsList.isEmpty())
    return;
  LibraryTreeNode *pLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(selectedItemsList.at(0));
  if (pLibraryTreeNode)
  {
    mpMainWindow->getDocumentationWidget()->showDocumentation(pLibraryTreeNode->getNameStructure());
    mpMainWindow->getDocumentationDockWidget()->show();
  }
}

void LibraryTreeWidget::simulate()
{
  QList<QTreeWidgetItem*> selectedItemsList = selectedItems();
  if (selectedItemsList.isEmpty())
    return;
  LibraryTreeNode *pLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(selectedItemsList.at(0));
  if (pLibraryTreeNode)
    mpMainWindow->simulate(pLibraryTreeNode);
}

void LibraryTreeWidget::simulateWithTransformationalDebugger()
{
  QList<QTreeWidgetItem*> selectedItemsList = selectedItems();
  if (selectedItemsList.isEmpty())
    return;
  LibraryTreeNode *pLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(selectedItemsList.at(0));
  if (pLibraryTreeNode)
    mpMainWindow->simulateWithTransformationalDebugger(pLibraryTreeNode);
}

void LibraryTreeWidget::simulateWithAlgorithmicDebugger()
{
  QList<QTreeWidgetItem*> selectedItemsList = selectedItems();
  if (selectedItemsList.isEmpty())
    return;
  LibraryTreeNode *pLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(selectedItemsList.at(0));
  if (pLibraryTreeNode)
    mpMainWindow->simulateWithAlgorithmicDebugger(pLibraryTreeNode);
}

void LibraryTreeWidget::simulationSetup()
{
  QList<QTreeWidgetItem*> selectedItemsList = selectedItems();
  if (selectedItemsList.isEmpty())
    return;
  LibraryTreeNode *pLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(selectedItemsList.at(0));
  if (pLibraryTreeNode)
    mpMainWindow->simulationSetup(pLibraryTreeNode);
}

void LibraryTreeWidget::instantiateModel()
{
  QList<QTreeWidgetItem*> selectedItemsList = selectedItems();
  if (selectedItemsList.isEmpty())
    return;
  LibraryTreeNode *pLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(selectedItemsList.at(0));
  if (pLibraryTreeNode)
    mpMainWindow->instantiatesModel(pLibraryTreeNode);
}

void LibraryTreeWidget::checkModel()
{
  QList<QTreeWidgetItem*> selectedItemsList = selectedItems();
  if (selectedItemsList.isEmpty())
    return;
  LibraryTreeNode *pLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(selectedItemsList.at(0));
  if (pLibraryTreeNode)
    mpMainWindow->checkModel(pLibraryTreeNode);
}

void LibraryTreeWidget::checkAllModels()
{
  QList<QTreeWidgetItem*> selectedItemsList = selectedItems();
  if (selectedItemsList.isEmpty())
    return;
  LibraryTreeNode *pLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(selectedItemsList.at(0));
  if (pLibraryTreeNode)
    mpMainWindow->checkAllModels(pLibraryTreeNode);
}

/*!
 * \brief LibraryTreeWidget::duplicateClass
 * Opens the DuplicateClassDialog.
 */
void LibraryTreeWidget::duplicateClass()
{
  QList<QTreeWidgetItem*> selectedItemsList = selectedItems();
  if (selectedItemsList.isEmpty()) {
    return;
  }
  LibraryTreeNode *pLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(selectedItemsList.at(0));
  if (pLibraryTreeNode) {
    DuplicateClassDialog *pCopyClassDialog = new DuplicateClassDialog(pLibraryTreeNode, mpMainWindow);
    pCopyClassDialog->exec();
  }
}

/*!
 * \brief LibraryTreeWidget::unloadClass
 * Unloads/Deletes the Modelica class.
 */
void LibraryTreeWidget::unloadClass()
{
  QList<QTreeWidgetItem*> selectedItemsList = selectedItems();
  if (selectedItemsList.isEmpty()) {
    return;
  }
  LibraryTreeNode *pLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(selectedItemsList.at(0));
  if (pLibraryTreeNode) {
    unloadClass(pLibraryTreeNode);
  }
}

void LibraryTreeWidget::unloadTextFile()
{
  QList<QTreeWidgetItem*> selectedItemsList = selectedItems();
  if (selectedItemsList.isEmpty())
    return;
  LibraryTreeNode *pLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(selectedItemsList.at(0));
  if (pLibraryTreeNode)
    unloadTextFile(pLibraryTreeNode);
}

void LibraryTreeWidget::unloadTLMFile()
{
  QList<QTreeWidgetItem*> selectedItemsList = selectedItems();
  if (selectedItemsList.isEmpty())
    return;
  LibraryTreeNode *pLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(selectedItemsList.at(0));
  if (pLibraryTreeNode)
    unloadTLMFile(pLibraryTreeNode);
}

void LibraryTreeWidget::refresh()
{
  QList<QTreeWidgetItem*> selectedItemsList = selectedItems();
  if (selectedItemsList.isEmpty())
    return;
  LibraryTreeNode *pLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(selectedItemsList.at(0));
  if (pLibraryTreeNode)
    if (pLibraryTreeNode->getModelWidget())
      pLibraryTreeNode->getModelWidget()->refresh();
}

void LibraryTreeWidget::exportModelFMU()
{
  QList<QTreeWidgetItem*> selectedItemsList = selectedItems();
  if (selectedItemsList.isEmpty())
    return;
  LibraryTreeNode *pLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(selectedItemsList.at(0));
  if (pLibraryTreeNode)
    mpMainWindow->exportModelFMU(pLibraryTreeNode);
}

void LibraryTreeWidget::exportModelXML()
{
  QList<QTreeWidgetItem*> selectedItemsList = selectedItems();
  if (selectedItemsList.isEmpty())
    return;
  LibraryTreeNode *pLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(selectedItemsList.at(0));
  if (pLibraryTreeNode)
    mpMainWindow->exportModelXML(pLibraryTreeNode);
}

void LibraryTreeWidget::exportModelFigaro()
{
  QList<QTreeWidgetItem*> selectedItemsList = selectedItems();
  if (selectedItemsList.isEmpty())
    return;
  LibraryTreeNode *pLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(selectedItemsList.at(0));
  if (pLibraryTreeNode)
    mpMainWindow->exportModelFigaro(pLibraryTreeNode);
}

/*!
 * \brief LibraryTreeWidget::fetchInterfaceData
 * Slot activated when mpFetchInterfaceDataAction triggered signal is raised.
 * Calls the function that fetches the interface data.
 */
void LibraryTreeWidget::fetchInterfaceData()
{
  QList<QTreeWidgetItem*> selectedItemsList = selectedItems();
  if (selectedItemsList.isEmpty()) {
    return;
  }
  LibraryTreeNode *pLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(selectedItemsList.at(0));
  if (pLibraryTreeNode) {
    mpMainWindow->fetchInterfaceData(pLibraryTreeNode);
  }
}

void LibraryTreeWidget::TLMSimulate()
{
  QList<QTreeWidgetItem*> selectedItemsList = selectedItems();
  if (selectedItemsList.isEmpty()) {
    return;
  }
  LibraryTreeNode *pLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(selectedItemsList.at(0));
  if (pLibraryTreeNode) {
    mpMainWindow->TLMSimulate(pLibraryTreeNode);
  }
}

void LibraryTreeWidget::openFile(QString fileName, QString encoding, bool showProgress, bool checkFileExists)
{
  /* if the file doesn't exist then remove it from the recent files list. */
  QFileInfo fileInfo(fileName);
  if (checkFileExists) {
    if (!fileInfo.exists()) {
      QMessageBox::information(mpMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::information),
                               GUIMessages::getMessage(GUIMessages::FILE_NOT_FOUND).arg(fileName), Helper::ok);
      QSettings *pSettings = OpenModelica::getApplicationSettings();
      QList<QVariant> files = pSettings->value("recentFilesList/files").toList();
      // remove the RecentFile instance from the list.
      foreach (QVariant file, files) {
        RecentFile recentFile = qvariant_cast<RecentFile>(file);
        if (recentFile.fileName.compare(fileName) == 0) {
          files.removeOne(file);
        }
      }
      pSettings->setValue("recentFilesList/files", files);
      mpMainWindow->updateRecentFileActions();
      return;
    }
  }
  if (fileInfo.suffix().compare("mo") == 0) {
    openModelicaFile(fileName, encoding, showProgress);
  } else if (fileInfo.suffix().compare("xml") == 0) {
    openTLMFile(fileInfo, showProgress);
  } else {
    QMessageBox::information(this, Helper::applicationName + " - " + Helper::error, GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED)
                             .arg(tr("Unable to open the file, unknown file type.")), Helper::ok);
  }
}

void LibraryTreeWidget::openModelicaFile(QString fileName, QString encoding, bool showProgress)
{
  // get the class names now to check if they are already loaded or not
  QStringList existingmodelsList;
  if (showProgress) mpMainWindow->getStatusBar()->showMessage(QString(Helper::loading).append(": ").append(fileName));
  QStringList classesList = mpMainWindow->getOMCProxy()->parseFile(fileName, encoding);
  if (!classesList.isEmpty()) {
    /*
      Only allow loading of files that has just one nonstructured entity.
      From Modelica specs section 13.2.2.2,
      "A nonstructured entity [e.g. the file A.mo] shall contain only a stored-definition that defines a class [A] with a name
       matching the name of the nonstructured entity."
      */
    if (classesList.size() > 1) {
      QMessageBox *pMessageBox = new QMessageBox(mpMainWindow);
      pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::error));
      pMessageBox->setIcon(QMessageBox::Critical);
      pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
      pMessageBox->setText(QString(GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_FILE).arg(fileName)));
      pMessageBox->setInformativeText(QString(GUIMessages::getMessage(GUIMessages::MULTIPLE_TOP_LEVEL_CLASSES)).arg(fileName)
                                      .arg(classesList.join(",")));
      pMessageBox->setStandardButtons(QMessageBox::Ok);
      pMessageBox->exec();
      return;
    }
    bool existModel = false;
    // check if the model already exists
    foreach(QString model, classesList) {
      if (mpMainWindow->getOMCProxy()->existClass(model)) {
        existingmodelsList.append(model);
        existModel = true;
      }
    }
    // if existModel is true, show user an error message
    if (existModel) {
      QMessageBox *pMessageBox = new QMessageBox(mpMainWindow);
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
      if (mpMainWindow->getOMCProxy()->loadFile(fileName, encoding)) {
        // create library tree nodes for loaded models
        int progressvalue = 0;
        if (showProgress) {
          mpMainWindow->getProgressBar()->setRange(0, classesList.size());
          mpMainWindow->showProgressBar();
        }
        foreach (QString model, classesList) {
          LibraryTreeNode *pLibraryTreeNode = addLibraryTreeNode(model);
          if (pLibraryTreeNode) {
            createLibraryTreeNodes(pLibraryTreeNode);
          }
          if (showProgress) mpMainWindow->getProgressBar()->setValue(++progressvalue);
        }
        mpMainWindow->addRecentFile(fileName, encoding);
        loadDependentLibraries(mpMainWindow->getOMCProxy()->getClassNames());
        if (showProgress) mpMainWindow->hideProgressBar();
      }
    }
  }
  if (showProgress) mpMainWindow->getStatusBar()->clearMessage();
}

void LibraryTreeWidget::openTLMFile(QFileInfo fileInfo, bool showProgress)
{
  if (showProgress) mpMainWindow->getStatusBar()->showMessage(QString(Helper::loading).append(": ").append(fileInfo.absoluteFilePath()));
  // check if the file is already loaded.
  for (int i = 0; i < topLevelItemCount(); ++i) {
    LibraryTreeNode *pLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(topLevelItem(i));
    if (pLibraryTreeNode && pLibraryTreeNode->getFileName().compare(fileInfo.absoluteFilePath()) == 0) {
      QMessageBox *pMessageBox = new QMessageBox(mpMainWindow);
      pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::information));
      pMessageBox->setIcon(QMessageBox::Information);
      pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
      pMessageBox->setText(QString(GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_FILE).arg(fileInfo.absoluteFilePath())));
      pMessageBox->setInformativeText(QString(GUIMessages::getMessage(GUIMessages::REDEFINING_EXISTING_CLASSES))
                                      .arg(fileInfo.fileName()).append("\n")
                                      .append(GUIMessages::getMessage(GUIMessages::DELETE_AND_LOAD).arg(fileInfo.absoluteFilePath())));
      pMessageBox->setStandardButtons(QMessageBox::Ok);
      pMessageBox->exec();
      return;
    }
  }
  // create a LibraryTreeNode for new loaded TLM file.
  LibraryTreeNode *pLibraryTreeNode = addLibraryTreeNode(LibraryTreeNode::TLM, fileInfo.completeBaseName(), true);
  if (pLibraryTreeNode) {
    pLibraryTreeNode->setSaveContentsType(LibraryTreeNode::SaveInOneFile);
    pLibraryTreeNode->setIsSaved(true);
    pLibraryTreeNode->setFileName(fileInfo.absoluteFilePath());
    addToExpandedLibraryTreeNodesList(pLibraryTreeNode);
    mpMainWindow->addRecentFile(fileInfo.absoluteFilePath(), Helper::utf8);
  }
  if (showProgress) mpMainWindow->getStatusBar()->clearMessage();
}

void LibraryTreeWidget::parseAndLoadModelicaText(QString modelText)
{
  QStringList classNames = mpMainWindow->getOMCProxy()->parseString(modelText, "");
  if (classNames.size() == 0) {
    return;
  }
  // if user is defining multiple top level classes.
  if (classNames.size() > 1) {
    QMessageBox::critical(mpMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          QString(GUIMessages::getMessage(GUIMessages::MULTIPLE_TOP_LEVEL_CLASSES)).arg("").arg(classNames.join(",")),
                          Helper::ok);
    return;
  }
  QString className = classNames.at(0);
  bool existModel = mpMainWindow->getOMCProxy()->existClass(className);
  // check if existModel is true
  if (existModel) {
    QMessageBox *pMessageBox = new QMessageBox(mpMainWindow);
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
    if (mpMainWindow->getOMCProxy()->loadString(StringHandler::escapeString(modelText), className)) {
      QString modelName = StringHandler::getLastWordAfterDot(className);
      QString parentName = StringHandler::removeLastWordAfterDot(className);
      if (modelName.compare(parentName) == 0) {
        parentName = "";
      }
      LibraryTreeNode *pLibraryTreeNode;
      pLibraryTreeNode = addLibraryTreeNode(modelName, parentName);
      if (pLibraryTreeNode) {
        createLibraryTreeNodes(pLibraryTreeNode);
      }
    }
  }
}

void LibraryTreeWidget::showModelWidget(LibraryTreeNode *pLibraryTreeNode, bool newClass, bool extendsClass, QString text)
{
  QApplication::setOverrideCursor(Qt::WaitCursor);
  QList<QTreeWidgetItem*> selectedItemsList = selectedItems();
  if (pLibraryTreeNode == 0) {
    if (selectedItemsList.isEmpty()) {
      QApplication::restoreOverrideCursor();
      return;
    }
    pLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(selectedItemsList.at(0));
  }
  mpMainWindow->getPerspectiveTabBar()->setCurrentIndex(1);
  /* Search Tree Items never have model widget so find the equivalent Library Tree Node */
  if (isSearchedTree()) {
    pLibraryTreeNode = mpMainWindow->getLibraryTreeWidget()->getLibraryTreeNode(pLibraryTreeNode->getNameStructure());
    mpMainWindow->getLibraryTreeWidget()->showModelWidget(pLibraryTreeNode, newClass, extendsClass);
    QApplication::restoreOverrideCursor();
    return;
  }
  if (pLibraryTreeNode->getModelWidget()) {
    pLibraryTreeNode->getModelWidget()->setWindowTitle(pLibraryTreeNode->getNameStructure() + (pLibraryTreeNode->isSaved() ? "" : "*"));
    mpMainWindow->getModelWidgetContainer()->addModelWidget(pLibraryTreeNode->getModelWidget());
  } else {
    ModelWidget *pModelWidget = new ModelWidget(pLibraryTreeNode, mpMainWindow->getModelWidgetContainer(), newClass, extendsClass, text);
    pLibraryTreeNode->setModelWidget(pModelWidget);
    pLibraryTreeNode->getModelWidget()->setWindowTitle(pLibraryTreeNode->getNameStructure() + (pLibraryTreeNode->isSaved() ? "" : "*"));
    mpMainWindow->getModelWidgetContainer()->addModelWidget(pModelWidget);
  }
  QApplication::restoreOverrideCursor();
}

void LibraryTreeWidget::openLibraryTreeNode(QString nameStructure)
{
  LibraryTreeNode *pLibraryTreeNode = getLibraryTreeNode(nameStructure);
  if (!pLibraryTreeNode)
    return;
  showModelWidget(pLibraryTreeNode);
}

void LibraryTreeWidget::loadLibraryComponent(LibraryTreeNode *pLibraryTreeNode)
{
  OMCProxy *pOMCProxy = mpMainWindow->getOMCProxy();
  QString result = pOMCProxy->getIconAnnotation(pLibraryTreeNode->getNameStructure());
  LibraryComponent *pLibraryComponent = getLibraryComponentObject(pLibraryTreeNode->getNameStructure());
  if (pLibraryComponent) {
    mLibraryComponentsList.removeOne(pLibraryComponent);
  }
  pLibraryComponent = new LibraryComponent(result, pLibraryTreeNode->getNameStructure(), pOMCProxy);
  QPixmap pixmap = pLibraryComponent->getComponentPixmap(iconSize());
  // if the component does not have icon annotation check if it has non standard dymola annotation or not.
  if (pixmap.isNull()) {
    pOMCProxy->sendCommand("getNamedAnnotation(" + pLibraryTreeNode->getNameStructure() + ", __Dymola_DocumentationClass)");
    if (StringHandler::unparseBool(StringHandler::removeFirstLastCurlBrackets(pOMCProxy->getResult())) || pLibraryTreeNode->isDocumentationClass()) {
      result = pOMCProxy->getIconAnnotation("Modelica.Icons.Information");
      pLibraryComponent = new LibraryComponent(result, pLibraryTreeNode->getNameStructure(), pOMCProxy);
      pixmap = pLibraryComponent->getComponentPixmap(iconSize());
      // if still the pixmap is null for some unknown reasons then used the pre defined image
      if (pixmap.isNull()) {
        pLibraryTreeNode->setIcon(0, QIcon(":/Resources/icons/info-icon.svg"));
      }
    } else {
      // if the component does not have non standard dymola annotation as well.
      pLibraryTreeNode->setIcon(0, pLibraryTreeNode->getModelicaNodeIcon());
    }
  } else {
    pLibraryTreeNode->setIcon(0, QIcon(pixmap));
  }
  addLibraryComponentObject(pLibraryComponent);
}

void LibraryTreeWidget::mouseDoubleClickEvent(QMouseEvent *event)
{
  if (!itemAt(event->pos()))
    return;
  showModelWidget();
  QTreeWidget::mouseDoubleClickEvent(event);
}

void LibraryTreeWidget::startDrag(Qt::DropActions supportedActions)
{
  LibraryTreeNode *pLibraryTreeNode = dynamic_cast<LibraryTreeNode*>(currentItem());
  // get the component pixmap to show on drag
  LibraryComponent *pLibraryComponent = getLibraryComponentObject(pLibraryTreeNode->getNameStructure());
  if (isSearchedTree()) {
    pLibraryTreeNode = mpMainWindow->getLibraryTreeWidget()->getLibraryTreeNode(pLibraryTreeNode->getNameStructure());
  }
  QByteArray itemData;
  QDataStream dataStream(&itemData, QIODevice::WriteOnly);
  dataStream << pLibraryTreeNode->getNameStructure() << pLibraryTreeNode->getFileName();
  QMimeData *mimeData = new QMimeData;
  mimeData->setData(Helper::modelicaComponentFormat, itemData);
  qreal adjust = 35;
  QDrag *drag = new QDrag(this);
  drag->setMimeData(mimeData);
  // if we have component pixmap
  if (pLibraryComponent) {
    QPixmap pixmap = pLibraryComponent->getComponentPixmap(QSize(50, 50));
    drag->setPixmap(pixmap);
    drag->setHotSpot(QPoint((drag->hotSpot().x() + adjust), (drag->hotSpot().y() + adjust)));
  }
  drag->exec(supportedActions);
}

Qt::DropActions LibraryTreeWidget::supportedDropActions() const
{
  return Qt::CopyAction;
}

LibraryComponent::LibraryComponent(QString value, QString className, OMCProxy *omc)
{
  mClassName = className;
  mpComponent = new Component(value, className, omc);

  if (mpComponent->boundingRect().width() > 1)
    mRectangle = mpComponent->boundingRect();
  else
    mRectangle = QRectF(-100.0, -100.0, 200.0, 200.0);

  qreal adjust = 25;
  mRectangle.setX(mRectangle.x() - adjust);
  mRectangle.setY(mRectangle.y() - adjust);
  mRectangle.setWidth(mRectangle.width() + adjust);
  mRectangle.setHeight(mRectangle.height() + adjust);

  mpGraphicsView = new QGraphicsView;
  mpGraphicsView->setScene(new QGraphicsScene);
  mpGraphicsView->setSceneRect(mRectangle);
  mpGraphicsView->scene()->addItem(mpComponent);
}

LibraryComponent::~LibraryComponent()
{
  delete mpComponent;
  delete mpGraphicsView;
}

QPixmap LibraryComponent::getComponentPixmap(QSize size)
{
  // if view is empty we return null QPixmap
  mHasIconAnnotation = false;
  hasIconAnnotation(mpComponent);
  if (!mHasIconAnnotation)
    return QPixmap();

  QPixmap pixmap(size);
  pixmap.fill(QColor(Qt::transparent));
  QPainter painter(&pixmap);
  painter.setRenderHint(QPainter::Antialiasing);
  painter.setRenderHint(QPainter::TextAntialiasing);
  painter.setRenderHint(QPainter::SmoothPixmapTransform);
  painter.setWindow(mRectangle.toRect());
  painter.scale(1.0, -1.0);
  mpGraphicsView->scene()->render(&painter, mRectangle, mpGraphicsView->sceneRect());
  painter.end();
  return pixmap;
}

void LibraryComponent::hasIconAnnotation(Component *pComponent)
{
  if (!pComponent->getShapesList().isEmpty())
  {
    mHasIconAnnotation = true;
  }
  else
  {
    foreach (Component *inheritedComponent, pComponent->getInheritanceList())
    {
      hasIconAnnotation(inheritedComponent);
    }
    foreach (Component *childComponent, pComponent->getComponentsList())
    {
      hasIconAnnotation(childComponent);
    }
  }
}
