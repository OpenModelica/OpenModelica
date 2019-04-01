#ifndef TOOLS_H
#define TOOLS_H

#include "basic.h"
#include "Graph_Scene.h"
#include "Sketch_Files.h"

#include "document.h"
#include "command.h"
#include "application.h"
#include "documentview.h"

//

class Tools:public QMainWindow
{
    Q_OBJECT
    public:
      struct image_info
      {
             QString imageName;//image file name
             QImage* image;//image
       QString text;//text written into the image
       QString cellId;//cellId
       QString cell_text;//text of the cell
       QString cursor_position;//cusor position in that cell
      };

      struct document_info
      {
       QString onbFileName;
       int cellId;
       QVector<image_info> images_info;
      };


          Tools(Document *,DocumentView *);
      void open(const QString filename);
      void open();
      void getCells(const QVector<Cell*> cells);
      void getFileName(const QString &FileName);

      void SaveSketchImage(QString filename);
      void readXml(QString file_name);
      void writeXml(QString &image_name);


      void readFileAttributes(QVector<QString> &subStrings);

      void insertImage(QString imageName);

      void writeImage(QImage *image,QString fileName);

      //function takes the information from image_info
      void writeImage(image_info imageinfo);

      //function takes the information from image_info and filename
      void writeImage(image_info imageinfo,QString filename,int indx);


      void writeImage(QString filename);



      void updateCells();

      void updateImages();

        QVector<QString> filenames;

        private slots:
           //methods initializes the respective shapes to draw
           void draw_arc();
           void draw_arrow();
           void draw_rect();
           void draw_round_rect();
           void draw_line();
           void draw_linearrow();
           void draw_ellipse();
           void draw_polygon();
           void draw_triangle();
           void draw_text();

           void draw_new();
           void draw_save();
           void draw_open();
           void draw_shapes();

           //write the shapes to the images and exports to OMNotebook
           void draw_image_save();
           void draw_xml_save(){}

           void draw_copy();
           void draw_cut();
           void draw_paste();

       void setColors();
           void setPenStyles(int indx);
           void setPenWidths(int width);
           void setBrushStyles(int indx);
       void pen_lineSolidStyle();
       void pen_lineDashStyle();
       void pen_lineDotStyle();
       void pen_lineDashDotStyle();
       void pen_lineDashDotDotStyle();
       void brush_color();

       void imageinfo(QString filename);

       void enableProperties();
       void disableProperties();



    protected:
       //void mouseMoveEvent(QMouseEvent *);
           void mousePressEvent(QMouseEvent *);
       void mouseReleaseEvent(QMouseEvent *);
       void closeEvent(QCloseEvent* event);//function to close the window



           void keyPressEvent(QKeyEvent *);
           void keyReleaseEvent(QKeyEvent *);

        private:
           void button_action();
           void action();
           void menu();
           void draw_element(int id);

           void openFile();

       //funcrtion to write the image of the paticular document
       void writeImage(document_info &docs);
       void add_components();
           void file_components();
           void edit_components();
           void color_pen_components();
       void item_selected(Graph_Scene* scene_item);

       void reloadShapesProerties();

       QString application;
       QString file_name,onb_file_name,img_file_name;

       QToolBar *tool_bar1;
       QToolBar *tool_bar2;
       QToolBar *tool_bar3;
       QToolBar *tool_bar4;
       QToolButton *rect;
       QMenu *fileMenu,*editMenu,*toolMenu;
       QAction *arc,*arrow,*rectangle,*round_rectangle,*line,*linearrow,*ellipse,*polygon,*triangle,*text,*new_scene,*save_scene,*open_scene;
       //Action for file items
       QAction *close_me,*file_new,*file_open,*file_save,*file_close,*file_xml_save,*file_image_save;

       //Action for copy,cut and paste
       QAction *copy,*cut,*paste;

       //Action for shapes
       QAction *shapes;

       //Color dialog box
       QColorDialog *color_dialog;

       QLabel *label;
       QLayout *layout;
       QVBoxLayout *main_layout;
       QVBoxLayout *hlayout;
       QWidget *main_widget;
       QFrame *frame;
       Graph_Scene *scene;
       QGraphicsView *view;

     QStatusBar *statusBar;

     image_info images;
     image_info edit_img_info;



     QVector<QString> onbfilenames;
     QVector<QString> imagefilenames;
     QVector<QString> positions;
     QVector<QString> texts;
     QVector<QString> cellIds;
     QVector<Cell*> cells,temp_cells;

     QVector<image_info> images_info;
     QVector<image_info> edit_imgs_info;
     QVector<image_info> doc_images;
     QVector<document_info> documents_info;

     //Return the present cellId
     void getCellId(const Cell* cell,int &id);//Added by jhansi

     void writeImage(QImage *&image);

       QTextEdit *textEdit;
       QTextCharFormat *textFormat;


     Document *document;
     DocumentView *doc_view;

     bool itemSelected;

     bool edit;

     bool isSaved;

     bool file_read;

     QPen pen;
     QBrush brush;
       QColor color;


       //push buttons for file managment
       QToolButton *new_file,*open_file,*save_file,*saveas_file,*export_file,*import_file;
       //push buttons for editing
       QToolButton *cut_shape,*copy_shape,*paste_shape,*redo_shape,*undo_shape;
       //push button for color dialog
       QToolButton *select_color,*fill_color;

       //combobox for penstyles
       QComboBox *select_pen,*select_brush;

       //spinbox for line thickness
       QSpinBox *penWidth;

       QSize size;

     Sketch_Files* files;

     QVector<QImage*> drawn_images;


};

#endif // TOOLS_H
