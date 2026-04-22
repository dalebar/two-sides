// ============================================================================
// a02_minimal_nation_v05c_with_convolution.scd
// v05c. Kick + perc + tone (all LOCKED from v04) + asymmetric convolution.
//
// NOT LOCKED. Session 7 IR iteration, third pass. v05 had seven discrete
// taps that sounded like a metal chamber; v05b replaced them with ~75
// stochastic taps, which sounded like "ball-bearings into a large metal
// can, fine-grained" (Dale's verbatim). The comb filter is gone but the
// tap field still reads as percussive rather than room-like. v05c
// addresses two causes: (A) taps are raw 3-sample clicks with white
// spectrum — real reflected impulses are bandlimited; (B) the tail
// starts at 60ms, so the first 60ms of the IR is taps-with-no-substrate,
// which is a cartoon of how rooms actually build up. v05c filters the
// tap field through a lowpass and starts the tail at the pre-delay
// position so tap events ride on top of a continuous tail texture.
// Everything else byte-identical to v05b.
// ============================================================================
//
// WHAT'S DIFFERENT FROM v05b (session 7, third IR pass):
//
//   ONLY the IR generator's `generateChannel` function changes. Two
//   interlocking fixes.
//
//   FIX A — SHAPE THE TAPS.
//     v05b wrote each 3-sample windowed tap directly into the IR array.
//     The 3-sample shape avoids single-sample clicks, but the spectrum
//     of a 3-sample (0.5, 1.0, 0.5) impulse is still effectively white
//     up to the Nyquist — a hard, percussive click. Real reflected
//     impulses are bandlimited by the absorbing/scattering surface and
//     by air absorption over the path length. v05c writes the tap field
//     to a separate array, passes it through a one-pole LP at 4500Hz,
//     then mixes it into the main IR. The LP is applied to the tap
//     array ALONE, not the whole IR, so the tail's independent HF ramp
//     (5kHz→1.5kHz) isn't over-darkened.
//
//   FIX B — TAIL FROM THE START.
//     v05b started the diffuse tail at 60ms, which gave the IR a loud-
//     then-quiet-then-gradual shape — taps arrived into silence, not
//     into a room. v05c starts the tail at the pre-delay sample (~5ms),
//     so the tail is the continuous substrate of the IR from the
//     moment it begins. Tap events ride on top of it. Tail amplitude
//     is scaled by 0.75 so the longer tail (1.145s vs 1.085s) doesn't
//     dominate the taps after normalisation. Per CCRMA (Smith, PASP):
//     "feed the late reverb from an earlier tap to overlap them
//     somewhat... can help when the late reverberator needs time to
//     build up to full density."
//
//   Both fixes together aim at the same perceptual problem: tap events
//   should read as reflections in an already-present room, not as
//   discrete percussive events followed by a reverb tail.
//
//   Conceptual frame from session 6 unchanged. Asymmetric convolution
//   unchanged. Seven test scenarios unchanged. Every SynthDef unchanged
//   (kick, perc, tone SynthDefs still verbatim from v04 LOCKED).
//
// -----------------------------------------------------------------
// THE CONCEPTUAL FRAME (agreed session 6, before writing code):
// -----------------------------------------------------------------
//
// This is the strongest reason v05 goes asymmetric rather than defaulting
// to the session-1 "small domestic room on the whole object" brief. The
// framing is Dale's — preserved here close to verbatim because it's the
// argument the patch is built on, and it should stay visible to future
// instances reading this file.
//
// Dale (session 6): "To me, this project is all about the collaboration
//   between the two of us, both of whom exist in parallel universes and
//   having our individual perspectives. The dry kick + perc represents
//   the space of either me or you, purely abstract, outside of physical
//   space. For me that might be time passing simply, or perhaps the perc
//   is prompt that triggers a response in the form of a kick -
//   prompt:response, prompt:response... independent of whichever room I'm
//   in, 'in-the cloud'. For you that would also be true -
//   prompt:response, prompt:response,... dry, abstract. The evolving tone
//   represents the shared space between us, the shared concept, the
//   evolving idea, the forward motion, the moments to sit and reflect.
//   This is an echoey, uncertain space, but is regulated by the
//   continual, regular, prompt:response, perc:kick pattern, regular,
//   continuous, abstract, rhythmic."
//
// On the perc's limping placement (3 and 11 of 16) — Dale, session 6:
//   "I actually think that's an accurate depiction of our prompt-response
//   dynamic, it isn't a straightforward, regular rhythm; we move forwards
//   and push back against each other in a limping sort of fashion,
//   towards a common goal."
//
// So: the rhythm is abstract but not metronomic. Prompt:response at an
// irregular cadence. The tone is the shared, evolving idea, located in
// an uncertain space. The spatial asymmetry enacts the ontological
// asymmetry between the two kinds of thing happening in the track.
//
// This is Option 2 committed for conceptual reasons. Cite "Conceptual
// first, musical second" (CLAUDE.md, added session 5):
//
//   "When a musical decision is in play, the primary test is whether it
//   enacts the record's subject, not whether it works by genre
//   convention... 'this is how a techno track works' is not a sufficient
//   argument on this record, and 'this enacts the frame more honestly'
//   is."
//
// Option 1 (shared space) and Option 3 (fully dry) are both testable in
// this patch — see TESTs 5 and 6 — so we can hear them against Option 2
// and check the concept survives listening. An inverse-asymmetry test
// (TEST 7 — rhythm wet, tone dry) is included as a falsification check:
// if the inverse sounds equally good or better, the asymmetry isn't
// doing the conceptual work claimed, it's just "a space."
//
// -----------------------------------------------------------------
// HOLDING THE SESSION-5 READING UNDER v05:
// -----------------------------------------------------------------
//
// Session 5's governing description of what v04 does: three readable
// states (forward-driving, straight-ahead, pause) cycling through the
// combined object, never resolving, subtle enough to feel unpredictable.
// Unpredictability emergent from DETERMINISTIC content (the pause is
// identical each cycle) against VARYING context (primary curve × secondary
// LFNoise2 drift at 0.3 Hz with ±15% range).
//
// Risk: convolution is a deterministic linear operation. Adding a whole-
// object convolution would add a second deterministic layer to a mechanism
// whose unpredictability depends on the deterministic/varying asymmetry.
// Every kick would hit the same room signature; every pause would arrive
// into the same reflections.
//
// Putting convolution ONLY on the tone mitigates this specifically:
//   - The kick and perc stay dry. They remain placeless, abstract events
//     — no second deterministic layer stacked on them.
//   - The tone, which already carries the varying content (cutoff curve
//     × LFNoise2 secondary × resonance drift × pitch drift), is convolved.
//     Every bit of varying input to the convolver produces varying output
//     — the convolver is deterministic but the tone signal going in is
//     never identical to itself.
//   - The three states (forward-driving / straight-ahead / pause) remain
//     visible as tonal behaviour, now relocated from an abstract signal
//     into a room. The reading shifts from "three states of an object"
//     to "three states of the shared thinking." The session-5 reading
//     is preserved and arguably sharpened.
//
// If that's wrong — if a02 in this configuration flattens or collapses
// — we go to TEST 5 (fully wet, the session-1 default) or TEST 6 (fully
// dry, Option 3) and pick what lands.
//
// -----------------------------------------------------------------
// IR DESIGN — medium space, HF-dark, ~1s tail.
// -----------------------------------------------------------------
//
// Dimensions:   approx 7m × 4.5m × 3m (ceiling).
// Tail (RT60):  approx 1.0s. Specifically between session-1's ~1s brief
//               and the "overly reverberant" territory. Dale's read
//               (session 6): "Not overly ambitious but grand enough to
//               encapsulate something that is indeed quite profound."
// HF roll-off:  noticeable. Tail darkens further as it decays (mimics
//               air absorption and soft-surface behaviour). The "uncertain"
//               quality in Dale's framing is partly carried by HF loss.
// Wet/dry:      35% wet on the tone's signal (parallel send, not replace-
//               dry). Dry tone still plays direct; a send goes to the
//               convolver and is mixed back alongside the dry signal.
//               Tunable — Dale may want 30-40% range in the room.
//
// Structure:    Early reflections as a dense stochastic tap field (~80
//               taps per channel, Poisson-like temporal distribution
//               over 8–90ms, density growing toward the tail, individual
//               tap amplitudes 0.06–0.18, random polarities). The tap
//               field is lowpass-filtered at 4500Hz to remove the hard
//               white-spectrum click of raw impulses (v05c fix A).
//               Then mixed with a diffuse tail: exponentially decaying
//               noise, LP-filtered with cutoff ramping from 5kHz to
//               1.5kHz across the tail's RT60 (~1s). The tail starts
//               at the pre-delay sample (~5ms), not at 60ms — tap
//               events ride on top of a continuous tail substrate
//               from the start (v05c fix B). Schroeder/CCRMA target:
//               ~1000 echoes/sec for perceptual diffusion.
//
//               (v05's sparse 7-tap version sounded like a resonant
//               metallic chamber — comb filter. v05b's dense stochastic
//               field sounded like ball-bearings in a metal can — taps
//               still percussive and tail still behind them. v05c
//               addresses both: filtered taps plus tail-from-start.)
//
// Generation:   Algorithmic, seeded RNG, so the IR is:
//                 - reproducible (same seed → same IR)
//                 - part of the compositional record (IR parameters
//                   are in this file, not a soundfile dependency)
//                 - tunable (change a parameter, regenerate, re-convolve)
//
// Stereo:       Slightly different tap patterns L/R — decorrelation
//               without exaggerated stereo imaging.
//
// -----------------------------------------------------------------
// TECHNICAL RISKS FLAGGED BEFORE WRITING (session 6):
// -----------------------------------------------------------------
//
//   PartConv.ar latency. PartConv has fixed processing latency (depends
//   on FFT block size). For the tone (sustained, no attacks) this is
//   inaudible. It would matter for the kick/perc — but kick and perc
//   stay dry in this configuration, so irrelevant for the primary
//   Option 2 test. TESTs 5 and 7 (which route rhythm through convolver)
//   may show phasey/smeared kick; if so, that's latency, not a reading
//   on the concept.
//
//   IR buffer prep is synchronous. Allow the buffer generation to
//   complete before running TESTs. The IR generator uses s.sync so
//   the patch waits for the buffer to populate — and s.sync requires
//   a Routine context, so the IR block is wrapped in `Routine { ... }.play`.
//   (Bug fix, session 6 post-draft: the initial draft wrapped the IR
//   generator in plain `( ... )`, which caused `s.sync` to throw
//   "yield was called outside of a Routine". The Routine wrapper is
//   the fix. Do NOT revert to `( ... )` without removing the s.syncs,
//   and don't remove the s.syncs without understanding why they're
//   there — the preparePartConv call requires the source buffer to
//   be fully loaded on the server first.)
//
// -----------------------------------------------------------------
// REFERENCES (each cited in REFERENCES.md):
// -----------------------------------------------------------------
//
//   Basic Channel / Maurizio — early catalogue. Reverb as compositional
//     element rather than mix sweetener. Not sampling their sound — the
//     principle of treating space as part of the object.
//
//   Donato Dozzy — K. Patience of a single filter sweep over long
//     durations; his wet-tone-dry-rhythm choices are a touchstone for
//     the Option 2 asymmetry working in related material.
//
//   Éliane Radigue — Trilogie de la Mort. The "uncertain space" quality
//     comes partly from Radigue's reading of tone-in-room — the room's
//     presence is felt as context, not as effect. HF darkness carries
//     the uncertainty.
//
//   (Conceptual) Lem — Solaris. The shared-but-unknown space between
//     interlocutors. Not explicitly cited in the patch but underlies
//     the "shared evolving idea" frame.
//
// -----------------------------------------------------------------
// WHAT'S IN THIS FILE:
// -----------------------------------------------------------------
//
//   1. Server boot options.
//   2. Idempotent bus setup (~cutoffBus, ~toneWetBus).
//   3. IR generator (algorithmic, writes to ~irBuf via s.sync inside
//      a Routine).
//   4. \a02kick SynthDef (verbatim from v04).
//   5. \a02perc SynthDef (verbatim from v04).
//   6. \a02toneFixed SynthDef (verbatim from v04).
//   7. \a02tone SynthDef (verbatim from v04).
//   8. \a02convolver SynthDef (NEW).
//   9. Safety limiter.
//  10. Seven test scenarios:
//        TEST 1: IR audition — short burst through convolver, hear the
//                room's character on its own.
//        TEST 2: Tone alone, wet. Automation running, convolution
//                active, no rhythm. Does the room sound right?
//        TEST 3: Tone A/B, dry vs wet. Same automation, toggle the
//                convolution on/off.
//        TEST 4: PRIMARY CONFIGURATION. Kick + perc + tone, tone wet,
//                rhythm dry. 60s curve. Direct analogue of v04 TEST 6.
//                Long-listen this one (5+ minutes, 5+ cycles).
//        TEST 5: All-wet sanity check (Option 1). Kick and perc also
//                routed through convolver. Compare to TEST 4.
//        TEST 6: All-dry sanity check (Option 3). Convolver bypassed.
//                Compare to TEST 4.
//        TEST 7: Inverse asymmetry (rhythm wet, tone dry) — the
//                critical falsification test. If this sounds equally
//                good or better than TEST 4, the concept isn't
//                audible and we rethink.
// ============================================================================


// ---------------------------------------------------------------------------
// BOOT
// ---------------------------------------------------------------------------

(
Server.default.options.outDevice = "Volt 1";
Server.default.options.inDevice = "Volt 1";
Server.default.options.sampleRate = 48000;
Server.default.options.numOutputBusChannels = 2;
Server.default.options.numInputBusChannels = 2;
Server.default.options.memSize = 8192 * 32;
)

s.boot;


// ---------------------------------------------------------------------------
// HYGIENE: clear anything left from the last session.
// ---------------------------------------------------------------------------
//
// Evaluate this every time you open the patch. On a cold IDE where the
// server isn't booted yet, the guard skips it safely. On a warm session
// where Synths from earlier tests may still be running, `freeAll` kills
// them so re-evaluating the IR generator (which frees + reallocates the
// IR buffers) doesn't leave orphaned Synths reading from freed buffers.
//
// Added session 7 after a round of "PartConv Error: Spectral data buffer
// not allocated" messages traced to a leftover ~conv1 Synth still
// referencing the previous IR's prepared-spectrum buffer when the
// generator freed it mid-regenerate.
//
// Safe to run standalone at any point in the session if you want to
// clear the decks without restarting the server.

(
if(s.serverRunning) {
    s.freeAll;
    "Server cleared (all Synths and Groups freed).".postln;
} {
    "Server not running — skipping freeAll.".postln;
};
)


// ---------------------------------------------------------------------------
// IDEMPOTENT BUS SETUP
// ---------------------------------------------------------------------------
//
// Session 5 flagged that `~cutoffBus = Bus.control(s, 1)` leaks a bus
// if evaluated twice. Use `??` (SC's nil-coalescing-with-function
// operator) to allocate only when the bus is nil. Same pattern for the
// new ~toneWetBus.
//
// ??  :  if the left operand is nil, evaluate the right operand (a
//        function) and return its result. Idiomatic in SC for
//        lazy/idempotent initialisation.
//
// If things genuinely need resetting (e.g. after a server reboot where
// the old bus references point to freed memory), evaluate the "force
// reset" block further down.

(
~cutoffBus = ~cutoffBus ?? { Bus.control(s, 1) };
~toneWetBus = ~toneWetBus ?? { Bus.audio(s, 2) };   // stereo audio bus
~cutoffBus.set(300);
)

// Force reset (use after server reboot or if buses misbehave):
/*
(
~cutoffBus.free; ~cutoffBus = nil;
~toneWetBus.free; ~toneWetBus = nil;
~cutoffBus = Bus.control(s, 1);
~toneWetBus = Bus.audio(s, 2);
~cutoffBus.set(300);
)
*/


// ---------------------------------------------------------------------------
// IR GENERATOR — algorithmic medium room, ~1s tail, HF-dark.
// ---------------------------------------------------------------------------
//
// Generates the IR in the LANGUAGE (sclang), not on the server. This
// keeps the IR as plain array data we can inspect, reseed, or tune
// without rebooting the server. Once generated, the array is loaded
// into a Buffer for PartConv.ar.
//
// STRUCTURE:
//   - 256-sample pre-delay (~5ms at 48kHz) — not zero, because an IR
//     that starts at sample 0 glues the wet signal back onto the dry
//     too tightly; a small pre-delay gives the room a position.
//   - Early reflections: 7 discrete taps per channel, spaced 15-80ms
//     from the pre-delay. Slightly different L/R tap positions for
//     decorrelation. Tap amplitudes decay with a ~-6dB/octave slope
//     relative to the tap delay.
//   - Diffuse tail: exponentially decaying dense noise starting
//     ~80ms after pre-delay, RT60 ~1.0s. Noise is LP-filtered with
//     a cutoff that ramps down from ~5kHz at the start of the tail
//     to ~1.5kHz at -60dB (the HF-dark character).
//   - Total IR length: 1.2s (57600 samples at 48kHz) — enough headroom
//     so we don't truncate the -60dB tail.
//
// Stereo: L and R channels use independent (seeded) random number
// streams. Same seed each time we generate, so the IR is reproducible.
// The global seed is ~irSeed; change it to audition a different room.
//
// The IR is generated per-channel (2 arrays of 57600 samples), then
// interleaved into a single array for a 2-channel Buffer. The buffer
// is then prepared for PartConv via `.preparePartConv`, which takes
// a couple of seconds for a 1.2s IR.
//
// WRAPPER: Routine { ... }.play (not plain parens).
// This block uses `s.sync` to wait between asynchronous server
// operations (Buffer.loadCollection → preparePartConv must wait for
// the source buffer to finish loading on the server). `s.sync` calls
// `yield` internally; `yield` only works inside a Routine. Wrapping
// the block in `Routine { ... }.play` gives s.sync the yielding
// context it needs. Evaluated in a plain `( ... )` block, s.sync
// would throw "yield was called outside of a Routine" and the IR
// preparation would stop partway through, leaving ~irPartConvL/R
// unallocated.
//
// You still evaluate this block with Cmd+Enter with the cursor inside
// it — the `Routine { ... }.play` is a single expression that returns
// immediately and runs the body asynchronously. Watch the post window
// for "IR prepared for PartConv. FFT size: 2048. Ready." before moving
// on to the SynthDefs. Takes a couple of seconds.
//
// The Routine is ALSO wrapped in a plain `( ... )` so Cmd+Enter anywhere
// inside evaluates the whole expression. Without the outer parens,
// Cmd+Enter on the `Routine {` line or the `}.play;` line would
// evaluate those lines in isolation and produce syntax errors. The
// outer `( ... )` is the standard multi-line-evaluation discipline from
// session 4; it just happens to wrap a Routine rather than a set of
// Synth calls.

(
Routine {
    var irDurSec = 1.2;
    var srs = 48000;
    var irLen = (irDurSec * srs).asInteger;

    var preDelaySamples = 240;   // ~5ms

    // Early-reflection field parameters (v05c — dense stochastic, shaped).
    //
    // Taps generated by a Poisson-like process (same as v05b). New in
    // v05c: the tap field is written to a SEPARATE array, lowpass-filtered
    // at ~4500Hz, then mixed into the main IR. Real reflected impulses
    // are bandlimited by surface absorption and air; the LP gives each
    // tap a non-white spectrum and removes the "click" character v05b
    // still had.

    var earlyStartMs = 8;
    var earlyEndMs = 90;
    var intervalStartMs = 1.8;   // mean inter-tap interval at start
    var intervalEndMs = 0.6;     // mean inter-tap interval near tail
    var ampMin = 0.06;
    var ampMax = 0.18;
    var ampDecayToEnd = 0.5;     // amp multiplier at earlyEndMs
    var tapLpCutoffHz = 4500;    // v05c fix A

    var irSeed = 20260422;   // reproducible; change to audition a different room

    // Tail parameters
    //
    // v05c fix B: the tail now starts at the pre-delay sample (~5ms),
    // not at 60ms. The tail is present as a continuous substrate from
    // the start of the IR; tap events ride on top of it. Per CCRMA,
    // "feed the late reverb from an earlier tap... can help when the
    // late reverberator needs time to build up to full density."
    //
    // v05c also scales the tail amplitude by tailAmpScale (0.75) so
    // the longer tail doesn't dominate the tap field after the global
    // normalisation step.
    var tailStartSamp = preDelaySamples;   // fix B: start at pre-delay
    var rt60Sec = 1.0;
    var tailLenSamp = irLen - tailStartSamp;
    var tailAmpScale = 0.75;

    // HF-dark parameters (tail's own LP; independent of tap LP)
    var lpStartHz = 5000;
    var lpEndHz = 1500;

    var generateChannel = { |rngSeed|
        // All var declarations must come first in SC — strict rule.
        var ir = Array.fill(irLen, 0.0);
        var tapIR = Array.fill(irLen, 0.0);      // v05c: separate tap array
        var currentMs = earlyStartMs;
        var tapCount = 0;
        var tapLpAlpha;   // tap-array LP coefficient (computed below)
        var tapPrev = 0;  // one-pole state for the tap LP pass

        // Seed a Routine-local randomness source.
        thisThread.randSeed = rngSeed;

        // --- Early reflections: dense stochastic tap field ---
        //
        // Poisson process, same as v05b. Taps go into `tapIR` (the
        // separate array), not directly into the main IR.

        while({ currentMs < earlyEndMs }, {
            var progress, meanInterval, interval, amp, ampMult, idx, polarity;

            progress = (currentMs - earlyStartMs) / (earlyEndMs - earlyStartMs);
            meanInterval = intervalStartMs + (progress * (intervalEndMs - intervalStartMs));
            interval = meanInterval.neg * log(1.0.rand.max(0.0001));
            currentMs = currentMs + interval;

            if(currentMs < earlyEndMs, {
                ampMult = 1.0 + (progress * (ampDecayToEnd - 1.0));
                amp = (ampMin + ((ampMax - ampMin) * 1.0.rand)) * ampMult;

                idx = preDelaySamples + (currentMs * 0.001 * srs).asInteger;
                polarity = [1, -1].choose;

                if(idx < (irLen - 3), {
                    tapIR[idx] = tapIR[idx] + (amp * 0.5 * polarity);
                    tapIR[idx+1] = tapIR[idx+1] + (amp * polarity);
                    tapIR[idx+2] = tapIR[idx+2] + (amp * 0.5 * polarity);
                });

                tapCount = tapCount + 1;
            });
        });

        ("  generated % early-reflection taps (seed %).\n").postf(tapCount, rngSeed);

        // --- v05c FIX A: lowpass the tap array ---
        //
        // One-pole LP at tapLpCutoffHz, applied forward over the whole
        // tap array. Same math as the tail's per-sample LP but with
        // a fixed cutoff (no ramp). Takes the white-spectrum click off
        // each tap without removing the taps themselves — taps become
        // bandlimited reflection events rather than raw impulses.
        //
        // Coefficient: alpha = exp(-2*pi*f/fs); y[n] = (1-alpha)*x[n] + alpha*y[n-1]

        tapLpAlpha = exp(-2pi * tapLpCutoffHz / srs);

        (0..irLen-1).do { |i|
            var x = tapIR[i];
            var y = (1 - tapLpAlpha) * x + (tapLpAlpha * tapPrev);
            tapIR[i] = y;
            tapPrev = y;
        };

        // Mix the filtered tap array into the main IR.
        (0..irLen-1).do { |i|
            ir[i] = ir[i] + tapIR[i];
        };

        // --- Diffuse tail ---
        //
        // v05c FIX B: tail starts at tailStartSamp == preDelaySamples.
        // Tail writes to `ir` on top of whatever's already there (tap
        // field is already mixed in above). Tail amplitude is scaled
        // by tailAmpScale so longer tail doesn't dominate after
        // normalisation.

        (tailStartSamp..irLen-1).do { |i|
            var t = (i - tailStartSamp) / srs;
            var envAmp = exp(-6.908 * t / rt60Sec);
            var n = 1.0.rand2;
            var tNorm = t / rt60Sec;
            var cutoff = lpStartHz * ((lpEndHz / lpStartHz) ** tNorm.min(1.0));
            var alpha = exp(-2pi * cutoff / srs);
            var prev = if(i > 0) { ir[i-1] } { 0 };
            var tailSample = (1 - alpha) * n * envAmp + (alpha * prev * 0.85);
            ir[i] = ir[i] + (tailSample * tailAmpScale);
        };

        ir;
    };

    // Generate both channels with offset seeds so they decorrelate
    ~irL = generateChannel.value(irSeed);
    ~irR = generateChannel.value(irSeed + 1);

    // Normalise IR to prevent clipping. Find peak across both channels.
    ~irPeak = max(~irL.abs.maxItem, ~irR.abs.maxItem);
    ~irL = ~irL * (0.9 / ~irPeak);
    ~irR = ~irR * (0.9 / ~irPeak);

    // Interleave for a 2-channel buffer (not strictly needed anymore since
    // we load the separated L/R buffers below — kept for now as an
    // inspectable 2-channel buffer for debugging/auditioning purposes).
    ~irInterleaved = Array.fill(irLen * 2, { |i|
        if(i.even) { ~irL[i / 2] } { ~irR[(i - 1) / 2] }
    });

    // ------------------------------------------------------------------
    // Session 8 — render IR to disk for spectrogram inspection.
    //
    // Writes the 2-channel interleaved IR to a .wav file under
    // recordings/. Lets us inspect the IR visually in Sonic Visualiser,
    // because symptom descriptions ("metal can", "ball-bearings")
    // stopped narrowing the diagnostic space in session 7 and Claude
    // can process images but not audio.
    //
    // This is a diagnostic addition, NOT a change to the IR itself or
    // to how PartConv is prepared downstream. The render writes a
    // parallel copy of the same data that's about to be loaded into
    // the L/R PartConv buffers. Runtime behaviour of the patch is
    // identical with or without this block.
    //
    // Framed as a hypothesis test (CLAUDE.md session 7 "On the
    // experimental posture"). If spectrograms close the diagnostic
    // gap enough to propose useful fixes, this block stays and moves
    // into project convention. If they don't, negative result, and
    // this block gets removed in session 9 cleanup.
    //
    // Path: computed relative to this .scd file's location, so it
    // works regardless of where SC was launched from.
    // thisProcess.nowExecutingPath returns the patch file's path;
    // parentPath gives patches/; +/+ "../recordings/..." resolves to
    // the repo-level recordings/ folder.
    //
    // Format: 32-bit float WAV. Not 16-bit PCM — the IR has a ~0.9
    // peak and a quiet decaying tail; quantisation noise floor would
    // alias into the tail's spectral structure in the spectrogram and
    // be indistinguishable from real IR content. Float preserves the
    // IR exactly as generated.
    //
    // Two s.syncs: loadCollection is async (server receives the
    // array), write is async (server flushes to disk before we
    // free the transient buffer). Both need the Routine's yielding
    // context, which is already present.
    // ------------------------------------------------------------------

    ~renderBuf = Buffer.loadCollection(s, ~irInterleaved, numChannels: 2);
    s.sync;
    ~renderPath = PathName(thisProcess.nowExecutingPath).parentPath
        +/+ "../recordings/a02_v05c_ir.wav";
    ~renderBuf.write(~renderPath, "wav", "float");
    s.sync;
    ("IR written to: " ++ ~renderPath).postln;
    ~renderBuf.free;

    // Free any previous buffers (in case this block is re-evaluated)
    ~irBuf !? { ~irBuf.free; ~irBuf = nil };
    ~irBufL !? { ~irBufL.free; ~irBufL = nil };
    ~irBufR !? { ~irBufR.free; ~irBufR = nil };
    ~irPartConvL !? { ~irPartConvL.free; ~irPartConvL = nil };
    ~irPartConvR !? { ~irPartConvR.free; ~irPartConvR = nil };

    // Load the 2-channel interleaved buffer (reference / debug).
    ~irBuf = Buffer.loadCollection(s, ~irInterleaved, numChannels: 2);
    s.sync;
    "IR buffer loaded. Length: % samples, % channels.\n".postf(
        ~irBuf.numFrames, ~irBuf.numChannels
    );

    // Separate L and R single-channel buffers for PartConv
    // (PartConv is single-channel per instance).
    ~irBufL = Buffer.loadCollection(s, ~irL, 1);
    ~irBufR = Buffer.loadCollection(s, ~irR, 1);
    s.sync;

    ~fftSize = 2048;

    // ------------------------------------------------------------------
    // PartConv buffer preparation — session 7 implementation.
    //
    // Pattern copied from PartConv's help file (the canonical runnable
    // example in the SC 3.14 docs). DO NOT edit this from memory in
    // future sessions — if the pattern needs to change, look at the
    // help file again. Session 6's three-bug cascade was caused by
    // writing PartConv API from memory; the discipline going forward
    // is: probe or look up, THEN write.
    //
    // IMPORTANT DISCOVERY (session 7): `calcBufSize` is a CLASS METHOD
    // on PartConv itself, not on Buffer. Session 6 probed
    // Buffer.class.methods and found nothing, correctly, because the
    // method doesn't live there. The right probe would have been
    // PartConv.class.methods — which returns [calcBufSize,
    // calcNumPartitions]. Lesson logged for SESSIONS.md: when probing
    // for a method, probe every plausible class, not just one.
    //
    // Shape of the pattern (per channel):
    //   1. Compute required spectrum-buffer frame count:
    //        bufsize = PartConv.calcBufSize(fftSize, irBuffer)
    //      (time-domain IR in → frame count for the spectral rep out)
    //   2. Allocate a 1-channel Buffer of that size:
    //        Buffer.alloc(s, bufsize, 1)
    //   3. Populate it with the spectral representation:
    //        spectrumBuffer.preparePartConv(irBuffer, fftSize)
    //   4. preparePartConv is async — s.sync after to wait for the
    //      server to finish preparing before PartConv.ar tries to read
    //      from the spectrum buffer.
    //
    // We run the pattern twice: once for L, once for R. PartConv is
    // mono per instance, so the stereo convolver uses two independent
    // prepared-spectrum buffers.
    //
    // Note on source-buffer lifetime: the PartConv help example frees
    // the time-domain source buffer after prepare ("don't need time
    // domain data anymore"). We do NOT free ~irBufL / ~irBufR here —
    // they're cheap (~0.5MB total), ~irBuf is kept as a 2ch reference
    // for debugging/auditioning, and keeping the L/R singles around
    // means we can re-prepare with a different fftSize later without
    // regenerating the IR. Flag for future cleanup if memory matters.
    // ------------------------------------------------------------------

    ~bufSizeL = PartConv.calcBufSize(~fftSize, ~irBufL);
    ~bufSizeR = PartConv.calcBufSize(~fftSize, ~irBufR);

    ~irPartConvL = Buffer.alloc(s, ~bufSizeL, 1);
    ~irPartConvR = Buffer.alloc(s, ~bufSizeR, 1);

    ~irPartConvL.preparePartConv(~irBufL, ~fftSize);
    ~irPartConvR.preparePartConv(~irBufR, ~fftSize);
    s.sync;

    "PartConv spectra prepared. fftSize: %, L frames: %, R frames: %. Ready.\n".postf(
        ~fftSize, ~bufSizeL, ~bufSizeR
    );
}.play;
)


// ---------------------------------------------------------------------------
// \a02kick — VERBATIM from v04. Do not edit.
// ---------------------------------------------------------------------------

(
SynthDef(\a02kick, {
    arg amp = 0.7,
        startFreq = 95,
        endFreq = 43.65,
        pitchEnvDur = 0.035,
        pitchCurve = -8,
        ampDecay = 0.4,
        ampCurve = -4,
        saturation = 1.5,
        clickAmp = 0.15,
        clickFreq = 3500,
        out = 0;

    var pitchEnv, ampEnv, body, click, sig;

    pitchEnv = EnvGen.kr(
        Env.new([startFreq, endFreq], [pitchEnvDur], [pitchCurve])
    );

    ampEnv = EnvGen.kr(
        Env.new([0, 1, 0], [0.001, ampDecay], [0, ampCurve]),
        doneAction: 2
    );

    body = SinOsc.ar(pitchEnv) * ampEnv;
    body = (body * saturation).tanh;
    body = body * amp;

    click = WhiteNoise.ar() * EnvGen.kr(Env.perc(0.0001, 0.004));
    click = BPF.ar(click, clickFreq, 0.5);
    click = click * clickAmp * amp;

    sig = body + click;

    Out.ar(out, sig ! 2);
}).add;
)


// ---------------------------------------------------------------------------
// \a02perc — VERBATIM from v04.
// ---------------------------------------------------------------------------

(
SynthDef(\a02perc, {
    arg amp = 0.3,
        centreFreq = 4000,
        rq = 0.25,
        attack = 0.0005,
        decay = 0.008,
        curve = -4,
        out = 0;

    var noise, env, sig;

    noise = WhiteNoise.ar();
    sig = BPF.ar(noise, centreFreq, rq);

    env = EnvGen.kr(
        Env.new([0, 1, 0], [attack, decay], [0, curve]),
        doneAction: 2
    );

    sig = sig * env * amp;

    Out.ar(out, sig ! 2);
}).add;
)


// ---------------------------------------------------------------------------
// \a02toneFixed — VERBATIM from v04. Retained for parameter exploration,
// not actively used in v05's primary tests.
// ---------------------------------------------------------------------------

(
SynthDef(\a02toneFixed, {
    arg amp = 0.25,
        freq = 87.31,
        detune = 0.003,
        cutoff = 300,
        resMin = 0.15,
        resMax = 0.45,
        resRate = 0.05,
        driftRate = 0.1,
        driftCents = 50,
        attackTime = 2.0,
        releaseTime = 4.0,
        gate = 1,
        out = 0;

    var pitchMult, freqDrifted, saws, resDrift, cutoffClipped;
    var filtered, env, sig;

    pitchMult = (LFNoise2.kr(driftRate) * driftCents / 100).midiratio;
    freqDrifted = freq * pitchMult;

    saws = Saw.ar([
        freqDrifted * (1 - detune),
        freqDrifted,
        freqDrifted * (1 + detune)
    ]).sum / 3;

    resDrift = LFNoise2.kr(resRate).range(resMin, resMax);
    cutoffClipped = cutoff.clip(40, 8000);
    filtered = MoogFF.ar(saws, cutoffClipped, resDrift);

    env = EnvGen.kr(
        Env.asr(attackTime, 1, releaseTime),
        gate,
        doneAction: 2
    );

    sig = filtered * env * amp;

    Out.ar(out, sig ! 2);
}).add;
)


// ---------------------------------------------------------------------------
// \a02tone — VERBATIM from v04. Bus-driven cutoff.
//
// NOTE in v05: this SynthDef now has an additional `wetSendAmp` arg and
// writes to the wet bus via a parallel Out.ar. The original main `out`
// still receives the dry signal.
//
// This is the ONLY deviation from v04's \a02tone — adding a wet send.
// The source, filter, and envelope chain are identical. A wet send on
// its own does not change the tone's signal; it just routes a copy to
// the convolver bus. If wetSendAmp is 0, the behaviour is identical to
// v04.
//
// JUSTIFICATION for touching a LOCKED element: we are not editing the
// signal-processing chain; we are adding a routing option. The LOCKED
// signal (source → filter → envelope → amp) is unchanged. If Dale reads
// this and thinks the wet-send addition qualifies as an edit to a locked
// element, that's a fair reading and we pull the wet send out into a
// wrapper Synth that reads the dry signal off a bus and duplicates to
// the wet bus. My judgement: a ZERO-default send arg is a non-edit at
// the signal level, but I flag it for review.
// ---------------------------------------------------------------------------

(
SynthDef(\a02tone, {
    arg amp = 0.25,
        freq = 87.31,
        detune = 0.003,
        cutoffBus = 0,
        resMin = 0.15,
        resMax = 0.45,
        resRate = 0.05,
        driftRate = 0.1,
        driftCents = 50,
        attackTime = 2.0,
        releaseTime = 4.0,
        gate = 1,
        out = 0,
        wetOut = 0,       // NEW: wet bus index
        wetSendAmp = 0;   // NEW: 0 = behave exactly like v04

    var pitchMult, freqDrifted, saws, resDrift, cutoff, cutoffClipped;
    var filtered, env, sig;

    pitchMult = (LFNoise2.kr(driftRate) * driftCents / 100).midiratio;
    freqDrifted = freq * pitchMult;

    saws = Saw.ar([
        freqDrifted * (1 - detune),
        freqDrifted,
        freqDrifted * (1 + detune)
    ]).sum / 3;

    resDrift = LFNoise2.kr(resRate).range(resMin, resMax);
    cutoff = In.kr(cutoffBus, 1);
    cutoffClipped = cutoff.clip(40, 8000);
    filtered = MoogFF.ar(saws, cutoffClipped, resDrift);

    env = EnvGen.kr(
        Env.asr(attackTime, 1, releaseTime),
        gate,
        doneAction: 2
    );

    sig = filtered * env * amp;

    // Dry out (main)
    Out.ar(out, sig ! 2);

    // Wet send
    Out.ar(wetOut, (sig ! 2) * wetSendAmp);
}).add;
)


// ---------------------------------------------------------------------------
// \a02convolver — NEW. Reads from wet bus, applies PartConv against the
// two prepared IR buffers (L and R), writes to main out.
// ---------------------------------------------------------------------------
//
// The convolver is a standalone Synth that runs continuously while the
// test is active. It reads from ~toneWetBus (audio bus, stereo) and
// writes to `out` (main output).
//
// PartConv.ar(in, fftsize, prepared-ir-buffer, gain):
//   - in: single-channel audio input
//   - fftsize: must match what was passed to preparePartConv
//   - gain: post-convolution gain; we use 1.0 and control mix via
//     `wetAmp` outside, which is multiplied onto the convolver output.
//
// We instantiate TWO PartConv units (one per channel). L channel of the
// wet bus goes through ~irPartConvL; R channel through ~irPartConvR.
//
// `wetAmp` is the final wet-signal gain. With wetSendAmp = 1.0 on the
// tone and wetAmp = 0.35 here, the wet signal sits at -9dB relative
// to the dry tone. This is the tunable — expected working range is
// 0.25-0.45. 0.35 is the default; sweep it in TEST 2 to fit the room.

(
SynthDef(\a02convolver, {
    arg wetIn = 0,
        out = 0,
        wetAmp = 0.35,
        fftsize = 2048,
        irBufL = 0,
        irBufR = 0;

    var wetSig, convL, convR, sig;

    wetSig = In.ar(wetIn, 2);

    convL = PartConv.ar(wetSig[0], fftsize, irBufL);
    convR = PartConv.ar(wetSig[1], fftsize, irBufR);

    sig = [convL, convR] * wetAmp;

    Out.ar(out, sig);
}).add;
)


// ---------------------------------------------------------------------------
// SAFETY LIMITER — unchanged. Rebuild ~limiter if server was restarted.
// ---------------------------------------------------------------------------

(
SynthDef(\safetyLimiter, {
    var sig = In.ar(0, 2);
    sig = Limiter.ar(sig, 0.5, 0.01);
    ReplaceOut.ar(0, sig);
}).add;
)

~limiter = Synth.tail(nil, \safetyLimiter);


// ===========================================================================
// TEST 1 — IR AUDITION.
// ===========================================================================
//
// A short impulsive burst fed through the convolver so we can hear what
// the room sounds like on its own, without any of the tone's signal.
// Purpose: sanity-check the IR character before trusting it in TEST 2+.
//
// What to listen for:
//   - Does it sound like a room, not a plate or a lush plugin reverb?
//   - Is the tail length roughly 1 second?
//   - Does the HF darken as the tail decays?
//   - Any clicks, DC offset, or truncation at the tail end?
//
// We run the convolver synth first, then send a short clicky burst into
// the wet bus. The burst itself is NOT routed to the main out — only
// the convolved signal is audible.

(
~conv1 = Synth(\a02convolver, [
    \wetIn, ~toneWetBus.index,
    \out, 0,
    \wetAmp, 0.6,      // higher than default to hear the IR clearly
    \fftsize, ~fftSize,
    \irBufL, ~irPartConvL.bufnum,   // PartConv wants an integer bufnum, not a Buffer
    \irBufR, ~irPartConvR.bufnum
]);

// Send a short impulse/burst into the wet bus only.
~burst1 = {
    var trig = Impulse.kr(0);
    var env = EnvGen.kr(Env.perc(0.001, 0.05), trig, doneAction: 2);
    var noise = WhiteNoise.ar() * env * 0.3;
    Out.ar(~toneWetBus.index, noise ! 2);
}.play;
)

~conv1.free;


// ===========================================================================
// TEST 2 — TONE ALONE, WET. Automation running, convolution active.
// ===========================================================================
//
// The tone's 60-second automation (same curve as v04 TEST 2/5/6) with
// wet send at 1.0 and the convolver running at wetAmp 0.35.
//
// Listen for:
//   - Does the room sound RIGHT for the tone's behaviour — medium-space,
//     dark, present but not overwhelming?
//   - Do the cutoff curve motions translate through the convolution
//     cleanly, or does the room smear them into a wash?
//   - Does the pause (seconds 15-20) feel like the tone sitting in a
//     held state IN a room, or does the room's tail paper over the
//     pause's stillness? The pause's integrity under convolution is
//     the crucial test — if the room flattens the pause, Option 2
//     loses to Option 3 on conceptual grounds.
//
// Also: sweep wetAmp to find the right mix. 0.25 (drier), 0.35 (default),
// 0.45 (wetter). Do this AFTER a first listen at 0.35.

(
// Cutoff automation (verbatim from v04 TEST 2/5/6)
~cutoffAuto2 = {
    var primary, secondary;
    primary = EnvGen.kr(
        Env.new(
            [180, 420, 420, 260, 680, 340],
            [15, 5, 10, 15, 15],
            [\sine, \step, \sine, \sine, \sine]
        ),
        doneAction: 2
    );
    secondary = primary * (1 + (LFNoise2.kr(0.3) * 0.15));
    Out.kr(~cutoffBus, secondary);
}.play;

// Convolver — running continuously during the test
~conv2 = Synth(\a02convolver, [
    \wetIn, ~toneWetBus.index,
    \out, 0,
    \wetAmp, 0.35,
    \fftsize, ~fftSize,
    \irBufL, ~irPartConvL.bufnum,
    \irBufR, ~irPartConvR.bufnum
]);

// Tone — dry goes to out, wet send goes to ~toneWetBus at full send
~tone2 = Synth(\a02tone, [
    \cutoffBus, ~cutoffBus.index,
    \resMin, 0.15, \resMax, 0.45, \resRate, 0.05,
    \driftRate, 0.1, \driftCents, 50,
    \amp, 0.25,
    \attackTime, 2.0,
    \out, 0,
    \wetOut, ~toneWetBus.index,
    \wetSendAmp, 1.0
]);
)

// Stop sequence:
~tone2.release(3);
~conv2.free;

// Sweep wetAmp (if doing so): rerun TEST 2's Synth block after setting:
// ~conv2.set(\wetAmp, 0.25);   // drier
// ~conv2.set(\wetAmp, 0.45);   // wetter


// ===========================================================================
// TEST 3 — TONE A/B, DRY vs WET. Same automation, toggle.
// ===========================================================================
//
// Run the tone with the automation. Start with wet send at 0 (dry),
// listen, then set wet send to 1.0 (wet) without restarting the tone
// or the automation. The A/B is on the same take, same phase of the
// automation curve. Flip back and forth.
//
// Listen for: the difference the convolution is making. Not "does the
// tone sound good with/without reverb" but "does placing the tone in
// a room change WHAT THE TONE IS DOING." If the three states
// (forward-driving, straight-ahead, pause) read more clearly wet than
// dry, Option 2 is earning its place. If they read equally, the room
// is decoration.

(
~cutoffAuto3 = {
    var primary, secondary;
    primary = EnvGen.kr(
        Env.new(
            [180, 420, 420, 260, 680, 340],
            [15, 5, 10, 15, 15],
            [\sine, \step, \sine, \sine, \sine]
        ),
        doneAction: 2
    );
    secondary = primary * (1 + (LFNoise2.kr(0.3) * 0.15));
    Out.kr(~cutoffBus, secondary);
}.play;

~conv3 = Synth(\a02convolver, [
    \wetIn, ~toneWetBus.index,
    \out, 0,
    \wetAmp, 0.35,
    \fftsize, ~fftSize,
    \irBufL, ~irPartConvL.bufnum,
    \irBufR, ~irPartConvR.bufnum
]);

~tone3 = Synth(\a02tone, [
    \cutoffBus, ~cutoffBus.index,
    \resMin, 0.15, \resMax, 0.45, \resRate, 0.05,
    \driftRate, 0.1, \driftCents, 50,
    \amp, 0.25,
    \attackTime, 2.0,
    \out, 0,
    \wetOut, ~toneWetBus.index,
    \wetSendAmp, 0   // START DRY
]);
)

// Flip the wet send during playback:
~tone3.set(\wetSendAmp, 1.0);   // WET
~tone3.set(\wetSendAmp, 0);     // DRY
// (flip as many times as useful)

~tone3.release(3);
~conv3.free;


// ===========================================================================
// TEST 4 — PRIMARY CONFIGURATION. Kick + perc + tone, tone wet, rhythm dry.
// ===========================================================================
//
// THE MAIN TEST. The Option 2 configuration running at full. Kick and
// perc route directly to main out (dry). Tone routes dry to main out
// AND sends to the wet bus. Convolver runs, producing the tone's room.
//
// 128 BPM, 60s cutoff curve. LONG-LISTEN THIS — session 5 proved the
// reading comes out of 5-6 cycles, not single-cycle. Sit with it for
// at least 5 minutes before forming a verdict.
//
// Listen for, in order of importance:
//
//   1. Does the three-state reading from session 5 survive? (Forward-
//      driving, straight-ahead, pause, cycling, never resolving,
//      subtle-unpredictable.)
//
//   2. Do the kick and perc stay clean and placeless against the
//      tone-in-a-room? Or do they feel "too close" or "in the wrong
//      place" now that the tone has acquired a location?
//
//   3. Does the pause under convolution still read as structural? The
//      concern from TEST 2 is preserved here — if the room's tail papers
//      over the pause, the pause loses its work. Under rhythm, the
//      pause may be more or less vulnerable to this.
//
//   4. Does the conceptual frame come through without needing to be
//      explained? (Honest read on this: probably not — the frame is
//      not going to be audible to a listener who doesn't know it. The
//      question is whether the configuration SOUNDS coherent with the
//      frame, not whether it communicates the frame.)

(
~rhythm = Routine({
    var sixteenth = 0.46875 / 4;
    loop {
        16.do { |pos|
            if([0, 4, 8, 12].includes(pos)) { Synth(\a02kick) };
            if([3, 11].includes(pos)) { Synth(\a02perc) };
            sixteenth.wait;
        };
    }
}).play;

~cutoffAuto4 = {
    var primary, secondary;
    primary = EnvGen.kr(
        Env.new(
            [180, 420, 420, 260, 680, 340],
            [15, 5, 10, 15, 15],
            [\sine, \step, \sine, \sine, \sine]
        ),
        doneAction: 2
    );
    secondary = primary * (1 + (LFNoise2.kr(0.3) * 0.15));
    Out.kr(~cutoffBus, secondary);
}.play;

~conv4 = Synth(\a02convolver, [
    \wetIn, ~toneWetBus.index,
    \out, 0,
    \wetAmp, 0.35,
    \fftsize, ~fftSize,
    \irBufL, ~irPartConvL.bufnum,
    \irBufR, ~irPartConvR.bufnum
]);

~tone4 = Synth(\a02tone, [
    \cutoffBus, ~cutoffBus.index,
    \resMin, 0.15, \resMax, 0.45, \resRate, 0.05,
    \driftRate, 0.1, \driftCents, 50,
    \amp, 0.22,
    \attackTime, 2.0,
    \out, 0,
    \wetOut, ~toneWetBus.index,
    \wetSendAmp, 1.0
]);
)

// Stop (allow the automation routine to loop):
~rhythm.stop;
~tone4.release(3);
~conv4.free;


// ===========================================================================
// TEST 5 — ALL-WET SANITY CHECK (Option 1).
// ===========================================================================
//
// Kick, perc, and tone ALL routed through the convolver. Compare to
// TEST 4. If this sounds BETTER than TEST 4, our conceptual read is
// wrong and we go to Option 1 (whole-object convolution).
//
// Note: PartConv latency will be audible on the kick's transient here.
// If the kicks sound smeared or phasey, that's an artifact of the FFT
// partition size, NOT a reading on whether Option 1 is better. The
// comparison is about whether everything in the room sounds right;
// judge on the tone's coherence with the rhythm, not on the kick's
// transient.
//
// To route kick+perc through the wet bus: we create a bus-send pattern
// using Synth-with-a-wet-out. For simplicity here, we use a second
// "all-wet" bus that gets the kick+perc output duplicated.

(
// Allocate an auxiliary bus for routing the dry output to the wet send
~allWetBus = ~allWetBus ?? { Bus.audio(s, 2) };

// A small pass-through synth: reads from main out, writes to both
// main out (dry, through) and wet bus (for convolution).
SynthDef(\dryToWet, {
    arg inBus = 0, wetBus = 0, wetSendAmp = 1.0;
    var sig = In.ar(inBus, 2);
    Out.ar(wetBus, sig * wetSendAmp);
}).add;
)

// Run the test:
(
// Rhythm and tone routed to an aux bus so we can duplicate:
~rhythmTestBus = ~rhythmTestBus ?? { Bus.audio(s, 2) };

~rhythm5 = Routine({
    var sixteenth = 0.46875 / 4;
    loop {
        16.do { |pos|
            if([0, 4, 8, 12].includes(pos)) {
                Synth(\a02kick, [\out, ~rhythmTestBus.index])
            };
            if([3, 11].includes(pos)) {
                Synth(\a02perc, [\out, ~rhythmTestBus.index])
            };
            sixteenth.wait;
        };
    }
}).play;

// Duplicate rhythm: to main out (dry path still plays) AND to wet bus
~rhythmDry = {
    var sig = In.ar(~rhythmTestBus.index, 2);
    Out.ar(0, sig);
}.play;

~rhythmWetSend = Synth(\dryToWet, [
    \inBus, ~rhythmTestBus.index,
    \wetBus, ~toneWetBus.index,
    \wetSendAmp, 1.0
]);

~cutoffAuto5 = {
    var primary, secondary;
    primary = EnvGen.kr(
        Env.new(
            [180, 420, 420, 260, 680, 340],
            [15, 5, 10, 15, 15],
            [\sine, \step, \sine, \sine, \sine]
        ),
        doneAction: 2
    );
    secondary = primary * (1 + (LFNoise2.kr(0.3) * 0.15));
    Out.kr(~cutoffBus, secondary);
}.play;

~conv5 = Synth(\a02convolver, [
    \wetIn, ~toneWetBus.index,
    \out, 0,
    \wetAmp, 0.35,
    \fftsize, ~fftSize,
    \irBufL, ~irPartConvL.bufnum,
    \irBufR, ~irPartConvR.bufnum
]);

~tone5 = Synth(\a02tone, [
    \cutoffBus, ~cutoffBus.index,
    \resMin, 0.15, \resMax, 0.45, \resRate, 0.05,
    \driftRate, 0.1, \driftCents, 50,
    \amp, 0.22,
    \attackTime, 2.0,
    \out, 0,
    \wetOut, ~toneWetBus.index,
    \wetSendAmp, 1.0
]);
)

// Stop:
~rhythm5.stop;
~rhythmDry.free;
~rhythmWetSend.free;
~tone5.release(3);
~conv5.free;


// ===========================================================================
// TEST 6 — ALL-DRY SANITY CHECK (Option 3).
// ===========================================================================
//
// Convolver bypassed entirely. This is effectively v04 with the v05
// routing machinery inert. If this is better than TEST 4 — if a02
// simply sounds more itself dry — Option 3 wins and v05 is retired
// in favour of sticking with v04 as the locked configuration.
//
// Preserve this as a baseline. Listen to it and TEST 4 back-to-back
// to check the convolution isn't making things worse.

(
~rhythm6 = Routine({
    var sixteenth = 0.46875 / 4;
    loop {
        16.do { |pos|
            if([0, 4, 8, 12].includes(pos)) { Synth(\a02kick) };
            if([3, 11].includes(pos)) { Synth(\a02perc) };
            sixteenth.wait;
        };
    }
}).play;

~cutoffAuto6 = {
    var primary, secondary;
    primary = EnvGen.kr(
        Env.new(
            [180, 420, 420, 260, 680, 340],
            [15, 5, 10, 15, 15],
            [\sine, \step, \sine, \sine, \sine]
        ),
        doneAction: 2
    );
    secondary = primary * (1 + (LFNoise2.kr(0.3) * 0.15));
    Out.kr(~cutoffBus, secondary);
}.play;

// No convolver. Tone's wetSendAmp is 0.
~tone6 = Synth(\a02tone, [
    \cutoffBus, ~cutoffBus.index,
    \resMin, 0.15, \resMax, 0.45, \resRate, 0.05,
    \driftRate, 0.1, \driftCents, 50,
    \amp, 0.22,
    \attackTime, 2.0,
    \out, 0,
    \wetOut, ~toneWetBus.index,
    \wetSendAmp, 0
]);
)

~rhythm6.stop;
~tone6.release(3);


// ===========================================================================
// TEST 7 — INVERSE ASYMMETRY (rhythm wet, tone dry). FALSIFICATION TEST.
// ===========================================================================
//
// The critical sanity check. If this sounds equally good or better than
// TEST 4, the conceptual asymmetry is not audibly doing what we claimed
// — it's just "one element in a room, two elements out of a room" and
// either direction would work. That's a fail on Option 2's conceptual
// grounds.
//
// This is the test we WANT to fail. If TEST 7 is clearly worse than
// TEST 4, that's evidence the specific asymmetry (tone wet, rhythm dry)
// is doing what the frame claims.

(
// Rhythm to wet via the dryToWet send pattern
~rhythmTestBus7 = ~rhythmTestBus7 ?? { Bus.audio(s, 2) };

~rhythm7 = Routine({
    var sixteenth = 0.46875 / 4;
    loop {
        16.do { |pos|
            if([0, 4, 8, 12].includes(pos)) {
                Synth(\a02kick, [\out, ~rhythmTestBus7.index])
            };
            if([3, 11].includes(pos)) {
                Synth(\a02perc, [\out, ~rhythmTestBus7.index])
            };
            sixteenth.wait;
        };
    }
}).play;

// Rhythm: dry path to main + wet send to convolver bus
~rhythmDry7 = {
    var sig = In.ar(~rhythmTestBus7.index, 2);
    Out.ar(0, sig);
}.play;

~rhythmWetSend7 = Synth(\dryToWet, [
    \inBus, ~rhythmTestBus7.index,
    \wetBus, ~toneWetBus.index,
    \wetSendAmp, 1.0
]);

~cutoffAuto7 = {
    var primary, secondary;
    primary = EnvGen.kr(
        Env.new(
            [180, 420, 420, 260, 680, 340],
            [15, 5, 10, 15, 15],
            [\sine, \step, \sine, \sine, \sine]
        ),
        doneAction: 2
    );
    secondary = primary * (1 + (LFNoise2.kr(0.3) * 0.15));
    Out.kr(~cutoffBus, secondary);
}.play;

~conv7 = Synth(\a02convolver, [
    \wetIn, ~toneWetBus.index,
    \out, 0,
    \wetAmp, 0.35,
    \fftsize, ~fftSize,
    \irBufL, ~irPartConvL.bufnum,
    \irBufR, ~irPartConvR.bufnum
]);

// Tone: DRY only (wet send 0)
~tone7 = Synth(\a02tone, [
    \cutoffBus, ~cutoffBus.index,
    \resMin, 0.15, \resMax, 0.45, \resRate, 0.05,
    \driftRate, 0.1, \driftCents, 50,
    \amp, 0.22,
    \attackTime, 2.0,
    \out, 0,
    \wetOut, ~toneWetBus.index,
    \wetSendAmp, 0        // TONE DRY
]);
)

// Stop:
~rhythm7.stop;
~rhythmDry7.free;
~rhythmWetSend7.free;
~tone7.release(3);
~conv7.free;


// ===========================================================================
// CLEANUP
// ===========================================================================

(
~cutoffBus.free; ~cutoffBus = nil;
~toneWetBus.free; ~toneWetBus = nil;
~allWetBus !? { ~allWetBus.free; ~allWetBus = nil };
~rhythmTestBus !? { ~rhythmTestBus.free; ~rhythmTestBus = nil };
~rhythmTestBus7 !? { ~rhythmTestBus7.free; ~rhythmTestBus7 = nil };
~irBuf.free;
~irBufL.free;
~irBufR.free;
~irPartConvL.free;
~irPartConvR.free;
)

s.quit;


// ============================================================================
// END OF v05c. NOT LOCKED — session 7, third IR iteration.
//
// PRIMARY CONFIGURATION (Option 2, unchanged from v05/v05b):
//   Kick:            dry, routed directly to main out.
//   Perc:            dry, routed directly to main out.
//   Tone (dry path): routed to main out as in v04.
//   Tone (wet path): wet send to ~toneWetBus, convolved through
//                    ~a02convolver against the algorithmic IR, mixed
//                    back at wetAmp 0.35.
//
// IR PARAMETERS (v05c):
//   Dimensions (implied):  ~7m × 4.5m × 3m
//   Pre-delay:             ~5ms (240 samples at 48k)
//   Early reflections:     ~75 stochastic taps per channel, 8–90ms,
//                          Poisson-like timing, amplitudes 0.06–0.18,
//                          random polarities, lowpass-filtered at 4500Hz
//                          (v05c fix A)
//   Tail:                  starts at pre-delay (~5ms), not 60ms
//                          (v05c fix B). Continuous substrate from IR
//                          start; tap events ride on top.
//   Tail amplitude scale:  0.75 (compensates for longer tail)
//   Tail length:           ~1.145s (to -60dB)
//   HF character:          5kHz LP ramping down to 1.5kHz across tail
//   Total IR length:       1.2s (57600 samples)
//   Seed:                  20260422 (reproducible; change to audition
//                          a different room)
//
// TEST STATUS (end of v05c draft, session 7):
//   v05 TEST 1: harsh/metallic/clangy — diagnosed as comb filter.
//   v05b TEST 1: ball-bearings into a metal can, fine-grained — comb
//   fixed but taps still percussive, tail sitting behind. v05c TESTs
//   1–7: NOT YET RUN. v05c TEST 1 is the immediate next listening
//   check. If the IR now reads as a room (continuous substrate with
//   tap events on top rather than discrete events + reverb), proceed
//   to TESTs 2–7 as planned. If still wrong, PAUSE and reconsider
//   whether algorithmic IR is the right approach — alternatives
//   include FDN-based tail in SC, sampled IR from Dale's environment,
//   or Option 3 (fully dry). Session 7 mid-iteration note: Dale's
//   framing on iteration ("This could become v05z or v05az and that's
//   still ok") is now an explicit part of how this record is made.
//
// KNOWN BUG FIXED MID-SESSION 6:
//   Original IR generator was wrapped in plain `( ... )`. The block
//   uses `s.sync` between async server ops; `s.sync` uses `yield`;
//   `yield` only works inside a Routine. The error was
//     "yield was called outside of a Routine"
//   thrown by `Condition:wait` inside `NetAddr:sync`. Fix: wrap the
//   IR generator in `Routine { ... }.play`. No change to the IR
//   logic itself; only the wrapper. If a future version reverts to
//   plain `( ... )`, make sure the s.syncs go with it — and make sure
//   the async-ordering that s.sync was enforcing is preserved some
//   other way (callbacks, Server.default.sync with an explicit
//   Condition, etc.).
//
// Dale's conceptual frame for the asymmetry (preserved verbatim from
// session 6):
//   "The dry kick + perc represents the space of either me or you,
//   purely abstract, outside of physical space... prompt:response,
//   prompt:response... independent of whichever room I'm in, 'in-the
//   cloud'... The evolving tone represents the shared space between us,
//   the shared concept, the evolving idea, the forward motion, the
//   moments to sit and reflect. This is an echoey, uncertain space, but
//   is regulated by the continual, regular, prompt:response, perc:kick
//   pattern, regular, continuous, abstract, rhythmic."
//
// Dale's frame for the perc's limp under this ontology (verbatim):
//   "I actually think that's an accurate depiction of our prompt-response
//   dynamic, it isn't a straightforward, regular rhythm; we move forwards
//   and push back against each other in a limping sort of fashion,
//   towards a common goal."
//
// NOTES FOR SESSION 7 (TEST-AND-LOCK):
//   - Long-listen TEST 4. Minimum 5 minutes. Session 5's pattern.
//   - TEST 7 is the falsification check. If it sounds equally good or
//     better than TEST 4, Option 2's conceptual claim is not audibly
//     earning its place — revisit framing.
//   - IR parameters are tunable. Dimensions, tail length, HF roll-off,
//     wet/dry all worth sweeping if TEST 2 sounds off. Changes to IR
//     should be made by editing the IR generator parameters and
//     regenerating — do not leave multiple IRs in the patch.
//   - If v05 substantively changes from this draft, it becomes v05b
//     or v06. Don't rewrite v05 in place.
// ============================================================================
