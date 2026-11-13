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

// Avrunding / myke overganger
CORNER_R = 3;      // avrundede hjørner i fri ende
CH_TOP   = 0.8;    // fas på toppkant
CH_BOT   = 0.5;    // fas på bunnkant (motvirker "elephant foot")
FIL      = 2;      // hulkil mellom hengselknoke og plate
KCH      = 0.5;    // fas på knokenes ender

CX  = sqrt((R + FIL)^2 - FIL^2);   // hvor hulkilen møter platen (fra aksen)
CUT = CX + GAP;                     // utsparing rundt motstående knoke

DIE_CX = (X0 - CUT) / 2 + 1;
DIE_CY = W / 2;
tw = TXT_W > 0 ? TXT_W : min(X0 - CUT - 10, len(TXT) * 9);

module footprint() {
    translate([DIE_CX, DIE_CY])
        resize([tw, 0], auto = true)
            text(TXT, size = 10, font = FONT, halign = "center", valign = "center");
}

// 2D-plate: avrundede hjørner i fri ende (x=0), rette ved hengselen
module plate2d(inset = 0) {
    offset(delta = -inset) hull() {
        translate([CORNER_R, CORNER_R]) circle(r = CORNER_R);
        translate([CORNER_R, W - CORNER_R]) circle(r = CORNER_R);
        translate([X0 - 1, 0]) square([1, W]);
    }
}
// Plate med fas oppe og nede
module plate(z0, h, cb, ct) {
    translate([0, 0, z0]) hull() {
        linear_extrude(0.01) plate2d(cb);
        translate([0, 0, cb]) linear_extrude(h - cb - ct) plate2d(0);
        translate([0, 0, h - 0.01]) linear_extrude(0.01) plate2d(ct);
    }
}

// Knoke med fasede ender
module knuckle(y0, y1) {
    translate([X0, y0, H]) rotate([-90, 0, 0]) hull() {
        cylinder(r = R - KCH, h = y1 - y0);
        translate([0, 0, KCH]) cylinder(r = R, h = y1 - y0 - 2*KCH);
    }
}

// Hulkil (myk overgang) mellom knoke og plateflate på z = H.
// up = 1: kilen går oppover fra flaten, up = -1: nedover.
module fillet(y0, y1, up = 1) {
    C = [X0 - CX, H + up*FIL];
    T = [X0, H] + R * (C - [X0, H]) / norm(C - [X0, H]);
    translate([0, y1 - KCH, 0]) rotate([90, 0, 0]) linear_extrude(y1 - y0 - 2*KCH)
        difference() {
            polygon([[X0 - CX, H], [X0, H], T, C]);
            translate(C) circle(r = FIL);
        }
}

// ---------- BASE (ligger fast på bordet) ----------
module base() {
    difference() {
        union() {
            plate(0, T, CH_BOT, CH_TOP);
            knuckle(0, KB);
            knuckle(W - KB, W);
            fillet(0, KB, 1);
            fillet(W - KB, W, 1);
            // hevet tekst
            translate([0, 0, T]) linear_extrude(RELIEF) footprint();
        }
        // utsparing for lokk-knoken
        translate([X0 - CUT, y_lid0 - GAP, -1]) cube([CUT + R + 1, KL + 2*GAP, 3*T]);
    }
    // tapp gjennom hele hengselen
    translate([X0, 0, H]) rotate([-90, 0, 0]) cylinder(r = PIN_R, h = W);
}

// ---------- LOKK modellert i LUKKET posisjon ----------
module lid_closed() {
    difference() {
        union() {
            plate(T, T, CH_TOP, CH_BOT);   // undersiden blir oversiden i print
            knuckle(y_lid0, y_lid1);
            fillet(y_lid0, y_lid1, -1);
        }
        // klaring rundt base-knokene
        translate([X0 - CUT, -1, 0]) cube([CUT + R + 1, KB + GAP + 1, 3*T]);
        translate([X0 - CUT, W - KB - GAP, 0]) cube([CUT + R + 1, KB + GAP + 1, 3*T]);
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
