// ============================================================================
// a02_minimal_nation_v03_kick_and_perc.scd
// v03. Kick (locked from v02) + filtered-noise perc SynthDef.
// LOCKED session 3. Perc centreFreq defaulted to 4000 after listening.
// ============================================================================
//
// What's new in v03 (session 3):
//
//   Adds \a02perc — a filtered-noise percussion voice. SynthDef is new;
//   the kick is unchanged from v02 and carries forward verbatim so this
//   patch runs end-to-end without depending on v02 being loaded.
//
//   Rhythmic placement (decided session 3, before writing code):
//
//     Perc lands on the "a" of 1 and "a" of 3 — i.e. the second 16th
//     note after each half-bar kick anchor. Two perc hits per bar.
//     In a 4/4 bar subdivided into 16ths ( 1 e & a  2 e & a  3 e & a  4 e & a ),
//     the perc fires on positions marked P below:
//
//         1 . . P    2 . . .    3 . . P    4 . . .
//
//     Against a 4-on-the-floor kick:
//
//         K . . P    K . . .    K . . P    K . . .
//
//   Reference: Robert Hood — Internal Empire (1994), particularly the
//   placement on Museum and The Pace. The perc lands one sixteenth after
//   the offbeat, not on the offbeat itself. This is deliberately NOT
//   call-and-response — offbeat placement (position 3 of 4) would give
//   the cleaner, more rolling "tsch" between kicks that most techno
//   uses. We're avoiding that on purpose.
//
//   Why this placement, musically:
//
//     1. The placement creates an asymmetry the body doesn't want to
//        resolve to. Offbeats grid-fit; this doesn't. It reads as a
//        "limp" — present, rhythmic, but refusing to sit where symmetry
//        wants it.
//
//     2. Structural coupling to the record's subject. a02's broader
//        frame is refusal-of-resolution — machine interiority as open
//        question. A perc placement that enacts refusal-of-resolution
//        at the bar level is doing structural work for the record,
//        not just citing Hood.
//
//     3. Two hits per bar, not four. Four would soften the asymmetry
//        by filling it in evenly. Two hits keeps the displacement
//        audible as displacement. The two-per-bar reading also maps
//        to a half-time feel, which is closer to Internal Empire's
//        weight than to Minimal Nation title-track's tighter pattern.
//
//   Why these synth parameters:
//
//     - Band-pass noise centred at 5kHz, Q=4. Tight enough to give the
//       perc a sense of pitch (around E8); loose enough to keep air
//       and bite. Start at 5kHz; test 4 and 6kHz to find the spot that
//       reads as brittle without turning harsh.
//
//     - Envelope 0.5ms attack, 8ms decay, exponential. Short enough
//       that the transient dominates and the tail is nearly absent.
//       The perc is a pinprick, not a shaker.
//
//     - No saturation. The kick earns the harmonic weight; the perc
//       stays clean. This keeps the two spectrally distinct even when
//       they're doing rhythmic work against each other. If the perc
//       and kick share harmonic character, the ear glues them into a
//       single event and the placement's displacement gets lost.
//
//     - Default amp 0.3, well below the kick's 0.7. The perc is meant
//       to register as presence, not as counterweight.
//
// What's in this file:
//   1. Server boot options (same as v02).
//   2. \a02kick SynthDef (unchanged from v02).
//   3. \a02perc SynthDef (new).
//   4. Safety limiter (unchanged).
//   5. Six test scenarios covering perc alone, kick alone, and the two
//      together in three rhythmic contexts.
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
// \a02kick — unchanged from v02. See v02 patch for full annotation.
// ---------------------------------------------------------------------------
//
// Carried forward verbatim so this patch runs standalone. The kick is
// locked; nothing about it should change in v03. If you find yourself
// wanting to edit the kick while working on perc, stop — that's scope
// creep and we'll handle it as v04.

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
// \a02perc — NEW. Band-passed noise burst, short envelope.
// ---------------------------------------------------------------------------
//
// Anatomy:
//
//   NOISE SOURCE
//     White noise. The statistical simplest source; no timbral
//     pre-colouring. All timbral character comes from the band-pass
//     filter.
//
//   BAND-PASS FILTER
//     Default centre 5000 Hz, rq 0.25 (Q ≈ 4). SuperCollider's BPF
//     takes `rq` (reciprocal of Q), so smaller rq = higher Q = narrower
//     band. rq=0.25 gives a band that's audibly pitched (you can hum
//     it) but still has enough bandwidth for the noise character to
//     come through. If rq is pushed lower (e.g. 0.1, Q=10), the perc
//     starts sounding like a tuned sine burst; if higher (e.g. 0.5,
//     Q=2), it loses pitch character and starts to sound like a
//     generic hi-hat sample. 0.25 is the middle.
//
//   ENVELOPE
//     0.5ms attack, 8ms decay, exponential (curve -4). Total duration
//     ~8.5ms. Shorter than most techno hats (typical closed hat is
//     40-80ms). The shortness is deliberate: at 8ms the perc reads as
//     a click with pitch rather than as a sustained percussive event.
//     It doesn't fill the space between kicks; it marks a point.
//
//   NO SATURATION
//     See header for reasoning. Kick does harmonic work; perc stays
//     clean.
//
//   PARAMETER RANGES TO EXPLORE (via the test scenarios below):
//     centreFreq: 4000 — 6000 Hz (darker to brighter)
//     rq:         0.15 — 0.5   (tighter pitch to looser noise)
//     decay:      0.005 — 0.015 (tighter snap to softer tail)

(
SynthDef(\a02perc, {
    arg amp = 0.3,           // well below kick's 0.7 — perc is a pinprick
        centreFreq = 4000,   // LOCKED session 3. Was 5000 initially; dropped
                             // to 4000 after Dale's listening: 5000 read as
                             // slightly disconnected from the kick, 4000
                             // integrates — perc and kick read as belonging
                             // together while staying spectrally distinct.
                             // Also: at 4000, the perc is still clearly
                             // brittle but doesn't over-correct for the
                             // Kenwoods' low-end bias.
        rq = 0.25,           // reciprocal Q; smaller = narrower band
        attack = 0.0005,     // 0.5ms attack
        decay = 0.008,       // 8ms decay — short, transient-dominated
        curve = -4,          // exponential decay
        out = 0;

    var noise, env, sig;

    // Noise source. WhiteNoise, no pre-shaping.
    noise = WhiteNoise.ar();

    // Band-pass filter. This is where the perc gets its pitch-character.
    sig = BPF.ar(noise, centreFreq, rq);

    // Envelope. Percussive, one-shot, frees the synth when done.
    env = EnvGen.kr(
        Env.new([0, 1, 0], [attack, decay], [0, curve]),
        doneAction: 2
    );

    sig = sig * env * amp;

    // Mono to stereo. Perc sits centred; no panning for v03.
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


// ---------------------------------------------------------------------------
// TEST 1 — Single perc hit. Parameter exploration.
// ---------------------------------------------------------------------------
//
// Default is now the LOCKED sound (centreFreq 4000, rq 0.25, 8ms decay,
// amp 0.3). The variations below are for future exploration — useful
// reference points if we ever need to push the perc in a direction,
// not live decisions to revisit.
//
// You're listening for:
//   - Does the perc have pitch character, or does it just sound like
//     noise?
//   - Does the centre feel right in the chain, or do we need to move
//     it? 5000 reads as slightly disconnected from the kick; 3500 would
//     start to collide with the kick's click region (3500Hz BPF noise
//     burst) and muddy the separation.
//   - Does 8ms decay read as "click with pitch" rather than "short hat"?

Synth(\a02perc);                                        // LOCKED default
                                                        // (4000, rq 0.25, 8ms, amp 0.3)

Synth(\a02perc, [\centreFreq, 3500]);                   // darker — near kick's click region
Synth(\a02perc, [\centreFreq, 5000]);                   // brighter — previous default
Synth(\a02perc, [\centreFreq, 6000]);                   // brightest tested

Synth(\a02perc, [\rq, 0.15]);                           // tighter pitch (more sine-like)
Synth(\a02perc, [\rq, 0.5]);                            // looser (more hat-like) — rejected
                                                        // session 3 as drifting toward hat

Synth(\a02perc, [\decay, 0.005]);                       // tighter snap
Synth(\a02perc, [\decay, 0.015]);                       // longer tail — rejected session 3
                                                        // as fills space the placement
                                                        // wants to leave empty

Synth(\a02perc, [\amp, 0.5]);                           // louder — to hear character cleanly


// ---------------------------------------------------------------------------
// TEST 2 — Kick alone, 4-on-the-floor at 128 BPM. (Same as v02 TEST 2.)
// ---------------------------------------------------------------------------
//
// Included so you can A/B against scenarios 3 and 4 without loading v02.

(
~kickOnly = Routine({
    loop {
        Synth(\a02kick);
        0.46875.wait;    // quarter note at 128 BPM = 60/128 = 0.46875 s
    }
}).play;
)

~kickOnly.stop;


// ---------------------------------------------------------------------------
// TEST 3 — TARGET PATTERN. 4/4 kick + perc on "a" of 1 and 3.
// ---------------------------------------------------------------------------
//
// This is the placement we agreed on. Bar is divided into 16 sixteenth
// notes; kick on every quarter (positions 0, 4, 8, 12); perc on
// positions 3 and 11 (the "a" of 1 and the "a" of 3).
//
//   position:  0  1  2  3   4  5  6  7   8  9  10 11  12 13 14 15
//   kick:      K  .  .  .   K  .  .  .   K  .  .  .   K  .  .  .
//   perc:      .  .  .  P   .  .  .  .   .  .  .  P   .  .  .  .
//
// At 128 BPM, one 16th note = 0.46875 / 4 = 0.1171875 s.
//
// Listen for:
//   - Does the perc read as intentional displacement, or as a mistake?
//     If as a mistake, we may need to rethink — but note the tone
//     (v04) will contextualise it further.
//   - Does the "limp" quality come through? Hood's Internal Empire
//     has a very specific feeling of leaning forward and falling short;
//     we're after that.
//   - Does the perc sit well against the kick's F1 fundamental
//     spectrally? There should be clear separation: kick owns
//     20-200Hz and the saturation harmonics; perc owns ~5kHz. The
//     midrange (200Hz–2kHz) is deliberately empty. That emptiness is
//     where the tonal element (v04) will live.

(
~kickAndPerc_target = Routine({
    var sixteenth = 0.46875 / 4;   // 0.1171875 s at 128 BPM
    loop {
        // One bar at a time.
        // Positions 0, 4, 8, 12 = kicks.
        // Positions 3, 11 = percs.
        16.do { |pos|
            if([0, 4, 8, 12].includes(pos)) { Synth(\a02kick) };
            if([3, 11].includes(pos)) { Synth(\a02perc) };   // uses LOCKED default
            sixteenth.wait;
        };
    }
}).play;
)

~kickAndPerc_target.stop;


// ---------------------------------------------------------------------------
// TEST 4 — COMPARISON. Kick + perc on "a" of every beat (4 per bar).
// ---------------------------------------------------------------------------
//
// Same kick pattern, but perc fires on the "a" of every beat
// (positions 3, 7, 11, 15) — four perc hits per bar instead of two.
//
//   position:  0  1  2  3   4  5  6  7   8  9  10 11  12 13 14 15
//   kick:      K  .  .  .   K  .  .  .   K  .  .  .   K  .  .  .
//   perc:      .  .  .  P   .  .  .  P   .  .  .  P   .  .  .  P
//
// This fills the displacement in more evenly and softens the asymmetry.
// Play this IMMEDIATELY after TEST 3 to hear the difference. The
// argument for two-per-bar is that four-per-bar reads as groove (even
// if displaced) where two-per-bar reads as limp. Testing this lets us
// verify the argument or discover it was wrong.

(
~kickAndPerc_4perBar = Routine({
    var sixteenth = 0.46875 / 4;
    loop {
        16.do { |pos|
            if([0, 4, 8, 12].includes(pos)) { Synth(\a02kick) };
            if([3, 7, 11, 15].includes(pos)) { Synth(\a02perc) };
            sixteenth.wait;
        };
    }
}).play;
)

~kickAndPerc_4perBar.stop;


// ---------------------------------------------------------------------------
// TEST 5 — STRESS TEST. Sparse kick + target perc placement.
// ---------------------------------------------------------------------------
//
// Kick drops beat 3 on even bars (same as v02 TEST 3). Perc stays on
// the "a" of 1 and 3 regardless of whether the beat-3 kick is present.
//
// This is the crucial test. When the beat-3 kick drops out, the perc
// at position 11 has no local kick anchor to displace from — it's
// firing against silence. Two questions:
//
//   1. Does the perc placement still read as intentional when its
//      anchor drops out? If yes, the placement is doing its own work.
//      If no, it's riding on the kick and we'll need to rethink —
//      either with a different placement that survives anchor-drop,
//      or by accepting that the perc must always follow the kick.
//
//   2. Does the missing beat-3 kick feel like a structural event, or
//      like something lost? Hood's use of negative space makes
//      absence feel like presence. This is the first test of whether
//      our kick-and-perc system supports that.

(
~kickAndPerc_sparse = Routine({
    var sixteenth = 0.46875 / 4;
    var bar = 0;
    loop {
        16.do { |pos|
            // Kick on 0, 4, 12 always. Kick on 8 only on odd bars.
            var kickPositions = if(bar.even) { [0, 4, 12] } { [0, 4, 8, 12] };
            if(kickPositions.includes(pos)) { Synth(\a02kick) };
            if([3, 11].includes(pos)) { Synth(\a02perc) };
            sixteenth.wait;
        };
        bar = bar + 1;
    }
}).play;
)

~kickAndPerc_sparse.stop;


// ---------------------------------------------------------------------------
// TEST 6 — PERC ALONE at the target placement (no kick).
// ---------------------------------------------------------------------------
//
// Same 16-step grid, just the perc on positions 3 and 11. No kick at
// all. This is the most stripped-back way to hear whether the placement
// has an inherent musical character, or whether it only reads as
// intentional when something anchors it.
//
// Listen for: does the rhythm have identity on its own? Or is it just
// two hits per bar that could be anything?

(
~percAlone_target = Routine({
    var sixteenth = 0.46875 / 4;
    loop {
        16.do { |pos|
            if([3, 11].includes(pos)) { Synth(\a02perc) };
            sixteenth.wait;
        };
    }
}).play;
)

~percAlone_target.stop;


// ---------------------------------------------------------------------------
// QUIT when done.
// ---------------------------------------------------------------------------

s.quit;

// ============================================================================
// END OF v03. LOCKED session 3.
//
// Locked parameters:
//   Kick: v02 defaults (F1 fundamental, 95Hz start, 35ms pitch env,
//         400ms amp decay, sat 1.5, click 0.15 at 3500Hz).
//   Perc: centreFreq 4000, rq 0.25, attack 0.0005, decay 0.008,
//         curve -4, amp 0.3.
//   Placement: 128 BPM, kick on positions 0/4/8/12 of a 16-step bar,
//              perc on positions 3/11 ("a" of 1 and "a" of 3 —
//              Internal Empire displaced placement, two hits per bar).
//
// How it sounds in the room (Dale, session 3):
//   TEST 3  — target placement reads as intentional displacement. Locked.
//   TEST 5  — when beat 3 kick drops on even bars, the perc at position
//             11 "attaches itself to the kick that follows." Negative
//             space reads as structural, not as hole. Placement is
//             doing its own work.
//   TEST 6  — perc alone at target placement generates kick-shaped
//             negative space. Dale reports anticipating the kick from
//             perc alone — the placement is generating structure, not
//             riding on the kick.
//
// Next: v04 adds the tonal element at F2 (87.31Hz) with resonant LP
// automation. Tone register locked session 2. The midrange (200Hz-2kHz)
// is currently empty by design — that's where F2 tone will live.
// ============================================================================
