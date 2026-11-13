# UTOP pregetang (embosser)

Hengslet pregetang, printes ferdig montert (print-in-place) – ingen støtte nødvendig.

| Fil | Tekst |
|---|---|
| `utop.stl` | UTOP |
| `utop_no.stl` | utop.no |
| `utop_preg.scad` | Kildefil (OpenSCAD) – endre `TXT` for annen tekst |

**Mål:** 124 × 32 × 8 mm (åpen/printposisjon). Lukket ligger lokket kant i kant med basen.

## Print
- Legg flatt slik den er i fila. Ingen support.
- Kantene er avrundet/faset, og hengselknokene har myke overganger (hulkil) mot platene.
- 0,2 mm lag, 3–4 vegger, 40 %+ infill (den må tåle trykk).
- PLA/PETG. Hvis hengselen sitter fast etter print: bøy forsiktig fram og tilbake til den løsner.

## Bruk
Legg papiret inn mellom delene med forsiden opp og klem hardt. Teksten blir **hevet** på forsiden.
Funker best på 120–300 g papir/kartong. Til tykkere kartong: øk `PAPER_OFF` i scad-fila.
