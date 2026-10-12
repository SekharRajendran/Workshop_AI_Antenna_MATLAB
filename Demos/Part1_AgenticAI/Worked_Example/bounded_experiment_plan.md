# Bounded single-element antenna experiment

Status: planned. No additional simulations have been run for this plan.

## Objective and scope

Compare exactly six physical inset-fed microstrip patch candidates. Select the
smallest board that satisfies sampled matching and broadside realized-gain
requirements. Break equal-area ties using higher minimum sampled realized
gain, then lower (more negative) worst sampled S11.

Keep the requirements in antenna_demo_requirements.md unchanged. This plan
covers single elements only; array spacing and feed-network studies are later
stages. There is no open-ended optimization or additional geometry search.

## Experimental factors

Use the full Cartesian product of two square-board sides and three patch
lengths. Candidate identifiers remain fixed regardless of execution order.

| Candidate | Board side (mm) | Patch length (mm) | Board area (mm^2) | Existing evidence / planned work |
|---|---:|---:|---:|---|
| D1 | 122.364285 | 55.063921 | 14973.018 | Reuse saved S11; calculate five missing realized-gain samples |
| D2 | 122.364285 | 55.738173 | 14973.018 | New screening model, S11 and gain |
| D3 | 122.364285 | 56.440519 | 14973.018 | New screening model, S11 and gain |
| D4 | 100.000000 | 55.063921 | 10000.000 | New screening model, S11 and gain |
| D5 | 100.000000 | 55.738173 | 10000.000 | New screening model, S11 and gain |
| D6 | 100.000000 | 56.440519 | 10000.000 | New screening model, S11 and gain |

The smaller board reduces area by 33.21%. Increasing patch length is expected
to lower the patch resonance, but its effect on matching and gain must be
measured. Reducing the finite ground-plane size can change both matching and
radiation; no candidate is presumed to pass.

## Controlled settings

- Model: Antenna Toolbox patchMicrostripInsetfed, physical full-wave model.
- Patch width: 55.063921 mm; height/air gap: 3.059107 mm.
- Notch length: 8.157618 mm; notch width: 6.118213 mm.
- Strip feed width: 3.496122 mm.
- FeedOffset: [-boardSide/2, 0], so its x position is -61.1821425 mm on the
  larger board and -50 mm on the smaller board. Keep the board-edge feed rule,
  rather than retaining the larger board's absolute feed coordinate.
- PatchCenterOffset: [0, 0]; patch in the x-y plane; zero tilt.
- Substrate: air. Conductor: finite-conductivity copper. Preserve baseline
  catalog values: conductivity 5.96e7 S/m and thickness 0.03556 mm.
- Reference impedance: 50 ohm. Center frequency: 2.45 GHz.
- Pattern metric: absolute, combined-polarization realized gain at +z
  (azimuth 0 degrees, elevation 90 degrees), referenced to 50 ohm.
- Convert geometry from millimeters to meters before construction.

## Existing baseline and reuse

Use this session's baseline_results/baseline.mat and its saved configuration,
mesh, frequency vector, and complex S11 values. Check agreement with the D1
settings before reuse. Do not use objects or studies from other sessions or
parent/sibling folders. Construct fresh objects for D2-D6 and the finer mesh.

D1 already has a fixed lambda/16 mesh and the required frequency samples:

- Direct S11 at 2.45 GHz: -4.2112 dB.
- Worst sampled S11 in the evaluation band: -3.7844 dB; matching fails.
- Maximum complex-S interpolation check error: 2.2247669e-5; check passes.
- Broadside directivity at 2.45 GHz: 9.6603 dBi.

The saved directivity is not realized gain. D1 still needs the five requested
gain samples for the complete comparison table, even though matching already
fails. Reuse completed D1 S11 and directivity work without repeating solves.

## Screening protocol

1. Check configuration, dimensions, units, finite conductivity, and material
   consistency. Verify the installed realized-gain API and its 50-ohm reference
   convention before calculating the new gain samples.
2. Use maximum mesh edge lambda0/16 = 7.6477668 mm at 2.45 GHz. Fix the mesh
   for all frequency and gain calculations on each candidate.
3. Reuse D1 S11. For D2-D6, run sparameters with SweepOption="interp" using
   the same 117-point output vector as the baseline: the union of
   2.20:0.005:2.70 GHz and 2.440:0.001:2.460 GHz. This retains the wide-band
   context and all 21 required in-band samples on identical frequency grids.
4. For every candidate, compute broadside realized gain at 2.440, 2.445,
   2.450, 2.455, and 2.460 GHz. Avoid full 3D pattern calculations during
   screening; only the five broadside values are needed for selection.
5. Save each result as it completes. Record timing, mesh, complex S11, gain
   samples, and any numerical errors. Missing values remain missing.

Screening passes only when both of the following hold:

- Maximum S11 in dB over all 21 in-band samples is <= -10 dB.
- Minimum of the five broadside realized-gain samples is >= 5 dBi.

Both board sizes satisfy the 125 x 125 mm individual-board limit. Nonfinite
or otherwise invalid numerical results are marked invalid, rather than
treated as RF passes. A missing metric is marked incomplete, not estimated.

## Selection and numerical verification

Rank screening-feasible candidates by ascending board area, descending
minimum sampled realized gain, and ascending worst sampled S11 in dB.

For the first-ranked candidate:

1. Directly evaluate S11 at 2.440, 2.450, and 2.460 GHz on the screening mesh.
   Require max(abs(S11_direct - S11_interpolated)) <= 0.01 in complex linear
   units, not a difference of S11 magnitudes in dB.
2. If interpolation fails, replace the 21 in-band samples with direct solves
   before judging that candidate. If its corrected screening result fails,
   consider the next screening-feasible candidate while budget remains.
3. Perform at most one lambda0/24 finalist evaluation, with maximum edge
   5.0985112 mm. Use the same fixed-mesh sweep frequencies, all five gain
   samples, and three direct S11 checks. If interpolation fails on this mesh,
   use direct in-band solves, subject to the same numerical budget.
4. Report changes in worst sampled S11, minimum sampled gain, and their
   frequency-by-frequency values between meshes. Apply the original RF
   thresholds to the finer results. Report rank changes if observed.

A finalized selection requires completed interpolation/direct-solve checks
and passing finer-mesh RF results. If the sole finer-mesh finalist fails,
report that the experiment produced no verified selection; do not silently
add more finer-mesh trials. If no screening candidate passes, report that
outcome without choosing a nominal winner. If work stops before all candidates
are evaluated, any choice is provisional among evaluated candidates only.

This is a two-mesh sensitivity check, not full convergence qualification.
Gain conclusions apply to the five sampled frequencies, not every frequency
between them. No extra mesh-difference tolerance is imposed by this plan.

## Numerical budget and stopping rules

Use a 180-second soft cumulative numerical budget. Conservatively charge the
already completed baseline numerical work (7.074 seconds), leaving about
172.926 seconds for the remaining screening and checks. Code generation,
discussion, report formatting, and plotting cached data are outside this
numerical budget.

Plan approximately 120 seconds total for screening (including the baseline)
and reserve the remaining approximately 60 seconds for finalist checks.
These are scheduling allowances, not predictions of solver runtime. Nominal
order is D1's missing gain samples, then D2-D6; checkpoint after each solver
call and candidate. Do not skip gain evaluation simply because matching fails.

Check accumulated numerical time before starting each meshing, S-parameter,
or gain calculation. Never start a new numerical call after the 180-second
budget has been reached. Finish an in-flight call, save it, and report any
overrun and unstarted work. If screening consumes the validation reserve,
report unfinished checks rather than claiming a verified winner.

The bounds are six unique screening candidates, at most one finer-mesh
finalist, and the necessary direct checks/fallbacks within the soft budget.
Replotting or later comparisons must load saved data instead of recomputing.

## Planned deliverables

- MATLAB source and a saved configuration for the experiment.
- Per-candidate models, mesh settings, numerical samples, timings, and status.
- A six-row comparison table with board and patch dimensions, board area,
  worst sampled S11, minimum sampled realized gain, and separate matching,
  gain, and overall screening status; untested entries remain marked planned
  or incomplete. Keep screening status distinct from finalist validation.
- Board area versus minimum sampled realized gain, with candidate labels and
  screening-feasible designs highlighted.
- Overlaid S11 curves, five-frequency gain comparisons, and the finalist's
  numerical check summary if a finalist is available.
- A record of pending/invalid work, interpolation errors, mesh sensitivity,
  and cumulative numerical time, preserving the baseline files.

If candidates fail, inspect geometry, feed placement, input impedance, mesh,
and interpolation evidence before proposing a later change. Retain the
current targets whenever any candidates pass. Do not relax an RF target to
compensate for an invalid numerical result.
