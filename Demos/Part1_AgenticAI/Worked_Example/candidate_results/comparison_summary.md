# Bounded antenna experiment results

Generated from this session's saved numerical results. Targets were unchanged.

| Candidate | Board side (mm) | Patch length (mm) | Area (mm^2) | Worst S11 (dB) | Min realized gain (dBi) | Match | Gain | Screening |
|---|---:|---:|---:|---:|---:|---|---|---|
| D1 | 122.364285 | 55.063921 | 14973.018 | -3.7844 | 7.1920 | Fail | Pass | Fail |
| D2 | 122.364285 | 55.738173 | 14973.018 | -14.0105 | 9.3511 | Pass | Pass | Pass |
| D3 | 122.364285 | 56.440519 | 14973.018 | -7.0198 | 8.5916 | Fail | Pass | Fail |
| D4 | 100.000000 | 55.063921 | 10000.000 | -3.9023 | 6.8164 | Fail | Pass | Fail |
| D5 | 100.000000 | 55.738173 | 10000.000 | -6.9405 | 8.1318 | Fail | Pass | Fail |
| D6 | 100.000000 | 56.440519 | 10000.000 | -12.3023 | 8.8993 | Pass | Pass | Pass |

Screening: fixed lambda/16 maximum-edge mesh (7.647767 mm at 2.45 GHz).
Matching: S11 <= -10 dB at all 21 samples, 2.440:0.001:2.460 GHz, 50 ohm.
Gain: combined-polarization broadside realized gain >= 5 dBi at 2.440, 2.445, 2.450, 2.455, 2.460 GHz.
Broadside is +z (azimuth 0 degrees, elevation 90 degrees). Realized gain includes mismatch and loss.
All geometry/material checks passed if GeometryMaterialsPass is true in candidate_comparison.csv.
Each model uses copper (5.96e7 S/m, 0.03556 mm thick), air, 3.059107 mm separation, and zero tilt.
Patch width is 55.063921 mm; notch and strip widths/length remain at the specified baseline values.
Feed placement follows [-boardSide/2, 0]. Both square board sizes meet the 125 mm limit.
D1 S11 was reused; its realized gain was newly calculated. Other screening results were newly generated.

Study status: complete_finalist_checked
Numerical time including baseline: 31.619 / 180 seconds.
No full 3D patterns were recomputed for this comparison.

## Finalist: D6

Selected screening candidate: D6; finer-mesh verification passed: 1.
Selection rule: smallest feasible board area, then higher minimum sampled gain, then better matching.
Board 100.000000 x 100.000000 mm; patch 56.440519 x 55.063921 mm.

| Metric | lambda/16 | lambda/24 | Fine minus coarse |
|---|---:|---:|---:|
| Worst band S11 (dB) | -12.302277 | -12.159905 | +0.142372 |
| Minimum sampled realized gain (dBi) | 8.899258 | 8.899900 | +0.000642 |
| Maximum complex-S interpolation error | 2.17369265e-05 | 2.40674015e-05 | -- |

Direct interpolation checks use 2.440, 2.450 and 2.460 GHz; the complex-S tolerance is 0.01.
Direct full-band fallback used: screening 0; fine 0.
Maximum frequency-by-frequency S11 mesh change: 1.054752 dB.
Maximum frequency-by-frequency realized-gain mesh change: 0.058636 dB.

Only the selected candidate received the lambda/24 check. Other passing candidates have screening evidence.
This is a two-mesh sensitivity check, not full mesh convergence qualification.
Passing sampled gain does not prove continuous-band performance.
Array and feed-network requirements belong to later requested studies.
