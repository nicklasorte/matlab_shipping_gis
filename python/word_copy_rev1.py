"""Build the Word copy of the working paper from a Docs export.

The Docs export (docx, pictures "fit") leaves large figures as "[image: <alt>]"
placeholder paragraphs. This script:
  1. puts each figure back, taken from the previous Word copy by matching alt text
     (the docPr descr attribute), at 6.5 in wide;
  2. marks every page DRAFT//PRE-DECISIONAL in the header and the footer, with a
     page number in the footer;
  3. gives every figure and table caption the Caption style and turns its number
     into a SEQ field, so Word can build a list of figures and tables (review CB-73).

Usage: python3 python/word_copy_rev1.py <export.docx> <previous.docx> <out.docx>
"""
import copy
import io
import os
import re
import sys

from docx import Document
from docx.enum.style import WD_STYLE_TYPE
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor

MARK = "DRAFT//PRE-DECISIONAL"
PLACEHOLDER = re.compile(r"^\[image: (.*)\]$")
CAPTION = re.compile(r"^(Figure|Table) (A-)?(\d+)([a-z]?)\. ")


def norm(s):
    return re.sub(r"[\s–—-]+", " ", s).strip().lower()


def previous_images(path):
    """alt text -> image bytes, from the previous Word copy."""
    doc = Document(path)
    out = {}
    for shape in doc.inline_shapes:
        inline = shape._inline
        descr = inline.docPr.get("descr") or ""
        blip = inline.xpath(".//a:blip")[0]
        rid = blip.get(qn("r:embed"))
        out[norm(descr)] = doc.part.related_parts[rid].blob
    return out


def put_images(doc, images):
    missing = []
    for p in doc.paragraphs:
        m = PLACEHOLDER.match(p.text.strip())
        if not m:
            continue
        alt = m.group(1)
        blob = images.get(norm(alt))
        if blob is None:
            # Alt texts edited since the last copy: fall back to the longest shared prefix.
            # Refuse ties (sibling figures share long prefixes) and log every fallback.
            score = {k: len(os.path.commonprefix([k, norm(alt)])) for k in images}
            best = max(score.values())
            keys = [k for k, v in score.items() if v == best]
            if best < 40 or len(keys) > 1:
                missing.append(alt[:80])
                continue
            print(f"fallback match ({best} chars): {alt[:60]!r} -> {keys[0][:60]!r}")
            blob = images[keys[0]]
        for r in list(p.runs):
            r._r.getparent().remove(r._r)
        run = p.add_run()
        pic = run.add_picture(io.BytesIO(blob), width=Inches(6.5))
        pic._inline.docPr.set("descr", alt)
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    return missing


def mark_section(sec):
    for part, page in ((sec.header, False), (sec.footer, True)):
        part.is_linked_to_previous = False
        p = part.paragraphs[0] if part.paragraphs else part.add_paragraph()
        p.text = ""
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = p.add_run(MARK)
        r.bold = True
        r.font.size = Pt(10)
        r.font.color.rgb = RGBColor(0x16, 0x33, 0x53)
        if page:
            p.add_run("    Page ")
            field(p, "PAGE", "1")


def field(p, instr, result):
    """Append a simple field (PAGE, SEQ ...) with a cached result to paragraph p."""
    def r_with(child):
        r = OxmlElement("w:r")
        r.append(child)
        p._p.append(r)
        return r
    b = OxmlElement("w:fldChar"); b.set(qn("w:fldCharType"), "begin"); r_with(b)
    t = OxmlElement("w:instrText"); t.set(qn("xml:space"), "preserve"); t.text = f" {instr} "; r_with(t)
    s = OxmlElement("w:fldChar"); s.set(qn("w:fldCharType"), "separate"); r_with(s)
    v = OxmlElement("w:t"); v.text = result; rr = r_with(v)
    e = OxmlElement("w:fldChar"); e.set(qn("w:fldCharType"), "end"); r_with(e)
    return rr


def caption_style(doc):
    """Word's built-in Caption style, added if the export lacks it."""
    try:
        return doc.styles["Caption"]
    except KeyError:
        st = doc.styles.add_style("Caption", WD_STYLE_TYPE.PARAGRAPH)
        st.base_style = doc.styles["Normal"]
        st.quick_style = True
        st.font.size = Pt(10)
        st.font.color.rgb = RGBColor(0x16, 0x33, 0x53)
        st.paragraph_format.space_after = Pt(10)
        return st


def captions(doc):
    """Caption style plus a SEQ field for the number in every figure and table caption."""
    n = 0
    style = caption_style(doc)
    for p in doc.paragraphs:
        m = CAPTION.match(p.text)
        if not m or not p.runs:
            continue
        kind, app, num, suffix = m.groups()
        first = p.runs[0]
        if suffix and suffix != "a":
            # A-4b, A-4c: Caption style only; a SEQ field would renumber them on update
            # (A-4a carries the SEQ field for the group).
            p.style = style
            n += 1
            continue
        if not first.text.startswith(f"{kind} {app or ''}{num}"):
            continue          # number split across runs: keep the text as is
        bold = first.bold
        rest = first.text[len(f"{kind} {app or ''}{num}"):]
        first.text = f"{kind} {app or ''}"
        seq_name = kind + ("_A" if app else "")
        # Insert the field runs right after the first run, then the rest of its text.
        tail = list(p._p)[list(p._p).index(first._r) + 1:]
        for el in tail:
            p._p.remove(el)
        field(p, f"SEQ {seq_name} \\* ARABIC", num)
        for r in p._p.findall(qn("w:r"))[-5:]:
            if bold:
                rpr = r.get_or_add_rPr()
                rpr.append(OxmlElement("w:b"))
        after = copy.deepcopy(first._r)
        after.find(qn("w:t")).text = rest
        after.find(qn("w:t")).set(qn("xml:space"), "preserve")
        p._p.append(after)
        for el in tail:
            p._p.append(el)
        p.style = style
        n += 1
    return n


def main(export, previous, out):
    doc = Document(export)
    missing = put_images(doc, previous_images(previous))
    for sec in doc.sections:
        mark_section(sec)
    n = captions(doc)
    doc.save(out)
    print(f"captions with SEQ fields: {n}; images missing: {len(missing)}")
    for m in missing:
        print("  missing:", m)


if __name__ == "__main__":
    main(*sys.argv[1:4])
