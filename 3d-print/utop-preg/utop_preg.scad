// UTOP – hengslet preg-/embossingtang (print-in-place)
// Papiret legges mellom delene med forsiden opp. Teksten blir HEVET på forsiden.
// Basen har hevet tekst (patrise), lokket har nedsenket speilvendt tekst (matrise).
//
// Render:  openscad -D 'TXT="UTOP"' -o utop.stl utop_preg.scad

TXT       = "UTOP";        // "UTOP" eller "UTOP.no"
FONT      = "Inter:style=Bold";
TXT_W     = 0;             // 0 = automatisk bredde ut fra tekstlengde

W         = 32;    // bredde (langs hengselen)
L         = 62;    // lengde på basen fra papirkant til hengselakse
T         = 4;     // platetykkelse (base og lokk)
TAB       = 4;     // gripekant på lokket
R         = 4.0;   // hengselknoke radius
PIN_R     = 1.8;   // tapp radius
CLR       = 0.40;  // klaring i hengsel (radielt og aksialt)
GAP       = 0.50;  // luft rundt knoker
RELIEF    = 0.8;   // høyde på hevet tekst
DEPTH     = 1.2;   // dybde på nedsenket tekst
PAPER_OFF = 0.45;  // ekstra rom rundt bokstavene (papirtykkelse)

$fn = 64;

X0 = L;            // hengselakse x
H  = T;            // hengselakse z  (= (T+T)/2 så lokket ligger flatt når åpent)

// Knokefordeling langs y: base | lokk | base
KB = (W - 2*GAP) * 0.28;   // base-knoke
KL = W - 2*KB - 2*GAP;     // lokk-knoke
y_lid0 = KB + GAP;
y_lid1 = y_lid0 + KL;

DIE_CX = (X0 - R - GAP) / 2 + 1;
DIE_CY = W / 2;
tw = TXT_W > 0 ? TXT_W : min(X0 - R - GAP - 10, len(TXT) * 9);

module footprint() {
    translate([DIE_CX, DIE_CY])
        resize([tw, 0], auto = true)
            text(TXT, size = 10, font = FONT, halign = "center", valign = "center");
}

module knuckle(y0, y1) {
    translate([X0, y0, H]) rotate([-90, 0, 0]) cylinder(r = R, h = y1 - y0);
}

// ---------- BASE (ligger fast på bordet) ----------
module base() {
    difference() {
        union() {
            cube([X0, W, T]);
            knuckle(0, KB);
            knuckle(W - KB, W);
            // tapp gjennom hele hengselen
            translate([X0, 0, H]) rotate([-90, 0, 0]) cylinder(r = PIN_R, h = W);
            // hevet tekst
            translate([0, 0, T]) linear_extrude(RELIEF) footprint();
        }
        // utsparing for lokk-knoken
        translate([X0 - R - GAP, y_lid0 - GAP, -1]) cube([2*R + 2*GAP + 1, KL + 2*GAP, 3*T]);
    }
    // tappen må fortsatt gå gjennom utsparingen
    translate([X0, 0, H]) rotate([-90, 0, 0]) cylinder(r = PIN_R, h = W);
}

// ---------- LOKK modellert i LUKKET posisjon ----------
module lid_closed() {
    difference() {
        union() {
            translate([-TAB, 0, T]) cube([X0 + TAB, W, T]);
            knuckle(y_lid0, y_lid1);
        }
        // klaring rundt base-knokene
        translate([X0 - R - GAP, -1, 0]) cube([2*R + GAP + 1, KB + GAP + 1, 3*T]);
        translate([X0 - R - GAP, W - KB - GAP, 0]) cube([2*R + GAP + 1, KB + GAP + 1, 3*T]);
        // nedsenket tekst (matrise) i undersiden
        translate([0, 0, T - 0.01]) linear_extrude(DEPTH + 0.01) offset(r = PAPER_OFF) footprint();
    }
}

// Teardrop-hull (spiss opp i printretning) for tappen
module pin_hole() {
    translate([X0, -1, H]) rotate([-90, 0, 0]) linear_extrude(W + 2)
        union() {
            circle(r = PIN_R + CLR);
            rotate(45 + 180) square(PIN_R + CLR);   // spiss mot +z etter rotate([-90,0,0])
        }
}

// Lokket vippet 180° rundt hengselaksen (printposisjon: flatt ved siden av basen)
module lid_open() {
    difference() {
        translate([X0, 0, H]) rotate([0, 180, 0]) translate([-X0, 0, -H]) lid_closed();
        pin_hole();
    }
}

base();
lid_open();
