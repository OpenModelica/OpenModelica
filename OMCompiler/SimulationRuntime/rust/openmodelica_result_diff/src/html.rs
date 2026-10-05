//! The dygraph HTML page `diffSimulationResultsHtml` writes for one variable.

use crate::ellipse2014::TubeCmp;
use crate::format::{format_g_prec, format_g_prec15};

/// The dygraph HTML report for one variable, mirroring the `isHtml=1` output of
/// C `cmpDataTubes`: a `<html>` page embedding a Dygraph fed an array of
/// `[time,reference,actual,high,low,error,actual(original)]` rows.
#[allow(clippy::too_many_arguments)]
pub fn tube_html(
    var_name: &str,
    time: &[f64],
    reftime: &[f64],
    refdata: &[f64],
    data: &[f64],
    cmp: &TubeCmp,
    reltol: f64,
    reltol_diff_max_min: f64,
    range_delta: f64,
) -> String {
    let TubeCmp { calibrated: calibrated_values, high, low, error, n, abstol } = cmp;
    let (n, abstol) = (*n, *abstol);
    let error = error.as_deref();
    let mut html = String::new();
    let ref_size = reftime.len();
    // `concat!` preserves the exact leading whitespace of each line (the CSS
    // block is indented); a `\`-continued string literal would strip it.
    html.push_str(concat!(
        "<html>\n",
        "<head>\n",
        "<script type=\"text/javascript\" src=\"dygraph-combined.js\"></script>\n",
        "    <style type=\"text/css\">\n",
        "    #graphdiv {\n",
        "      position: absolute;\n",
        "      left: 10px;\n",
        "      right: 10px;\n",
        "      top: 40px;\n",
        "      bottom: 10px;\n",
        "    }\n",
        "    </style>\n",
        "</head>\n",
        "<body>\n",
        "<div id=\"graphdiv\"></div>\n",
        "<p><input type=checkbox id=\"0\" checked onClick=\"change(this)\">\n",
        "<label for=\"0\">reference</label>\n",
        "<input type=checkbox id=\"1\" checked onClick=\"change(this)\">\n",
        "<label for=\"1\">actual</label>\n",
        "<input type=checkbox id=\"2\" checked onClick=\"change(this)\">\n",
        "<label for=\"2\">high</label>\n",
        "<input type=checkbox id=\"3\" checked onClick=\"change(this)\">\n",
        "<label for=\"3\">low</label>\n",
        "<input type=checkbox id=\"4\" checked onClick=\"change(this)\">\n",
        "<label for=\"4\">error</label>\n",
        "<input type=checkbox id=\"5\" onClick=\"change(this)\">\n",
        "<label for=\"5\">actual (original)</label>\n",
    ));
    html.push_str(&format!(
        "Reference time: {} to {}, actual time: {} to {}. Parameters used for the comparison: \
Relative tolerance {}. Absolute tolerance {} ({} relative). Range delta {}.",
        format_g_prec15(reftime[0]),
        format_g_prec15(reftime[ref_size - 1]),
        format_g_prec15(time[0]),
        format_g_prec15(time[time.len() - 1]),
        format_g_prec(reltol, 2),
        format_g_prec(abstol, 2),
        format_g_prec(reltol_diff_max_min, 2),
        format_g_prec(range_delta, 2),
    ));
    html.push_str(
        "</p>\n\
<script type=\"text/javascript\">\n\
g = new Dygraph(document.getElementById(\"graphdiv\"),\n\
[\n",
    );

    let mut j = 0usize;
    for i in 0..ref_size {
        html.push_str(&format!("[{},{},", format_g_prec15(reftime[i]), format_g_prec15(refdata[i])));
        if i < n {
            match error {
                Some(e) if !e[i].is_nan() => html.push_str(&format!(
                    "{},{},{},{}",
                    format_g_prec15(calibrated_values[i]), format_g_prec15(high[i]), format_g_prec15(low[i]), format_g_prec15(e[i])
                )),
                _ => html.push_str(&format!(
                    "{},{},{},null",
                    format_g_prec15(calibrated_values[i]), format_g_prec15(high[i]), format_g_prec15(low[i])
                )),
            }
            if j < data.len() && reftime[i] == time[j] {
                html.push_str(&format!(",{}],\n", format_g_prec15(data[j])));
                j += 1;
            } else {
                html.push_str(",null],\n");
            }
        } else {
            html.push_str("null,null,null,null,null],\n");
        }
        while j < data.len() && reftime[i] > time[j] {
            html.push_str(&format!(
                "[{},null,null,null,null,null,{}],\n",
                format_g_prec15(time[j]), format_g_prec15(data[j])
            ));
            j += 1;
        }
    }
    html.push_str("],\n");
    html.push_str(&format!(
        "{{title: '{var_name}',\n\
legend: 'always',\n\
xlabel: ['time'],\n\
connectSeparatedPoints: true,\n\
labels: ['time','reference','actual','high','low','error','actual (original)'],\n\
y2label: ['error'],\n\
series : {{ 'error': {{ axis: 'y2' }} }},\n\
colors: ['blue','red','teal','lightblue','orange','black'],\n\
visibility: [true,true,true,true,true,false]\n\
}});\n\
function change(el) {{\n  g.setVisibility(parseInt(el.id), el.checked);\n\
}}\n\
</script>\n\
</body>\n\
</html>\n"
    ));
    html
}
