from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.units import mm
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_JUSTIFY
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    HRFlowable, PageBreak, KeepTogether
)
from reportlab.platypus.flowables import Flowable
from reportlab.lib.colors import HexColor
from reportlab.pdfgen import canvas
import os

# ─── Brand colours ───────────────────────────────────────────────────────────
DEEP_NAVY    = HexColor("#0F1F3D")
ACCENT_TEAL  = HexColor("#0E7C7B")
ACCENT_AMBER = HexColor("#E8A838")
LIGHT_BG     = HexColor("#F4F7FA")
RULE_GREY    = HexColor("#D0D8E4")
TEXT_DARK    = HexColor("#1A2540")
TEXT_MUTED   = HexColor("#5A6880")
WHITE        = colors.white

P0_RED   = HexColor("#C0392B")
P1_ORG   = HexColor("#E67E22")
P2_YEL   = HexColor("#D4AC0D")
P3_GRN   = HexColor("#27AE60")
P4_BLU   = HexColor("#2980B9")

# ─── Styles ───────────────────────────────────────────────────────────────────
def make_styles():
    s = {}
    base = getSampleStyleSheet()

    s['cover_title'] = ParagraphStyle(
        'cover_title', fontName='Helvetica-Bold', fontSize=32,
        textColor=WHITE, leading=38, spaceAfter=8
    )
    s['cover_sub'] = ParagraphStyle(
        'cover_sub', fontName='Helvetica', fontSize=13,
        textColor=HexColor("#A8C4D8"), leading=18, spaceAfter=4
    )
    s['cover_date'] = ParagraphStyle(
        'cover_date', fontName='Helvetica', fontSize=10,
        textColor=HexColor("#7A9BB5"), leading=14
    )
    s['toc_heading'] = ParagraphStyle(
        'toc_heading', fontName='Helvetica-Bold', fontSize=18,
        textColor=DEEP_NAVY, leading=22, spaceAfter=16
    )
    s['toc_item'] = ParagraphStyle(
        'toc_item', fontName='Helvetica', fontSize=11,
        textColor=TEXT_DARK, leading=20, leftIndent=0
    )
    s['toc_item_sub'] = ParagraphStyle(
        'toc_item_sub', fontName='Helvetica', fontSize=10,
        textColor=TEXT_MUTED, leading=18, leftIndent=16
    )
    s['section_label'] = ParagraphStyle(
        'section_label', fontName='Helvetica-Bold', fontSize=8,
        textColor=ACCENT_TEAL, leading=12, spaceBefore=4,
        spaceAfter=2, tracking=60
    )
    s['h1'] = ParagraphStyle(
        'h1', fontName='Helvetica-Bold', fontSize=22,
        textColor=DEEP_NAVY, leading=26, spaceBefore=6, spaceAfter=6
    )
    s['h2'] = ParagraphStyle(
        'h2', fontName='Helvetica-Bold', fontSize=14,
        textColor=DEEP_NAVY, leading=18, spaceBefore=14, spaceAfter=4
    )
    s['h3'] = ParagraphStyle(
        'h3', fontName='Helvetica-Bold', fontSize=11,
        textColor=ACCENT_TEAL, leading=15, spaceBefore=10, spaceAfter=3
    )
    s['body'] = ParagraphStyle(
        'body', fontName='Helvetica', fontSize=10,
        textColor=TEXT_DARK, leading=15, spaceAfter=6, alignment=TA_JUSTIFY
    )
    s['body_muted'] = ParagraphStyle(
        'body_muted', fontName='Helvetica', fontSize=9,
        textColor=TEXT_MUTED, leading=13, spaceAfter=4
    )
    s['callout'] = ParagraphStyle(
        'callout', fontName='Helvetica-BoldOblique', fontSize=11,
        textColor=DEEP_NAVY, leading=16, spaceAfter=8, alignment=TA_JUSTIFY
    )
    s['bullet'] = ParagraphStyle(
        'bullet', fontName='Helvetica', fontSize=10,
        textColor=TEXT_DARK, leading=15, spaceAfter=3,
        leftIndent=14, firstLineIndent=-10
    )
    s['tag_label'] = ParagraphStyle(
        'tag_label', fontName='Helvetica-Bold', fontSize=8,
        textColor=WHITE, leading=10
    )
    s['table_header'] = ParagraphStyle(
        'table_header', fontName='Helvetica-Bold', fontSize=9,
        textColor=WHITE, leading=12
    )
    s['table_cell'] = ParagraphStyle(
        'table_cell', fontName='Helvetica', fontSize=9,
        textColor=TEXT_DARK, leading=13
    )
    s['table_cell_bold'] = ParagraphStyle(
        'table_cell_bold', fontName='Helvetica-Bold', fontSize=9,
        textColor=TEXT_DARK, leading=13
    )
    s['footer_text'] = ParagraphStyle(
        'footer_text', fontName='Helvetica', fontSize=8,
        textColor=TEXT_MUTED
    )
    return s


# ─── Custom Flowables ─────────────────────────────────────────────────────────
class LayerBanner(Flowable):
    """Full-width coloured banner for each layer heading."""
    def __init__(self, layer_num, title, status, width):
        super().__init__()
        self.layer_num = layer_num
        self.title = title
        self.status = status
        self.w = width
        self.h = 44

    def wrap(self, availW, availH):
        return self.w, self.h

    def draw(self):
        c = self.canv
        # Background
        c.setFillColor(DEEP_NAVY)
        c.roundRect(0, 0, self.w, self.h, 4, fill=1, stroke=0)
        # Layer number badge
        c.setFillColor(ACCENT_TEAL)
        c.roundRect(10, 8, 28, 28, 3, fill=1, stroke=0)
        c.setFillColor(WHITE)
        c.setFont('Helvetica-Bold', 11)
        c.drawCentredString(24, 17, str(self.layer_num))
        # Title
        c.setFillColor(WHITE)
        c.setFont('Helvetica-Bold', 14)
        c.drawString(48, 24, self.title)
        # Status badge
        c.setFillColor(ACCENT_AMBER)
        status_w = len(self.status) * 6.2 + 14
        c.roundRect(self.w - status_w - 10, 12, status_w, 20, 3, fill=1, stroke=0)
        c.setFillColor(DEEP_NAVY)
        c.setFont('Helvetica-Bold', 8)
        c.drawCentredString(self.w - status_w/2 - 10, 19, self.status)


class StatusTag(Flowable):
    def __init__(self, label, color, text_color=WHITE, width=90, height=18):
        super().__init__()
        self.label = label
        self.color = color
        self.text_color = text_color
        self.w = width
        self.h = height

    def wrap(self, availW, availH):
        return self.w, self.h

    def draw(self):
        c = self.canv
        c.setFillColor(self.color)
        c.roundRect(0, 0, self.w, self.h, 3, fill=1, stroke=0)
        c.setFillColor(self.text_color)
        c.setFont('Helvetica-Bold', 8)
        c.drawCentredString(self.w / 2, 5, self.label)


class SectionRule(Flowable):
    def __init__(self, width, color=RULE_GREY, thickness=0.5):
        super().__init__()
        self.w = width
        self.color = color
        self.thickness = thickness
        self.h = 8

    def wrap(self, availW, availH):
        return self.w, self.h

    def draw(self):
        c = self.canv
        c.setStrokeColor(self.color)
        c.setLineWidth(self.thickness)
        c.line(0, 4, self.w, 4)


class AccentBox(Flowable):
    """Left-accent quote / callout box."""
    def __init__(self, text, width, accent=ACCENT_TEAL, bg=LIGHT_BG):
        super().__init__()
        self.text = text
        self.w = width
        self.accent = accent
        self.bg = bg
        self._height = None

    def wrap(self, availW, availH):
        self.w = availW
        # Estimate height
        chars_per_line = int(self.w / 6.5)
        lines = max(3, len(self.text) // chars_per_line + 2)
        self._height = lines * 14 + 20
        return self.w, self._height

    def draw(self):
        c = self.canv
        h = self._height
        c.setFillColor(self.bg)
        c.roundRect(0, 0, self.w, h, 4, fill=1, stroke=0)
        c.setFillColor(self.accent)
        c.rect(0, 0, 4, h, fill=1, stroke=0)
        c.setFillColor(TEXT_DARK)
        c.setFont('Helvetica-BoldOblique', 10)
        # Simple text wrap
        words = self.text.split()
        line, lines_out, x, y = [], [], 16, h - 16
        for w in words:
            test = ' '.join(line + [w])
            if c.stringWidth(test, 'Helvetica-BoldOblique', 10) < self.w - 30:
                line.append(w)
            else:
                lines_out.append(' '.join(line))
                line = [w]
        if line:
            lines_out.append(' '.join(line))
        for ln in lines_out:
            c.drawString(x, y, ln)
            y -= 14


# ─── Page template callbacks ──────────────────────────────────────────────────
class DocBuilder:
    def __init__(self, path):
        self.path = path
        self.page_num = 0

    def on_page(self, canv, doc):
        self.page_num += 1
        w, h = A4
        # Footer bar
        canv.saveState()
        canv.setFillColor(DEEP_NAVY)
        canv.rect(0, 0, w, 22, fill=1, stroke=0)
        canv.setFillColor(WHITE)
        canv.setFont('Helvetica', 8)
        canv.drawString(20, 7, "PAMPIRI · STRATEGIC GAP ANALYSIS · JUNE 2026")
        canv.drawRightString(w - 20, 7, f"Page {self.page_num}")
        # Top accent line
        canv.setFillColor(ACCENT_TEAL)
        canv.rect(0, h - 3, w, 3, fill=1, stroke=0)
        canv.restoreState()

    def on_first_page(self, canv, doc):
        pass  # Cover page handled via story


# ─── Cover page ───────────────────────────────────────────────────────────────
def build_cover(styles, page_w, page_h):
    items = []

    class CoverBg(Flowable):
        def wrap(self, aw, ah):
            return page_w, page_h - 40*mm

        def draw(self):
            c = self.canv
            # Navy background
            c.setFillColor(DEEP_NAVY)
            c.rect(0, 0, page_w, page_h, fill=1, stroke=0)
            # Teal geometric accent
            c.setFillColor(ACCENT_TEAL)
            c.setFillAlpha(0.15)
            c.circle(page_w - 30*mm, page_h - 40*mm, 90*mm, fill=1, stroke=0)
            c.setFillAlpha(0.08)
            c.circle(page_w - 10*mm, page_h - 10*mm, 50*mm, fill=1, stroke=0)
            c.setFillAlpha(1)
            # Amber bottom strip
            c.setFillColor(ACCENT_AMBER)
            c.rect(0, 0, page_w, 8, fill=1, stroke=0)
            # Teal top strip
            c.setFillColor(ACCENT_TEAL)
            c.rect(0, page_h - 5, page_w, 5, fill=1, stroke=0)
            # App name badge
            c.setFillColor(ACCENT_TEAL)
            c.roundRect(20*mm, page_h - 55*mm, 50*mm, 14*mm, 3, fill=1, stroke=0)
            c.setFillColor(WHITE)
            c.setFont('Helvetica-Bold', 13)
            c.drawCentredString(20*mm + 25*mm, page_h - 55*mm + 4*mm, "PAMPIRI")
            # Main title
            c.setFillColor(WHITE)
            c.setFont('Helvetica-Bold', 30)
            c.drawString(20*mm, page_h - 90*mm, "What's Missing to Become")
            c.drawString(20*mm, page_h - 103*mm, "the Go-To SA Finance App")
            # Subtitle
            c.setFillColor(HexColor("#A8C4D8"))
            c.setFont('Helvetica', 13)
            c.drawString(20*mm, page_h - 116*mm, "Strategic Gap Analysis")
            # Date
            c.setFillColor(HexColor("#7A9BB5"))
            c.setFont('Helvetica', 10)
            c.drawString(20*mm, page_h - 126*mm, "June 2026")
            # Divider
            c.setStrokeColor(ACCENT_TEAL)
            c.setLineWidth(1.5)
            c.line(20*mm, page_h - 132*mm, 80*mm, page_h - 132*mm)
            # Tagline
            c.setFillColor(HexColor("#A8C4D8"))
            c.setFont('Helvetica-Oblique', 10)
            c.drawString(20*mm, page_h - 142*mm,
                "Capture what others ignore. Extract what others miss.")
            c.drawString(20*mm, page_h - 153*mm,
                "Organise what others leave in a shoebox.")

    items.append(CoverBg())
    items.append(PageBreak())
    return items


# ─── TOC ──────────────────────────────────────────────────────────────────────
def build_toc(styles, W):
    items = []
    items.append(Spacer(1, 12*mm))
    items.append(Paragraph("Contents", styles['toc_heading']))
    items.append(SectionRule(W))
    items.append(Spacer(1, 4*mm))

    toc_data = [
        ("01", "The Strategic Frame", "Layer architecture overview", None),
        ("02", "Layer 1 — Trust Layer", "Security, privacy, POPIA compliance", "70% done"),
        ("03", "Layer 2 — Financial Intelligence", "Income, VAT, dashboards, insights", "30% done"),
        ("04", "Layer 3 — SA-Specific Finance", "SARS, logbook, petty cash, ZAR", "20% done"),
        ("05", "Layer 4 — Ecosystem Bridges", "Accountant exports, integrations", "10% done"),
        ("06", "Layer 5 — Growth Mechanics", "Referrals, retention, partner program", "5% done"),
        ("07", "Priority Stack", "Impact vs. effort ranking", None),
        ("08", "Scope Protection", "What Pampiri should NOT build", None),
        ("09", "Position Statement", "Revised competitive framing", None),
    ]

    for num, title, sub, status in toc_data:
        row = [[
            Paragraph(f'<font color="#0E7C7B"><b>{num}</b></font>', styles['toc_item']),
            Paragraph(f'<b>{title}</b><br/><font color="#5A6880" size="9">{sub}</font>', styles['toc_item']),
            Paragraph(f'<font color="#E8A838"><b>{status}</b></font>' if status else '', styles['toc_item']),
        ]]
        t = Table(row, colWidths=[14*mm, W - 55*mm, 35*mm])
        t.setStyle(TableStyle([
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
            ('TOPPADDING', (0, 0), (-1, -1), 6),
            ('LINEBELOW', (0, 0), (-1, 0), 0.3, RULE_GREY),
            ('ALIGN', (2, 0), (2, 0), 'RIGHT'),
        ]))
        items.append(t)

    items.append(PageBreak())
    return items


# ─── Strategic Frame ──────────────────────────────────────────────────────────
def build_frame(styles, W):
    items = []
    items.append(Paragraph("STRATEGIC OVERVIEW", styles['section_label']))
    items.append(Paragraph("The Strategic Frame", styles['h1']))
    items.append(SectionRule(W, ACCENT_TEAL, 1.5))
    items.append(Spacer(1, 4*mm))
    items.append(AccentBox(
        "The core must not change. Pampiri's identity is: scan a physical or digital document "
        "→ AI extracts structured data → act on it. Everything below is built on top of that engine.",
        W
    ))
    items.append(Spacer(1, 4*mm))
    items.append(Paragraph(
        "There are 5 layers between where Pampiri is today and where it needs to be to own the "
        "SA finance/fintech space for SMEs, gig workers, and fleet operators. Each layer is additive "
        "— nothing below disrupts the OCR engine.",
        styles['body']
    ))
    items.append(Spacer(1, 4*mm))

    # Architecture pyramid table
    layers = [
        ("Layer 5", "GROWTH MECHANICS", "Retention · Virality · Ecosystem stickiness", ACCENT_AMBER),
        ("Layer 4", "ECOSYSTEM BRIDGES", "Connect to what SA already uses", HexColor("#2980B9")),
        ("Layer 3", "SA-SPECIFIC FINANCE", "SARS · POPIA · ZAR-native features", ACCENT_TEAL),
        ("Layer 2", "FINANCIAL INTELLIGENCE", "Turn raw data into decisions", HexColor("#8E44AD")),
        ("Layer 1", "TRUST LAYER", "The foundation everything else needs", DEEP_NAVY),
        ("CORE", "DOCUMENT CAPTURE → OCR → STRUCTURED DATA → EXPORT", "", HexColor("#0A1428")),
    ]

    for lbl, name, desc, bg in layers:
        row = [[
            Paragraph(f'<b><font color="white">{lbl}</font></b>', styles['table_header']),
            Paragraph(f'<b><font color="white">{name}</font></b>', styles['table_header']),
            Paragraph(f'<font color="#CCDDEE">{desc}</font>', styles['body_muted']),
        ]]
        cw = [18*mm, 70*mm, W - 96*mm]
        if lbl == "CORE":
            row = [[
                Paragraph(f'<b><font color="{ACCENT_AMBER.hexval()}">CORE</font></b>', styles['table_header']),
                Paragraph(f'<b><font color="white">{name}</font></b>', styles['table_header']),
                Paragraph('', styles['body_muted']),
            ]]
        t = Table(row, colWidths=cw)
        t.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), bg),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('TOPPADDING', (0, 0), (-1, -1), 7),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 7),
            ('LEFTPADDING', (0, 0), (0, 0), 8),
            ('LINEBELOW', (0, 0), (-1, 0), 1, WHITE),
        ]))
        items.append(t)

    items.append(Spacer(1, 3*mm))
    items.append(Paragraph(
        "Start at the bottom. Each layer only works if the one below it is solid.",
        styles['body_muted']
    ))
    items.append(PageBreak())
    return items


# ─── Layer sections ───────────────────────────────────────────────────────────
def bullet(styles, text):
    return Paragraph(f"<bullet>&bull;</bullet> {text}", styles['bullet'])


def missing_item(styles, title, body_paras):
    items = []
    items.append(Paragraph(f"&#10007;  {title}", styles['h3']))
    for p in body_paras:
        items.append(Paragraph(p, styles['body']))
    return items


def have_item(styles, text):
    return Paragraph(f"<font color='#27AE60'>&#10003;</font>  {text}", styles['body'])


def build_layer1(styles, W):
    items = []
    items.append(LayerBanner(1, "The Trust Layer", "70% done", W))
    items.append(Spacer(1, 4*mm))
    items.append(Paragraph(
        "Users will not store their financial life in an app they don't trust. "
        "This is not marketing — it's architecture. Every subsequent layer depends on this one being solid.",
        styles['body']
    ))
    items.append(Spacer(1, 3*mm))

    items.append(Paragraph("What You Have", styles['h2']))
    for h in [
        "POPIA-compliant positioning",
        "Custom branded OTP email verification",
        "PayFast (SA-native, trusted payment processor)",
        "Zero-trust quota guard",
        "90-day data purge policy (cloud model)",
        "Firestore security rules (partial — 3 critical bugs remain)",
    ]:
        items.append(have_item(styles, h))

    items.append(Spacer(1, 4*mm))
    items.append(Paragraph("Critical Gaps", styles['h2']))

    # 1.1
    items.append(KeepTogether([
        Paragraph("1.1  Subscription Plan Self-Elevation Bug", styles['h3']),
        Table([[
            Paragraph("<b>CRITICAL SECURITY BUG</b>", styles['table_header']),
            Paragraph(
                "Clients can write subscriptionPlan = 'free_trial' directly to Firestore. "
                "Your entire monetisation model has a bypass vulnerability. "
                "Fix: lock all subscription fields to Admin SDK writes only.",
                styles['table_cell']
            )
        ]], colWidths=[42*mm, W - 46*mm], style=TableStyle([
            ('BACKGROUND', (0, 0), (0, 0), P0_RED),
            ('BACKGROUND', (1, 0), (1, 0), HexColor("#FDF0F0")),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('TOPPADDING', (0, 0), (-1, -1), 8),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
            ('LEFTPADDING', (1, 0), (1, 0), 10),
            ('BOX', (0, 0), (-1, -1), 0.5, P0_RED),
        ])),
        Spacer(1, 3*mm),
    ]))

    # 1.2
    items.append(KeepTogether([
        Paragraph("1.2  Data Isolation Bug in /scans Root Collection", styles['h3']),
        Paragraph(
            "A user who guesses another user's scan document ID can read it. The flat root collection "
            "has no ownership enforcement. This is a real data privacy breach risk — unacceptable for "
            "a POPIA-compliant product.",
            styles['body']
        ),
        bullet(styles, "Fix: migrate to /documents/{docId} with proper ownership security rules."),
        Spacer(1, 2*mm),
    ]))

    # 1.3
    items.append(KeepTogether([
        Paragraph("1.3  No In-App Privacy / POPIA Dashboard", styles['h3']),
        Paragraph(
            "POPIA compliance is mentioned in the Play Store description but there is no in-app screen "
            "where users can exercise their legal rights.",
            styles['body']
        ),
        bullet(styles, "Right to see what data is stored about them"),
        bullet(styles, "Right to erasure (deletion request)"),
        bullet(styles, "Right to data portability (export their data)"),
        Paragraph("This is legally required under POPIA and a trust signal for Business plan users.", styles['body_muted']),
        Spacer(1, 2*mm),
    ]))

    # 1.4
    items.append(KeepTogether([
        Paragraph("1.4  No Incident / Outage Communication Channel", styles['h3']),
        Paragraph(
            "When the OCR backend goes down, users receive a generic error. There is no status page, "
            "no in-app service health indicator, and no email notification.",
            styles['body']
        ),
        bullet(styles, "Add a /health status page at status.mypampiri.co.za"),
        bullet(styles, "In-app banner reading from Firebase Remote Config during outages"),
        Spacer(1, 2*mm),
    ]))

    items.append(PageBreak())
    return items


def build_layer2(styles, W):
    items = []
    items.append(LayerBanner(2, "Financial Intelligence Layer", "30% done", W))
    items.append(Spacer(1, 4*mm))
    items.append(Paragraph(
        "This is what separates a document scanner from a finance tool. The data is already extracted "
        "— Pampiri just isn't doing enough with it yet. This layer has the highest ROI of any work on the roadmap.",
        styles['body']
    ))
    items.append(Spacer(1, 3*mm))

    sections = [
        (
            "2.1  Income Journal — THE Core Missing Piece",
            [
                "Every financial calculation — profit, margin, tax — requires both sides of the equation. "
                "Pampiri knows your expenses but has no place to record income. Without this, you can never "
                "show a real P&amp;L, tax summary, or net worth view.",
                "<b>What it IS:</b> A simple income log — amount, date, category (Sales, Service, Rental, "
                "Commission, Other), optional client link. When a Pampiri Invoice is marked paid, it "
                "auto-creates an income entry.",
                "<b>What it is NOT:</b> A general ledger. Full double-entry is out of scope and the wrong "
                "tool for this market.",
            ]
        ),
        (
            "2.2  VAT Summary / VAT201 Helper",
            [
                "Every VAT-registered SA business must file a VAT201 return every 2 months. This is the #1 "
                "reason SMEs pay for accounting software. Pampiri already extracts VAT amounts from every receipt.",
                "Input VAT: sum of extracted vatAmount fields from expenses in the period. Output VAT: sum of "
                "VAT on invoices marked paid. Net VAT payable: Output minus Input. Downloadable as PDF/CSV in "
                "VAT201 format.",
                "<b>What it is NOT:</b> eFiling integration — that is a future enterprise feature.",
            ]
        ),
        (
            "2.3  Profitability Dashboard — BRD-defined, not built",
            [
                "Already specced in the BRD. Income minus expenses minus commission equals net profit. "
                "The income journal (2.1) is the missing input that makes this complete.",
            ]
        ),
        (
            "2.4  Budget Monitoring — BRD-defined, not built",
            [
                "Set limits per category, receive alerts at 80% and 100%. The data already exists — every "
                "document has a category. This is a Cloud Function away from working once the schema "
                "migration is complete.",
            ]
        ),
        (
            "2.5  Expense Trends &amp; Insights",
            [
                "Once you have 3+ months of categorised expense data, surface insights such as: 'Your Fuel "
                "spend increased 23% vs last month' or 'Your highest expense day is Monday.'",
                "This is not AI magic — it is simple aggregation on data Pampiri already has. It is what "
                "makes users open the app even when they are not scanning documents.",
            ]
        ),
        (
            "2.6  Cash Flow View",
            [
                "What came in vs. what went out, by week or month. Outstanding invoices (money owed to you). "
                "Projected cash position based on outstanding invoices. Pampiri Invoice already has a payment "
                "aging chart — extend it into a full cash flow tab.",
            ]
        ),
    ]

    for title, paras in sections:
        items.append(KeepTogether(
            [Paragraph(f"&#10007;  {title}", styles['h3'])]
            + [Paragraph(p, styles['body']) for p in paras]
            + [Spacer(1, 3*mm)]
        ))

    items.append(PageBreak())
    return items


def build_layer3(styles, W):
    items = []
    items.append(LayerBanner(3, "SA-Specific Finance Layer", "20% done", W))
    items.append(Spacer(1, 4*mm))
    items.append(Paragraph(
        "This is the layer that makes Pampiri for South Africa rather than just in South Africa. "
        "No international competitor will prioritise these features. This is your defensible territory "
        "and the source of your strongest competitive moat.",
        styles['body']
    ))
    items.append(Spacer(1, 3*mm))

    sections = [
        (
            "3.1  SARS Expense Category Alignment",
            [
                "The current categories are generic (Fuel, Food, Supplies, Services). SARS Section 11 "
                "deductible categories are specific: Travel, Home office, Business meals (partial deduction), "
                "Professional services, Equipment/assets with depreciation, Telephone &amp; internet.",
                "Map Pampiri categories to SARS Section 11 codes. When a user exports for their accountant, "
                "include the SARS code. This turns Pampiri into something accountants will recommend to clients.",
            ]
        ),
        (
            "3.2  Travel Logbook — Section 8(1)(b) Compliance",
            [
                "The most underserved SA business need in any app. SARS requires a travel logbook for business "
                "travel deductions: date, odometer start/end, destination, business purpose, vehicle registration.",
                "Pampiri can add a 'Log Trip' action (1 tap start, 1 tap stop — GPS odometer optional). Toll "
                "receipts and fuel receipts auto-link to trips. Export as a SARS-compliant logbook CSV.",
                "<b>This feature alone makes Pampiri essential for any freelancer or SME who claims travel "
                "deductions.</b> It is deeply tied to the OCR engine and fits perfectly in the Gig Driver persona.",
            ]
        ),
        (
            "3.3  Petty Cash Register",
            [
                "SA SMEs and fleet operations run on petty cash. A simple module: opening balance, record cash "
                "out linked to a scanned receipt, record cash in, running balance, print/export petty cash sheet.",
                "Petty cash receipts are exactly what Pampiri's OCR was built to process. Existing tools handle "
                "this poorly on mobile.",
            ]
        ),
        (
            "3.4  POPIA Data Subject Request Flow",
            [
                "Legally required, not optional. Already surfaced in Layer 1 — highlighted here again because "
                "it is a regulatory requirement with potential fines, not a nice-to-have.",
            ]
        ),
        (
            "3.5  ZAR-Denominated Financial Benchmarks",
            [
                "Show users how their spending compares to SA industry averages once scale is reached. "
                "'Your fuel spend as % of revenue is higher than 68% of Pampiri gig drivers.' Plan the "
                "anonymised aggregate data model now so the feature ships cleanly at scale.",
            ]
        ),
    ]

    for title, paras in sections:
        items.append(KeepTogether(
            [Paragraph(f"&#10007;  {title}", styles['h3'])]
            + [Paragraph(p, styles['body']) for p in paras]
            + [Spacer(1, 3*mm)]
        ))

    items.append(PageBreak())
    return items


def build_layer4(styles, W):
    items = []
    items.append(LayerBanner(4, "Ecosystem Bridge Layer", "10% done", W))
    items.append(Spacer(1, 4*mm))
    items.append(Paragraph(
        "Pampiri doesn't need to replace every tool — it needs to be the best feeder into the tools "
        "SA businesses already use. Export formats exist; nothing else is connected yet.",
        styles['body']
    ))
    items.append(Spacer(1, 3*mm))

    sections = [
        (
            "4.1  Accountant Export Pack",
            [
                "The most important sales channel for Pampiri is accountants. When an accountant recommends "
                "Pampiri to a client, that client stays forever.",
                "A single ZIP containing: all receipts for the period (PDFs), a categorised expenses CSV, a "
                "VAT summary, and an income statement — labelled per period and generated in one click from "
                "Pampiri Invoice.",
            ]
        ),
        (
            "4.2  Google Drive / OneDrive Export — BRD-defined, not built",
            [
                "Already specced. Build it. This is a Business plan selling point.",
            ]
        ),
        (
            "4.3  Xero / Sage CSV Import Format",
            [
                "Do not integrate with their APIs (complex, expensive, maintenance-heavy). Instead, add export "
                "options formatted as Xero-compatible and Sage-compatible expense import CSVs.",
                "Users import the file themselves. Pampiri becomes the capture layer that feeds existing tools. "
                "Zero API maintenance, massive value to accountants.",
            ]
        ),
        (
            "4.4  Bank Statement Reconciliation (CSV Import)",
            [
                "Let users upload their bank statement CSV (FNB, Standard Bank, ABSA, Nedbank all export CSV). "
                "Auto-match statement lines to scanned receipts using amount + date + merchant.",
                "Show unmatched items for manual categorisation. This is reconciliation-lite — not "
                "double-entry accounting, just matching.",
                "<b>This is the feature that makes Pampiri sticky</b> for small business owners. Scan receipts "
                "as you go; at month-end upload your bank statement and see what matched and what's missing.",
            ]
        ),
        (
            "4.5  WhatsApp Receipt Submission",
            [
                "Fleet drivers send a photo of a receipt via WhatsApp to a dedicated Pampiri Business number. "
                "OCR processes it automatically and it appears in the fleet manager's inbox.",
                "This removes the need for drivers to have the app installed at all for basic receipt submission "
                "— an acquisition channel and a UX win for the low-tech fleet driver persona.",
            ]
        ),
    ]

    for title, paras in sections:
        items.append(KeepTogether(
            [Paragraph(f"&#10007;  {title}", styles['h3'])]
            + [Paragraph(p, styles['body']) for p in paras]
            + [Spacer(1, 3*mm)]
        ))

    items.append(PageBreak())
    return items


def build_layer5(styles, W):
    items = []
    items.append(LayerBanner(5, "Growth Mechanics Layer", "5% done", W))
    items.append(Spacer(1, 4*mm))
    items.append(Paragraph(
        "A great product in South Africa needs word-of-mouth. These are the mechanics that create it. "
        "Currently only in-app review prompts exist.",
        styles['body']
    ))
    items.append(Spacer(1, 3*mm))

    sections = [
        (
            "5.1  Referral Program",
            ["Refer a friend, both get 1 month free. Simple, but Pampiri doesn't have it. "
             "The existing PayFast integration can handle coupon codes."]
        ),
        (
            "5.2  Upload Streak — BRD-defined, not built",
            [
                "The BRD defines consecutive-week upload tracking as a gig driver feature. Add a streak "
                "counter on the dashboard with milestone badges at 4, 8, and 26 weeks.",
                "This is a retention mechanic disguised as a productivity insight: "
                "'You're on a 6-week streak — you've processed R12,400 in expenses.'",
            ]
        ),
        (
            "5.3  Monthly Financial Health Email",
            [
                "Automatically send each user a monthly summary: total documents processed, total expenses "
                "categorised, top category, outstanding invoices, net profit (if income journal is set up), "
                "and one contextual insight.",
                "This keeps Pampiri top-of-mind even for users who don't open the app every week.",
            ]
        ),
        (
            "5.4  Accountant Partner Program",
            [
                "A dedicated portal (even a landing page + email signup) where accountants register as a "
                "Pampiri Partner, receive a referral code for their clients, and earn commission or a discount "
                "on every paying client they refer.",
                "This turns every accountant in South Africa into a sales rep.",
            ]
        ),
        (
            "5.5  Public API — Long-term",
            [
                "The BRD correctly marks API-only products as out of scope for now. But the architecture "
                "(Python FastAPI + Firebase) is already API-first. When the time comes, a read-only API for "
                "third-party integrations is the path to Enterprise revenue.",
            ]
        ),
    ]

    for title, paras in sections:
        items.append(KeepTogether(
            [Paragraph(f"&#10007;  {title}", styles['h3'])]
            + [Paragraph(p, styles['body']) for p in paras]
            + [Spacer(1, 3*mm)]
        ))

    items.append(PageBreak())
    return items


# ─── Priority table ───────────────────────────────────────────────────────────
def build_priority(styles, W):
    items = []
    items.append(Paragraph("ROADMAP", styles['section_label']))
    items.append(Paragraph("Priority Stack", styles['h1']))
    items.append(SectionRule(W, ACCENT_TEAL, 1.5))
    items.append(Spacer(1, 3*mm))
    items.append(Paragraph(
        "Ranked by impact versus effort. Fix the foundation first — every layer above it depends on it.",
        styles['body']
    ))
    items.append(Spacer(1, 4*mm))

    rows = [
        ("P0", P0_RED, "Fix subscription self-elevation bug", "1", "Critical", "Low", "Everyone"),
        ("P0", P0_RED, "Fix /scans data isolation bug", "1", "Critical", "Medium", "Everyone"),
        ("P0", P0_RED, "Income Journal", "2", "Very High", "Medium", "Gig + SME"),
        ("P1", P1_ORG, "VAT201 Summary", "3", "Very High", "Low–Med", "SME + Fleet"),
        ("P1", P1_ORG, "Budget Monitoring (BRD)", "2", "High", "Low", "SME"),
        ("P1", P1_ORG, "Profitability Dashboard (BRD)", "2", "High", "Low*", "Gig Driver"),
        ("P1", P1_ORG, "Plan-gate Pampiri Invoice", "1", "High", "Low", "Business"),
        ("P2", P2_YEL, "Travel Logbook", "3", "Very High", "Medium", "Gig + Fleet"),
        ("P2", P2_YEL, "Bank Statement CSV Reconciliation", "4", "Very High", "Medium", "SME"),
        ("P2", P2_YEL, "Accountant Export Pack", "4", "High", "Low", "SME + Accountants"),
        ("P2", P2_YEL, "Xero / Sage export format", "4", "High", "Low", "SME"),
        ("P2", P2_YEL, "Google Drive / OneDrive (BRD)", "4", "Medium", "Medium", "Business"),
        ("P3", P3_GRN, "POPIA Data Subject Request screen", "1", "High (legal)", "Low", "Everyone"),
        ("P3", P3_GRN, "Expense Trends & Insights", "2", "High", "Medium", "All"),
        ("P3", P3_GRN, "Monthly Financial Health Email", "5", "Medium", "Low", "All"),
        ("P3", P3_GRN, "WhatsApp Receipt Submission", "4", "High", "High", "Fleet"),
        ("P3", P3_GRN, "Petty Cash Register", "3", "Medium", "Medium", "Fleet + SME"),
        ("P4", P4_BLU, "Referral Program", "5", "Medium", "Medium", "Growth"),
        ("P4", P4_BLU, "Upload Streak (BRD)", "5", "Medium", "Low", "Gig Driver"),
        ("P4", P4_BLU, "Accountant Partner Program", "5", "High", "Low", "Growth"),
    ]

    header = [
        Paragraph("<b>Priority</b>", styles['table_header']),
        Paragraph("<b>Feature</b>", styles['table_header']),
        Paragraph("<b>Layer</b>", styles['table_header']),
        Paragraph("<b>Impact</b>", styles['table_header']),
        Paragraph("<b>Effort</b>", styles['table_header']),
        Paragraph("<b>Who benefits</b>", styles['table_header']),
    ]

    col_w = [16*mm, W - 100*mm, 13*mm, 24*mm, 18*mm, 25*mm]
    table_data = [header]

    for pri, col, feat, layer, impact, effort, who in rows:
        table_data.append([
            Paragraph(f'<b><font color="white">{pri}</font></b>', styles['table_header']),
            Paragraph(feat, styles['table_cell']),
            Paragraph(layer, styles['table_cell']),
            Paragraph(impact, styles['table_cell']),
            Paragraph(effort, styles['table_cell']),
            Paragraph(who, styles['table_cell']),
        ])

    t = Table(table_data, colWidths=col_w, repeatRows=1)
    style_cmds = [
        ('BACKGROUND', (0, 0), (-1, 0), DEEP_NAVY),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [WHITE, LIGHT_BG]),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING', (0, 0), (-1, -1), 5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ('GRID', (0, 0), (-1, -1), 0.3, RULE_GREY),
    ]

    # Colour priority badge cells
    priority_map = {
        "P0": P0_RED, "P1": P1_ORG, "P2": P2_YEL, "P3": P3_GRN, "P4": P4_BLU
    }
    for i, (pri, col, *_) in enumerate(rows, start=1):
        style_cmds.append(('BACKGROUND', (0, i), (0, i), priority_map[pri]))

    t.setStyle(TableStyle(style_cmds))
    items.append(t)
    items.append(Spacer(1, 3*mm))
    items.append(Paragraph("* Requires Income Journal to be complete first.", styles['body_muted']))
    items.append(PageBreak())
    return items


# ─── Scope protection ─────────────────────────────────────────────────────────
def build_scope(styles, W):
    items = []
    items.append(Paragraph("SCOPE PROTECTION", styles['section_label']))
    items.append(Paragraph("What Pampiri Should NOT Build", styles['h1']))
    items.append(SectionRule(W, ACCENT_TEAL, 1.5))
    items.append(Spacer(1, 3*mm))
    items.append(Paragraph(
        "These are tempting but wrong for this stage. Discipline here preserves the product's identity.",
        styles['body']
    ))
    items.append(Spacer(1, 4*mm))

    dont_build = [
        ("Full double-entry general ledger", "This is QuickBooks. It's a different product."),
        ("SARS eFiling integration", "Complex, regulatory, changes constantly, support nightmare."),
        ("Payroll module", "Sage Payroll exists. Do not compete there."),
        ("Stock / inventory management", "Out of scope for the document intelligence mission."),
        ("Banking API integrations", "High cost, high maintenance, regulatory complexity."),
        ("Separate desktop app", "BRD explicitly out of scope."),
        ("White-label platform", "BRD explicitly out of scope."),
    ]

    scope_data = [[
        Paragraph("<b>Do NOT build</b>", styles['table_header']),
        Paragraph("<b>Why</b>", styles['table_header']),
    ]]
    for feat, reason in dont_build:
        scope_data.append([
            Paragraph(f"&#10007;  {feat}", styles['table_cell_bold']),
            Paragraph(reason, styles['table_cell']),
        ])

    t = Table(scope_data, colWidths=[W * 0.42, W * 0.58])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), DEEP_NAVY),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [WHITE, LIGHT_BG]),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING', (0, 0), (-1, -1), 7),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 7),
        ('LEFTPADDING', (0, 0), (-1, -1), 10),
        ('GRID', (0, 0), (-1, -1), 0.3, RULE_GREY),
    ]))
    items.append(t)
    items.append(PageBreak())
    return items


# ─── Position statement ───────────────────────────────────────────────────────
def build_position(styles, W):
    items = []
    items.append(Paragraph("COMPETITIVE FRAMING", styles['section_label']))
    items.append(Paragraph("The Pampiri Position Statement", styles['h1']))
    items.append(SectionRule(W, ACCENT_TEAL, 1.5))
    items.append(Spacer(1, 6*mm))
    items.append(AccentBox(
        "Pampiri is South Africa's document intelligence platform for the financial life of small "
        "businesses, gig workers, and fleets. We capture what others ignore, extract what others miss, "
        "and organise what others leave in a shoebox. We are not an accounting replacement — we are "
        "the missing layer between your physical world and your accounting tool.",
        W, accent=ACCENT_AMBER
    ))
    items.append(Spacer(1, 6*mm))
    items.append(Paragraph(
        "That framing is your competitive moat. Own it. Every feature in this document serves it.",
        styles['body']
    ))
    items.append(Spacer(1, 8*mm))
    items.append(SectionRule(W, RULE_GREY))
    items.append(Spacer(1, 4*mm))
    items.append(Paragraph(
        "Pampiri · Strategic Gap Analysis · June 2026 · Confidential",
        styles['body_muted']
    ))
    return items


# ─── Main ─────────────────────────────────────────────────────────────────────
def main():
    # Save to Windows Downloads folder
    downloads_dir = os.path.join(os.path.expanduser("~"), "Downloads")
    out_path = os.path.join(downloads_dir, "Pampiri_Strategic_Gap_Analysis.pdf")
    os.makedirs(downloads_dir, exist_ok=True)

    page_w, page_h = A4
    margin = 20 * mm
    usable_w = page_w - 2 * margin

    db = DocBuilder(out_path)

    doc = SimpleDocTemplate(
        out_path,
        pagesize=A4,
        leftMargin=margin, rightMargin=margin,
        topMargin=14*mm, bottomMargin=16*mm,
        title="Pampiri — Strategic Gap Analysis",
        author="Pampiri Product Team",
        subject="What's Missing to Become the Go-To SA Finance App",
    )

    styles = make_styles()

    story = []
    story += build_cover(styles, page_w, page_h)
    story += build_toc(styles, usable_w)
    story += build_frame(styles, usable_w)
    story += build_layer1(styles, usable_w)
    story += build_layer2(styles, usable_w)
    story += build_layer3(styles, usable_w)
    story += build_layer4(styles, usable_w)
    story += build_layer5(styles, usable_w)
    story += build_priority(styles, usable_w)
    story += build_scope(styles, usable_w)
    story += build_position(styles, usable_w)

    doc.build(
        story,
        onFirstPage=db.on_first_page,
        onLaterPages=db.on_page,
    )
    print(f"PDF written to {out_path}")


if __name__ == "__main__":
    main()