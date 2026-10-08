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

#include "Modeling/WasmDocViewer.h"

#if defined(__EMSCRIPTEN__)

#include <QScrollBar>
#include <QTextCursor>

QWebEngineView::QWebEngineView(QWidget *parent)
  : QTextBrowser(parent)
{
  // Links fire anchorClicked (routed to the page) instead of navigating QTextBrowser.
  setOpenLinks(false);
  setOpenExternalLinks(false);
  mBaseFontPointSize = font().pointSizeF();
  connect(this, &QTextBrowser::anchorClicked, this, &QWebEngineView::onAnchorClicked);
  connect(this, &QTextBrowser::highlighted, this, &QWebEngineView::onHighlighted);
}

void QWebEngineView::setPage(QWebEnginePage *pPage)
{
  mpPage = pPage;
  if (mpPage) {
    mpPage->setBrowser(this);
  }
}

void QWebEngineView::setUrl(const QUrl &url)
{
  setSource(url);
  emit loadFinished(true);
}

void QWebEngineView::setHtml(const QString &html)
{
  QTextBrowser::setHtml(html);
  emit loadFinished(true);
}

void QWebEngineView::setZoomFactor(qreal zoom)
{
  mZoom = zoom;
  if (mBaseFontPointSize > 0.0) {
    QFont f = font();
    f.setPointSizeF(mBaseFontPointSize * zoom);
    setFont(f);
  }
}

// QtWebEngine cannot delegate links, so DocumentationPage overrides
// acceptNavigationRequest to emit linkClicked; reuse it for QTextBrowser clicks.
void QWebEngineView::onAnchorClicked(const QUrl &url)
{
  if (mpPage) {
    mpPage->acceptNavigationRequest(url, QWebEnginePage::NavigationTypeLinkClicked, true);
  }
}

void QWebEngineView::onHighlighted(const QUrl &url)
{
  if (mpPage) {
    mpPage->emitLinkHovered(url.toString());
  }
}

QString QWebEnginePage::selectedText() const
{
  return mpBrowser ? mpBrowser->textCursor().selectedText() : QString();
}

bool QWebEnginePage::hasSelection() const
{
  return mpBrowser && mpBrowser->textCursor().hasSelection();
}

QPointF QWebEnginePage::scrollPosition() const
{
  if (!mpBrowser) {
    return QPointF();
  }
  return QPointF(mpBrowser->horizontalScrollBar()->value(),
                 mpBrowser->verticalScrollBar()->value());
}

void QWebEnginePage::setHtml(const QString &html)
{
  if (mpBrowser) {
    mpBrowser->setHtml(html);
  }
}

void QWebEnginePage::setUrl(const QUrl &url)
{
  if (mpBrowser) {
    mpBrowser->setSource(url);
  }
}

#endif // __EMSCRIPTEN__
