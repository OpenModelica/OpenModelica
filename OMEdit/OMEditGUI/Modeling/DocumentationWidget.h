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

#ifndef DOCUMENTATIONWIDGET_H
#define DOCUMENTATIONWIDGET_H

#include <QWidget>
#include <QToolButton>
#include <QTabbar>
#include <QFile>
#include <QWebView>
#include <QToolBar>
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
  QToolButton* getPreviousToolButton() {return mpPreviousToolButton;}
  QToolButton* getNextToolButton() {return mpNextToolButton;}
  DocumentationViewer* getDocumentationViewer() {return mpDocumentationViewer;}
  void showDocumentation(LibraryTreeItem *pLibraryTreeItem);
private:
  QFile mDocumentationFile;
  QToolButton *mpPreviousToolButton;
  QToolButton *mpNextToolButton;
  QToolButton *mpEditInfoToolButton;
  QToolButton *mpEditRevisionsToolButton;
  QToolButton *mpEditInfoHeaderToolButton;
  QToolButton *mpSaveToolButton;
  QToolButton *mpCancelToolButton;
  DocumentationViewer *mpDocumentationViewer;
  QWidget *mpEditorsWidget;
  QTabBar *mpTabBar;
  QWidget *mpHTMLEditorWidget;
  QToolBar *mpEditorToolBar;
  DocumentationViewer *mpHTMLEditor;
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
  HTMLEditor *mpHTMLSourceEditor;
  EditType mEditType;
  QList<DocumentationHistory> *mpDocumentationHistoryList;
  int mDocumentationHistoryPos;

  QPixmap createPixmapForToolButton(QColor color, QIcon icon);
  void updatePreviousNextButtons();
  void writeDocumentationFile(QString documentation);
  void execCommand(const QString &commandName);
  void execCommand(const QString &commandName, const QString &valueArgument);
  bool queryCommandState(const QString &commandName);
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
  void applyTextColor();
  void applyTextColor(QColor color);
  void applyBackgroundColor();
  void applyBackgroundColor(QColor color);
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
private:
  void createActions();
  void resetZoom();
public slots:
  void processLinkClick(QUrl url);
  void requestFinished();
  void processLinkHover(QString link, QString title, QString textContent);
  void showContextMenu(QPoint point);
protected:
  virtual void paintEvent(QPaintEvent *event);
  virtual QWebView* createWindow(QWebPage::WebWindowType type);
  virtual void keyPressEvent(QKeyEvent *event);
  virtual void wheelEvent(QWheelEvent *event);
  virtual void mouseDoubleClickEvent(QMouseEvent *event);
};

#endif // DOCUMENTATIONWIDGET_H
