# Demo 2: Talking Points

Voice-over content for narration during live demo pauses.

## Introduction (~1 minute)

- "This demo addresses a practical challenge in 5G mmWave antenna testing: characterizing the full 3-D radiation pattern from a small number of chamber measurements. A full-sphere sweep at 1-degree resolution means over 65,000 sample points — hours of chamber time per beam state. We want to do this from just a few cuts."

- "patternFromAI uses a pretrained deep learning model trained on diverse antenna and array patterns from the Antenna Toolbox catalog. It has learned the general structure of physical radiation patterns on the sphere, so it can infer the full 3-D pattern from sparse observations."

- "We'll evaluate this on three scenarios of increasing difficulty: a single patch element, a 4x4 uniform array, and a beamsteered array. Then we'll compare against pattern multiplication — a physics-based alternative that uses the reconstructed element plus known array geometry."

## After loading element data

- "We're working with synthetic data from a full-wave simulation of a 28 GHz patch element — this gives us ground truth to evaluate against. In practice, these sparse slices would come from physical chamber measurements."

- "The measurement configuration is two elevation cuts at azimuth 0 and 90 degrees, plus one azimuthal cut at the horizon. That's about 540 samples from a 65,000-point grid — a 120x compression."

## While patternFromAI runs (element)

- "The model takes in the sparse samples — each one is a triplet of magnitude, azimuth, elevation — and outputs the full 3-D pattern on a 1-degree grid. The inference takes a few seconds on CPU."

## After element reconstruction appears

- "The element pattern is smooth and broad — a relatively easy case. The reconstruction captures the main lobe shape and the back-hemisphere rolloff. RMSE is typically around 1 dB for element patterns like this."

- "The error concentrates near nulls and in regions far from any measurement cut — exactly where the model has the least information to work with."

## After array reconstruction appears

- "The array pattern is a harder test — narrower beams, deeper nulls, more sidelobe structure. The model still recovers the overall shape, but you can see the RMSE increases to around 5 dB."

- "Most of that error is in the null regions. In the main beam and first sidelobes — the region that matters for link budget and interference analysis — the accuracy is substantially better."

## After CDF comparison plot

- "This cumulative distribution shows the fraction of angular coordinates below a given error threshold. For the element, 96% of directions are within 3 dB. For the array, it drops to about 69%. The element's smooth structure is inherently easier to interpolate from sparse samples."

## While pattern multiplication runs

- "Pattern multiplication gives us a physics-based alternative: take the reconstructed element pattern, apply the known array geometry, and compute the array pattern analytically. No array-level measurements needed."

- "The trade-off: pattern multiplication excels in the main beam because it applies exact superposition, but it ignores mutual coupling, finite-array truncation, and ground-plane effects — so it's less accurate in the back hemisphere and near deep nulls."

## After pattern multiplication results

- "In the main-beam region — within 10 dB of the peak — pattern multiplication is more accurate than direct AI reconstruction. That makes it the better choice when link budget is the primary concern."

- "Direct AI reconstruction wins on full-sphere RMSE because it implicitly captures the coupling effects that pattern multiplication ignores. The choice depends on the application."

## After steered array — standard cuts

- "Here's where measurement strategy becomes critical. The beam is steered to azimuth 30, elevation 60 degrees, but none of our standard cuts pass through the beam peak. The model underestimates the peak by several dB — it can't recover amplitude information that simply isn't in the input."

- "This isn't a model failure — it's a measurement design failure. The model is honest about what it doesn't know."

## After steered array — with targeted cut

- "Adding one elevation cut at azimuth 30 degrees — through the beam — recovers the peak from about 10 dBi to 18 dBi, against a true value of 19. One additional cut, roughly 180 more samples, and the reconstruction improves dramatically."

- "The lesson: for steered beams, include at least one cut through the steering direction. A few minutes of extra chamber time saves hours of full-sphere measurement."

## After steered pattern multiplication

- "Pattern multiplication gets the steered beam right without any steered-array measurements — just the element characterization plus the known phase shifts. This is the measurement-free path to beam characterization across all scan states."

- "For 5G NR beam management, where you might need to characterize dozens of beam states, measuring the element once and applying pattern multiplication for each steering vector is far more practical than sweeping each state individually."

## After summary table

- "To summarize: patternFromAI enables full 3-D pattern reconstruction from sparse measurements in under a minute. Element patterns reconstruct with high accuracy. Array patterns are more challenging but still useful for quick characterization."

- "The two approaches — direct AI reconstruction and pattern multiplication from the AI-reconstructed element — are complementary. Use pattern multiplication when main-beam fidelity and multi-beam characterization are the priority. Use direct AI reconstruction when full-sphere accuracy matters or when you don't have the array geometry available."

- "In both cases, the enabling capability is the same: a pretrained deep learning model that has learned the physics of radiation patterns on the sphere, applied to a practical testing workflow that reduces measurement time by two orders of magnitude."
