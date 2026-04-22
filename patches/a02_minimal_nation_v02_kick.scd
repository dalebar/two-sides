// ============================================================================
// a02_minimal_nation_v02_kick.scd
// v02 of the a02 kick. Fundamental moved from A1 (55Hz) to F1 (43.65Hz).
// ============================================================================
//
// Change from v01 (session 2):
//
//   Root pitch moved from A1 → F1 (55Hz → 43.65Hz). This is a structural
//   change to the track, not just a parameter tweak. a02 is now in F, and
//   is explicitly framed as "Hood's principles in a 2026 low-end register"
//   rather than strict-period homage. Dale's call; his reasoning is that
//   his own decades of post-Minimal Nation listening should inform the
//   low-end register, and strict 1994-register pastiche would be a worse
//   dedication to Hood than honest contemporary interpretation. I agree
//   with that reasoning once it's framed that way.
//
//   Consequence for later elements:
//     - Tonal element moves from A2 (110Hz) to F2 (87Hz) or F3 (174Hz)
//       — decision pending.
//     - Anything tuned to the track needs to move down a minor third.
//
// What's in this file (unchanged from v01 otherwise):
//   1. Server boot options (same as before).
//   2. \a02kick SynthDef with F1 as default endFreq.
//   3. Safety limiter.
//   4. Three test scenarios (single hit, 4-on-the-floor, sparse pattern).
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
// THE KICK — SynthDef(\a02kick)
// ---------------------------------------------------------------------------
//
// Anatomy, with v02 values noted:
//
//   FUNDAMENTAL PITCH ENVELOPE
//     Starts at 95Hz (was 120 in v01), drops to 43.65Hz (F1, was 55Hz/A1)
//     over 35ms, exponential curve. startFreq scaled down proportionally
//     from v01 so the drop RATIO stays roughly the same (~2.2x). If we'd
//     kept startFreq at 120 while dropping endFreq to 43.65, the ratio
//     would have jumped to ~2.75x, making the kick more "whoomp" than
//     "thump". Preserving the ratio preserves the kick's character and
//     only changes its absolute register.
//
//   AMPLITUDE ENVELOPE
//     Unchanged from v01: 0ms attack, 400ms exponential decay.
//
//   WAVESHAPING
//     Unchanged from v01: tanh soft-clip at drive 1.5. Note: at F1 the
//     fundamental sits deeper into the roll-off of most playback systems,
//     which means the harmonics produced by the saturation do more of
//     the audible work. This is part of why the kick reads as "deep" /
//     "modern" — you're hearing the harmonic partials as much as the
//     fundamental on most systems.
//
//   FRONT-EDGE CLICK
//     Unchanged. 4ms band-passed noise burst at 3.5kHz, amp 0.15.
//     The click's role becomes more important at F1 than at A1 — the
//     deeper fundamental means the kick has less natural transient
//     snap, so the click is doing more work holding the front edge.
//     Listen for this: if the kick feels like it lacks attack on your
//     system, nudging clickAmp up slightly (0.18–0.22) is the first
//     thing to try.

(
SynthDef(\a02kick, {
    arg amp = 0.7,           // overall kick level.

        startFreq = 95,      // v02: 95Hz (was 120). Preserves ~2.2x drop
                             // ratio relative to new endFreq.
        endFreq = 43.65,     // v02: F1 (was 55/A1). Track root.
        pitchEnvDur = 0.035, // 35ms pitch drop.
        pitchCurve = -8,     // exponential (fast early, slow late).

        ampDecay = 0.4,      // 400ms decay.
        ampCurve = -4,       // exponential.

        saturation = 1.5,    // tanh drive amount.

        clickAmp = 0.15,     // front-edge click level.
        clickFreq = 3500,    // centre freq of click noise burst.

        out = 0;

    var pitchEnv, ampEnv, body, click, sig;

    // Pitch envelope: 95Hz → 43.65Hz over 35ms, exponential curve.
    pitchEnv = EnvGen.kr(
        Env.new([startFreq, endFreq], [pitchEnvDur], [pitchCurve])
    );

    // Amplitude envelope: instant attack, exponential decay, one-shot.
    ampEnv = EnvGen.kr(
        Env.new([0, 1, 0], [0.001, ampDecay], [0, ampCurve]),
        doneAction: 2
    );

    // Kick body: sine at pitch-enveloped frequency, amplitude-enveloped,
    // then soft-saturated.
    body = SinOsc.ar(pitchEnv) * ampEnv;
    body = (body * saturation).tanh;
    body = body * amp;

    // Front-edge click: 4ms band-passed noise burst.
    click = WhiteNoise.ar() * EnvGen.kr(Env.perc(0.0001, 0.004));
    click = BPF.ar(click, clickFreq, 0.5);
    click = click * clickAmp * amp;

    sig = body + click;

    Out.ar(out, sig ! 2);
}).add;
)


// ---------------------------------------------------------------------------
// SAFETY LIMITER
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
// TEST 1 — Single kick hit.
// ---------------------------------------------------------------------------

Synth(\a02kick);

// Parameter variations to hear what each control does at F1:

Synth(\a02kick, [\startFreq, 80, \pitchEnvDur, 0.025]);      // tighter, less boom
Synth(\a02kick, [\startFreq, 110, \pitchEnvDur, 0.045]);     // looser, more boom
Synth(\a02kick, [\saturation, 1.0]);                          // pure sine — note
                                                              // how much the kick
                                                              // loses without
                                                              // the harmonics
Synth(\a02kick, [\saturation, 2.5]);                          // obvious grit
Synth(\a02kick, [\clickAmp, 0]);                              // no click —
                                                              // note the loss
                                                              // of front edge
Synth(\a02kick, [\clickAmp, 0.22]);                           // slightly more
                                                              // click, worth
                                                              // comparing at F1
Synth(\a02kick, [\ampDecay, 0.25]);                           // tighter tail
Synth(\a02kick, [\ampDecay, 0.55]);                           // longer, rounder


// ---------------------------------------------------------------------------
// TEST 2 — 4-on-the-floor at 128 BPM.
// ---------------------------------------------------------------------------

(
~kickLoop = Routine({
    loop {
        Synth(\a02kick);
        0.46875.wait;
    }
}).play;
)

~kickLoop.stop;


// ---------------------------------------------------------------------------
// TEST 3 — Sparse pattern (listening for the silence).
// ---------------------------------------------------------------------------
//
// Drop beat 3 on even bars. Listen for the absent beat as a structural
// element, not a mistake. This is closer to how the kick will actually
// function in the finished track — where the negative space does as
// much work as the hits.

(
~sparseKickLoop = Routine({
    var bar = 0;
    loop {
        Synth(\a02kick);
        0.46875.wait;

        Synth(\a02kick);
        0.46875.wait;

        if(bar.even) { Synth(\a02kick) };
        0.46875.wait;

        Synth(\a02kick);
        0.46875.wait;

        bar = bar + 1;
    }
}).play;
)

~sparseKickLoop.stop;


// ---------------------------------------------------------------------------
// QUIT when done.
// ---------------------------------------------------------------------------

s.quit;

// ============================================================================
// END OF v02.
//
// Next: v03 will add the filtered-noise perc. Before then, lock the tone
// register decision (F2 or F3) so I can think about how perc and tone will
// stack in the frequency domain.
// ============================================================================
