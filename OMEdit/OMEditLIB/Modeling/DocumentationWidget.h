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

#ifndef DOCUMENTATIONWIDGET_H
#define DOCUMENTATIONWIDGET_H

#include <QWidget>
#include <QToolButton>
#include <QTabBar>
#include <QFile>
#ifndef OM_DISABLE_DOCUMENTATION
#ifdef OM_OMEDIT_ENABLE_QTWEBENGINE
#include <QWebEngineView>
#else // #ifdef OM_OMEDIT_ENABLE_QTWEBENGINE
#include <QWebView>
#endif // #ifdef OM_OMEDIT_ENABLE_QTWEBENGINE
#endif // #ifndef OM_DISABLE_DOCUMENTATION
#include <QToolBar>
#include <QComboBox>
#include <QFontComboBox>
#include <QSpinBox>
#include <QColorDialog>

class LibraryTreeItem;
class DocumentationHistory
{
public:
  LibraryTreeItem *mpLibraryTreeItem;
  QPoint mScrollPosition;
  DocumentationHistory(LibraryTreeItem *pLibraryTreeItem)
  {
    mpLibraryTreeItem = pLibraryTreeItem;
    mScrollPosition = QPoint(0, 0);
  }
  bool operator==(const DocumentationHistory &documentationHistory) const
  {
    return (documentationHistory.mpLibraryTreeItem == this->mpLibraryTreeItem);
  }
};

class DocumentationViewer;
class HTMLEditor;
class DocumentationWidget : public QWidget
{
  Q_OBJECT
public:
  enum EditType {
    None,
    Info,
    Revisions,
    InfoHeader
  };
  DocumentationWidget(QWidget *pParent = 0);
#ifndef OM_DISABLE_DOCUMENTATION
  ~DocumentationWidget();
  QAction* getPreviousAction() {return mpPreviousAction;}
  QAction* getNextAction() {return mpNextAction;}
  DocumentationViewer* getDocumentationViewer() {return mpDocumentationViewer;}
#endif // #ifndef OM_DISABLE_DOCUMENTATION
  void showDocumentation(LibraryTreeItem *pLibraryTreeItem);
#ifndef OM_DISABLE_DOCUMENTATION
  void execCommand(const QString &commandName);
  void execCommand(const QString &commandName, const QString &valueArgument);
  bool queryCommandState(const QString &commandName);
  QString queryCommandValue(const QString &commandName);
  void saveScrollPosition();
  bool isExecutingPreviousNextButtons() const {return mExecutingPreviousNextButtons;}
  void setExecutingPreviousNextButtons(bool executingPreviousNextButtons) {mExecutingPreviousNextButtons = executingPreviousNextButtons;}
  QPoint getScrollPosition() const {return mScrollPosition;}
  void setScrollPosition(const QPoint &scrollPosition) {mScrollPosition = scrollPosition;}
  bool isEditingDocumentation() const {return mEditType != EditType::None;}
  void updateDocumentationHistory(LibraryTreeItem *pLibraryTreeItem);
private:
  QFile mDocumentationFile;
  QAction *mpPreviousAction;
  QAction *mpNextAction;
  QAction *mpEditInfoAction;
  QAction *mpEditRevisionsAction;
  QAction *mpEditInfoHeaderAction;
  QAction *mpSaveAction;
  QAction *mpCancelAction;
#else // #ifndef OM_DISABLE_DOCUMENTATION
  bool isEditingDocumentation() const {return false;}
#endif // #ifndef OM_DISABLE_DOCUMENTATION
  DocumentationViewer *mpDocumentationViewer;
  QFrame *mpDocumentationViewerFrame;
#ifndef OM_DISABLE_DOCUMENTATION
  QWidget *mpEditorsWidget;
  QTabBar *mpTabBar;
  QWidget *mpHTMLEditorWidget;
  QToolBar *mpEditorToolBar;
  DocumentationViewer *mpHTMLEditor;
  QFrame *mpHTMLEditorFrame;
  QComboBox *mpStyleComboBox;
  QFontComboBox *mpFontComboBox;
  QSpinBox *mpFontSizeSpinBox;
  QAction *mpBoldAction;
  QAction *mpItalicAction;
  QAction *mpUnderlineAction;
  QAction *mpStrikethroughAction;
  QAction *mpSubscriptAction;
  QAction *mpSuperscriptAction;
  QColor mTextColor;
  QColorDialog *mpTextColorDialog;
  QToolButton *mpTextColorToolButton;
  QColor mBackgroundColor;
  QColorDialog *mpBackgroundColorDialog;
  QToolButton *mpBackgroundColorToolButton;
  QToolButton *mpAlignLeftToolButton;
  QToolButton *mpAlignCenterToolButton;
  QToolButton *mpAlignRightToolButton;
  QToolButton *mpJustifyToolButton;
  QAction *mpDecreaseIndentAction;
  QAction *mpIncreaseIndentAction;
  QAction *mpBulletListAction;
  QAction *mpNumberedListAction;
  QAction *mpLinkAction;
  QAction *mpUnLinkAction;
  HTMLEditor *mpHTMLSourceEditor;
  EditType mEditType;
  QList<DocumentationHistory> *mpDocumentationHistoryList;
  int mDocumentationHistoryPos;
  bool mExecutingPreviousNextButtons;
  QPoint mScrollPosition;

  QPixmap createPixmapForToolButton(QColor color, QIcon icon);
  void updatePreviousNextButtons();
  void writeDocumentationFile(QString documentation);
  bool isLinkSelected();
  bool removeDocumentationHistory(LibraryTreeItem *pLibraryTreeItem);
public slots:
  void previousDocumentation();
  void nextDocumentation();
  void editInfoDocumentation();
  void editRevisionsDocumentation();
  void editInfoHeaderDocumentation();
  void saveDocumentation(LibraryTreeItem *pNextLibraryTreeItem = 0);
  void cancelDocumentation();
  void toggleEditor(int tabIndex);
  void updateActions();
  void formatBlock(int index);
  void fontName(QFont font);
  void fontSize(int size);
  void applyTextColor();
  void applyTextColor(QColor color);
  void applyBackgroundColor();
  void applyBackgroundColor(QColor color);
  void alignLeft();
  void alignCenter();
  void alignRight();
  void justify();
  void bulletList();
  void numberedList();
  void createLink();
  void removeLink();
  void updateHTMLSourceEditor();
#endif // #ifndef OM_DISABLE_DOCUMENTATION
};

#ifndef OM_DISABLE_DOCUMENTATION
#ifdef OM_OMEDIT_ENABLE_QTWEBENGINE
class DocumentationViewer : public QWebEngineView
#else // #ifdef OM_OMEDIT_ENABLE_QTWEBENGINE
class DocumentationViewer : public QWebView
#endif // #ifdef OM_OMEDIT_ENABLE_QTWEBENGINE
#else // #ifndef OM_DISABLE_DOCUMENTATION
class DocumentationViewer : public QWidget
#endif // #ifndef OM_DISABLE_DOCUMENTATION
{
  Q_OBJECT
private:
  DocumentationWidget *mpDocumentationWidget;
public:
  DocumentationViewer(DocumentationWidget *pDocumentationWidget, bool isContentEditable = false);
#ifndef OM_DISABLE_DOCUMENTATION
  void setFocusInternal();
private:
  void createActions();
  void resetZoom();
public slots:
  void processLinkClick(QUrl url);
  void requestFinished();
  void processLinkHover(QString link);
  void processLinkHover(QString link, QString title, QString textContent);
  void showContextMenu(QPoint point);
  void pageLoaded(bool ok);
protected:
#ifdef OM_OMEDIT_ENABLE_QTWEBENGINE
  virtual QWebEngineView* createWindow(QWebEnginePage::WebWindowType type) override;
#else // #ifdef OM_OMEDIT_ENABLE_QTWEBENGINE
  virtual QWebView* createWindow(QWebPage::WebWindowType type) override;
#endif // #ifdef OM_OMEDIT_ENABLE_QTWEBENGINE
  virtual void keyPressEvent(QKeyEvent *event) override;
  virtual void wheelEvent(QWheelEvent *event) override;
  virtual void mouseDoubleClickEvent(QMouseEvent *event) override;
#endif // #ifndef OM_DISABLE_DOCUMENTATION
  bool mIsContentEditable;
};

#endif // DOCUMENTATIONWIDGET_H
