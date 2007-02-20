#ifndef LEGENDLABEL_H
#define LEGENDLABEL_H
#include <QLabel>
#include <QString>
#include <QColor>
using namespace std;


class LegendLabel: public QLabel
{
public:
	LegendLabel(QColor color_, QString& s, QWidget* parent): QLabel(s, parent)
	{
		color = color_;

	}
	~LegendLabel()
	{

	}

protected:

	void paintEvent ( QPaintEvent * event )
	{

		QPainter painter(this);
		painter.setPen(Qt::black);
		painter.setBrush(color);
		painter.setRenderHints(QPainter::Antialiasing);
		painter.drawEllipse(1, 1, max(0,height()-2), max(0,height()-2));
		
//		setIndent(height()+2);		

		QLabel::paintEvent(event);
	}

 void resizeEvent ( QResizeEvent * event )
 {
	setIndent(height() +2);
 }

private:
	QColor color;
};


#endif