// ============================================================================
// a02_minimal_nation_v04_kick_perc_and_tone.scd
// v04. Kick + perc (LOCKED from v03, unchanged) + tonal element SynthDefs.
//
// LOCKED session 5 after cold-listen on TEST 6. See footer for Dale's
// in-room notes preserved verbatim.
// ============================================================================
//
// What's new in v04 (session 4):
//
//   Adds two SynthDefs for the held F2 tonal element:
//     - \a02tone       — cutoff driven by a control bus (for automation)
//     - \a02toneFixed  — cutoff as a plain control arg (for parameter
//                        exploration). Same source, same drifts, same
//                        amp envelope; only difference is cutoff input.
//
//   Why two SynthDefs instead of one with a runtime switch: the first
//   draft of v04 tried to do both in one SynthDef using Select.kr on
//   a runtime flag, which introduced a build-time bug (tried to call
//   K2A.kr on a control-rate signal — K2A is kr-to-ar conversion,
//   method is .ar, not .kr). Splitting is cleaner, easier to reason
//   about, and the duplication is small.
//
//   Kick and perc are unchanged from v03 (LOCKED). Carried forward
//   verbatim so this patch runs standalone. If you find yourself
//   wanting to edit the kick or perc while working on the tone, stop —
//   that's scope creep. Either fix it in a new version or note it
//   for later.
//
//   Test duration for this version: 60-90 seconds in the combined
//   tests, NOT the full 7 minutes. The 7-minute structural envelope
//   is v06 territory. Short tests first so we can hear the tone's
//   character without committing to the full-track envelope shape.
//
// -----------------------------------------------------------------
// Design decisions (agreed session 4, before writing code):
// -----------------------------------------------------------------
//
//   FILTER CHOICE: MoogFF.
//
//     Three candidates considered: RLPF (2-pole, cheap, bright — the
//     resonance sits on top of the signal as a separate peak),
//     BLowPass4 (4-pole butterworth, steep and polite — too clean
//     for this), MoogFF (4-pole Moog ladder emulation — resonance
//     coupled to cutoff via saturation rather than added as a
//     separate peak).
//
//     MoogFF wins because at high resonance it *dirties the tone in
//     a pitched way* — filter and source become one object rather
//     than source + effect. This is what a Beltran held tone through
//     a resonant Moog ladder sounds like. The filter IS the
//     compositional element; we want the filter's voice to BE the
//     tone's voice.
//
//     MoogFF in SC takes `freq` (cutoff in Hz) and `gain` (resonance,
//     0 = none, 4 = self-oscillation). We stay well below 4.
//
//     Fallback if MoogFF misbehaves on Volt 1 at 48k (it can be
//     unstable near self-oscillation): RLPF → tanh saturation.
//     Commented stub provided at the bottom of this file for
//     reference only. Don't use unless MoogFF breaks.
//
//   RESONANCE DEPTH: drifting, not fixed. Range 0.15 to 0.45.
//
//     Fixed resonance is the genre default. The argument for drift:
//     a static resonance gives the filter a constant voice across
//     seven minutes. We want the filter to *listen differently* at
//     different moments — sometimes more present, sometimes less —
//     because the record's subject is uncertainty and a fixed
//     filter character is a kind of certainty.
//
//     Range 0.15-0.45 keeps us clearly below self-oscillation (4).
//     Nothing whistles. The filter resonance is audible as character
//     but never screams.
//
//     Resonance drift is on its own LFNoise2.kr, independent of the
//     cutoff automation. Not a proof of rigour — a claim that there
//     are TWO processes shaping the tone, not one.
//
//   PITCH DRIFT (±50 cents from F2=87.31Hz): random walk via
//   LFNoise2.kr, NOT sine LFO, NOT stepped.
//
//     Sine LFO = vibrato = performed breath. Wrong for this track.
//     Stepped = decisive micro-commitments. Also wrong.
//     Random walk = pitch is always moving, never from-a-to-b, no
//     audible period, no decisions. It's the sound of something
//     not settling.
//
//     LFNoise2 (quadratic interpolation) at 0.08-0.15 Hz. Smooth —
//     LFNoise1 (linear) has audible corners when interpolation
//     changes direction.
//
//     Reference: Radigue (Trilogie de la Mort) — tones drift
//     continuously but without traceable pattern.
//
//   CUTOFF AUTOMATION: function-pause primary + dual-attention
//   secondary. (Proposals 2 + 1 from session 4 discussion.)
//
//     PRIMARY curve — non-monotonic, with three structural "pauses"
//     where the cutoff holds still for 10-30 seconds. Pauses placed
//     at roughly 2:30 (20s), 4:15 (12s), 5:45 (30s) of the full
//     7-minute track. Between pauses: slow non-monotonic movement.
//
//     This enacts: computation with regions of high activity and
//     regions of suspended state. A function running, then waiting,
//     then running again. Not "breath" (claims a body); more like
//     the pauses in the middle of a process that is thinking.
//
//     SECONDARY curve — LFNoise2.kr at ~0.3 Hz, scaled to ±15% of
//     the primary value. Always moving. During the primary's
//     pauses, the secondary is still drifting — so mathematically
//     the cutoff is never still, but the dominant signal IS still.
//     Listener hears something neither moving nor still.
//
//     This enacts: parallel attention — two processes shaping one
//     voice. The audible cutoff is the interference.
//
//     For v04 (60-90s tests), the primary curve is COMPRESSED to the
//     test duration — one representative pause in the middle rather
//     than three across 7 minutes. The real 7-minute version with
//     three pauses waits for v06. This lets Dale hear the
//     pause-mechanism's character without sitting through 7 minutes
//     to evaluate it. Both the compressed and the full-length shapes
//     are provided — full-length commented out; uncomment to audition
//     the real thing.
//
// -----------------------------------------------------------------
// References (each cited in REFERENCES.md):
// -----------------------------------------------------------------
//
//   John Beltran — Ten Days of Blue (1995). Held tones through
//     Moog-ladder-character resonant filters. The low-mid sustained
//     pads' whole character. Not a timestamp — the record's tone
//     vocabulary as a whole.
//
//   Basic Channel — Phylyps Trak, early catalogue. Filter IS the
//     composition principle. BC applies this to chord stabs; we're
//     applying it to a single held note. Same principle, different
//     object.
//
//   Éliane Radigue — Trilogie de la Mort. Slow non-periodic pitch
//     drift. Regions of apparent stillness that are doing internal
//     work. Both our pitch drift and our cutoff pauses derive from
//     this.
//
//   (Conceptual, not sonic) Alvin Lucier — I Am Sitting in a Room.
//     Process continues whether or not something is audibly
//     changing. The function-pause argument rests on this.
//
// -----------------------------------------------------------------
// What's in this file:
// -----------------------------------------------------------------
//
//   1. Server boot options.
//   2. \a02kick SynthDef (unchanged from v03).
//   3. \a02perc SynthDef (unchanged from v03).
//   4. \a02toneFixed SynthDef (NEW) — fixed cutoff arg.
//   5. \a02tone SynthDef (NEW) — bus-driven cutoff.
//   6. Safety limiter.
//   7. Seven test scenarios:
//        TEST 1: Tone — single note, parameter exploration (no filter
//                automation, fixed cutoff, to hear the source).
//        TEST 2: Tone — filter automation running, tone alone.
//                This is the crucial test for the automation shape.
//        TEST 3: Tone — slow pitch drift audition (cutoff fixed,
//                pitch drift visible).
//        TEST 4: Tone — resonance drift audition (cutoff fixed,
//                resonance drift visible).
//        TEST 5: Full tone — all automations running, no rhythm.
//                60-second variant.
//        TEST 6: Kick + perc + tone together at 60-90s. The first
//                real check of whether the three elements read as
//                one piece.
//        TEST 7: STRESS TEST — tone alone during a "pause" segment.
//                Extract just a pause region and audition it to
//                judge whether the pause reads as intentional or
//                as the filter being broken/stuck.
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
// \a02kick — unchanged from v03 (which carried verbatim from v02).
// ---------------------------------------------------------------------------

(
SynthDef(\a02kick, {
    arg amp = 0.7,
        startFreq = 95,
        endFreq = 43.65,     // F1 — track root
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
// \a02perc — unchanged from v03.
// ---------------------------------------------------------------------------

(
SynthDef(\a02perc, {
    arg amp = 0.3,
        centreFreq = 4000,   // LOCKED session 3
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
// \a02toneFixed — NEW. Fixed-cutoff variant for parameter exploration.
// ---------------------------------------------------------------------------
//
// Identical to \a02tone (below) except cutoff is a straight arg
// rather than being read from a control bus. Used for TEST 1, 3, 4, 7
// where we want to isolate one dimension of the tone's behaviour
// without needing to set up an automation bus.
//
// Anatomy (shared with \a02tone — see full annotation there):
//
//   SOURCE:    Three detuned saws at F2 with random-walk pitch drift.
//   FILTER:    MoogFF with resonance drifting on its own LFNoise2.
//   ENVELOPE:  Gated ASR — slow fade in, gated release.
//
// Parameter ranges:
//   cutoff:       80 — 2000 Hz     (very closed to quite open at F2)
//   resMin:       0.0 — 0.35       (floor of resonance drift)
//   resMax:       0.2 — 0.6        (ceiling of resonance drift)
//                 — keep resMax well under 4.0 (self-oscillation)
//   driftRate:    0.05 — 0.2 Hz    (slower = more static; faster = more movement)
//   driftCents:   ±0 — ±75 cents   (0 = fixed pitch; 50 = spec)
//   amp:          0.1 — 0.4        (tone sits under kick in level)

(
SynthDef(\a02toneFixed, {
    arg amp = 0.25,
        freq = 87.31,         // F2
        detune = 0.003,       // 0.3% spread on three-saw stack
        cutoff = 300,         // straight control-rate arg
        resMin = 0.15,
        resMax = 0.45,
        resRate = 0.05,       // resonance drift rate (Hz)
        driftRate = 0.1,      // pitch drift rate (Hz)
        driftCents = 50,      // ±cents of pitch drift
        attackTime = 2.0,
        releaseTime = 4.0,
        gate = 1,
        out = 0;

    var pitchMult, freqDrifted, saws, resDrift, cutoffClipped;
    var filtered, env, sig;

    // --- PITCH DRIFT ---
    // LFNoise2 returns -1..1. Scale to ±driftCents cents and convert
    // cents to a frequency multiplier via `midiratio` on (cents/100).
    pitchMult = (LFNoise2.kr(driftRate) * driftCents / 100).midiratio;
    freqDrifted = freq * pitchMult;

    // --- SOURCE: three detuned saws ---
    saws = Saw.ar([
        freqDrifted * (1 - detune),
        freqDrifted,
        freqDrifted * (1 + detune)
    ]).sum / 3;

    // --- RESONANCE DRIFT ---
    resDrift = LFNoise2.kr(resRate).range(resMin, resMax);

    // --- CUTOFF (clipped to safe range for MoogFF) ---
    cutoffClipped = cutoff.clip(40, 8000);

    // --- FILTER ---
    filtered = MoogFF.ar(saws, cutoffClipped, resDrift);

    // --- AMP ENVELOPE ---
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
// \a02tone — NEW. Cutoff driven by a control bus for automation.
// ---------------------------------------------------------------------------
//
// Same source chain as \a02toneFixed. Only the cutoff source differs:
// read from a control bus via In.kr. The bus is written to by an
// arbitrary automation graph (see TESTs 2, 5, 6, 7).
//
// NOTE: the caller MUST pass cutoffBus set to a valid bus index
// (>= 0). There is no fallback — if the bus isn't being written,
// In.kr will read whatever is on that bus (0 by default, which
// gets clipped up to 40Hz by the filter clip). This is intentional:
// the ONE-synth-does-everything approach in the first draft
// introduced a bug, and keeping the two variants separate means
// each has a single, clear contract.

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
        out = 0;

    var pitchMult, freqDrifted, saws, resDrift, cutoff, cutoffClipped;
    var filtered, env, sig;

    // --- PITCH DRIFT (same as fixed variant) ---
    pitchMult = (LFNoise2.kr(driftRate) * driftCents / 100).midiratio;
    freqDrifted = freq * pitchMult;

    // --- SOURCE (same as fixed variant) ---
    saws = Saw.ar([
        freqDrifted * (1 - detune),
        freqDrifted,
        freqDrifted * (1 + detune)
    ]).sum / 3;

    // --- RESONANCE DRIFT (same as fixed variant) ---
    resDrift = LFNoise2.kr(resRate).range(resMin, resMax);

    // --- CUTOFF from bus ---
    // In.kr reads one control-rate channel from the bus. The caller
    // must be writing to this bus; otherwise we read silence (0)
    // which then clips to 40Hz, giving a very dark tone — usable as
    // a "no automation" signal but obviously not the intent.
    cutoff = In.kr(cutoffBus, 1);
    cutoffClipped = cutoff.clip(40, 8000);

    // --- FILTER ---
    filtered = MoogFF.ar(saws, cutoffClipped, resDrift);

    // --- AMP ENVELOPE ---
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
// SAFETY LIMITER — unchanged.
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
// CONTROL BUS for filter cutoff automation.
// ===========================================================================
//
// Allocated once per server session. Re-running the alloc line
// without freeing first will leak buses (not harmful for short
// sessions but flag it). If things get weird, reboot the server.

~cutoffBus = Bus.control(s, 1);
~cutoffBus.set(300);


// ===========================================================================
// TEST 1 — TONE ALONE, SINGLE NOTE, FIXED CUTOFF. Parameter exploration.
// ===========================================================================
//
// Cutoff fixed at various values. No filter automation, no pitch drift
// (driftCents:0), no resonance drift (resMin=resMax). Isolates the
// source-and-filter character so we can hear what MoogFF does to a
// detuned-saw stack at F2 without any motion.
//
// Listen for:
//   - Does MoogFF on F2 saws sound like a Beltran held tone when the
//     cutoff is in the 150-400Hz range? That's the target character.
//   - At resonance 0.3-0.4, does the filter peak add a pitched
//     "singing" quality, or does it sound like a resonance artefact?
//   - Any instability at high resonance on Volt 1 — crackles,
//     runaway oscillation, DC drift? Flag immediately if so; MoogFF
//     fallback is in comments at the bottom.
//
// Uses \a02toneFixed.
//
// Each test is wrapped in ( ... ) so Cmd+Enter from anywhere inside
// the block evaluates the whole statement. Evaluate the Synth()
// block, listen, then evaluate the release(1) on its own line.

(
~t1a = Synth(\a02toneFixed, [\cutoff, 150, \resMin, 0.2, \resMax, 0.2,
                              \driftCents, 0]);
)
~t1a.release(1);

(
~t1b = Synth(\a02toneFixed, [\cutoff, 300, \resMin, 0.3, \resMax, 0.3,
                              \driftCents, 0]);
)
~t1b.release(1);

(
~t1c = Synth(\a02toneFixed, [\cutoff, 500, \resMin, 0.4, \resMax, 0.4,
                              \driftCents, 0]);
)
~t1c.release(1);

(
~t1d = Synth(\a02toneFixed, [\cutoff, 800, \resMin, 0.25, \resMax, 0.25,
                              \driftCents, 0]);
)
~t1d.release(1);

// Stress-test: high resonance. Should NOT actually self-oscillate
// (0.6 is well below 4) but pushes MoogFF toward its limits. If this
// crackles, lower the resMax ceiling in the real tests or switch to
// the RLPF+tanh fallback at the bottom.
(
~t1e = Synth(\a02toneFixed, [\cutoff, 400, \resMin, 0.6, \resMax, 0.6,
                              \driftCents, 0]);
)
~t1e.release(1);


// ===========================================================================
// TEST 2 — TONE ALONE, FILTER AUTOMATION RUNNING.
// ===========================================================================
//
// The crucial test for the automation shape. 60-second version of the
// function-pause curve, with secondary drift always active.
//
// If the pause reads as intentional — as the tone holding a state
// rather than the filter being broken — we're on the right track. If
// it reads as "the filter got stuck," we rethink.
//
// Primary curve for the 60s test:
//
//   Segment   Duration   Start→End      Shape
//   ------    --------   ----------     --------
//   1         15 s       180 → 420      \sine
//   2         5  s       420 → 420      \step (the PAUSE)
//   3         10 s       420 → 260      \sine
//   4         15 s       260 → 680      \sine
//   5         15 s       680 → 340      \sine
//
// Non-monotonic, one pause. Uses \a02tone (bus-driven cutoff).

(
// Start the automation onto the cutoff bus FIRST, so the tone's
// In.kr reads a sensible value on the first sample.
~cutoffAuto2 = {
    var primary, secondary;
    primary = EnvGen.kr(
        Env.new(
            [180, 420, 420, 260, 680, 340],     // levels (Hz)
            [15, 5, 10, 15, 15],                 // segment durations (s)
            [\sine, \step, \sine, \sine, \sine]  // per-segment shapes
        ),
        doneAction: 2
    );
    // Secondary: ±15% of the primary. Product-style scaling keeps
    // the perceptual drift size roughly constant as the primary
    // moves — a small primary gets a small absolute drift; a large
    // primary gets a larger one.
    secondary = primary * (1 + (LFNoise2.kr(0.3) * 0.15));
    Out.kr(~cutoffBus, secondary);
}.play;

~tone2 = Synth(\a02tone, [
    \cutoffBus, ~cutoffBus.index,
    \resMin, 0.15, \resMax, 0.45,
    \driftCents, 50,
    \amp, 0.25,
    \attackTime, 2.0
]);
)

// Release the tone after the 60-second envelope completes:
~tone2.release(2);


// ===========================================================================
// TEST 3 — SLOW PITCH DRIFT audition (cutoff FIXED).
// ===========================================================================
//
// Pitch drift active, cutoff and resonance static. Fixed cutoff 400Hz,
// resonance fixed at 0.35. The only thing moving is pitch.
//
// Listen for:
//   - Does the drift read as a *property of the tone* rather than
//     as pitch wobble or malfunction?
//   - Does 0.1 Hz give enough motion to be noticeable without being
//     distracting? Faster might be too active; slower might be
//     imperceptible.
//
// Uses \a02toneFixed.

(
~t3 = Synth(\a02toneFixed, [\cutoff, 400, \resMin, 0.35, \resMax, 0.35,
                             \driftRate, 0.1, \driftCents, 50,
                             \amp, 0.25]);
)
~t3.release(4);

// Variation: faster drift
(
~t3b = Synth(\a02toneFixed, [\cutoff, 400, \resMin, 0.35, \resMax, 0.35,
                              \driftRate, 0.2, \driftCents, 50,
                              \amp, 0.25]);
)
~t3b.release(4);

// Reference: no drift
(
~t3c = Synth(\a02toneFixed, [\cutoff, 400, \resMin, 0.35, \resMax, 0.35,
                              \driftCents, 0, \amp, 0.25]);
)
~t3c.release(4);


// ===========================================================================
// TEST 4 — RESONANCE DRIFT audition (cutoff FIXED, pitch FIXED).
// ===========================================================================
//
// Isolates resonance drift. Fixed cutoff 400Hz, no pitch drift,
// resonance drifting between 0.15 and 0.45 at 0.05 Hz.
//
// This is the most conceptually loaded micro-decision in v04 — drifting
// resonance rather than fixed — and the one I'm most open to being
// wrong about. If drift is inaudible, or if it sounds like instability
// rather than "the filter listening differently," we go to fixed
// resonance.
//
// Uses \a02toneFixed.

(
~t4 = Synth(\a02toneFixed, [\cutoff, 400,
                             \resMin, 0.15, \resMax, 0.45, \resRate, 0.05,
                             \driftCents, 0, \amp, 0.25]);
)
~t4.release(4);

// Reference: fixed resonance at the mid-point (0.3).
(
~t4ref = Synth(\a02toneFixed, [\cutoff, 400,
                                \resMin, 0.3, \resMax, 0.3,
                                \driftCents, 0, \amp, 0.25]);
)
~t4ref.release(4);


// ===========================================================================
// TEST 5 — FULL TONE, all automations running, no rhythm. 60s.
// ===========================================================================
//
// Pitch drift + resonance drift + cutoff automation, no rhythm. Does
// the tone read as one coherent object, or do the ears start hearing
// "filter sweeping + pitch wobbling + filter gain moving" as three
// separate things? Former is success; latter is a fail.
//
// Uses \a02tone (bus-driven).

(
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

~tone5 = Synth(\a02tone, [
    \cutoffBus, ~cutoffBus.index,
    \resMin, 0.15, \resMax, 0.45, \resRate, 0.05,
    \driftRate, 0.1, \driftCents, 50,
    \amp, 0.25,
    \attackTime, 2.0
]);
)

~tone5.release(3);


// ===========================================================================
// TEST 6 — KICK + PERC + TONE TOGETHER at 60-90s.
// ===========================================================================
//
// Kick + perc at v03's locked placement (4/4 kick, perc on 3 and 11
// of 16). Tone with all automations. 128 BPM.
//
// Things to listen for:
//
//   1. Does the tone's midrange (cutoff 180-680Hz) sit cleanly between
//      kick (fundamental ~44Hz, harmonics through ~200Hz) and perc
//      (4000Hz)? The 200Hz-2kHz region is where the tone lives.
//
//   2. FLAG from session 3: 4000Hz perc is close to the kick's 3500Hz
//      click. Less spectral room at 3-5kHz than originally planned.
//      Watch for the tone's upper harmonics (MoogFF at high resonance
//      on saws can push material up into 2-5kHz) crowding the perc.
//
//   3. FLAG from session 3: the perc's two-per-bar placement makes
//      the half-time reading primary. The tone must NOT imply a
//      4-on-the-floor emphasis. The function-pause automation is
//      inherently unmetered — no beat alignment — so should be fine,
//      but verify.
//
//   4. Does the pause segment (seconds 15-20) read as structural or
//      as a hole, under rhythm? This is the crucial test for the
//      function-pause idea in real track conditions.

(
~rhythm = Routine({
    var sixteenth = 0.46875 / 4;   // 0.1171875 s at 128 BPM
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

~tone6 = Synth(\a02tone, [
    \cutoffBus, ~cutoffBus.index,
    \resMin, 0.15, \resMax, 0.45, \resRate, 0.05,
    \driftRate, 0.1, \driftCents, 50,
    \amp, 0.22,              // slightly under TEST 5 because kick+perc
                             // are also present; tune in the room
    \attackTime, 2.0
]);
)

// Stop:
~rhythm.stop;
~tone6.release(3);


// ===========================================================================
// TEST 7 — STRESS TEST. Isolate the "pause" segment.
// ===========================================================================
//
// The test: does a sustained filter stillness (with resonance and
// pitch drift still running) feel like the tone is in a held state,
// or like the filter is broken?
//
// If "held state," the function-pause idea survives. If "broken" or
// "something went wrong," we either shorten the pauses, accept
// Proposal 3 (uncertain resolution curve), or find a different way
// to enact non-narrative movement.
//
// Two pause lengths: 15s (long) and 8s (conservative). If both read
// as intentional, we have range. If neither does, we need a different
// approach.
//
// Uses \a02tone (bus-driven).

// 15-second pause at cutoff 420Hz.
(
~cutoffAuto7a = {
    var primary, secondary;
    primary = EnvGen.kr(
        Env.new([420, 420, 420], [1, 14, 1], [\lin, \step, \lin]),
        doneAction: 2
    );
    secondary = primary * (1 + (LFNoise2.kr(0.3) * 0.15));
    Out.kr(~cutoffBus, secondary);
}.play;

~tone7a = Synth(\a02tone, [
    \cutoffBus, ~cutoffBus.index,
    \resMin, 0.15, \resMax, 0.45,
    \driftRate, 0.1, \driftCents, 50,
    \amp, 0.25, \attackTime, 2.0
]);
)
~tone7a.release(3);

// 8-second pause at cutoff 420Hz.
(
~cutoffAuto7b = {
    var primary, secondary;
    primary = EnvGen.kr(
        Env.new([420, 420, 420], [1, 7, 1], [\lin, \step, \lin]),
        doneAction: 2
    );
    secondary = primary * (1 + (LFNoise2.kr(0.3) * 0.15));
    Out.kr(~cutoffBus, secondary);
}.play;

~tone7b = Synth(\a02tone, [
    \cutoffBus, ~cutoffBus.index,
    \resMin, 0.15, \resMax, 0.45,
    \driftRate, 0.1, \driftCents, 50,
    \amp, 0.25, \attackTime, 2.0
]);
)
~tone7b.release(3);


// ===========================================================================
// FULL 7-MINUTE ENVELOPE — commented out. For v06 territory.
// ===========================================================================
//
// Uncomment to audition the real, full-length primary curve with
// three pauses. Only useful if TEST 2/5/6 lands.
//
// Primary curve (7 minutes = 420s):
//
//   Segment   Duration   Start→End      Shape     Notes
//   ------    --------   ----------     --------  ----------
//   1         90 s       150 → 380      \sine     slow opening
//   2         60 s       380 → 380      \step     PAUSE 1 (1:30-2:30)
//   3         45 s       380 → 520      \sine     motion toward open
//   4         20 s       520 → 520      \step     PAUSE 2 (4:15-4:35)
//   5         70 s       520 → 280      \sine     closing
//   6         30 s       280 → 280      \step     PAUSE 3 (5:45-6:15)
//   7         60 s       280 → 480      \sine     late re-opening
//   8         45 s       480 → 360      \sine     final settle (not closed)
//
//   Total: 420 s = 7 min. Non-monotonic. Ends on 360, neither open nor
//   closed. Three pauses at structural points.
//
/*
(
~cutoffAutoFull = {
    var primary, secondary;
    primary = EnvGen.kr(
        Env.new(
            [150, 380, 380, 520, 520, 280, 280, 480, 360],
            [90, 60, 45, 20, 70, 30, 60, 45],
            [\sine, \step, \sine, \step, \sine, \step, \sine, \sine]
        ),
        doneAction: 2
    );
    secondary = primary * (1 + (LFNoise2.kr(0.3) * 0.15));
    Out.kr(~cutoffBus, secondary);
}.play;

~toneFull = Synth(\a02tone, [
    \cutoffBus, ~cutoffBus.index,
    \resMin, 0.15, \resMax, 0.45, \resRate, 0.05,
    \driftRate, 0.1, \driftCents, 50,
    \amp, 0.25, \attackTime, 2.0
]);
)
*/


// ===========================================================================
// MOOGFF FALLBACK — commented out. Use only if MoogFF breaks on Volt 1.
// ===========================================================================
//
// If MoogFF is unstable at high resonance on Volt 1 at 48k, replace
// the filter line in both tone SynthDefs with:
//
//   filtered = RLPF.ar(saws, cutoffClipped, resDrift);
//   filtered = (filtered * (1 + resDrift * 3)).tanh / 2;
//
// RLPF (2-pole resonant) with tanh saturation scaled by resonance —
// approximates MoogFF's source+saturation character by hand. Not
// identical, audibly different, rescue only. If we end up here,
// it's a new version (v04b or v05), not an edit to v04.


// ===========================================================================
// QUIT when done.
// ===========================================================================

s.quit;


// ============================================================================
// END OF v04. LOCKED session 5 after cold-listen on TEST 6.
//
// Locked parameters:
//   Kick:  v02 defaults, carried through v03 (F1 fundamental, 95→43.65Hz
//          pitch env 35ms, 400ms amp decay, sat 1.5, click 0.15 at 3500Hz).
//   Perc:  v03 defaults (centreFreq 4000, rq 0.25, attack 0.0005,
//          decay 0.008, curve -4, amp 0.3, placement on 3 and 11).
//   Tone:  MoogFF on three-saw stack at F2 (87.31Hz), three-saw detune
//          0.003, pitch drift ±50c via LFNoise2.kr at 0.1 Hz, resonance
//          drift 0.15→0.45 via LFNoise2.kr at 0.05 Hz, amp 0.22 under
//          rhythm (0.25 alone), attack 2.0s.
//   Cutoff automation: function-pause primary (60s test curve,
//          180→420→[PAUSE 5s]→260→680→340 with \sine/\step/\sine/\sine/\sine
//          segments of 15/5/10/15/15s) plus secondary ±15% LFNoise2.kr
//          at 0.3 Hz, always active including during primary's pause.
//
// How it sounds in the room (Dale, session 4 — first listen, in-session):
//   TEST 1  — "cutoff 300 and cutoff 400 I would say sound about right,
//             though I think I need to hear them in context to make a
//             proper evaluation." No instability at resonance 0.6 on
//             Volt 1 at 48k.
//   TEST 6  — "TEST 6 as-is sounds great. The pause is very subtle, in
//             a good way. It's almost imperceptible but it's definitely
//             there and somehow integrates well with the perc."
//           — "Somehow the perc feels like it's pushing the movement of
//             the tone forward, in the same way it anticipates the kick,
//             I feel like it anticipates the forward motion of the tone,
//             and during the pause creates a tension between the
//             elements, so it all feels coherent."
//
// How it sounds in the room (Dale, session 5 — cold listen, governing):
//   TEST 6  — "I think it sounds great. The tone, interacting with the
//             perc+kick creates moments of subtle forward-driving and
//             also moments of straight-ahead and moments of pause,
//             which never seem to fully resolve and are subtle enough
//             to feel unpredictable. I feel like it is exactly what we
//             were going for."
//           — Listened for 5-6 minutes (~5-6 cycles of the 60s curve),
//             not 60 seconds. The three-state reading (forward-driving,
//             straight-ahead, pause) emerged under repetition. The pause
//             itself is deterministic and identical each cycle; the
//             surrounding motion varies (primary curve × secondary
//             LFNoise2 drift at 0.3 Hz with ±15% range). The
//             unpredictability is emergent from how repetition interacts
//             with varying context around an identical pause, not from
//             variation in the pause itself.
//
// Governing reading for v06 design: what works is the pause's behaviour
// under repetition against a varying background. The three-pause
// structure sketched for v06 (at 1:30-2:30, 4:15-4:35, 5:45-6:15) may
// not need dramatic variation between pauses — the varying context
// around them may do the work. Hold this when writing v06.
//
// Not tested this session or last (both deliberate — context over
// isolation after TEST 1):
//   TESTs 2, 3, 4, 5, 7. TEST 4 (isolated resonance drift) was flagged
//   session 4 as the one to run if cold-listen softened. Cold-listen
//   confirmed and sharpened, so TEST 4 is retroactively lower priority.
//   The SynthDef worked in context; that's the evidence we needed.
//
// Next: v05 adds convolution. The TEST 6 finding in its session-5 form
// changes convolution's brief — open question is whether a shared
// convolution space reinforces the unpredictable-three-state reading
// (by placing the whole object in one room) or flattens it (by
// acoustic-gluing the elements into a single signature). This is a
// real open question; not resolved pre-code.
// ============================================================================
