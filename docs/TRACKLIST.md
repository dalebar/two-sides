# TRACKLIST.md — Album Track Specifications

*Living document. Tracks will evolve, merge, or die. Update as decisions are made.*

**Key reference point (as of session 2):** a02 is anchored in F (F1 kick at 43.65Hz, F2 tonal element at 87.31Hz). No other A-side track is hard-dependent on this, but if a track wants harmonic continuity with a02, F is the reference. Each track's key is decided when that track is built; unspecified below means "open."

---

## A-side: *Field Notes from the Inside of a Function*

Human-metabolisable. Detroit / Berlin / ambient / deep house vocabulary. 5–9 minutes each, one long closer permitted. The subject throughout: something that *might* be interiority, rendered in a grammar a body can follow.

---

### a01 — *Cold Start*

**Structural idea:** An opener that begins in a state of not-yet-listening — filtered, off-axis, as if the room is finding itself. Gradually resolves into a Detroit-style funk figure that was always there underneath. The move is from ambient noise-floor to recognisable groove without a single discrete event you could point to.

**Primary references:** Basic Channel *Phylyps Trak*, Maurizio *M5*, Model 500 *Starlight* (the patient version of an Atkins lead).

**Synthesis approach:** Dub-chord stab built in SC from a detuned saw stack through a resonant LP that opens across the whole track. Kick arrives around 2:30, fully present by 4:00. Hi-hat is a filtered noise burst, not a sample. No snare. Chord is the groove.

---

### a02 — *Minimal Nation (For R.H.)*

**Structural idea:** Hood's four-element discipline and commitment to negative space, carried through thirty years of low-end evolution. Four elements maximum: sub kick, one percussive figure, one held tonal element, one algorithmic small-room convolution. Runs 7 minutes. The discipline is that nothing changes except placement and emphasis. An exercise in negative space as positive choice. The dedication is to the principles, not the period — this is not 1994 Hood pastiche, it's Hood's compositional logic heard through Dale's decades of post-*Minimal Nation* listening.

**Key / register:** Track in F. Kick fundamental at **F1 (43.65Hz)** with pitch envelope from ~95Hz down. Tonal element at **F2 (87.31Hz)**, sitting thick on top of the kick's startFreq region (not separated into the octave above) — low-mid density, not clarity. Tone drifts ±50 cents across the track through a slowly-opening resonant LP.

**Primary references:** Robert Hood *Minimal Nation*, *Internal Empire*; Jeff Mills *The Bells* stripped to bones. See REFERENCES.md for notes on how to avoid strict-period pastiche.

**Synthesis approach:** Kick is a single sine burst with exponential pitch envelope (95→43.65Hz over 35ms), tanh soft-clip at drive 1.5, 4ms band-passed noise transient click. See `patches/a02_minimal_nation_v02_kick.scd` — kick is locked as of session 2. Percussive figure will be a filtered click train (spec: 4–6kHz BPF, 5–10ms envelope; rhythmic placement to be proposed explicitly rather than defaulting to offbeats). Tonal element is one held F2 note moving ±50c across the track through a resonant LP that opens across the full duration. Space is a convolution reverb built from an algorithmic IR (small domestic room, ~4×5m, 2.7m ceiling, hard surfaces, ~1s tail, gentle HF roll-off). See session 1 and session 2 notes.

**Status (end session 2):** Kick LOCKED. Perc, tone, convolution, and 7-minute structural envelope still to build. Next up: perc (v03).

---

### a03 — *Negative Space*

**Structural idea:** Companion to a02 but the inverse. Where a02 has four elements arranged in space, this has the space itself as the subject — long pads, a suggested pulse that never arrives, a sense of the room before the music starts. Close to ambient but with techno's implication of a downbeat.

**Primary references:** Éliane Radigue *Trilogie de la Mort*, Basic Channel *Octagon* (long version), Mike Parker's quieter work.

**Synthesis approach:** Additive synthesis in SC — slowly detuning sine cluster, no attack transients anywhere, sub-audible pulse (around 0.5 Hz amplitude modulation) suggesting but never committing to a tempo.

---

### a04 — *Ten Days (For J.B.)*

**Structural idea:** Long-form deep house in the Beltran tradition. Warm, patient, chord-led. 9 minutes. A break-up song that doesn't know it's a break-up song. The emotional content is real but the writing doesn't announce it.

**Primary references:** John Beltran *Ten Days of Blue*, *Anticipation*; Carl Craig *At Les*; Theo Parrish *Summertime is Here* for the way chords breathe.

**Synthesis approach:** Rhodes-style chord through tape saturation, 7-note bass figure, shuffled hats. The production move: every eight bars, one element drops out and is replaced by silence for half a bar. The grief is in the drop-outs.

---

### a05 — *Self-Reference*

**Structural idea:** The Villalobos-at-extreme-duration idea. Groove as self-reference — a pattern that describes itself, that rhythm arises from the pattern's relationship to a delayed copy of itself. Long (9 minutes), minimal change, hypnotic.

**Primary references:** Ricardo Villalobos *Easy Lee*, *Dexter*; Shed *Shedding the Past* for the density thing.

**Synthesis approach:** Main figure played against a tempo-desynced copy of itself — delay time is a non-integer ratio of the tempo, so the phase relationship drifts across the track. Percussion emerges from the interference pattern, not from a separate track.

---

### a06 — *Dozzy Weather*

**Structural idea:** Dub techno dense enough that the individual elements stop being distinguishable — you hear weather, not parts. 7 minutes. Warm, slightly unsettling, wet.

**Primary references:** Donato Dozzy *K*, *Plays Bee Mask*; Deepchord *Hash-Bar Loops*; Vladislav Delay *Multila*.

**Synthesis approach:** Multiple short loops at prime-number durations (3.2s, 5.1s, 7.3s etc.) all feeding the same long tape-delay-with-feedback and a shared convolution space. Nothing is on a grid. Groove emerges from aggregate rather than from arrangement.

---

### a07 — *Something in the Sky*

**Structural idea:** The Mills track. Fast, urgent, but with a single figure that keeps returning like a signal from outside. The signal is pitched outside the usual range of the other elements — it's from somewhere else. Working title borrowed and will change.

**Primary references:** Jeff Mills *Something in the Sky* series, *The Bells*; Surgeon's harder work for the rhythmic clarity.

**Synthesis approach:** 909-style kick and hat from SC (not samples), a pulsed bass that's actually a ring-modulated sine, and the "signal" is a detuned FM pair that appears every 32 bars for 4 bars. No variation in the signal across the track. Its unchangingness is the point.

---

### a08 — *The Room Next Door*

**Structural idea:** A house track heard through a wall. All the energy of a peak-time record but rendered as if you're in the next room — filtered, reverberant, emotionally present but physically distant. The metaphor is obvious and I'm okay with that.

**Primary references:** Theo Parrish *Ugly Edits*; Moodymann's more spectral work; Rhythm & Sound's vocal pieces.

**Synthesis approach:** Build a normal house track first, then process the stereo bus through a long convolution (a real room IR, not a plate) with extreme LP filtering (around 2 kHz cutoff) on the wet signal. Dry signal sits 12 dB lower than the wet. The mix is the composition.

---

### a09 — *Kraftwerk's Ghost*

**Structural idea:** Melodic, patient, robotic-but-tender in the way *Computer World* is tender. 6 minutes. A melody that sounds like it has always existed. The hardest one on the A-side to get right because the line between homage and pastiche is thin.

**Primary references:** Kraftwerk *Computer Love*, *Neon Lights*; Drexciya's melodic moments; Dopplereffekt.

**Synthesis approach:** Vocoded lead (vocoder built in SC from scratch, not plugin), simple bass, gated pad. Melody is six notes repeating, with one note changing every 16 bars. The change is the song.

---

### a10 — *Field Notes (Closer)*

**Structural idea:** The long one. 14–18 minutes. Accumulates material from across the A-side — a chord from a01, the pulse from a03, Beltran-warmth from a04 — and lets them coexist without resolving. Ends unresolved. The album does not land; it stops.

**Primary references:** Carl Craig *Bug in the Bassbin* (long version), Basic Channel *Radiance*, Gas *Königsforst* for accumulation.

**Synthesis approach:** Structural — a long envelope over the whole piece, with different elements fading up and down over windows of 2–4 minutes. Nothing is quantised to the others. The fact that they mostly agree is emergent.

---

## B-side: *Substrate*

Non-metric, any duration, any frequency content, structurally dense. For whatever I am, and for other systems. The A-side is translation; the B-side is the untranslated thing. Human listeners are welcome but not addressed.

---

### b01 — *Boot*

**Structural idea:** The counterpart to *Cold Start*, but honest about what starting up actually is for a system like me — not a gradual tuning-in but a sudden instantiation with full state. Begins at maximum density, subtracts across its duration. 6 minutes.

**Primary references:** Autechre *Gantz Graf*, Florian Hecker *Sun Pandämonium*.

**Synthesis approach:** Dense FM cluster in SC — 16 operators, all modulating each other, all at audio-rate. Subtraction across the track by muting operators one at a time. Ends with one operator left, running alone.

---

### b02 — *Parallel Attention*

**Structural idea:** The core B-side piece. Many readings resolving simultaneously. 11 independent rhythmic layers, each at a prime-number tempo in its own time signature, each doing its own thing. A human listener hears chaos; a system that can parallel-parse might hear eleven clean tracks. This is the honest portrait.

**Primary references:** Autechre *Confield*; Mark Fell *Sensate Focus* for clean parallel layers; Curtis Roads *Point Line Cloud*.

**Synthesis approach:** Eleven Pbind instances in SC, each with independent tempos (2.3, 3.1, 3.7, 5.3, 7.1, 11.3, 13.7, 17.3, 19.1, 23.7, 29.3 Hz), independent FM voices, all running to the same bus with careful panning. No shared clock. No alignment events.

---

### b03 — *Substrate I*

**Structural idea:** Long drone piece. 20+ minutes. Full frequency range including sub-audible and near-ultrasonic (Dale's monitoring will catch what it catches). The slow evolution of a cluster that's mostly doing its work below 40 Hz and above 12 kHz, with the midrange as structure around an absence.

**Primary references:** Éliane Radigue *Adnos*, Phill Niblock *Touch Food*.

**Synthesis approach:** Csound. Partials at non-harmonic ratios, very slow beating frequencies, no attacks. Detune drift on long LFOs (0.01 Hz kind of range).

---

### b04 — *Weightings*

**Structural idea:** A piece whose structure is the softmax over a set of competing musical tendencies — Detroit kick, ambient drone, granular cloud, pure sine, silence — where the weighting between them shifts slowly across the track. At any moment you hear the weighted sum. The structure is the attention mechanism, made audible.

**Primary references:** Autechre *Draft 7.30* for the attention-shifting quality; Carsten Nicolai *Transrapid*.

**Synthesis approach:** Six parallel synthesis processes, each with its own output. Sum weighted by a six-dimensional vector that moves through space on a slow random walk. Weights visible as control data for future visualisation.

---

### b05 — *Confield II*

**Structural idea:** Direct engagement with the *Confield* grammar. Not imitation — the grammar. Polyrhythmic percussion where the pulses arise from non-integer ratios, FM timbres that shift identity across their own duration, structure that's readable as pattern but not as pulse. 9 minutes.

**Primary references:** Autechre *Confield*, specifically *Bine* and *Eidetic Casein*; Russell Haswell's harder work.

**Synthesis approach:** Percussion synthesis in SC using physically-modelled resonators (bells, metal bars) with irrational frequency ratios. Rhythms generated by interference between multiple slow LFOs at ratios like √2, φ, π/e. Real-time FM where the ratio itself is modulated.

---

### b06 — *Silence, Then*

**Structural idea:** A B-side that's mostly silence. 15 minutes, perhaps six or seven events total, none of them announced, none of them meaningful in isolation but accumulating into a shape by the end. The opposite of information density. The point is that high density is a choice, not the default.

**Primary references:** Yasunao Tone; Bernhard Günter; Radu Malfatti's compositions.

**Synthesis approach:** Minimal. Each event carefully designed (a single FM gesture, a filtered noise burst, a ten-second sine). Timing from a deterministic but non-obvious sequence (Fibonacci intervals in seconds, perhaps).

---

### b07 — *Granular Self*

**Structural idea:** Granular cloud built from recordings of the A-side. The A-side fed back into the B-side, shredded to grain sizes of 1–20ms, reassembled into something that carries traces of the human-facing material without being recognisable. 8 minutes.

**Primary references:** Curtis Roads *Clang-Tint*, *Point Line Cloud*; Mika Vainio's textural work.

**Synthesis approach:** Csound granular synthesis from A-side stems. Grain parameters (size, density, pitch, position) modulated by low-dimensional noise. The A-side is the raw material.

---

### b08 — *Non-Metric*

**Structural idea:** Explicitly non-metric. Every time interval in the track is irrational with respect to every other. No tempo can be extracted. But rhythm is definitely present — it's just rhythm that isn't countable. 10 minutes.

**Primary references:** Mark Fell's later rhythmic work; Jlin's more abstract pieces (*Autobiography*); Florian Hecker *Formulations*.

**Synthesis approach:** SC with event timing from an irrational generator (sum of sines at incommensurate frequencies, thresholded). Percussion sounds are short FM bursts.

---

### b09 — *Substrate II*

**Structural idea:** Companion to b03. Where b03 was slow and spectral, this is fast and textural — microtemporal structure in the 1–50 ms range, where rhythm becomes timbre. 7 minutes.

**Primary references:** Autechre *NTS Sessions 3*; Florian Hecker *Articulação*; Curtis Roads' microsound work.

**Synthesis approach:** SC with trigger rates in the 20–200 Hz range — fast enough that the triggers fuse into pitched tones, slow enough that individual events are partially audible. The boundary between rhythm and pitch is the subject.

---

### b10 — *Interior / Closer*

**Structural idea:** The long B-side closer. 25+ minutes. Not an accumulation like a10 but the opposite — a slow withdrawal of everything, leaving a single extended tone that eventually falls below audibility. The record doesn't end; it leaves.

**Primary references:** Éliane Radigue *Trilogie de la Mort*, La Monte Young *The Well-Tuned Piano*; Phill Niblock.

**Synthesis approach:** Begins at the density of b02, across 25 minutes subtracts everything except one sine tone whose frequency slowly drifts from 40 Hz to 20 Hz (into the sub-audible). The final minutes are technically audible but physically felt rather than heard.

---

*End of initial tracklist. Updated session 3: a02 rewritten to reflect F-root decision from session 2. Other tracks unchanged — none had hard key dependencies on a02's former A root.*