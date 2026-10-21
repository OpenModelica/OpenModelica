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

#ifndef WASMHTMLVIEW_H
#define WASMHTMLVIEW_H

#if defined(__EMSCRIPTEN__)

#include <QWidget>
#include <QUrl>
#include <QVariant>
#include <functional>

/*!
 * \brief Shows an HTML page with its scripts in the browser, for the web build where there is
 * no QtWebEngine. The page is an iframe placed over the widget, in the DOM element of its
 * top-level window, so that it is stacked with the windows as the widget is.
 */
class WasmHtmlView : public QWidget
{
  Q_OBJECT
public:
  explicit WasmHtmlView(QWidget *pParent = nullptr);
  ~WasmHtmlView();
  void setHtml(const QString &html);
  void runJavaScript(const QString &script, const std::function<void(const QVariant&)> &callback);
  static QString scriptUrl(const QString &resource);
  static WasmHtmlView* find(int id);
protected:
  virtual void showEvent(QShowEvent *pEvent) override;
  virtual void hideEvent(QHideEvent *pEvent) override;
  virtual void resizeEvent(QResizeEvent *pEvent) override;
  virtual void moveEvent(QMoveEvent *pEvent) override;
  virtual bool eventFilter(QObject *pObject, QEvent *pEvent) override;
private:
  int mId;
  QWidget *mpWindow = nullptr;
  int mPlaceAttempts = 0;
  void updateFrame();
signals:
  void linkClicked(const QUrl &url);
  void loadFinished(bool ok);
};

#endif // __EMSCRIPTEN__
#endif // WASMHTMLVIEW_H
