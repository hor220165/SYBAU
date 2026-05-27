from __future__ import annotations

import copy
import re
import shutil
import tempfile
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET


SOURCE = Path("/Users/david/Desktop/4BHIF/PRE/Abschlussbericht_SYBAU.pptx")
OUT = Path("/Users/david/SYBAU/document_output/Projektabschlussbericht_SYBAU_Praesentation_fixed.pptx")

P_NS = "http://schemas.openxmlformats.org/presentationml/2006/main"
A_NS = "http://schemas.openxmlformats.org/drawingml/2006/main"
R_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
PKG_REL_NS = "http://schemas.openxmlformats.org/package/2006/relationships"
CT_NS = "http://schemas.openxmlformats.org/package/2006/content-types"

ET.register_namespace("p", P_NS)
ET.register_namespace("a", A_NS)
ET.register_namespace("r", R_NS)
ET.register_namespace("", PKG_REL_NS)


SLIDE_MAP = [1, 2, 2, 2, 3, 4, 5, 7, 6, 4, 5, 8]


def ns(tag: str, namespace: str) -> str:
    return f"{{{namespace}}}{tag}"


def parse(path: Path) -> ET.ElementTree:
    return ET.parse(path)


def write_xml(tree: ET.ElementTree, path: Path) -> None:
    tree.write(path, encoding="UTF-8", xml_declaration=True)


def shape_by_id(root: ET.Element, shape_id: int) -> ET.Element | None:
    for sp in root.findall(f".//{ns('sp', P_NS)}"):
        c_nv_pr = sp.find(f".//{ns('cNvPr', P_NS)}")
        if c_nv_pr is not None and c_nv_pr.get("id") == str(shape_id):
            return sp
    return None


def set_shape_text(root: ET.Element, shape_id: int, text: str) -> None:
    sp = shape_by_id(root, shape_id)
    if sp is None:
        return
    tx_body = sp.find(ns("txBody", P_NS))
    if tx_body is None:
        return
    paragraphs = tx_body.findall(ns("p", A_NS))
    if not paragraphs:
        return

    first = paragraphs[0]
    first_r = first.find(ns("r", A_NS))
    if first_r is None:
        first_r = ET.SubElement(first, ns("r", A_NS))
    first_t = first_r.find(ns("t", A_NS))
    if first_t is None:
        first_t = ET.SubElement(first_r, ns("t", A_NS))
    first_t.text = text

    for r in list(first.findall(ns("r", A_NS)))[1:]:
        first.remove(r)
    for p in paragraphs[1:]:
        tx_body.remove(p)


def set_counter(root: ET.Element) -> None:
    set_shape_text(root, 8, "/12")


def table_cells(root: ET.Element) -> list[ET.Element]:
    return root.findall(f".//{ns('tbl', A_NS)}/{ns('tr', A_NS)}/{ns('tc', A_NS)}")


def set_cell_text(cell: ET.Element, text: str) -> None:
    tx_body = cell.find(ns("txBody", A_NS))
    if tx_body is None:
        tx_body = ET.SubElement(cell, ns("txBody", A_NS))
    paragraphs = tx_body.findall(ns("p", A_NS))
    if not paragraphs:
        p = ET.SubElement(tx_body, ns("p", A_NS))
    else:
        p = paragraphs[0]
        for extra in paragraphs[1:]:
            tx_body.remove(extra)

    for child in list(p):
        if child.tag != ns("pPr", A_NS):
            p.remove(child)
    r = ET.SubElement(p, ns("r", A_NS))
    t = ET.SubElement(r, ns("t", A_NS))
    t.text = text


def set_table(root: ET.Element, values: list[list[str]]) -> None:
    cells = table_cells(root)
    flat = [value for row in values for value in row]
    for cell, value in zip(cells, flat):
        set_cell_text(cell, value)


def remove_notes_relationships(rels_path: Path) -> None:
    if not rels_path.exists():
        return
    tree = parse(rels_path)
    root = tree.getroot()
    for rel in list(root):
        if rel.get("Type", "").endswith("/notesSlide"):
            root.remove(rel)
    write_xml(tree, rels_path)


def edit_slide(slide_no: int, root: ET.Element) -> None:
    set_counter(root)

    if slide_no == 1:
        set_shape_text(root, 4, "SYBAU")
        set_shape_text(root, 6, "David Novakovic | Viktor Horvath | Bakir Duric | David Pfeiffer")
        set_shape_text(root, 7, "Projektabschlusspräsentation | 26.05.2026")
    elif slide_no == 2:
        set_shape_text(root, 3, "Projektidee")
        set_shape_text(
            root,
            10,
            "SYBAU verbindet Workout-Tracking mit Gamification. Nutzer tragen Übungen ein, sammeln XP und Coins, schließen Quests ab und entwickeln ihren Avatar weiter.\n\nZiel ist es, Training sichtbarer, motivierender und vergleichbarer zu machen.",
        )
    elif slide_no == 3:
        set_shape_text(root, 3, "Ziele")
        set_shape_text(
            root,
            10,
            "Geplant war eine Web-App mit Backend, Datenbank und Gamification-Kern: Login, Workouts, XP/Level, Avatar, Challenges und Deployment.\n\nIm Projektverlauf wurde der Umfang erweitert, unter anderem durch Shop, Chests, Freunde, Leaderboard und eine vollständige Mobile-App.",
        )
    elif slide_no == 4:
        set_shape_text(root, 3, "Technik")
        set_shape_text(
            root,
            10,
            "Website: Vue 3, TypeScript und Vite, bereitgestellt über Vercel.\n\nBackend: ASP.NET Core / C# mit Entity Framework Core, bereitgestellt über Render.\n\nDatenbank: Neon Free PostgreSQL.\n\nMobile-App: Flutter/Dart mit derselben API und denselben Kontodaten.",
        )
    elif slide_no == 5:
        values = {
            3: "Website-Funktionen",
            10: "Kernbereiche",
            11: "Final umgesetzt",
            4: "Login &\nRegistrierung",
            5: "Dashboard",
            6: "Workouts",
            7: "Quests",
            24: "Shop &\nChests",
            19: "Avatar",
            25: "Profil",
            16: "Erfolge",
            17: "Freunde",
            21: "Leaderboard",
            22: "Admin",
            27: "Rechtliches",
            23: "100%\nFertig\n(Website)",
        }
        for key, value in values.items():
            set_shape_text(root, key, value)
    elif slide_no == 6:
        values = {
            3: "Mobile-App",
            10: "Zusatzumfang",
            11: "Umgesetzt",
            4: "Gleicher\nLogin",
            5: "Dashboard",
            6: "Workouts",
            7: "Quests",
            25: "Profil",
            20: "Health-\nSync",
            24: "Shop",
            16: "Freunde",
            17: "Leaderboard",
            18: "Avatar",
            19: "iOS Build",
            21: "Gemeinsame\nAPI",
            23: "Mobile\nfertig",
            27: "Flutter\nApp",
            22: "App\nfertig",
        }
        for key, value in values.items():
            set_shape_text(root, key, value)
    elif slide_no == 7:
        set_shape_text(root, 3, "Soll-Ist-Vergleich")
        set_table(
            root,
            [
                ["MS", "Soll", "Ist", "Status", "+/-", "Kurz"],
                ["DB", "01.02.26", "01.02.26", "Erfüllt", "0", "Grundlage"],
                ["XP/Level", "15.03.26", "20.05.26", "Erfüllt", "+", "balanciert"],
                ["Avatar", "21.03.26", "20.05.26", "Erfüllt", "+", "integriert"],
                ["Quests", "01.04.26", "25.05.26", "Erfüllt", "+", "fertig"],
                ["Release", "06.05.26", "23.05.26", "Erfüllt", "+", "Vercel/Render"],
            ],
        )
        set_shape_text(root, 18, "Kernumfang erfüllt | Mobile-App als Zusatzumfang | Zahlungssystem vorbereitet")
    elif slide_no == 8:
        values = {
            3: "Zeitaufwand",
            10: "Viktor Horvath",
            5: "David Novakovic",
            6: "Bakir Duric",
            7: "David Pfeiffer",
            19: "95,1 h",
            16: "146,7 h",
            17: "120,1 h",
            18: "109,0 h",
            4: "20%",
            11: "31%",
            12: "26%",
            14: "23%",
            20: "~471/400 h.",
            22: "118%",
            25: "Gesamt",
        }
        for key, value in values.items():
            set_shape_text(root, key, value)
    elif slide_no == 9:
        set_shape_text(root, 3, "Finaler Status")
        set_shape_text(root, 7, "100%\nfertig.")
        set_shape_text(root, 5, "Geplanter Kernumfang")
        set_shape_text(root, 4, "App\nfertig.")
        set_shape_text(root, 10, "Zusatzumfang")
    elif slide_no == 10:
        values = {
            3: "Lessons Learned",
            10: "Gut funktioniert",
            11: "Herausforderungen",
            4: "Gemeinsame\nAPI",
            5: "Feedback\nschnell umgesetzt",
            6: "Gamification\nmotiviert",
            7: "Web & Mobile\nverbunden",
            25: "Klare\nAufteilung",
            20: "Tests vor\nAbgabe",
            24: "Hosting-\nWechsel",
            16: "Responsive\nDetails",
            17: "Scope\ngewachsen",
            18: "Zeitdruck am\nEnde",
            19: "Datenschutz\nspät ergänzt",
            21: "iOS Signing",
            23: "Früher\nprüfen",
            27: "Kleiner\nplanen",
            22: "Früh\ntesten",
        }
        for key, value in values.items():
            set_shape_text(root, key, value)
    elif slide_no == 11:
        set_shape_text(root, 3, "Live-Demo")
        set_table(
            root,
            [
                ["Schritt", "Bereich", "Was wird gezeigt", "Ziel", "Hinweis", "Status"],
                ["1", "Landing/Login", "Startseite und Anmeldung", "Einstieg", "Web", "Demo"],
                ["2", "Dashboard", "XP, Coins, Avatar", "Fortschritt", "Web", "Demo"],
                ["3", "Workouts", "Übung eintragen", "Belohnung", "Web", "Demo"],
                ["4", "Quests/Shop", "Timer, Coins, Chest", "Motivation", "Web", "Demo"],
                ["5", "Mobile-App", "gleicher Account", "Zusatzumfang", "iPhone", "Demo"],
            ],
        )
        set_shape_text(root, 18, "Ablauf: Website zuerst, danach kurzer Einblick in die Mobile-App.")
    elif slide_no == 12:
        set_shape_text(root, 4, "Projektziel erreicht")
        set_shape_text(root, 6, "Website + Backend + Datenbank + Mobile-App")
        set_shape_text(root, 7, "SYBAU ist präsentationsbereit")


def update_presentation_xml(root_dir: Path) -> None:
    path = root_dir / "ppt/presentation.xml"
    tree = parse(path)
    root = tree.getroot()
    sld_id_lst = root.find(ns("sldIdLst", P_NS))
    if sld_id_lst is None:
        sld_id_lst = ET.SubElement(root, ns("sldIdLst", P_NS))
    for child in list(sld_id_lst):
        sld_id_lst.remove(child)
    for index in range(12):
        sld_id = ET.SubElement(sld_id_lst, ns("sldId", P_NS))
        sld_id.set("id", str(256 + index))
        sld_id.set(ns("id", R_NS), f"rIdSlide{index + 1}")
    write_xml(tree, path)


def update_presentation_rels(root_dir: Path) -> None:
    path = root_dir / "ppt/_rels/presentation.xml.rels"
    tree = parse(path)
    root = tree.getroot()
    for rel in list(root):
        if rel.get("Type", "").endswith("/slide"):
            root.remove(rel)
    for index in range(12):
        rel = ET.SubElement(root, ns("Relationship", PKG_REL_NS))
        rel.set("Id", f"rIdSlide{index + 1}")
        rel.set("Type", "http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide")
        rel.set("Target", f"slides/slide{index + 1}.xml")
    write_xml(tree, path)


def update_content_types(root_dir: Path) -> None:
    path = root_dir / "[Content_Types].xml"
    text = path.read_text(encoding="utf-8")
    text = re.sub(
        r'<Override PartName="/ppt/slides/slide\d+\.xml" ContentType="application/vnd\.openxmlformats-officedocument\.presentationml\.slide\+xml"\s*/>',
        "",
        text,
    )
    overrides = "".join(
        f'<Override PartName="/ppt/slides/slide{index}.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>'
        for index in range(1, 13)
    )
    text = text.replace("</Types>", f"{overrides}</Types>")
    path.write_text(text, encoding="utf-8")


def update_app_props(root_dir: Path) -> None:
    path = root_dir / "docProps/app.xml"
    if not path.exists():
        return
    tree = parse(path)
    root = tree.getroot()
    for elem in root.iter():
        if elem.tag.endswith("Slides"):
            elem.text = "12"
    write_xml(tree, path)


def build() -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        root_dir = Path(tmp) / "pptx"
        with zipfile.ZipFile(SOURCE, "r") as zin:
            zin.extractall(root_dir)

        slide_dir = root_dir / "ppt/slides"
        rel_dir = slide_dir / "_rels"
        original_slides = {i: (slide_dir / f"slide{i}.xml").read_bytes() for i in range(1, 9)}
        original_rels = {}
        for i in range(1, 9):
            rel_path = rel_dir / f"slide{i}.xml.rels"
            if rel_path.exists():
                original_rels[i] = rel_path.read_bytes()

        for path in slide_dir.glob("slide*.xml"):
            path.unlink()
        for path in rel_dir.glob("slide*.xml.rels"):
            path.unlink()

        for target_index, source_index in enumerate(SLIDE_MAP, start=1):
            slide_path = slide_dir / f"slide{target_index}.xml"
            slide_path.write_bytes(original_slides[source_index])
            if source_index in original_rels:
                rel_path = rel_dir / f"slide{target_index}.xml.rels"
                rel_path.write_bytes(original_rels[source_index])
                remove_notes_relationships(rel_path)

            tree = parse(slide_path)
            edit_slide(target_index, tree.getroot())
            write_xml(tree, slide_path)

        update_presentation_xml(root_dir)
        update_presentation_rels(root_dir)
        update_content_types(root_dir)
        update_app_props(root_dir)

        if OUT.exists():
            OUT.unlink()
        with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED) as zout:
            for file_path in root_dir.rglob("*"):
                if file_path.is_file():
                    zout.write(file_path, file_path.relative_to(root_dir).as_posix())


if __name__ == "__main__":
    build()
    print(OUT)
