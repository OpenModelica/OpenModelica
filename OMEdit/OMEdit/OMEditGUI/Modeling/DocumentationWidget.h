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
#include <QWebView>
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
  DocumentationHistory(LibraryTreeItem *pLibraryTreeItem) {mpLibraryTreeItem = pLibraryTreeItem;}
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
  ~DocumentationWidget();
  QAction* getPreviousAction() {return mpPreviousAction;}
  QAction* getNextAction() {return mpNextAction;}
  DocumentationViewer* getDocumentationViewer() {return mpDocumentationViewer;}
  void showDocumentation(LibraryTreeItem *pLibraryTreeItem);
  void execCommand(const QString &commandName);
  void execCommand(const QString &commandName, const QString &valueArgument);
  bool queryCommandState(const QString &commandName);
  QString queryCommandValue(const QString &commandName);
private:
  QFile mDocumentationFile;
  QAction *mpPreviousAction;
  QAction *mpNextAction;
  QAction *mpEditInfoAction;
  QAction *mpEditRevisionsAction;
  QAction *mpEditInfoHeaderAction;
  QAction *mpSaveAction;
  QAction *mpCancelAction;
  DocumentationViewer *mpDocumentationViewer;
  QFrame *mpDocumentationViewerFrame;
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

  QPixmap createPixmapForToolButton(QColor color, QIcon icon);
  void updatePreviousNextButtons();
  void writeDocumentationFile(QString documentation);
  bool isLinkSelected();
  void updateDocumentationHistory(LibraryTreeItem *pLibraryTreeItem);
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
  void updateDocumentationHistory();
};

class DocumentationViewer : public QWebView
{
  Q_OBJECT
private:
  DocumentationWidget *mpDocumentationWidget;
public:
  DocumentationViewer(DocumentationWidget *pDocumentationWidget, bool isContentEditable = false);
  void setFocusInternal();
private:
  void createActions();
  void resetZoom();
public slots:
  void processLinkClick(QUrl url);
  void requestFinished();
  void processLinkHover(QString link, QString title, QString textContent);
  void showContextMenu(QPoint point);
protected:
  virtual QWebView* createWindow(QWebPage::WebWindowType type);
  virtual void keyPressEvent(QKeyEvent *event);
  virtual void wheelEvent(QWheelEvent *event);
  virtual void mouseDoubleClickEvent(QMouseEvent *event);
};

#endif // DOCUMENTATIONWIDGET_H
