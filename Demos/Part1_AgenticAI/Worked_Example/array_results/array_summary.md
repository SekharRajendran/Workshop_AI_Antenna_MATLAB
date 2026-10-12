# Coupled 2x2 D6 array study

Four independent 100 x 100 mm copper/air inset-fed patch boards, all identically oriented.
D6 patch: 56.440519 x 55.063921 mm; air gap 3.059107 mm; original notch and strip dimensions retained.
All four ports use 50-ohm reference impedance and equal, in-phase incident waves: a = [0.5;0.5;0.5;0.5] sqrt(W).
Total incident power is 1 W (0.25 W per port). Physical feed-network and connector losses are not modeled.
Full 4x4 EM S-matrices were computed directly at 2.440:0.001:2.460 GHz, including mutual coupling.
Active reflection is (S*a)_i/a_i. It is distinct from Sii, which assumes the other ports are matched.

## Screening results: fixed lambda/16 mesh

| Spacing (mm) | Board gap (mm) | Footprint (mm) | Worst active reflection (dB) | Strongest coupling (dB) | Min broadside realized gain (dBi) | Status |
|---|---|---|---:|---:|---:|---|
| 105 | 5 | 205 x 205 | -12.4227 | -28.7342 | 14.9703 | Pass |
| 112 | 12 | 212 x 212 | -12.8569 | -31.3192 | 15.0754 | Pass |
| 120 | 20 | 220 x 220 | -12.6258 | -33.7802 | 15.0814 | Pass |

Pass targets: active reflection <= -10 dB at every port/frequency, and realized gain >= 5 dBi at 2.440, 2.450, 2.460 GHz.
No separate coupling limit was imposed. Gain is combined polarization at +z, referenced to total incident power.
Selection: smallest passing spacing within 0.5 dB of the best minimum sampled gain among passing spacings.
Study status: budget_exhausted
Numerical time: 12478.363 / 600 seconds.

## Excitation and numerical checks

The installed conformalArray implementation defines AmplitudeTaper in volts and uses a voltage source.
Set terminal peak phasors V=sqrt(2*Z0)*(a+S*a) through AmplitudeTaper=abs(V), PhaseShift=angle(V).
Check feedCurrent against I=sqrt(2/Z0)*(a-S*a), recover a=(V+Z0*I)/sqrt(8*Z0), and compare terminal and wave power.
Use Paccepted = ||a||^2-||S*a||^2 = 0.5*real(sum(V.*conj(I))).
Gain is calculated from the coupled E/H fields: G=4*pi*r^2*0.5*real((E cross conj(H)) dot rhat)/Pincident.
Fields are sampled at 100 m. The planned doubled-distance check tests the selected center-frequency far-field estimate.
Checks use max |S-S transpose| <= 0.001, largest singular value <= 1.001, relative current/incident-wave errors < 0.001, and power mismatch < 0.001 W.
The array mesh is checked for triangles bridging the gaps; no shared ground panel is introduced.

Spacing 105 mm: 21/21 direct S samples; reciprocity error 5.64212e-16; max singular value 0.282961.
Spacing 112 mm: 21/21 direct S samples; reciprocity error 4.09924e-16; max singular value 0.286712.
Spacing 120 mm: 21/21 direct S samples; reciprocity error 4.04188e-16; max singular value 0.284171.

## Provisional spacing recommendation

Recommend 105 mm center spacing in x and y from screening: 5 mm board gaps and 205 x 205 mm footprint.
Minimum sampled gain 14.970269 dBi, within 0.111145 dB of the best screening result.
Max relative current error 2.10236e-16; incident-wave error 1.11152e-16; terminal/wave-power disagreement 1.11022e-16 W.
Finer-mesh verification is incomplete: 17/21 direct S samples and 0/3 gain samples saved.
The partial finer-mesh results are preserved in array_study.mat and are not reported as a complete pass.
The active-match, coupling and gain figures use the completed lambda/16 screening results.
A solver call overran the soft numerical budget. No additional solver calls were started afterward.
Longest recorded solver-call elapsed interval: 12152.585 seconds. This is wall-clock time, not CPU-only time.


## Pending pattern checks

The coupled 3D realized-gain pattern, isolated-element pattern comparison, integrated radiated-power check,
and doubled-distance far-field check remain pending because the numerical budget was exhausted.
The saved broadside gains are the actual full coupled E/H field calculations, not an ideal array-factor estimate.
