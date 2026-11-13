//! The dygraph HTML page `diffSimulationResultsHtml` returns for one variable,
//! and the CSV file `diffSimulationResults` writes for it.

use crate::format::{format_g_prec, format_g_prec15};
use crate::{Algorithm, Comparison};

/// The rows `[time,reference,actual,high,low,error,actual(original)]` of an
/// `Ellipse2014` comparison of the actual `(time, data)`, like C `cmpDataTubes`.
fn rows(out: &mut String, time: &[f64], data: &[f64], cmp: &Comparison, html: bool) {
    debug_assert_eq!(cmp.algorithm, Algorithm::Ellipse2014);
    let (reftime, refdata) = (&cmp.reference.x, &cmp.reference.y);
    let n = cmp.time.len();
    let error = (cmp.error_count > 0).then_some(&cmp.error);
    let (empty, lbracket, rbracket) = if html { ("null", "[", "],") } else { ("", "", "") };
    let mut j = 0usize;
    for i in 0..reftime.len() {
        out.push_str(&format!(
            "{lbracket}{},{},",
            format_g_prec15(reftime[i]),
            format_g_prec15(refdata[i])
        ));
        if i < n {
            let (c, h, l) = (
                format_g_prec15(cmp.values[i]),
                format_g_prec15(cmp.high[i]),
                format_g_prec15(cmp.low[i]),
            );
            match error {
                Some(e) if !e[i].is_nan() => out.push_str(&format!("{c},{h},{l},{}", format_g_prec15(e[i]))),
                _ => out.push_str(&format!("{c},{h},{l},{empty}")),
            }
            if j < data.len() && reftime[i] == time[j] {
                out.push_str(&format!(",{}{rbracket}\n", format_g_prec15(data[j])));
                j += 1;
            } else {
                out.push_str(&format!(",{empty}{rbracket}\n"));
            }
        } else {
            out.push_str(if html { "null,null,null,null,null],\n" } else { ",,,,\n" });
        }
        while j < data.len() && reftime[i] > time[j] {
            out.push_str(&format!(
                "{lbracket}{},{empty},{empty},{empty},{empty},{empty},{}{rbracket}\n",
                format_g_prec15(time[j]),
                format_g_prec15(data[j])
            ));
            j += 1;
        }
    }
}

/// The comparison as `diffSimulationResults` writes it to `<prefix>.<var>.csv`.
pub fn tube_csv(time: &[f64], data: &[f64], cmp: &Comparison) -> String {
    let mut csv = String::from("time,reference,actual,high,low,error,actual (raw)\n");
    rows(&mut csv, time, data, cmp, false);
    csv.push('\n');
    csv
}

/// The dygraph HTML report of the comparison of the actual `(time, data)`.
pub fn tube_html(
    var_name: &str,
    time: &[f64],
    data: &[f64],
    cmp: &Comparison,
    reltol: f64,
    reltol_diff_max_min: f64,
    range_delta: f64,
) -> String {
    let reftime = &cmp.reference.x;
    let mut html = String::new();
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
        format_g_prec15(reftime[reftime.len() - 1]),
        format_g_prec15(time[0]),
        format_g_prec15(time[time.len() - 1]),
        format_g_prec(reltol, 2),
        format_g_prec(cmp.abstol, 2),
        format_g_prec(reltol_diff_max_min, 2),
        format_g_prec(range_delta, 2),
    ));
    html.push_str(
        "</p>\n\
<script type=\"text/javascript\">\n\
g = new Dygraph(document.getElementById(\"graphdiv\"),\n\
[\n",
    );

    rows(&mut html, time, data, cmp, true);
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
