//! `modelica://` URI rewriting, replacing the old Tidy.py/BeautifulSoup pass.

use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::sync::OnceLock;

pub struct Resource {
    pub source: PathBuf,
    pub target: String,
}

/// `(version tag, name)`. A `modelica://` URI names a class in every copy of
/// its library; the one a document means is its own, falling back to the
/// untagged copy for a library documented only once.
type Key = (String, String);

#[derive(Default)]
pub struct Resolver {
    /// (version tag, qualified class name) -> the directory its source file
    /// lives in. Doubles as the set of classes that have a generated page.
    class_dir: HashMap<Key, PathBuf>,
    /// (version tag, top-level class name) -> the library root directory.
    library_root: HashMap<Key, PathBuf>,
}

impl Resolver {
    pub fn add_class(&mut self, tag: &str, qualified_name: &str, source_file: &str) {
        let dir = Path::new(source_file).parent().unwrap_or(Path::new(""));
        self.class_dir
            .insert((tag.to_string(), qualified_name.to_string()), dir.to_path_buf());
        if !qualified_name.contains('.') {
            self.library_root
                .insert((tag.to_string(), qualified_name.to_string()), dir.to_path_buf());
        }
    }

    fn lookup<'a>(
        table: &'a HashMap<Key, PathBuf>,
        tag: &str,
        name: &str,
    ) -> Option<&'a PathBuf> {
        table
            .get(&(tag.to_string(), name.to_string()))
            .or_else(|| table.get(&(String::new(), name.to_string())))
    }

    /// The page a class name leads to from a document tagged `tag`.
    fn page_of(&self, tag: &str, name: &str) -> Option<String> {
        let own = !tag.is_empty() && self.class_dir.contains_key(&(tag.to_string(), name.to_string()));
        let tagged = match (own, name.split_once('.')) {
            (false, _) => name.to_string(),
            (true, Some((library, rest))) => format!("{library}@{tag}.{rest}"),
            (true, None) => format!("{name}@{tag}"),
        };
        Self::lookup(&self.class_dir, tag, name)
            .map(|_| format!("{}.html", uri_encode(&file_stem(&tagged))))
    }

    /// Every `modelica://` URI in `html`, resolved from the `tag` copy of the
    /// library. `prefix` joins the resolved relative URL to it, for a document
    /// that is not at the output root.
    pub fn rewrite_in(
        &self,
        tag: &str,
        prefix: &str,
        html: &str,
        resources: &mut Vec<Resource>,
    ) -> String {
        let mut out = String::with_capacity(html.len());
        let mut rest = html;
        while let Some(start) = find_scheme(rest) {
            out.push_str(&rest[..start]);
            let tail = &rest[start + SCHEME.len()..];
            // `&` ends it too: documentation strings that mention the scheme in
            // escaped markup would otherwise swallow the `&quot;` after it.
            let end = tail
                .find(|c: char| c.is_whitespace() || matches!(c, '"' | '\'' | '>' | '&' | '\\'))
                .unwrap_or(tail.len());
            let url = self.resolve(tag, &tail[..end], resources);
            if !url.starts_with(SCHEME) {
                out.push_str(prefix);
            }
            out.push_str(&url);
            rest = &tail[end..];
        }
        out.push_str(rest);
        out
    }

    /// A URI that names neither a class we generated a page for nor a file that
    /// exists is left as it was: the documentation is discussing the scheme,
    /// not linking with it.
    fn resolve(&self, tag: &str, uri: &str, resources: &mut Vec<Resource>) -> String {
        let (target, anchor) = match uri.split_once('#') {
            Some((u, a)) => (u, Some(a)),
            None => (uri, None),
        };
        let resolved = match target.split_once('/') {
            Some((class, file)) => self.resolve_file(tag, class, file, resources),
            None => self.page_of(tag, target),
        };
        match (resolved, anchor) {
            (Some(page), Some(anchor)) => format!("{page}#{anchor}"),
            (Some(page), None) => page,
            (None, _) => format!("{SCHEME}{uri}"),
        }
    }

    /// The file a `modelica://Lib.Sub/Resources/x.png` URI names.
    fn source_file(&self, tag: &str, class: &str, file: &str) -> Option<PathBuf> {
        let file = percent_decode(file);
        let mut dir = Self::lookup(&self.class_dir, tag, class);
        if dir.is_none() {
            // The class may be declared inside a package.mo, in which case the
            // enclosing package's directory is the one the URI resolves against.
            dir = class
                .rsplit_once('.')
                .and_then(|(p, _)| Self::lookup(&self.class_dir, tag, p));
        }
        let source = dir?.join(&file);
        source.is_file().then_some(source)
    }

    /// `modelica://Lib.Sub/Resources/x.png` -> `resources/Lib/Sub/Resources/x.png`.
    fn resolve_file(
        &self,
        tag: &str,
        class: &str,
        file: &str,
        resources: &mut Vec<Resource>,
    ) -> Option<String> {
        let source = self.source_file(tag, class, file)?;
        let library = class.split('.').next()?;
        let root = Self::lookup(&self.library_root, tag, library)?;
        let relative = source.strip_prefix(root).ok()?;
        let target = format!(
            "resources/{library}/{}",
            relative.to_string_lossy().replace('\\', "/")
        );
        let encoded = uri_encode(&target);
        resources.push(Resource { source, target });
        Some(encoded)
    }
}

impl Resolver {
    /// Replace every `modelica://` URI in an SVG with the file's bytes as a
    /// `data:` URI. A linked file cannot be used here: a browser renders an SVG
    /// loaded through `<img>` in secure static mode, where external references
    /// are never fetched, so the bitmap silently does not appear — on the class
    /// page and in the sidebar alike. Embedding costs nothing in practice,
    /// since a Bitmap in an icon is rare and the icon store is content
    /// addressed, so one logo is stored once however many classes show it.
    pub fn inline_uris(&self, svg: &str) -> String {
        let mut out = String::with_capacity(svg.len());
        let mut rest = svg;
        while let Some(start) = find_scheme(rest) {
            out.push_str(&rest[..start]);
            let tail = &rest[start + SCHEME.len()..];
            let end = tail
                .find(|c: char| c.is_whitespace() || matches!(c, '"' | '\'' | '>' | '&' | '\\'))
                .unwrap_or(tail.len());
            let uri = &tail[..end];
            match uri
                .split_once('/')
                .and_then(|(class, file)| self.source_file("", class, file))
                .and_then(|path| std::fs::read(&path).ok().map(|bytes| (path, bytes)))
            {
                Some((path, bytes)) => {
                    out.push_str("data:");
                    out.push_str(media_type(&path));
                    out.push_str(";base64,");
                    base64_into(&bytes, &mut out);
                }
                None => {
                    out.push_str(SCHEME);
                    out.push_str(uri);
                }
            }
            rest = &tail[end..];
        }
        out.push_str(rest);
        out
    }
}

fn media_type(path: &Path) -> &'static str {
    match path
        .extension()
        .map(|e| e.to_string_lossy().to_ascii_lowercase())
        .as_deref()
    {
        Some("jpg" | "jpeg") => "image/jpeg",
        Some("gif") => "image/gif",
        Some("svg") => "image/svg+xml",
        Some("bmp") => "image/bmp",
        Some("webp") => "image/webp",
        _ => "image/png",
    }
}

fn base64_into(bytes: &[u8], out: &mut String) {
    const ALPHABET: &[u8; 64] =
        b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    for chunk in bytes.chunks(3) {
        let b = [chunk[0], *chunk.get(1).unwrap_or(&0), *chunk.get(2).unwrap_or(&0)];
        let n = ((b[0] as u32) << 16) | ((b[1] as u32) << 8) | b[2] as u32;
        out.push(ALPHABET[(n >> 18) as usize & 63] as char);
        out.push(ALPHABET[(n >> 12) as usize & 63] as char);
        out.push(if chunk.len() > 1 { ALPHABET[(n >> 6) as usize & 63] as char } else { '=' });
        out.push(if chunk.len() > 2 { ALPHABET[n as usize & 63] as char } else { '=' });
    }
}

const SCHEME: &str = "modelica://";

fn find_scheme(haystack: &str) -> Option<usize> {
    let bytes = haystack.as_bytes();
    let scheme = SCHEME.as_bytes();
    bytes
        .windows(scheme.len())
        .position(|w| w.eq_ignore_ascii_case(scheme))
}

/// The same replacements the old GenerateDoc.mos used, so existing links to
/// generated pages keep working.
pub fn plain_stem(class: &str) -> String {
    class
        .replace('/', "Division")
        .replace('*', "Multiplication")
        .replace('<', "x3C")
        .replace('>', "x3E")
}

/// `plain_stem`, except where two classes differ only in case -- both
/// `Spice3.Internal.Diode` and `.DIODE` exist, and the .zip is unpacked where
/// that is one file. All but the first get a number before the extension,
/// which no class can have: an identifier cannot start with a digit.
pub fn file_stem(class: &str) -> String {
    match aliases().get(class) {
        Some(stem) => stem.clone(),
        None => plain_stem(class),
    }
}

/// Fixed before anything renders, so a link is the same wherever it is built
/// -- the sidebar script gets the same map.
pub fn resolve_aliases(names: impl IntoIterator<Item = String>) {
    let mut groups: HashMap<String, Vec<String>> = HashMap::new();
    for name in names {
        groups
            .entry(plain_stem(&name).to_lowercase())
            .or_default()
            .push(name);
    }
    let mut aliases = HashMap::new();
    for group in groups.into_values() {
        if group.len() < 2 {
            continue;
        }
        let mut group = group;
        group.sort();
        for (i, name) in group.iter().enumerate().skip(1) {
            aliases.insert(name.clone(), format!("{}.{}", plain_stem(name), i + 1));
        }
    }
    let _ = ALIASES.set(aliases);
}

pub fn aliases() -> &'static HashMap<String, String> {
    ALIASES.get_or_init(HashMap::new)
}

static ALIASES: OnceLock<HashMap<String, String>> = OnceLock::new();

/// Percent-encoding for a query value: `+` in a version is a space otherwise.
pub fn query_encode(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    for byte in s.bytes() {
        match byte {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'.' | b'_' | b'~' => {
                out.push(byte as char)
            }
            _ => out.push_str(&format!("%{byte:02X}")),
        }
    }
    out
}

pub fn uri_encode(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    for ch in s.chars() {
        match ch {
            ' ' => out.push_str("%20"),
            '\'' => out.push_str("%27"),
            '"' => out.push_str("%22"),
            '<' => out.push_str("%3C"),
            '>' => out.push_str("%3E"),
            _ => out.push(ch),
        }
    }
    out
}

fn percent_decode(s: &str) -> String {
    let bytes = s.as_bytes();
    let mut out = Vec::with_capacity(bytes.len());
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b'%' && i + 2 < bytes.len() {
            if let Ok(b) = u8::from_str_radix(&s[i + 1..i + 3], 16) {
                out.push(b);
                i += 3;
                continue;
            }
        }
        out.push(bytes[i]);
        i += 1;
    }
    String::from_utf8_lossy(&out).into_owned()
}
