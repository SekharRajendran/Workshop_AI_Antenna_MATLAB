# Antenna demonstration requirements

## Purpose and working context

Build and evaluate an antenna using MATLAB, then extend the selected element
to a coupled 2x2 array and plan its physical feed network. Start from the
requirements in this folder. Generate the MATLAB code, model objects, figures,
and numerical results during this session, and save them under this folder.

Installed MATLAB toolboxes and agent skills may be used. Existing project
scripts, simulations, or answers in parent/sibling folders are not inputs to
this demonstration. Build new model objects rather than reusing objects left
in the MATLAB workspace. Set MATLAB's current folder to this workspace.

These are the revised illustrative demonstration conditions. They are not
the earlier production-style 2.40-2.50 GHz / 70 mm specification. Judge this
exercise against the explicit conditions below and report actual outcomes.

## Single-element requirements

| Parameter | Value or target |
| --- | --- |
| Antenna | Inset-fed microstrip patch, finite square ground plane |
| Center frequency | 2.45 GHz |
| Evaluation band | 2.44-2.46 GHz |
| Reference impedance | 50 ohm |
| Matching | S11 <= -10 dB at every sampled frequency in the band |
| Broadside realized gain | >=5 dBi at 2.440, 2.445, 2.450, 2.455, 2.460 GHz |
| Maximum individual board | 125 x 125 mm |
| Conductor | Copper, finite conductivity |
| Substrate | Air |
| Patch/ground separation | 3.059107 mm |
| Polarization metric | Combined polarization |
| Broadside direction | +z; MATLAB elevation 90 degrees |
| Objective | Smallest passing board; then higher minimum sampled gain |

Use the physical inset-fed patch model available in Antenna Toolbox, checking
its installed API before constructing it. All dimensions below are in mm and
must be converted to meters for MATLAB geometry.

## Baseline geometry

| Dimension | Value |
| --- | --- |
| Square ground-plane side | 122.364285 mm |
| Patch length | 55.063921 mm |
| Patch width | 55.063921 mm |
| Height | 3.059107 mm |
| Inset/notch length | 8.157618 mm |
| Notch width | 6.118213 mm |
| Strip feed width | 3.496122 mm |
| Feed position | [-boardSide/2, 0] in the x-y plane |
| Orientation | Patch in x-y plane; no tilt |

The baseline is a starting candidate, not a guaranteed passing design.
Create its geometry, S11, and 3D directivity at the center frequency.

## Bounded element experiment

After the baseline, plan and evaluate the Cartesian product of these values:

- Board side: 122.364285 or 100 mm.
- Patch length: 55.063921, 55.738173, or 56.440519 mm.
- All other dimensions, copper/air materials, and height remain fixed.

This gives six unique candidates. Label them D1-D6 in order of the first board
size's three lengths, followed by the second board size's three lengths. Reuse
the baseline result if it uses the same model, mesh, and sampled frequencies.
Do not repeat a completed candidate simply because a later prompt asks for
its plot or comparison. Break ties in area using higher gain, then better match.

Use a three-minute soft numerical budget for the six-candidate study and
selected-candidate checks; finish an in-flight solver call, save checkpoints,
and report unfinished work. Agent code generation and user discussion are
outside that numerical budget. Do not invent results for unfinished rows.

## Numerical evaluation and checks

- Use a lambda/16 maximum-edge mesh at 2.45 GHz for screening and fix the mesh
  during each sweep. Check the selected candidate at lambda/24.
- Use fast interpolating S-parameter sweeps for the single element. Include
  every 1 MHz frequency in 2.44-2.46 GHz. A wider 2.20-2.70 GHz context sweep
  may use 5 MHz output samples.
- Check selected-element S11 directly at both band edges and the center.
  Maximum complex-S disagreement with interpolation must be <=0.01 for the
  demo check. Use direct solves if interpolation fails its check.
- Evaluate gain at the five stated frequencies on both screening and selected
  meshes. State minimum sampled gain; do not claim continuous-band proof.
- Report mesh sensitivity in matching and gain. Do not label a two-mesh check
  as full convergence qualification.
- Keep directivity distinct from realized gain. Label units and frequency.
  When exporting 3D graphics, verify that titles/units appear in the image.

Create a candidate table including dimensions, board area, worst sampled S11,
minimum sampled realized gain, and pass/fail. Plot board area versus minimum
sampled gain, highlighting feasible designs. Reuse this session's results for
later views. Save source code, inputs, numerical data, figures, and a check
summary so the work can be reproduced.

If asked to adjust the demo conditions, first explain whether adjustment is
necessary. Retain these targets if candidates already meet them. For a failure,
diagnose geometry, solver, and numerical checks before proposing a specific
change. Record any changed conditions and reevaluate the affected candidates.
A numerically invalid result is not a reason to relax an RF target.

## Coupled 2x2 extension, when requested

- Use the newly selected element, four independent finite boards, identical
  orientation, and equal in-phase incident waves at the four 50-ohm ports.
  Total incident power is 1 W across the array, not 1 W per element.
- For a selected 100 mm board, compare center spacings 105, 112, and 120 mm in
  both x and y. Check gaps and total footprint. If another board is selected,
  derive three non-overlapping spacings instead of forcing these values.
  The 125 mm individual-board limit is not an overall array-outline limit.
- Model antenna mutual coupling with the full four-port EM S-matrix. Do not
  replace this with an ideal array factor alone or connect separate ground
  planes into a shared panel without describing the new geometry.
- Use direct S-parameter samples every 1 MHz across the demo band. Multiport
  interpolation needs explicit direct-solve validation if used as an alternative.
- Compute active reflection (S*a)_i/a_i with all ports excited, and show ordinary
  Sii and off-diagonal coupling separately. Target active reflection <=-10 dB
  and minimum broadside realized gain >=5 dBi at the band edges and center.
- Use a common lambda/16 screening mesh rule for all spacings, then lambda/24
  for the selection. Choose the smallest passing spacing within 0.5 dB of the
  best minimum sampled gain. Report coupling; no separate coupling limit is set.
- Keep excitation and power conventions consistent. For 50-ohm power waves,
  Vpeak=sqrt(2*Z0)*(a+S*a) and Ipeak=sqrt(2/Z0)*(a-S*a). Check whether the
  array object's taper specifies terminal voltage or incident waves and apply
  the conversion needed by the installed MATLAB implementation.
- Verify reciprocity, passivity, currents/power normalization, and mesh
  sensitivity. Compare coupled patterns with an explicitly labeled isolated-
  element reference at the same total incident power.
- Show array geometry, coupling/active-match curves, a spacing table, and a
  3D realized-gain pattern. State whether feed-network loss is modeled.
- Budget at most three spacing trials and one finer check, with a ten-minute
  soft numerical limit. Save checkpoints and state incomplete evaluations.
  Generate and execute this array model in the current session; do not replay
  an older project study as fresh evidence.

## Feed-network planning, when requested

Plan at most six additional candidates to assess spacing, low-loss versus FR4
feed substrate, Wilkinson versus matched tee division, and equal-length route
reduction. Keep the radiator's air substrate unchanged unless explicitly
redesigning it. Define physical connectivity from a separate distribution
module to the four boards; a shared ground or nearby feed structure changes
which EM model can be reused.

Propose an input-referenced broadside gain goal of >=14 dBi after modeled feed
losses over the same band, input S11 <=-10 dB, amplitude spread <=0.5 dB, and
relative phase spread <=5 degrees. Treat this as a proposed next-study goal,
not an achieved result. Report the actual gain margin available from the array
just evaluated. Use a proposed <=0.75 dB feed power-delivery budget as an initial
screen; the loaded end-to-end gain must ultimately be calculated.

Explain MATLAB line and splitter modeling with RF PCB Toolbox and network
connection using RF Toolbox. Retain multiple reflections between the five-port
feed and four-port antenna. The inset feed strip already belongs to the element
model; avoid counting it twice. Include loss, routing phase, termination, and
any modeled connector transitions. An ideal -6.02 dB output from a four-way
splitter divides power; it is not 6 dB dissipative loss.

The feed-candidate request is a planning task unless the user explicitly asks
to run the new feed study. Mark untested candidates as planned; do not predict
passing results by subtracting assumed feed losses from an antenna-only gain.
