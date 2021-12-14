set (QWT_HEADERS
    qwt.h
    qwt_abstract_scale_draw.h
    qwt_clipper.h
    qwt_color_map.h
    qwt_column_symbol.h
    qwt_date.h
    qwt_date_scale_draw.h
    qwt_date_scale_engine.h
    qwt_dyngrid_layout.h
    qwt_global.h
    qwt_graphic.h
    qwt_interval.h
    qwt_interval_symbol.h
    qwt_math.h
    qwt_magnifier.h
    qwt_null_paintdevice.h
    qwt_painter.h
    qwt_painter_command.h
    qwt_panner.h
    qwt_picker.h
    qwt_picker_machine.h
    qwt_pixel_matrix.h
    qwt_point_3d.h
    qwt_point_polar.h
    qwt_round_scale_draw.h
    qwt_scale_div.h
    qwt_scale_draw.h
    qwt_scale_engine.h
    qwt_scale_map.h
    qwt_spline.h
    qwt_symbol.h
    qwt_system_clock.h
    qwt_text_engine.h
    qwt_text_label.h
    qwt_text.h
    qwt_transform.h
    qwt_widget_overlay.h
)

set(QWT_SOURCES
    qwt_abstract_scale_draw.cpp
    qwt_clipper.cpp
    qwt_color_map.cpp
    qwt_column_symbol.cpp
    qwt_date.cpp
    qwt_date_scale_draw.cpp
    qwt_date_scale_engine.cpp
    qwt_dyngrid_layout.cpp
    qwt_event_pattern.cpp
    qwt_graphic.cpp
    qwt_interval.cpp
    qwt_interval_symbol.cpp
    qwt_math.cpp
    qwt_magnifier.cpp
    qwt_null_paintdevice.cpp
    qwt_painter.cpp
    qwt_painter_command.cpp
    qwt_panner.cpp
    qwt_picker.cpp
    qwt_picker_machine.cpp
    qwt_pixel_matrix.cpp
    qwt_point_3d.cpp
    qwt_point_polar.cpp
    qwt_round_scale_draw.cpp
    qwt_scale_div.cpp
    qwt_scale_draw.cpp
    qwt_scale_map.cpp
    qwt_scale_engine.cpp
    qwt_spline.cpp
    qwt_symbol.cpp
    qwt_system_clock.cpp
    qwt_text_engine.cpp
    qwt_text_label.cpp
    qwt_text.cpp
    qwt_transform.cpp
    qwt_widget_overlay.cpp
)

if (QWT_WITH_PLOT)
  list (APPEND QWT_HEADERS
    qwt_curve_fitter.h
    qwt_event_pattern.h
    qwt_abstract_legend.h
    qwt_legend.h
    qwt_legend_data.h
    qwt_legend_label.h
    qwt_plot.h
    qwt_plot_renderer.h
    qwt_plot_curve.h
    qwt_plot_dict.h
    qwt_plot_directpainter.h
    qwt_plot_grid.h
    qwt_plot_histogram.h
    qwt_plot_item.h
    qwt_plot_abstract_barchart.h
    qwt_plot_barchart.h
    qwt_plot_multi_barchart.h
    qwt_plot_intervalcurve.h
    qwt_plot_tradingcurve.h
    qwt_plot_layout.h
    qwt_plot_marker.h
    qwt_plot_zoneitem.h
    qwt_plot_textlabel.h
    qwt_plot_rasteritem.h
    qwt_plot_spectrogram.h
    qwt_plot_spectrocurve.h
    qwt_plot_scaleitem.h
    qwt_plot_legenditem.h
    qwt_plot_seriesitem.h
    qwt_plot_shapeitem.h
    qwt_plot_canvas.h
    qwt_plot_panner.h
    qwt_plot_picker.h
    qwt_plot_zoomer.h
    qwt_plot_magnifier.h
    qwt_plot_rescaler.h
    qwt_point_mapper.h
    qwt_raster_data.h
    qwt_matrix_raster_data.h
    qwt_sampling_thread.h
    qwt_samples.h
    qwt_series_data.h
    qwt_series_store.h
    qwt_point_data.h
    qwt_scale_widget.h)

  list (APPEND QWT_SOURCES
        qwt_curve_fitter.cpp
        qwt_abstract_legend.cpp
        qwt_legend.cpp
        qwt_legend_data.cpp
        qwt_legend_label.cpp
        qwt_plot.cpp
        qwt_plot_renderer.cpp
        qwt_plot_axis.cpp
        qwt_plot_curve.cpp
        qwt_plot_dict.cpp
        qwt_plot_directpainter.cpp
        qwt_plot_grid.cpp
        qwt_plot_histogram.cpp
        qwt_plot_item.cpp
        qwt_plot_abstract_barchart.cpp
        qwt_plot_barchart.cpp
        qwt_plot_multi_barchart.cpp
        qwt_plot_intervalcurve.cpp
        qwt_plot_zoneitem.cpp
        qwt_plot_tradingcurve.cpp
        qwt_plot_spectrogram.cpp
        qwt_plot_spectrocurve.cpp
        qwt_plot_scaleitem.cpp
        qwt_plot_legenditem.cpp
        qwt_plot_seriesitem.cpp
        qwt_plot_shapeitem.cpp
        qwt_plot_marker.cpp
        qwt_plot_textlabel.cpp
        qwt_plot_layout.cpp
        qwt_plot_canvas.cpp
        qwt_plot_panner.cpp
        qwt_plot_rasteritem.cpp
        qwt_plot_picker.cpp
        qwt_plot_zoomer.cpp
        qwt_plot_magnifier.cpp
        qwt_plot_rescaler.cpp
        qwt_point_mapper.cpp
        qwt_raster_data.cpp
        qwt_matrix_raster_data.cpp
        qwt_sampling_thread.cpp
        qwt_series_data.cpp
        qwt_point_data.cpp
        qwt_scale_widget.cpp)
endif ()

if (QWT_WITH_OPENGL)
  if (NOT USE_QT6)
    list (APPEND QWT_HEADERS qwt_plot_glcanvas.h)
    list (APPEND QWT_SOURCES qwt_plot_glcanvas.cpp)
  endif ()
endif ()

if (QWT_WITH_SVG)
  list (APPEND QWT_HEADERS qwt_plot_svgitem.h)
  list (APPEND QWT_SOURCES qwt_plot_svgitem.cpp)
endif ()

if (QWT_WITH_WIDGETS)
  list (APPEND QWT_HEADERS
    qwt_abstract_slider.h
    qwt_abstract_scale.h
    qwt_arrow_button.h
    qwt_analog_clock.h
    qwt_compass.h
    qwt_compass_rose.h
    qwt_counter.h
    qwt_dial.h
    qwt_dial_needle.h
    qwt_knob.h
    qwt_slider.h
    qwt_thermo.h
    qwt_wheel.h)
  list (APPEND QWT_SOURCES
    qwt_abstract_slider.cpp
    qwt_abstract_scale.cpp
    qwt_arrow_button.cpp
    qwt_analog_clock.cpp
    qwt_compass.cpp
    qwt_compass_rose.cpp
    qwt_counter.cpp
    qwt_dial.cpp
    qwt_dial_needle.cpp
    qwt_knob.cpp
    qwt_slider.cpp
    qwt_thermo.cpp
    qwt_wheel.cpp)
endif ()

add_library(qwt SHARED ${QWT_HEADERS} ${QWT_SOURCES})

target_compile_definitions(qwt
	PUBLIC
		$<$<BOOL:MSVC>:QWT_DLL>
	PRIVATE
		$<$<BOOL:MSVC>:QWT_MAKEDLL>
)

target_include_directories(qwt
  PUBLIC
  $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/src>
  $<INSTALL_INTERFACE:include>)

if (USE_QT6)
  target_link_libraries(qwt
    PUBLIC
      Qt6::Core
      Qt6::OpenGL
      Qt6::OpenGLWidgets
    PRIVATE
      Qt6::Concurrent
      Qt6::PrintSupport
      Qt6::Svg)
else ()
    target_link_libraries(qwt
    PUBLIC
      Qt5::Core
      Qt5::OpenGL
    PRIVATE
      Qt5::Concurrent
      Qt5::PrintSupport
      Qt5::Svg)
endif ()

set_target_properties(qwt PROPERTIES
  VERSION ${QWT_VERSION}
  SOVERSION ${QWT_VER_MAJ}
  AUTOMOC ON)
target_compile_definitions(qwt PRIVATE QWT_MOC_INCLUDE)

target_link_options(qwt PRIVATE -Wl,--no-undefined)


install (FILES ${QWT_HEADERS} DESTINATION include/qwt)
install (TARGETS qwt)