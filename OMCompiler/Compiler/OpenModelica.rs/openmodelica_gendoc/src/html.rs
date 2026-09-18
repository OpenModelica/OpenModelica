//! Page rendering.

use crate::doc::{ClassDoc, Kind, Member};
use crate::links::{Resolver, Resource, file_stem, uri_encode};

pub struct Page {
    pub file: String,
    pub html: String,
    pub resources: Vec<Resource>,
}

/// Paths relative to the output directory.
pub struct Graphics {
    pub icon: Option<String>,
    pub diagram: Option<String>,
}

pub fn escape(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    for ch in s.chars() {
        match ch {
            '&' => out.push_str("&amp;"),
            '<' => out.push_str("&lt;"),
            '>' => out.push_str("&gt;"),
            '"' => out.push_str("&quot;"),
            _ => out.push(ch),
        }
    }
    out
}

/// A documentation string is either an HTML fragment wrapped in `<html>` or
/// plain text; the old generator made the same distinction.
fn documentation_html(s: &str) -> String {
    let trimmed = s.trim();
    if trimmed.is_empty() {
        String::new()
    } else if trimmed.to_ascii_lowercase().starts_with("<html>") {
        // The closing tag is optional: the specification has such a string
        // rendered as HTML whether or not it is there.
        strip_html_tags(&trimmed[6..]).to_string()
    } else {
        format!("<pre>{}</pre>", escape(trimmed))
    }
}

/// A description string is plain text unless it starts with `<html>`, which
/// makes the whole of it an HTML fragment (Modelica specification 18.4). Be
/// lenient about where the tag appears: libraries put it part way in, as
/// OpenIPSL.Copyright does with `"DISCLAIMER<html>…"`. What precedes it is
/// escaped as the text it is, and what follows is rendered.
fn description_html(s: &str) -> String {
    let Some(at) = s.to_ascii_lowercase().find("<html>") else {
        return escape(s);
    };
    // The text before the tag keeps its trailing space: it runs straight into
    // the markup, as in "Educational open source library on <html><a …".
    format!("{}{}", escape(&s[..at]), strip_html_tags(&s[at + 6..]))
}

/// Drops a trailing `</html>`, which may or may not be there.
fn strip_html_tags(s: &str) -> &str {
    let s = s.trim();
    match s.to_ascii_lowercase().rfind("</html>") {
        Some(end) if s[end..].len() == 7 => s[..end].trim_end(),
        _ => s,
    }
}

fn page_link(qualified_name: &str) -> String {
    format!("{}.html", uri_encode(&file_stem(qualified_name)))
}

fn breadcrumb(doc: &ClassDoc) -> String {
    let mut out = String::from("<nav class=\"om-crumbs\"><a href=\"index.html\">Libraries</a>");
    let mut prefix = String::new();
    for (i, segment) in doc.path.iter().enumerate() {
        if i > 0 {
            prefix.push('.');
        }
        prefix.push_str(segment);
        if i + 1 == doc.path.len() {
            out.push_str(&format!(
                "<span class=\"om-sep\">.</span><span class=\"om-current\">{}</span>",
                escape(segment)
            ));
        } else {
            out.push_str(&format!(
                "<span class=\"om-sep\">.</span><a href=\"{}\">{}</a>",
                page_link(&prefix),
                escape(segment)
            ));
        }
    }
    out.push_str("</nav>");
    out
}


pub fn render_class(
    classes: &[ClassDoc],
    class: usize,
    children: &[&ClassDoc],
    graphics: &Graphics,
    child_icons: &[Option<String>],
    resolver: &Resolver,
    footer: &str,
) -> Page {
    let doc = &classes[class];
    let mut resources = Vec::new();
    let name = doc.qualified_name();
    let mut body = String::with_capacity(4096);

    body.push_str(&header(&breadcrumb(doc)));

    let icon = match &graphics.icon {
        Some(url) => format!(
            "<img class=\"om-icon\" src=\"{}\" alt=\"\" loading=\"lazy\">",
            uri_encode(url)
        ),
        None => String::new(),
    };
    body.push_str(&format!(
        "<div class=\"om-title\">{icon}<h1><span class=\"om-restriction\">{}</span>{}</h1></div>\n",
        escape(&doc.restriction),
        escape(doc.name())
    ));
    if !doc.comment.is_empty() {
        body.push_str(&format!(
            "<div class=\"om-summary\">{}</div>\n",
            resolver.rewrite(&description_html(&doc.comment), &mut resources)
        ));
    }
    if !doc.version.is_empty() {
        body.push_str(&format!(
            "<p class=\"om-version\">Version {}</p>\n",
            escape(&doc.version)
        ));
    }

    if let Some(diagram) = &graphics.diagram {
        body.push_str(&format!(
            "<div class=\"om-graphics\"><img class=\"om-diagram\" src=\"{}\" \
             alt=\"Diagram of {}\" loading=\"lazy\"></div>\n",
            uri_encode(diagram),
            escape(doc.name())
        ));
    }

    body.push_str(&extends_line(classes, doc));
    body.push_str(&derived_line(classes, doc));

    if !doc.info_header.is_empty() {
        body.push_str(&resolver.rewrite(&documentation_html(&doc.info_header), &mut resources));
    }
    if !doc.info.is_empty() {
        body.push_str("<section id=\"info\"><h2>Information</h2>\n");
        body.push_str(&resolver.rewrite(&documentation_html(&doc.info), &mut resources));
        body.push_str("</section>\n");
    }

    body.push_str(&derived_table(doc));
    body.push_str(&enumeration_table(doc));
    body.push_str(&member_tables(classes, class));

    if !children.is_empty() {
        body.push_str(
            "<section id=\"contents\"><h2>Contents</h2>\n<table class=\"om-contents\">\
             <thead><tr><th>Name</th><th>Description</th></tr></thead><tbody>\n",
        );
        for (child, icon) in children.iter().zip(child_icons) {
            let icon_tag = match icon {
                Some(path) => format!(
                    "<img class=\"om-icon-small\" src=\"{}\" alt=\"\" loading=\"lazy\">",
                    uri_encode(path)
                ),
                None => String::new(),
            };
            let badge = if child.protected {
                "<span class=\"om-badge\">protected</span>"
            } else {
                ""
            };
            body.push_str(&format!(
                "<tr><td class=\"om-name\">{}<a href=\"{}\">{}</a>{}</td><td>{}</td></tr>\n",
                icon_tag,
                page_link(&child.qualified_name()),
                escape(child.name()),
                badge,
                description_html(&child.comment)
            ));
        }
        body.push_str("</tbody></table></section>\n");
    }

    if !doc.revisions.is_empty() {
        body.push_str("<section id=\"revisions\"><h2>Revisions</h2>\n");
        body.push_str(&resolver.rewrite(&documentation_html(&doc.revisions), &mut resources));
        body.push_str("</section>\n");
    }

    body.push_str("</main>\n");
    body.push_str(footer);

    Page {
        file: format!("{}.html", file_stem(&name)),
        html: document(&name, doc.path[0].as_str(), &name, &body),
        resources,
    }
}

fn extends_line(classes: &[ClassDoc], doc: &ClassDoc) -> String {
    let mut parts = Vec::new();
    for extends in &doc.extends {
        let text = escape(&extends.path);
        let link = match extends.base {
            Some(base) => format!(
                "<a href=\"{}\">{text}</a>",
                page_link(&classes[base].qualified_name())
            ),
            None => text,
        };
        let comment = extends
            .base
            .map(|b| classes[b].comment.as_str())
            .unwrap_or_default();
        parts.push(if comment.is_empty() {
            link
        } else {
            format!("{link} ({})", description_html(comment))
        });
    }
    if parts.is_empty() {
        return String::new();
    }
    format!(
        "<p class=\"om-extends\">Extends from {}.</p>\n",
        parts.join(", ")
    )
}

/// `type Angle = Real` — the base of a short class definition, linked.
fn derived_line(classes: &[ClassDoc], doc: &ClassDoc) -> String {
    let Some(derived) = &doc.derived else {
        return String::new();
    };
    let text = escape(&derived.base);
    let base = match derived.base_class {
        Some(target) => format!(
            "<a href=\"{}\">{text}</a>",
            page_link(&classes[target].qualified_name())
        ),
        None => text,
    };
    format!(
        "<p class=\"om-extends\">A <code>{}</code> of {base}{}.</p>\n",
        escape(&doc.restriction),
        escape(&derived.dims)
    )
}

/// The attributes a short class definition fixes: `unit`, `displayUnit`,
/// `quantity`, `min`, and whatever else it modifies.
fn derived_table(doc: &ClassDoc) -> String {
    let Some(derived) = &doc.derived else {
        return String::new();
    };
    if derived.modifiers.is_empty() {
        return String::new();
    }
    let mut out = String::from(
        "<section id=\"attributes\"><h2>Attributes</h2>\n<table class=\"om-members\">\
         <thead><tr><th>Name</th><th>Value</th></tr></thead><tbody>\n",
    );
    for modifier in &derived.modifiers {
        out.push_str(&format!(
            "<tr><td class=\"om-name\">{}{}</td><td class=\"om-default\">{}</td></tr>\n",
            escape(&modifier.name),
            if modifier.is_final {
                " <span class=\"om-badge\">final</span>"
            } else {
                ""
            },
            escape(&modifier.value)
        ));
    }
    out.push_str("</tbody></table></section>\n");
    out
}

fn enumeration_table(doc: &ClassDoc) -> String {
    if doc.enumeration.is_empty() {
        return String::new();
    }
    let mut out = String::from(
        "<section id=\"literals\"><h2>Literals</h2>\n<table class=\"om-members\">\
         <thead><tr><th>Name</th><th>Description</th></tr></thead><tbody>\n",
    );
    for literal in &doc.enumeration {
        out.push_str(&format!(
            "<tr><td class=\"om-name\">{}</td><td>{}</td></tr>\n",
            escape(&literal.name),
            escape(&literal.description)
        ));
    }
    out.push_str("</tbody></table></section>\n");
    out
}

/// Parameters, connectors and components — or, for a function, its inputs and
/// outputs — including everything inherited.
fn member_tables(classes: &[ClassDoc], class: usize) -> String {
    let members = crate::doc::members(classes, class);
    let public: Vec<&Member<'_>> = members.iter().filter(|m| !m.component.protected).collect();
    let mut out = String::new();
    if classes[class].is_function {
        out.push_str(&member_table(
            classes,
            "Inputs",
            &public,
            |m| m.component.kind == Kind::Input,
            false,
        ));
        out.push_str(&member_table(
            classes,
            "Outputs",
            &public,
            |m| m.component.kind == Kind::Output,
            false,
        ));
        return out;
    }
    let is_parameter =
        |m: &Member<'_>| matches!(m.component.kind, Kind::Parameter | Kind::Constant);
    let is_connector = |m: &Member<'_>| {
        m.component
            .type_class
            .is_some_and(|t| classes[t].restriction.ends_with("connector"))
    };
    out.push_str(&member_table(classes, "Parameters", &public, is_parameter, true));
    out.push_str(&member_table(
        classes,
        "Connectors",
        &public,
        |m| !is_parameter(m) && is_connector(m),
        false,
    ));
    out.push_str(&member_table(
        classes,
        "Components",
        &public,
        |m| !is_parameter(m) && !is_connector(m),
        false,
    ));
    out
}

fn member_table(
    classes: &[ClassDoc],
    title: &str,
    members: &[&Member<'_>],
    keep: impl Fn(&Member<'_>) -> bool,
    grouped: bool,
) -> String {
    let mut rows: Vec<&&Member<'_>> = members.iter().filter(|m| keep(m)).collect();
    if rows.is_empty() {
        return String::new();
    }
    if grouped {
        // Ungrouped first, then each group in the order it first appears; a
        // stable sort keeps declaration order inside a group.
        let mut order: Vec<&str> = Vec::new();
        for member in &rows {
            let group = member.component.group.as_str();
            if !group.is_empty() && !order.contains(&group) {
                order.push(group);
            }
        }
        rows.sort_by_key(|m| {
            let group = m.component.group.as_str();
            if group.is_empty() {
                0
            } else {
                1 + order.iter().position(|g| *g == group).unwrap_or(0)
            }
        });
    }
    let anchor = title.to_ascii_lowercase();
    let mut out = format!(
        "<section id=\"{anchor}\"><h2>{title}</h2>\n<table class=\"om-members\">\
         <thead><tr><th>Type</th><th>Name</th><th>Default</th><th>Description</th></tr></thead>\
         <tbody>\n"
    );
    let mut group = "";
    for member in rows {
        let component = member.component;
        if grouped && component.group != group {
            group = &component.group;
            if !group.is_empty() {
                out.push_str(&format!(
                    "<tr class=\"om-group\"><td colspan=\"4\">{}</td></tr>\n",
                    escape(group)
                ));
            }
        }
        let type_text = escape(&component.type_path);
        let type_cell = match component.type_class {
            Some(target) => format!(
                "<a href=\"{}\">{type_text}</a>",
                page_link(&classes[target].qualified_name())
            ),
            None => type_text,
        };
        let from = match member.inherited_from {
            Some(base) => format!(
                " <a class=\"om-from\" href=\"{}\" title=\"Inherited from {}\">(from {})</a>",
                page_link(&classes[base].qualified_name()),
                escape(&classes[base].qualified_name()),
                escape(classes[base].name())
            ),
            None => String::new(),
        };
        out.push_str(&format!(
            "<tr><td class=\"om-type\">{type_cell}{}</td><td class=\"om-name\">{}{from}</td>\
             <td class=\"om-default\">{}</td><td>{}</td></tr>\n",
            escape(&component.dims),
            escape(&component.name),
            escape(&component.default),
            escape(&component.description)
        ));
    }
    out.push_str("</tbody></table></section>\n");
    out
}

pub struct LibraryEntry<'a> {
    pub doc: &'a ClassDoc,
    pub icon: Option<String>,
    pub source: Option<String>,
}

pub fn render_index(libraries: &[LibraryEntry<'_>], footer: &str) -> String {
    let mut body = String::with_capacity(8192);
    body.push_str(&header(
        "<nav class=\"om-crumbs\"><span class=\"om-current\">Libraries</span></nav>",
    ));
    body.push_str("<h1>Modelica Library Documentation</h1>\n");
    body.push_str(
        "<p class=\"om-summary\">Generated from the Modelica libraries OpenModelica ships and \
         the ones in its <a href=\"https://github.com/OpenModelica/OpenModelicaLibraries\">package \
         index</a>. Not every library is supported or tested; report library problems to the \
         library's own project and compiler problems to \
         <a href=\"https://github.com/OpenModelica/OpenModelica/issues\">OpenModelica</a>.</p>\n",
    );
    body.push_str(
        "<table class=\"om-contents\"><thead><tr><th>Library</th><th>Description</th>\
         <th>Version</th><th>Source</th></tr></thead><tbody>\n",
    );
    for entry in libraries {
        let icon_tag = match &entry.icon {
            Some(path) => format!(
                "<img class=\"om-icon-small\" src=\"{}\" alt=\"\" loading=\"lazy\">",
                uri_encode(path)
            ),
            None => String::new(),
        };
        let source = match &entry.source {
            Some(url) => format!(
                "<a href=\"{}\" rel=\"noreferrer\">{}</a>",
                escape(url),
                source_mark(source_host(url))
            ),
            None => String::new(),
        };
        body.push_str(&format!(
            "<tr><td class=\"om-name\">{}<a href=\"{}\">{}</a></td><td>{}</td><td>{}</td>\
             <td class=\"om-source\">{source}</td></tr>\n",
            icon_tag,
            page_link(&entry.doc.qualified_name()),
            escape(entry.doc.name()),
            description_html(&entry.doc.comment),
            escape(&entry.doc.version)
        ));
    }
    body.push_str("</tbody></table>\n</main>\n");
    body.push_str(footer);
    document("Modelica Library Documentation", "", "", &body)
}

fn source_host(url: &str) -> &str {
    url.split_once("://")
        .map_or(url, |(_, rest)| rest)
        .split('/')
        .next()
        .unwrap_or(url)
}

/// The forge's own mark where we know it, a generic link glyph otherwise.
/// Inline SVG has no `alt`; `role="img"` plus a `<title>` is its equivalent, and
/// it names the link for a screen reader as well as being the hover tooltip.
fn source_mark(host: &str) -> String {
    const GITHUB: (&str, &str) = ("GitHub", r##"<path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.01 8.01 0 0 0 16 8c0-4.42-3.58-8-8-8Z"/>"##);
    const GITLAB: (&str, &str) = ("GitLab", r##"<path d="m23.6 9.6-.03-.08-3.26-8.5a.85.85 0 0 0-.34-.4.88.88 0 0 0-1 .05.88.88 0 0 0-.29.45l-2.2 6.73H7.52L5.32 1.12a.86.86 0 0 0-.3-.44.88.88 0 0 0-1-.06.86.86 0 0 0-.33.4L.42 9.52l-.03.08a6.05 6.05 0 0 0 2 7l.01.01.03.02 4.96 3.71 2.45 1.86 1.5 1.13a1.02 1.02 0 0 0 1.23 0l1.5-1.13 2.45-1.86 5-3.73.01-.01a6.05 6.05 0 0 0 2-7Z"/>"##);
    const LINK: (&str, &str) = ("", r##"<path fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/>"##);

    let (forge, path, box_size) = if host == "github.com" || host.ends_with(".github.com") {
        (GITHUB.0, GITHUB.1, 16)
    } else if host.contains("gitlab") {
        (GITLAB.0, GITLAB.1, 24)
    } else {
        (LINK.0, LINK.1, 24)
    };
    let label = if forge.is_empty() {
        format!("Source repository on {host}")
    } else {
        format!("{forge} repository ({host})")
    };
    format!(
        "<svg class=\"om-mark\" viewBox=\"0 0 {box_size} {box_size}\" role=\"img\" \
         fill=\"currentColor\"><title>{}</title>{path}</svg>",
        escape(&label)
    )
}

fn header(crumbs: &str) -> String {
    format!(
        "<header class=\"om-header\">\
         <button type=\"button\" id=\"om-sidebar-toggle\" class=\"om-iconbutton\" \
         aria-label=\"Show the library browser\" title=\"Library browser\">\u{2630}</button>\
         {crumbs}\
         <button type=\"button\" id=\"om-theme\" class=\"om-iconbutton\" \
         aria-label=\"Theme\">\u{263C}</button>\
         </header>\n<main id=\"om-main\">\n"
    )
}

/// Light unless the reader chose otherwise: much of the documentation embeds
/// images drawn for a white page. Applied before first paint so no page flashes
/// the wrong theme.
const THEME_BOOTSTRAP: &str = "<script>\
    (()=>{try{const t=localStorage.getItem('omdoc-theme');\
    if(t!=='auto')document.documentElement.setAttribute('data-theme',t==='dark'?'dark':'light');}\
    catch(e){document.documentElement.setAttribute('data-theme','light');}})();\
    </script>";

const SIDEBAR: &str = "<aside class=\"om-sidebar\" id=\"om-sidebar\">\
    <a class=\"om-brand\" href=\"index.html\">Modelica Documentation</a>\
    <input type=\"search\" id=\"om-q\" class=\"om-search\" autocomplete=\"off\" \
    spellcheck=\"false\" placeholder=\"Search classes and text\" \
    aria-label=\"Search classes and documentation text\" disabled>\
    <nav class=\"om-nav\" id=\"om-nav\"><p class=\"om-loading\">loading\u{2026}</p></nav>\
    </aside>";

fn document(title: &str, library: &str, class: &str, body: &str) -> String {
    format!(
        "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n\
         <meta charset=\"utf-8\">\n\
         <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n\
         <title>{title}</title>\n\
         <link rel=\"stylesheet\" href=\"style.css\">\n\
         {THEME_BOOTSTRAP}\n\
         </head>\n<body data-library=\"{library}\" data-class=\"{class}\">\n\
         <div class=\"om-shell\">{SIDEBAR}<div class=\"om-content\">\n\
         {body}</div></div>\n\
         <script src=\"index/aliases.js\" defer></script>\n\
         <script src=\"assets/gendoc.js\" defer></script>\n\
         </body>\n</html>\n",
        title = escape(title),
        library = escape(library),
        class = escape(class)
    )
}
