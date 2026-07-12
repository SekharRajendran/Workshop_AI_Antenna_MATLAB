# Demo 1: Talking Points

Voice-over content for narration during live demo pauses.

## While paretosearch runs (~50 seconds)

- "We're optimizing a V2X roadside antenna for the 5.9 GHz band. We want maximum gain for the link budget, and wider bandwidth gives us margin for manufacturing tolerances and multi-channel operation. These two objectives compete with each other, and we need to see the trade-off."

- "We also have a nonlinear constraint that keeps the resonant frequency within plus or minus 2% of 5.9 GHz. Without this, the optimizer could exploit geometries that achieve high bandwidth or gain by shifting the resonance away from the V2X band — technically optimal but practically useless."

- "The optimizer evaluates the AI surrogate hundreds of times — around 500 function evaluations — each calling both bandwidth and peakRadiation, plus resonantFrequency for the constraint check. With full-wave EM simulation, each evaluation requires a frequency sweep plus a full-sphere far-field computation — several minutes per evaluation. At that rate, this could take days. With the AI surrogate, we get the full Pareto front in under a minute."

- "The AI models are single-output machine learning models — one model per metric. Bandwidth, beamwidth, and peakRadiation are each predicted independently. A resonance-tracking algorithm ensures each model follows the correct mode as geometry changes, so the predictions stay physically meaningful across the tunable range."

- "paretosearch is a direct-search multiobjective optimizer — no gradients needed. It's well suited for bounded problems with inexpensive evaluations, which is exactly what we have with the AI surrogate."

## After Pareto front appears

- "Notice the red X — that's where the initial `design` output sits. Every blue point on this curve is a noninferior point: you can't improve one objective without worsening the other. The initial design is dominated — the optimizer found solutions that beat it in both bandwidth and gain simultaneously."

- "Look at the trade-off: we can push bandwidth up to about 65 MHz — a 28% improvement over the baseline 51 MHz — or we can maximize gain to nearly 8 dBi. The frequency constraint limits how far we can push, because it forces all solutions to stay within 2% of 5.9 GHz. That's a real-world constraint — an antenna that shifts off-band is useless regardless of its other metrics."

- "The balanced solution in the middle improves both objectives over the initial design. That improvement may look modest in absolute terms, but remember: the optimizer explored hundreds of geometries in under a minute, something that could take days with full-wave simulation. This kind of rapid what-if exploration early in the design cycle is exactly what the AI surrogate enables — you get the speed to map out trade-offs systematically, with the accuracy of full-wave EM backing it up when you're ready to commit."

## While resonantFrequency (EM) runs (~3 minutes)

- "Now we validate the balanced Pareto solution with full-wave EM simulation. This is the recommended workflow: AI for exploration, full-wave for confirmation before fabrication."

- "We're using SweepOption='interp' — MATLAB solves the EM system at a sparse set of frequencies and fits a rational function to the S-parameters, then evaluates at all 1001 frequency points. Fine frequency resolution at minimal additional cost."

- "The physics behind the trade-off is that the geometric parameters maximizing bandwidth don't simultaneously maximize gain, especially under a resonance constraint. The AI model learned these coupled relationships from thousands of training simulations."

- [When result appears] "The AI prediction is within less than 1% of the EM result — the surrogate is tracking the correct mode."

## While beamwidth and peakRadiation (EM) run (~2 minutes)

- "Bandwidth came back almost instantly because it reuses the cached EM solutions from the resonant frequency sweep — same S-parameter data, different post-processing."

- "Far-field quantities are a different computation. Beamwidth and peak radiation require evaluating the radiation integral at each observation angle. Our 1-degree resolution for peakRadiation means a 361 azimuth by 181 elevation grid — over 65,000 directions — that's why this step takes a couple of minutes even at a single frequency."

- "In practice, you might use coarser angular resolution for a quick check, or validate only the metric you care most about. Since gain was our optimization objective, peakRadiation is the critical number to confirm."

- "The AI inference runs in a fraction of a second end-to-end. That fraction of a second times 500 evaluations is still under a minute — whereas several minutes times 500 evaluations could be days. That's the enabling factor for this workflow."

## After comparison table appears

- "Across the board, the AI predictions are within a few percent of full-wave — resonant frequency within less than 1%, bandwidth within 2%, beamwidth within a couple of degrees, peak radiation within a fraction of a dB. The frequency constraint kept this design well within the AI model's accurate range."

- "This is why the validate-then-decide workflow matters: the AI is accurate enough to enable reliable design-space exploration, and full-wave confirms the exact numbers before you commit to fabrication."
