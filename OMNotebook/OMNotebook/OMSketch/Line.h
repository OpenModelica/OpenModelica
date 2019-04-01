#ifndef LINE_H
#define LINE_H

#include <QWidget>
#include <QColor>
#include <QImage>
#include <QPixmap>
#include <QPoint>
#include <QLabel>
#include <QPainter>

class Line: public QWidget
{
  Q_OBJECT
  public:
    Line(QWidget *parent=0);
    void draw_line();
    virtual ~Line();
    QPoint strt1_pnt;
    bool added;

  protected:
    void mousePressEvent(QMouseEvent *);
    void mouseMoveEvent(QMouseEvent *);
    void mouseReleaseEvent(QMouseEvent *);
    void paintEvent(QPaintEvent *);

  private:
    QImage image;
    QPixmap pixmap;
    QPoint strt_pnt;
    QPoint last_pnt;
    QLabel *label;
    QPainter painter;
};

#endif // LINE_H
