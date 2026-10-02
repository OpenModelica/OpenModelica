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

#ifdef OM_OMEDIT_CLASS_DIAGRAM
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/ModelWidgetContainer.h"
#include "OMC/OMCProxy.h"
#include "Util/Helper.h"
#include "Util/Utilities.h"
#include "Util/StringHandler.h"

#include <QCheckBox>
#include <QComboBox>
#include <QDesktopServices>
#include <QDockWidget>
#include <QFile>
#include <QFileInfo>
#include <QHBoxLayout>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMessageBox>
#include <QSettings>
#include <QSpinBox>
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
 * It is in a dock, tabbed with the documentation, that floats in a window of its own until the
 * user docks it with the dock button.
 * A click on a class opens it and a click on a line in a class, e.g. a component, opens the
 * text view of the class at the line the element is declared on.
 */
ClassDiagramWidget::ClassDiagramWidget(QWidget *pParent)
  : QWidget(pParent)
{
  // The viewer is in a resource file of its own, which OMEditLib, a static library, must initialize.
  Q_INIT_RESOURCE(resource_drawio);
  mpClassNameLabel = new Label;
  mpClassNameLabel->setElideMode(Qt::ElideMiddle);
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
  mpDockToolButton = new QToolButton;
  mpDockToolButton->setIcon(QIcon(":/Resources/icons/link-external.svg"));
  mpDockToolButton->setAutoRaise(true);
  connect(mpDockToolButton, SIGNAL(clicked()), SLOT(toggleDocked()));
  mpLayoutComboBox = new QComboBox;
  mpLayoutComboBox->addItem(tr("Class on top"), "north");
  mpLayoutComboBox->addItem(tr("Base classes on top"), "south");
  mpLayoutComboBox->addItem(tr("Rows by inheritance"), "");
  mpLayoutComboBox->setToolTip(tr("How the classes are laid out"));
  connect(mpLayoutComboBox, SIGNAL(currentIndexChanged(int)), SLOT(refresh()));
  connect(mpDepthSpinBox, SIGNAL(valueChanged(int)), SLOT(refresh()));
  connect(mpShowModifiersCheckBox, SIGNAL(toggled(bool)), SLOT(refresh()));
  mpClassDiagramView = createClassDiagramView();
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
  pToolsLayout->addWidget(mpDockToolButton);
  mpMainLayout = new QVBoxLayout;
  mpMainLayout->setContentsMargins(0, 0, 0, 0);
  mpMainLayout->addLayout(pToolsLayout);
  mpMainLayout->addWidget(mpClassDiagramView, 1);
  setLayout(mpMainLayout);
}

QWebEngineView* ClassDiagramWidget::createClassDiagramView()
{
  QWebEngineView *pClassDiagramView = new QWebEngineView;
  ClassDiagramPage *pClassDiagramPage = new ClassDiagramPage(pClassDiagramView);
  pClassDiagramView->setPage(pClassDiagramPage);
  connect(pClassDiagramPage, SIGNAL(linkClicked(QUrl)), SLOT(openLink(QUrl)));
  return pClassDiagramView;
}

QString ClassDiagramWidget::pageFileName() const
{
  return QString("%1/classdiagram.html").arg(Utilities::tempDirectory());
}

/*!
 * \brief ClassDiagramWidget::showClassDiagram
 * Shows the diagram of a class; the first time in a window in the middle of the main window,
 * two thirds its size, and afterwards where the user left it.
 * \param className
 */
void ClassDiagramWidget::showClassDiagram(const QString &className)
{
  mClassName = className;
  mpClassNameLabel->setText(className);
  QDockWidget *pDockWidget = dockWidget();
  if (pDockWidget) {
    pDockWidget->setWindowTitle(QString("%1 - %2").arg(Helper::classDiagram, className));
    QSettings *pSettings = Utilities::getApplicationSettings();
    if (pDockWidget->isFloating() && !pSettings->value("classDiagram/placed", false).toBool()) {
      QRect mainWindowGeometry = MainWindow::instance()->geometry();
      pDockWidget->resize(mainWindowGeometry.width() * 2 / 3, mainWindowGeometry.height() * 2 / 3);
      pDockWidget->move(mainWindowGeometry.center() - pDockWidget->rect().center());
      pSettings->setValue("classDiagram/placed", true);
    }
    pDockWidget->show();
    pDockWidget->raise();
    pDockWidget->activateWindow();
  }
  refresh();
}

QDockWidget* ClassDiagramWidget::dockWidget() const
{
  return qobject_cast<QDockWidget*>(parentWidget());
}

/*!
 * \brief ClassDiagramWidget::toggleDocked
 * Docks the floating window, or makes the dock float. A floating window has the frame of the
 * window manager, so it can't be dragged back to the main window like a Qt one.
 */
void ClassDiagramWidget::toggleDocked()
{
  QDockWidget *pDockWidget = dockWidget();
  if (pDockWidget) {
    pDockWidget->setFloating(!pDockWidget->isFloating());
    pDockWidget->show();
    pDockWidget->raise();
  }
}

/*!
 * \brief ClassDiagramWidget::floatingChanged
 * A floating dock gets the frame of the window manager, which moves it; Qt's own frame is moved
 * by Qt, which some window managers (WSLg) don't allow, so the window couldn't be moved at all.
 * Only on X11/Wayland: on Windows changing the flags recreates the native window under the web
 * view, which loses its D3D11 device when it is docked again, and the diagram stays blank.
 * \param floating
 */
void ClassDiagramWidget::floatingChanged(bool floating)
{
  mpDockToolButton->setToolTip(floating ? tr("Dock in the main window") : tr("Float in a window of its own"));
  /* On Windows the web view stays black once the dock floats or docks, as its native window is
   * recreated, so a new view shows the page again; the diagram isn't asked from omc again.
   */
  QWebEngineView *pClassDiagramView = createClassDiagramView();
  delete mpMainLayout->replaceWidget(mpClassDiagramView, pClassDiagramView);
  mpClassDiagramView->deleteLater();
  mpClassDiagramView = pClassDiagramView;
  if (!mClassName.isEmpty()) {
    mpClassDiagramView->setUrl(QUrl::fromLocalFile(pageFileName()));
  }
#if !defined(Q_OS_WIN) && !defined(Q_OS_MAC)
  QDockWidget *pDockWidget = dockWidget();
  if (!pDockWidget) {
    return;
  }
  // The frame of the window manager has the title, so Qt's title bar is only shown in the main window.
  QWidget *pTitleBarWidget = pDockWidget->titleBarWidget();
  pDockWidget->setTitleBarWidget(floating ? new QWidget(pDockWidget) : nullptr);
  delete pTitleBarWidget;
  if (floating) {
    // Changing the flags hides the window, but not explicitly.
    bool visible = pDockWidget->isVisible();
    pDockWidget->setWindowFlags(Qt::Window | Qt::WindowTitleHint | Qt::WindowSystemMenuHint | Qt::WindowMinMaxButtonsHint
                                | Qt::WindowCloseButtonHint);
    // Explicitly, or it is shown with the main window.
    pDockWidget->setVisible(visible);
  }
#endif
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
  QFile viewerFile(":/drawio/viewer-static.min.js");
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
  // At its size, scrolled, with the zoom and fit buttons; fitting a diagram into the dock makes the text unreadable.
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

#endif // OM_OMEDIT_CLASS_DIAGRAM
