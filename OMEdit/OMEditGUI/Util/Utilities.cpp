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

#include "MainWindow.h"
#include "Utilities.h"

MdiArea::MdiArea(QWidget *pParent)
  : QMdiArea(pParent)
{
  mpMainWindow = qobject_cast<MainWindow*>(pParent);
  setHorizontalScrollBarPolicy(Qt::ScrollBarAsNeeded);
  setVerticalScrollBarPolicy(Qt::ScrollBarAsNeeded);
  setActivationOrder(QMdiArea::ActivationHistoryOrder);
  setDocumentMode(true);
#if QT_VERSION >= 0x040800
  setTabsClosable(true);
#endif
}

MainWindow* MdiArea::getMainWindow()
{
  return mpMainWindow;
}

/*!
 * \class FileDataNotifier
 * \brief Looks for new data on file. When data is availabe emits bytesAvailable SIGNAL.
 * \brief FileDataNotifier::FileDataNotifier
 * \param fileName
 */
FileDataNotifier::FileDataNotifier(const QString fileName)
{
  mFile.setFileName(fileName);
  mStop = false;
  mBytesAvailable = 0;
}

/*!
 * \brief FileDataNotifier::exit
 * Reimplementation of QThread::exit()
 * Sets mStop to true.
 * \param retcode
 */
void FileDataNotifier::exit(int retcode)
{
  mStop = true;
  QThread::exit(retcode);
}

/*!
 * \brief FileDataNotifier::run
 * Reimplentation of QThread::run().
 * Looks for when is new data available for reading on file.
 * Emits the bytesAvailable SIGNAL.
 */
void FileDataNotifier::run()
{
  if (mFile.open(QIODevice::ReadOnly)) {
    while(!mStop) {
      // if file doesn't exist then break.
      if (!mFile.exists()) {
        break;
      }
      // if file has bytes available to read.
      if (mFile.bytesAvailable() > mBytesAvailable) {
        mBytesAvailable = mFile.bytesAvailable();
        emit bytesAvailable(mFile.bytesAvailable());
      }
      Sleep::sleep(1);
    }
  }
}

/*!
 * \brief FileDataNotifier::start
 * Reimplementation of QThread::start()
 * Sets mStop to false.
 * \param priority
 */
void FileDataNotifier::start(Priority priority)
{
  mStop = false;
  QThread::start(priority);
}

Label::Label(QWidget *parent, Qt::WindowFlags flags)
  : QLabel(parent, flags), mElideMode(Qt::ElideNone), mText("")
{
  setTextInteractionFlags(Qt::TextSelectableByMouse);
}

Label::Label(const QString &text, QWidget *parent, Qt::WindowFlags flags)
  : QLabel(text, parent, flags), mElideMode(Qt::ElideNone), mText(text)
{
  setTextInteractionFlags(Qt::TextSelectableByMouse);
  setToolTip(text);
}

QSize Label::minimumSizeHint() const
{
  if (pixmap() != NULL || mElideMode == Qt::ElideNone)
    return QLabel::minimumSizeHint();
  const QFontMetrics &fm = fontMetrics();
  QSize size(fm.width("..."), fm.height()+5);
  return size;
}

QSize Label::sizeHint() const
{
  if (pixmap() != NULL || mElideMode == Qt::ElideNone)
    return QLabel::sizeHint();
  const QFontMetrics& fm = fontMetrics();
  QSize size(fm.width(mText), fm.height()+5);
  return size;
}

void Label::setText(const QString &text)
{
  mText = text;
  setToolTip(text);
  QLabel::setText(text);
}

void Label::resizeEvent(QResizeEvent *event)
{
  if (mElideMode != Qt::ElideNone)
  {
    QFontMetrics fm(fontMetrics());
    QString str = fm.elidedText(mText, mElideMode, event->size().width());
    QLabel::setText(str);
  }
  QLabel::resizeEvent(event);
}

FixedCheckBox::FixedCheckBox(QWidget *parent)
 : QCheckBox(parent)
{
  setCheckable(false);
  mDefaultValue = false;
  mDefaultTickState = false;
  mTickState = false;
}

void FixedCheckBox::setDefaultTickState(bool defaultValue, bool defaultTickState, bool tickState)
{
  mDefaultValue = defaultValue;
  mDefaultTickState = defaultTickState;
  mTickState = tickState;
}

void FixedCheckBox::setTickState(bool defaultValue, bool tickState)
{
  mDefaultValue = defaultValue;
  if (mDefaultValue) {
    mTickState = mDefaultTickState;
  } else {
    mTickState = tickState;
  }
}

QString FixedCheckBox::tickState()
{
  if (mDefaultValue) {
    return "";
  } else if (mTickState) {
    return "true";
  } else {
    return "false";
  }
}

/*!
  Reimplementation of QCheckBox::paintEvent.\n
  Draws a custom checkbox suitable for fixed modifier.
  */
void FixedCheckBox::paintEvent(QPaintEvent *event)
{
  Q_UNUSED(event);
  QStylePainter p(this);
  QStyleOptionButton opt;
  opt.initFrom(this);
  if (mDefaultValue) {
    p.setBrush(QColor(225, 225, 225));
  } else {
    p.setBrush(Qt::white);
  }
  p.drawRect(opt.rect.adjusted(0, 0, -1, -1));
  // if is checked then draw a tick
  if (mTickState) {
    p.setRenderHint(QPainter::Antialiasing);
    QPen pen = p.pen();
    pen.setWidthF(1.5);
    p.setPen(pen);
    QVector<QPoint> lines;
    lines << QPoint(opt.rect.left() + 3, opt.rect.center().y());
    lines << QPoint(opt.rect.center().x() - 1, opt.rect.bottom() - 3);
    lines << QPoint(opt.rect.center().x() - 1, opt.rect.bottom() - 3);
    lines << QPoint(opt.rect.width() - 3, opt.rect.top() + 3);
    p.drawLines(lines);
  }
}
