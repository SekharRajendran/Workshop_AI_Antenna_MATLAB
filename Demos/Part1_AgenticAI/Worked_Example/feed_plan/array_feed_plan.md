# Planned 2x2 array and physical feed candidates

Keep the four selected D6 100 x 100 mm copper/air radiators unchanged. Start
with F1, then prioritize F4: low-loss feed laminate, two-stage Wilkinson
division, shortened equal-length routing, and 105 mm center spacing.
All six candidates are **Planned**. No feed-network performance has been
evaluated. This is a controlled screening plan, not a full factorial study.

## Proposed next-study goals

Over 2.440-2.460 GHz, target input-referenced combined-polarization broadside
gain >=14 dBi, input S11 <=-10 dB, antenna incident-wave amplitude spread
<=0.5 dB and relative phase spread <=5 degrees. Source reference impedance
is 50 ohm; source incident power is 1 W total. Start with 21 frequency points
at 1 MHz spacing, including all gain/balance metrics. Report sampled-band
results; refine frequency sampling where needed before a continuous-band claim.

Initially screen the complete feed with four matched loads for <=0.75 dB
power-delivery loss: -10 log10(sum(abs(Sfeed(2:5,1)).^2)). This metric includes
input mismatch and dissipative/radiative feed losses in the specified model.
An ideal four-way divider has four -6.0206 dB outputs and **0 dB total
delivery loss**. The loaded antenna network must still meet the final goals.

## Candidate table

| ID | Test order | Spacing / array outline (mm) | Feed material | Two-stage divider | 50-ohm route per path (mm) | Purpose | Status |
|---|---:|---|---|---|---:|---|---|
| F1 | 1 | 105 / 205 x 205 | Low loss | Wilkinson | 100 | Reference | Planned |
| F2 | 3 | 105 / 205 x 205 | FR4 | Wilkinson | 100 | Material comparison with F1 | Planned |
| F3 | 4 | 105 / 205 x 205 | Low loss | Matched tee | 100 | Topology comparison with F1 | Planned |
| F4 | 2 | 105 / 205 x 205 | Low loss | Wilkinson | 60 | Route reduction versus F1; priority option | Planned |
| F5 | 5 | 112 / 212 x 212 | Low loss | Wilkinson | 60 | Spacing comparison with F4 | Planned |
| F6 | 6 | 120 / 220 x 220 | Low loss | Wilkinson | 60 | Spacing comparison with F4 | Planned |

Array outline excludes the separate distribution module, connectors and cable
envelope. Module dimensions and assembled-system footprint remain to be laid
out. The 125 mm limit applies to each antenna board.

Assume a 0.813 mm feed laminate and 35 micrometer copper, conductivity
5.96e7 S/m. Use explicit provisional material models: low loss epsilon_r=3.55,
tan(delta)=0.0027; FR4 epsilon_r=4.30, tan(delta)=0.020. These are planning
assumptions, not certified properties of a named laminate. Replace them with
supplier design values before final validation. The radiator stays on air.

RF PCB Toolbox geometry synthesis at 2.45 GHz produced these initial
dimensions (not EM-verified line impedances or divider layouts):

| Feed material | 50-ohm width (mm) | 70.71-ohm width (mm) | 70.71-ohm quarter-wave length (mm) |
|---|---:|---:|---:|
| Low loss, assumed | 1.7707 | 0.9299 | 18.788 |
| FR4, assumed | 1.5316 | 0.7774 | 17.379 |

The MATLAB planning function ran successfully in the connected R2026b
session, preserved the specified substrate height, and passed Code Analyzer
without findings. No feed S-parameter or field evaluations were performed.

All paths contain 50-ohm input/interstage/output routing and two splitter
levels. The nominal 50-ohm length allocation is 10+30+60 mm for F1-F3 and
10+15+35 mm for F4-F6. These are layout targets, not established routable
dimensions. Count the splitter's built-in 50-ohm port lines within this total,
once. Quarter-wave matching arms and cable/connector lengths are additional.
Use the same nominal four 300 mm, 50-ohm, phase-matched low-loss coax jumpers
for all candidates, subject to a mechanical reach/bend-radius check.

Each 1:2 Wilkinson uses nominal 70.71-ohm quarter-wave arms and a 100-ohm
isolation resistor; three such dividers make a 1:4 network, two on each path.
For the tee candidate, transform each 50-ohm downstream load to 100 ohm at
the junction, for example with a 70.71-ohm quarter-wave arm, giving 50 ohm
in parallel. A bare tee with two 50-ohm branches is not input matched.
The matched tee has no Wilkinson isolation; it cannot simultaneously match
and isolate all three ports as a lossless reciprocal three-port. Verify its
response to unequal, mutually coupled antenna loads. Do not assume a tee
is less lossy: a Wilkinson's resistor ideally dissipates no power for equal
matched loads, but absorbs imbalance/reflections in practice.

Equalize complete **electrical** path length, including both splitter stages,
line dispersion, bends, launches and coax, not just PCB trace length. Keep
all four output phases equal across the band. The full 5-degree phase budget
is only 5.65 ps at 2.46 GHz; allocate less than that to routing mismatch so
connectors, laminate tolerances and splitter imbalance have room.

## Evidence behind the spacing suggestion

These are the saved lambda/16 antenna-only results at equal in-phase
incident waves, with 1 W total incident power and no feed losses:

| Spacing (mm) | Worst active reflection (dB) | Strongest coupling (dB) | Minimum sampled gain (dBi) | Margin to 14 dBi (dB) |
|---:|---:|---:|---:|---:|
| 105 | -12.4227 | -28.7342 | 14.9703 | 0.9703 |
| 112 | -12.8569 | -31.3192 | 15.0754 | 1.0754 |
| 120 | -12.6258 | -33.7802 | 15.0814 | 1.0814 |

Gain was sampled at 2.440, 2.450 and 2.460 GHz; S was sampled every 1 MHz.
Widening from 105 to 120 mm adds only 0.1111 dB minimum sampled gain, so
reducing routing and transition loss is a promising first direction. These
margins do not predict loaded gain by subtraction of an assumed feed loss.
Finer array verification remains incomplete (17/21 S samples, 0/3 gain
samples). The 3D coupled pattern and remaining power/field checks are pending.
The previous array numerical budget is exhausted and is not reset here.

## Physical connection and EM reuse

Place the separate distribution module laterally outside the antenna-board
outline, initially on the rear side. Use one input connector and four output
connectors. Route four shielded coax jumpers behind the boards, with center
conductors connected through board-edge launches to the existing D6 feed
ports, and shields bonded locally to the corresponding finite ground board.
Verify cable reach and equalize electrical lengths after module placement.
Do not join the four boards with a new conducting support panel.

The four antenna reference planes are the existing board-edge excitation
ports, ordered at spacing/2 times [-1,-1,0], [1,-1,0], [-1,1,0], [1,1,0].
Feed output ports 2-5 map to those four ports in order. The inset strip is
already in each antenna model. Model each new launch only up to that plane;
do not add another copy of the inset strip or duplicate a connector model.

Coax shields still create conducted ground connections through the module;
they are not physically independent grounds. A network connection treats
only differential port waves and neglects exterior shield/common-mode
currents and direct scattering. Cached four-port antenna S-matrices can be
used for **provisional circuit screening** if board geometry, orientation,
spacing, and reference planes are unchanged. Reuse for final prediction
requires showing that the added module, cables and launches do not
significantly perturb the radiating structure. A nearby feed ground, a shared
ground panel, rerouted metal near the patches, or appreciable shield currents
requires a new integrated EM model and new fields/S-matrices. No universal
module stand-off is claimed to guarantee negligible interaction.

## MATLAB modeling and loaded evaluation

Run ` [feedCandidates,feedPlan] = planArrayFeedCandidates; ` in this folder.
The function creates the candidate table, two material definitions and four
RF PCB Toolbox `microstripLine` starting templates (50 and 70.71 ohm on each
material). `design(...,Z0=...,LineLength=0.25)` synthesizes nominal transformer
dimensions; it does not evaluate the complete feed. The script saves CSV/MAT
files in this folder and performs no EM or S-parameter solves.

For the future study:

1. Lay out physical `wilkinsonSplitter` or matched `splitterTee` unit cells
   with RF PCB Toolbox, including matching sections and resistor parasitics.
   Set substrate before synthesis and verify thickness/dimensions afterward.
   Use `microstripLine` for uniform routes and physical bend/junction/launch
   models for discontinuities. Include finite conductor/dielectric loss,
   selected resistor/package data, and connector/cable two-port S-data.
   Unknown transitions are unresolved inputs, not zero-loss through lines.
2. Check mesh/memory and runtime on one unit cell before assembling an EM
   mesh of an entire four-way divider. Reuse unit-cell responses between
   candidates where geometry/material/ports match. Validate any omitted
   inter-branch electromagnetic coupling at the final layout stage.
3. For PCB EM responses use a fast interpolating sweep, checked against
   direct complex S at band edges and center (proposed max error <=0.01).
   Use direct samples if it fails. Keep loss, reciprocity and passivity checks.
4. In RF Toolbox, wrap physical response data with `nport`, connect them
   with `circuit`/`add`, and use `setports` once to expose the source plus four
   board-edge outputs. Each nport maps all positive terminals followed by
   all negative terminals. Use independent nport instances for repeated cells.
   The five-port retains output-to-output transmission and reflections;
   four separate forward S21 chains or a scalar RF budget cannot replace it.
   Use matched 50-ohm loads only for the standalone feed screen. For loaded
   evaluation replace those four loads with the full coupled antenna S.
5. Use the feedback equations below at every sampled frequency, at consistent
   50-ohm reference planes, to retain all feed/antenna multiple reflections.
6. Obtain four complex embedded antenna field responses for unit incident
   waves (other incident waves zero, other ports matched), then combine them
   with the loaded complex weights. Cached equal-excitation gains alone
   cannot reconstruct an arbitrary loaded pattern. Alternatively solve the
   coupled antenna under each loaded excitation using the installed voltage
   taper convention Vpeak=sqrt(2*50)*(aAnt+Sant*aAnt).
7. Compute gain from combined E/H radial power flux divided by source
   incident power, not antenna accepted power. Check input S11, amplitude/
   phase spread of aAnt, active reflection, accepted power, and total power
   balance. Verify the selected final geometry's mesh sensitivity and pattern.

Per-frequency loaded-wave calculation, where `Sf` is the complete five-port
feed S-matrix and `Sa` is the corresponding four-port antenna S-matrix:

```matlab
aSource = 1;                         % sqrt(W): 1 W incident at source port
Soo = Sf(2:5,2:5);
t = Sf(2:5,1);
aAnt = (eye(4)-Soo*Sa) \ (t*aSource);
bAnt = Sa*aAnt;
bSource = Sf(1,1)*aSource + Sf(1,2:5)*bAnt;
inputS11_dB = 20*log10(abs(bSource/aSource));
acceptedAntenna_W = sum(abs(aAnt).^2)-sum(abs(bAnt).^2);
feedLoss_W = abs(aSource)^2-abs(bSource)^2-acceptedAntenna_W;
amplitudeSpread_dB = 20*log10(max(abs(aAnt))/min(abs(aAnt)));
relativePhase_deg = rad2deg(angle(aAnt*conj(aAnt.')));
phaseSpread_deg = max(abs(relativePhase_deg),[],'all');
% E = sum_i(aAnt(i)*Eembedded_i), likewise H; use complex vector fields.
% Ginput = 4*pi*r^2*0.5*real(dot(cross(E,conj(H)),rhat))/abs(aSource)^2.
```

Here feedLoss_W includes non-port power loss represented by Sf, including
modeled feed radiation. If such radiation affects the array pattern, compute
the integrated feed-plus-antenna fields. Assume a matched source; an actual
nonzero source reflection coefficient needs another feedback connection.
Check feedback-system conditioning, passivity, and nonnegative power balances
within numerical tolerance. Directivity requires total radiated power and
must remain distinct from this input-referenced gain.

## Bounded sequence and decision

Propose a new 600-second soft **numerical** feed-screen budget, separate from
the already exhausted antenna-array study. This planning run does not start
it. Time one representative PCB unit-cell solve before committing; checkpoint
after each completed result, finish an in-flight call, then stop at the limit.
Do not silently expand the budget or label incomplete rows as passing.

Evaluate F1, F4, F2, F3, F5, F6. Screen delivery, match and balance first;
evaluate full loaded fields only for survivors. At most six nominal feed
candidates; use the comparison pairs to identify causes of improvement.
This plan does not resolve all material/topology/routing interactions.

Select the smallest assembled design that meets all sampled loaded goals
and required numerical checks; compare fabrication cost and margin among
passing options. Carry out material, etch-width, connector and cable-phase
tolerance checks on the finalist as a subsequent bounded verification stage.
If F4 misses 14 dBi, diagnose actual splitter/line/connector losses and
loaded mismatch/phase before spending area on F5/F6. No feed candidate is
currently feasible by evidence; all have unknown loaded performance.
