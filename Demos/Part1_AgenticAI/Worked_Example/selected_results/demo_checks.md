# Selected antenna: D6 demo checks

D6 meets the sampled single-element requirements and passed the specified finalist checks.
D2 and D6 passed screening. D6 was selected for its smaller board area; D2 was not fine-mesh checked.

| Check | Result |
|---|---|
| Individual board size | 100 x 100 mm; within 125 x 125 mm |
| Patch size | 56.440519 x 55.063921 mm |
| Model and materials | Physical inset-fed patch; finite copper; air; 3.059107 mm gap; zero tilt |
| Worst S11 over 21 samples, 2.44-2.46 GHz | -12.159905 dB <= -10 dB: PASS |
| Minimum broadside realized gain over five frequencies | 8.899900 dBi >= 5 dBi: PASS |
| Maximum complex-S interpolation error, lambda/16 | 2.17369265e-05 <= 0.01: PASS |
| Maximum complex-S interpolation error, lambda/24 | 2.40674015e-05 <= 0.01: PASS |
| Worst-band S11 change, fine minus coarse | +0.142372 dB |
| Minimum-gain change, fine minus coarse | +0.000642 dB |
| Maximum samplewise S11 mesh change | 1.054752 dB |
| Maximum samplewise gain mesh change | 0.058636 dB |
| Broadside directivity at 2.45 GHz | 9.278248 dBi |
| Peak sampled 3D directivity at 2.45 GHz | 9.278248 dBi |
| Numerical time including baseline, study, and new directivity | 32.947 s / 180 s |

Gain frequencies: 2.440, 2.445, 2.450, 2.455, 2.460 GHz. Broadside: azimuth 0, elevation 90 degrees.
Direct S11 checks: 2.440, 2.450, 2.460 GHz. Both meshes passed interpolation validation; no direct-band fallback was needed.
Mesh edge rules at 2.45 GHz: lambda/16 = 7.647767 mm; lambda/24 = 5.098511 mm.
Directivity describes radiation concentration; it is distinct from realized gain, which includes radiation and mismatch losses.
This is a two-mesh sensitivity check, not full convergence qualification. Gain conclusions are limited to the five sampled frequencies.
All six screening candidates and the selected-candidate checks completed. No requirements were relaxed.
The saved S11 and realized-gain results were reused. Only the selected antenna's 3D directivity was newly calculated.
