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
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#include "ItemDelegate.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Plotting/VariablesWidget.h"
#include "Simulation/SimulationOutputWidget.h"
#include "OMS/BusDialog.h"

#include <QPainter>

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
  /* ticket:5050 Use Qt::ElideRight for value column only if the value is a double in non-scientific notation.
   * If the value is in scientific notation then use Qt::ElideMiddle.
   * Other columns use Qt::ElideMiddle. */
  if (parent() && (qobject_cast<VariablesTreeView*>(parent())) && index.column() == 1) {
    bool isDouble;
    text.toDouble(&isDouble);
    if (isDouble && !(text.contains('e') || text.contains('E'))) {
      opt.textElideMode = Qt::ElideRight;
    } else {
      opt.textElideMode = Qt::ElideMiddle;
    }
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
  if (parent() && (qobject_cast<VariablesTreeView*>(parent()))) {
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
  if (parent() && qobject_cast<VariablesTreeView*>(parent())) {
    VariablesTreeView *pVariablesTreeView = qobject_cast<VariablesTreeView*>(parent());
    VariableTreeProxyModel *pVariableTreeProxyModel = pVariablesTreeView->getVariablesWidget()->getVariableTreeProxyModel();
    QModelIndex sourceIndex = pVariableTreeProxyModel->mapToSource(index);
    VariablesTreeItem *pVariablesTreeItem = static_cast<VariablesTreeItem*>(sourceIndex.internalPointer());

    if (index.column() == 1) { // value column
      QLineEdit *pValueTextBox = new QLineEdit(pParent);
      pValueTextBox->setText(index.data(Qt::DisplayRole).toString());
      QFont font = option.font;
      if (pVariablesTreeItem->isParameter()) {
        font.setItalic(true);
      }
      pValueTextBox->setFont(font);
      pValueTextBox->selectAll();
      pValueTextBox->setFocusPolicy(Qt::WheelFocus);
      return pValueTextBox;
    } else if (index.column() == 3) { // unit column
      // create the display units combobox
      QComboBox *pComboBox = new QComboBox(pParent);
      pComboBox->setEnabled(!pVariablesTreeItem->getDisplayUnits().isEmpty());
      pComboBox->addItems(pVariablesTreeItem->getDisplayUnits());
      connect(pComboBox, SIGNAL(currentIndexChanged(QString)), SLOT(unitComboBoxChanged(QString)));
      return pComboBox;
    }
  } else if (parent() && qobject_cast<ConnectorsTreeView*>(parent())) {
    if (index.column() == 1) { // TLM type column
      ConnectorsTreeView *pConnectorsTreeView = qobject_cast<ConnectorsTreeView*>(parent());
      ConnectorsModel *pConnectorsModel = qobject_cast<ConnectorsModel*>(pConnectorsTreeView->model());
      // create the TLM types combobox
      QComboBox *pComboBox = new QComboBox(pParent);
      pComboBox->addItems(pConnectorsModel->getTLMTypes());
      QStringList tlmTypesDescriptions = pConnectorsModel->getTLMTypesDescriptions();
      for (int i = 0 ; i < tlmTypesDescriptions.size() ; i++) {
        pComboBox->setItemData(i, tlmTypesDescriptions.at(i), Qt::ToolTipRole);
      }
      return pComboBox;
    }
  }
  return QItemDelegate::createEditor(pParent, option, index);
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
  } else if (parent() && qobject_cast<ConnectorsTreeView*>(parent()) && index.column() == 1) {
    ConnectorItem *pConnectorItem = static_cast<ConnectorItem*>(index.internalPointer());
    QString value = index.model()->data(index, Qt::DisplayRole).toString();
    QComboBox* comboBox = static_cast<QComboBox*>(editor);
    //set the index of the combo box
    int currentIndex = comboBox->findText(value, Qt::MatchExactly);
    // only set the description here. The actual value is set in ConnectorsModel::setData().
    pConnectorItem->setTLMTypeDescription(comboBox->itemData(currentIndex, Qt::ToolTipRole).toString());
    comboBox->setCurrentIndex(currentIndex);
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
    emit commitData(pComboBox);
    emit closeEditor(pComboBox);
  }
}
