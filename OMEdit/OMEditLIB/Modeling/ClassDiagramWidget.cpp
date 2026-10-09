/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include "ClassDiagramWidget.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Options/OptionsDialog.h"
#include "OMC/OMCProxy.h"
#include "Util/Helper.h"
#include "Util/Utilities.h"
#include "Util/StringHandler.h"

#include <QCheckBox>
#include <QComboBox>
#include <QDesktopServices>
#include <QFile>
#include <QFileInfo>
#include <QCloseEvent>
#include <QHBoxLayout>
#include <QIcon>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QMessageBox>
#include <QSettings>
#include <QSpinBox>
#include <QTabWidget>
#include <QTimer>
#include <QToolButton>
#include <QUrlQuery>
#include <QVBoxLayout>

/*!
 * \class ClassDiagramPage
 * \brief The page of the class diagram.
 * The draw.io viewer opens the link of a class or of a line in it with window.open,
 * which arrives in newWindowRequested; a link in a label is a plain link click.
 */
ClassDiagramPage::ClassDiagramPage(QObject *pParent)
  : QWebEnginePage(pParent)
{
  connect(this, SIGNAL(newWindowRequested(QWebEngineNewWindowRequest&)), SLOT(newWindowRequested(QWebEngineNewWindowRequest&)));
}

bool ClassDiagramPage::acceptNavigationRequest(const QUrl &url, NavigationType type, bool isMainFrame)
{
  if (type == QWebEnginePage::NavigationTypeLinkClicked && isMainFrame) {
    // Handled after the navigation request returns, see DocumentationPage::acceptNavigationRequest.
    QTimer::singleShot(0, this, [this, url]() {emit linkClicked(url);});
    return false;
  }
  return true;
}

/*!
 * \brief ClassDiagramPage::newWindowRequested
 * Never opens a window, the link is handled like a clicked one.
 * \param request
 */
void ClassDiagramPage::newWindowRequested(QWebEngineNewWindowRequest &request)
{
  emit linkClicked(request.requestedUrl());
}

/*!
 * \class ClassDiagramWidget
 * \brief Shows the UML class diagram of a class, from getClassDiagram, in the draw.io viewer.
 * Each class has a tab of its own in the ClassDiagramWindow.
 * A click on a class opens it and a click on a line in a class, e.g. a component, opens the
 * text view of the class at the line the element is declared on.
 * \param className
 */
ClassDiagramWidget::ClassDiagramWidget(const QString &className, QWidget *pParent)
  : QWidget(pParent), mClassName(className)
{
  mpClassNameLabel = new Label;
  mpClassNameLabel->setElideMode(Qt::ElideMiddle);
  mpClassNameLabel->setText(className);
  mpDepthSpinBox = new QSpinBox;
  mpDepthSpinBox->setRange(0, 10);
  mpDepthSpinBox->setValue(1);
  mpDepthSpinBox->setToolTip(tr("How many levels of used classes to show"));
  mpShowModifiersCheckBox = new QCheckBox(tr("Show modifiers"));
  mpShowModifiersCheckBox->setChecked(true);
  mpRefreshToolButton = new QToolButton;
  mpRefreshToolButton->setIcon(QIcon(":/Resources/icons/refresh.svg"));
  mpRefreshToolButton->setToolTip(Helper::refresh);
  mpRefreshToolButton->setAutoRaise(true);
  connect(mpRefreshToolButton, SIGNAL(clicked()), SLOT(refresh()));
  mpSaveAsToolButton = new QToolButton;
  mpSaveAsToolButton->setIcon(QIcon(":/Resources/icons/save.svg"));
  mpSaveAsToolButton->setToolTip(tr("Save the diagram as a draw.io file"));
  mpSaveAsToolButton->setAutoRaise(true);
  connect(mpSaveAsToolButton, SIGNAL(clicked()), SLOT(saveAs()));
  mpLayoutComboBox = new QComboBox;
  mpLayoutComboBox->addItem(tr("Class on top"), "north");
  mpLayoutComboBox->addItem(tr("Base classes on top"), "south");
  mpLayoutComboBox->addItem(tr("Rows by inheritance"), "");
  mpLayoutComboBox->setToolTip(tr("How the classes are laid out"));
  connect(mpLayoutComboBox, SIGNAL(currentIndexChanged(int)), SLOT(refresh()));
  connect(mpDepthSpinBox, SIGNAL(valueChanged(int)), SLOT(refresh()));
  connect(mpShowModifiersCheckBox, SIGNAL(toggled(bool)), SLOT(refresh()));
  mpClassDiagramView = new QWebEngineView;
  ClassDiagramPage *pClassDiagramPage = new ClassDiagramPage(mpClassDiagramView);
  mpClassDiagramView->setPage(pClassDiagramPage);
  connect(pClassDiagramPage, SIGNAL(linkClicked(QUrl)), SLOT(openLink(QUrl)));
  // layout
  QHBoxLayout *pToolsLayout = new QHBoxLayout;
  pToolsLayout->setContentsMargins(0, 0, 0, 0);
  pToolsLayout->addWidget(mpClassNameLabel, 1);
  pToolsLayout->addWidget(new Label(tr("Depth:")));
  pToolsLayout->addWidget(mpDepthSpinBox);
  pToolsLayout->addWidget(mpShowModifiersCheckBox);
  pToolsLayout->addWidget(new Label(tr("Layout:")));
  pToolsLayout->addWidget(mpLayoutComboBox);
  pToolsLayout->addWidget(mpRefreshToolButton);
  pToolsLayout->addWidget(mpSaveAsToolButton);
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->addLayout(pToolsLayout);
  pMainLayout->addWidget(mpClassDiagramView, 1);
  setLayout(pMainLayout);
  refresh();
}

ClassDiagramWidget::~ClassDiagramWidget()
{
  QFile::remove(pageFileName());
}

/*!
 * \brief ClassDiagramWidget::pageFileName
 * The page of the diagram, one per class as each has a window of its own.
 * \return
 */
QString ClassDiagramWidget::pageFileName() const
{
  QString name = mClassName;
  name.replace(QRegularExpression("[^A-Za-z0-9_.]"), "_");
  return QString("%1/classdiagram-%2.html").arg(Utilities::tempDirectory(), name);
}

/*!
 * \brief ClassDiagramWidget::refresh
 * Gets the diagram of the class again, e.g. after the class or the options changed.
 */
void ClassDiagramWidget::refresh()
{
  if (mClassName.isEmpty()) {
    return;
  }
  mDiagram = MainWindow::instance()->getOMCProxy()->getClassDiagram(mClassName, mpDepthSpinBox->value(), mpShowModifiersCheckBox->isChecked());
  mpSaveAsToolButton->setEnabled(!mDiagram.isEmpty());
  /* Loaded from a file, not with setHtml, which is limited to 2 MB. A page loaded from a file
   * can't load scripts from qrc:, so the viewer is copied next to it.
   */
  QString viewerFileName = QString("%1/drawio-viewer-static.min.js").arg(Utilities::tempDirectory());
  QFile viewerFile(":/Resources/drawio/viewer-static.min.js");
  if (QFileInfo(viewerFileName).size() != viewerFile.size()) {
    // The copy is read-only like the resource, and may be from another version.
    QFile::setPermissions(viewerFileName, QFile::ReadOwner | QFile::WriteOwner);
    QFile::remove(viewerFileName);
    viewerFile.copy(viewerFileName);
  }
  QString fileName = pageFileName();
  QFile file(fileName);
  if (file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
    file.write(htmlPage(mDiagram).toUtf8());
    file.close();
    mpClassDiagramView->setUrl(QUrl::fromLocalFile(fileName));
  }
}

/*!
 * \brief ClassDiagramWidget::htmlPage
 * Returns the page showing a draw.io diagram with the draw.io viewer, which is bundled so
 * that no network is needed.
 * \param diagram
 * \return
 */
QString ClassDiagramWidget::htmlPage(const QString &diagram) const
{
  if (diagram.isEmpty()) {
    return QString("<html><body><p>%1</p></body></html>").arg(tr("No class diagram of <b>%1</b>, see the Messages Browser.").arg(mClassName.toHtmlEscaped()));
  }
  /* QUrl makes the host lowercase, so modelica://P.M would be read as modelica://p.m.
   * With modelica:/// the class name is the path, see OMCProxy::getDocumentationAnnotation.
   */
  QString xml = diagram;
  xml.replace("modelica://", "modelica:///");
  QJsonObject config;
  config.insert("xml", xml);
  config.insert("nav", true);
  // At its size, scrolled, with the zoom and fit buttons; fitting a diagram into the window makes the text unreadable.
  config.insert("resize", false);
  config.insert("auto-fit", false);
  config.insert("zoom", 1);
  config.insert("lightbox", false);
  config.insert("toolbar", "zoom layers");
  config.insert("toolbar-nohide", true);
  config.insert("highlight", "#0000ff");
  // In a script, where only </script ends it.
  QString json = QString::fromUtf8(QJsonDocument(config).toJson(QJsonDocument::Compact)).replace("</", "<\\/");
  /* omc lays the classes out in rows by inheritance depth; mxGraph's hierarchical layout, in the
   * viewer, orders them to cross fewer edges. It runs in a hidden viewer, and the laid-out model is
   * shown and kept in classDiagramModel for saveAs.
   */
  QString script = QString(R"(
var config = %1;
var direction = "%2";
var div = document.getElementById("classdiagram");
window.classDiagramModel = "";
function show(cfg) {
  div.setAttribute("data-mxgraph", JSON.stringify(cfg));
  GraphViewer.createViewerForElement(div);
}
if (!direction) {
  show(config);
} else {
  var hidden = document.createElement("div");
  hidden.style.cssText = "position:absolute;left:-100000px;top:0;width:4000px";
  document.body.appendChild(hidden);
  hidden.setAttribute("data-mxgraph", JSON.stringify(config));
  GraphViewer.createViewerForElement(hidden, function(viewer) {
    var graph = viewer.graph, model = graph.getModel();
    model.beginUpdate();
    try {
      var layout = new mxHierarchicalLayout(graph, direction == "south" ? mxConstants.DIRECTION_SOUTH : mxConstants.DIRECTION_NORTH);
      layout.intraCellSpacing = 40;
      layout.interRankCellSpacing = 70;
      layout.parallelEdgeSpacing = 12;
      layout.execute(graph.getDefaultParent());
    } finally {
      model.endUpdate();
    }
    config.xml = mxUtils.getXml(new mxCodec().encode(model));
    window.classDiagramModel = config.xml;
    hidden.parentNode.removeChild(hidden);
    show(config);
  });
}
)").arg(json, mpLayoutComboBox->currentData().toString());
  return QString("<!DOCTYPE html>\n<html><head><meta charset=\"utf-8\"/></head><body>\n"
                 "<div id=\"classdiagram\"></div>\n"
                 "<script type=\"text/javascript\" src=\"drawio-viewer-static.min.js\"></script>\n"
                 "<script type=\"text/javascript\">%1</script>\n"
                 "</body></html>\n").arg(script);
}

/*!
 * \brief ClassDiagramWidget::saveAs
 * Saves the diagram as a draw.io file, to edit it in draw.io.
 */
void ClassDiagramWidget::saveAs()
{
  if (mDiagram.isEmpty()) {
    return;
  }
  QString name = StringHandler::getLastWordAfterDot(mClassName);
  QString fileName = StringHandler::getSaveFileName(this, QString("%1 - %2").arg(Helper::applicationName, Helper::saveAs), NULL,
                                                    tr("draw.io Files (*.drawio)"), NULL, "drawio", &name);
  if (fileName.isEmpty()) {
    return;
  }
  // The diagram as it is laid out in the view, if it is.
  mpClassDiagramView->page()->runJavaScript("window.classDiagramModel", [this, fileName](const QVariant &result) {
    QString diagram = mDiagram;
    QString model = result.toString();
    int start = diagram.indexOf("<mxGraphModel");
    int end = diagram.indexOf("</mxGraphModel>");
    if (!model.isEmpty() && start >= 0 && end > start) {
      model.replace("modelica:///", "modelica://");
      diagram.replace(start, end + QString("</mxGraphModel>").length() - start, model);
    }
    QFile file(fileName);
    if (file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
      file.write(diagram.toUtf8());
      file.close();
    } else {
      QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                            GUIMessages::getMessage(GUIMessages::UNABLE_TO_SAVE_FILE).arg(fileName, file.errorString()), QMessageBox::Ok);
    }
  });
}

/*!
 * \brief ClassDiagramWidget::openLink
 * Opens the class a link in the diagram is to, modelica:///P.M. A link of a line in a class,
 * modelica:///P.M?lineNumber=12, opens the text view at the line, or, for a component,
 * modelica:///P.M?lineNumber=12&element=c, selects the component if the class is shown in a
 * graphical view that has it. Other links are opened by the system.
 * \param url
 */
void ClassDiagramWidget::openLink(const QUrl &url)
{
  if (url.scheme().compare("modelica") != 0) {
    if (url.scheme().startsWith("http") || url.scheme().compare("mailto") == 0) {
      QDesktopServices::openUrl(url);
    }
    return;
  }
  QString className = url.path();
  if (className.startsWith("/")) {
    className.remove(0, 1);
  }
  QUrlQuery query(url);
  int lineNumber = query.queryItemValue("lineNumber").toInt();
  QString elementName = query.queryItemValue("element", QUrl::FullyDecoded);
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(className);
  if (!pLibraryTreeItem) {
    QMessageBox::information(this, QString("%1 - %2").arg(Helper::applicationName, Helper::information),
                             GUIMessages::getMessage(GUIMessages::CLASS_NOT_FOUND).arg(className), QMessageBox::Ok);
    return;
  }
  pLibraryTreeModel->showModelWidget(pLibraryTreeItem);
  ModelWidget *pModelWidget = pLibraryTreeItem->getModelWidget();
  if (!pModelWidget) {
    return;
  }
  /* A component is selected in the icon and diagram views and the text view is at its line, so
   * that the user finds it in whichever view is shown or switched to. The view doesn't change if
   * it shows the component; otherwise the text view is shown.
   */
  bool shown = false;
  if (!elementName.isEmpty()) {
    const QList<GraphicsView*> graphicsViews = {pModelWidget->getIconGraphicsView(), pModelWidget->getDiagramGraphicsView()};
    for (GraphicsView *pGraphicsView : graphicsViews) {
      Element *pElement = pGraphicsView ? pGraphicsView->getElementObject(elementName) : nullptr;
      if (pElement) {
        pGraphicsView->scene()->clearSelection();
        pElement->setSelected(true);
        pGraphicsView->centerOn(pElement);
        if ((pGraphicsView == pModelWidget->getIconGraphicsView() && pModelWidget->getIconViewToolButton()->isChecked())
            || (pGraphicsView == pModelWidget->getDiagramGraphicsView() && pModelWidget->getDiagramViewToolButton()->isChecked())) {
          shown = true;
        }
      }
    }
  }
  if (lineNumber > 0 && pModelWidget->getEditor()) {
    pModelWidget->getEditor()->getPlainTextEdit()->goToLineNumber(lineNumber);
    if (!shown) {
      pModelWidget->getTextViewToolButton()->setChecked(true);
    }
  }
}

/*!
 * \class ClassDiagramWindow
 * \brief The window of the class diagrams, a tab per class, see MainWindow::showClassDiagramWidget.
 * It is a window of its own and never docked in the main window: a web view docked there, or moved
 * between a floating dock and the main window, made the main window flicker and on Windows lost the
 * D3D11 device, and changing the window flags of a floating dock crashed QtWebEngine's view.
 * Closing it closes the diagrams, so that their web pages don't stay around.
 */
ClassDiagramWindow::ClassDiagramWindow()
  : QWidget(nullptr)
{
  setWindowIcon(QIcon(":/Resources/icons/model.svg"));
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName, Helper::classDiagram));
  mpTabWidget = new QTabWidget;
  mpTabWidget->setTabsClosable(true);
  mpTabWidget->setMovable(true);
  mpTabWidget->setDocumentMode(true);
  connect(mpTabWidget, SIGNAL(tabCloseRequested(int)), SLOT(closeTab(int)));
  connect(mpTabWidget, SIGNAL(currentChanged(int)), SLOT(currentTabChanged(int)));
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->addWidget(mpTabWidget);
  setLayout(pMainLayout);
  // Where it was left, else in the middle of the main window, two thirds its size.
  QSettings *pSettings = Utilities::getApplicationSettings();
  if (!(OptionsDialog::instance()->getGeneralSettingsPage()->getPreserveUserCustomizations()
        && restoreGeometry(pSettings->value("classDiagram/geometry").toByteArray()))) {
    QRect mainWindowGeometry = MainWindow::instance()->geometry();
    resize(mainWindowGeometry.width() * 2 / 3, mainWindowGeometry.height() * 2 / 3);
    move(mainWindowGeometry.center() - rect().center());
  }
}

/*!
 * \brief ClassDiagramWindow::~ClassDiagramWindow
 * Keeps the geometry, and deletes the diagrams: their web pages must go before the web engine
 * profile does, at exit.
 */
ClassDiagramWindow::~ClassDiagramWindow()
{
  Utilities::getApplicationSettings()->setValue("classDiagram/geometry", saveGeometry());
  closeAllTabs();
}

/*!
 * \brief ClassDiagramWindow::showClassDiagram
 * Shows the diagram of a class in a tab of its own, or the tab already showing it, with the
 * diagram got again.
 * \param className
 * \return
 */
ClassDiagramWidget* ClassDiagramWindow::showClassDiagram(const QString &className)
{
  ClassDiagramWidget *pClassDiagramWidget = nullptr;
  for (int i = 0; i < mpTabWidget->count(); ++i) {
    ClassDiagramWidget *pWidget = qobject_cast<ClassDiagramWidget*>(mpTabWidget->widget(i));
    if (pWidget && pWidget->getClassName().compare(className) == 0) {
      pClassDiagramWidget = pWidget;
      break;
    }
  }
  if (pClassDiagramWidget) {
    pClassDiagramWidget->refresh();
  } else {
    pClassDiagramWidget = new ClassDiagramWidget(className);
    const int index = mpTabWidget->addTab(pClassDiagramWidget, StringHandler::getLastWordAfterDot(className));
    mpTabWidget->setTabToolTip(index, className);
  }
  mpTabWidget->setCurrentWidget(pClassDiagramWidget);
  show();
  raise();
  activateWindow();
  setWindowState(windowState() & (~Qt::WindowMinimized | Qt::WindowActive));
  return pClassDiagramWidget;
}

void ClassDiagramWindow::closeEvent(QCloseEvent *pEvent)
{
  Utilities::getApplicationSettings()->setValue("classDiagram/geometry", saveGeometry());
  closeAllTabs();
  pEvent->accept();
}

void ClassDiagramWindow::closeAllTabs()
{
  while (mpTabWidget->count() > 0) {
    closeTab(0);
  }
}

/*!
 * \brief ClassDiagramWindow::closeTab
 * Closes a diagram, and the window with the last one.
 * \param index
 */
void ClassDiagramWindow::closeTab(int index)
{
  QWidget *pWidget = mpTabWidget->widget(index);
  mpTabWidget->removeTab(index);
  delete pWidget;
  if (mpTabWidget->count() == 0) {
    hide();
  }
}

void ClassDiagramWindow::currentTabChanged(int index)
{
  ClassDiagramWidget *pClassDiagramWidget = qobject_cast<ClassDiagramWidget*>(mpTabWidget->widget(index));
  setWindowTitle(pClassDiagramWidget ? QString("%1 - %2 - %3").arg(Helper::applicationName, Helper::classDiagram, pClassDiagramWidget->getClassName())
                                     : QString("%1 - %2").arg(Helper::applicationName, Helper::classDiagram));
}
