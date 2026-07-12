# Demo 1: AIAntenna Multiobjective Optimization

## Context
- Workshop: AP-S/URSI 2026, HD-7
- R2026b Prerelease features: substrate support for patchMicrostrip, far-field visualization
- Target: 5-10 min live demo

## Setup
- Antenna: patchMicrostrip on Teflon substrate, 5.8 GHz ISM band
- Tunable ranges (Teflon, 5.8 GHz):
  - Length: 0.014704–0.019894
  - Width: 0.018949–0.025637
  - Height: 0.00030318–0.00041019
  - SubstrateEpsilonR: 1.785–2.415
- Fix SubstrateEpsilonR at default (2.1 for Teflon), optimize over Length, Width, Height

## Trade-off confirmed
- Short/Wide/Tall: BW=85.5 MHz, Gain=6.72 dBi
- Long/Narrow/Low: BW=26.7 MHz, Gain=7.92 dBi
- Clear bandwidth vs. gain conflict

## Demo flow
1. Design patchMicrostrip(Substrate=dielectric("Teflon")) at 5.8 GHz, ForAI=true
2. Show geometry, tunableRanges
3. Define objective function: minimize [-bandwidth, -peakRadiation]
4. Set bounds from tunableRanges (Length, Width, Height)
5. Run paretosearch (3 variables, 2 objectives)
6. Plot Pareto front (BW vs Gain)
7. Pick 2-3 solutions: max-BW, max-gain, balanced
8. Visualize far-field for each (R2026b: beamwidth/peakRadiation with no output args -> plots)
9. Export balanced solution, validate with full-wave (SweepOption="interp")
10. Compare AI vs EM in a table

## Key points to make during demo
- AI surrogate evaluations are instant -> enables optimization that would take hours with full-wave
- Teflon substrate: AI matches EM within ~0.1% on fR, ~4% on BW
- Far-field visualization (new in R2026b) lets you see the pattern shape, not just numbers
- paretosearch: efficient for bounded multiobjective problems

## Full-wave notes
- Use SweepOption="interp" for resonantFrequency/bandwidth (rational fitting speedup)
- beamwidth: 0,0:360 for elevation plane; 0:360,0 for azimuth plane (1-deg resolution)
- peakRadiation: 0:360,0:360

## AI vs EM accuracy (default Teflon design)
- fR: AI=5.848 GHz, EM=5.855 GHz (~0.1% error)
- BW: AI=50.1 MHz, EM=52.1 MHz (~4% error)

---

# Demo 2: Pattern Reconstruction (TBD)
- Will discuss after Demo 1 is complete
