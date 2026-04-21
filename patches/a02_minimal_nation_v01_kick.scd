// ============================================================================
// a02_minimal_nation_v01_kick.scd
// First fragment of a02 (Minimal Nation (For R.H.)) — just the kick.
// ============================================================================
//
// This is v01 of the kick for a02, in isolation. No perc, no tonal element,
// no convolution, no structural envelope. Just: can we make a kick that
// sits in Hood territory and holds the weight of being the only element in
// the room.
//
// The a02 brief (from SESSIONS.md session 1):
//   - Sine-burst kick at A1 (55 Hz) with short pitch drop.
//   - Track in A, seven minutes, four-element discipline.
//   - Hood's "minimal" is maximalist: every element fighting for its right
//     to be there. The kick has to earn its place when it's alone.
//
// What's in here:
//   1. ServerOptions block (same as the teaching patch — paste & run).
//   2. The \a02kick SynthDef with commentary on every musical choice.
//   3. A safety limiter.
//   4. Three ways to trigger it: single hit, regular 4-on-the-floor, and
//      a slightly more interesting pattern that lets you hear the kick
//      against silence (which is the actual test — Hood-style kicks live
//      or die by how they sit against the empty bars).
//
// WORKFLOW:
//   - Boot server (top of file).
//   - Add the SynthDefs (middle).
//   - Start the limiter.
//   - Trigger single hits first — is the shape right?
//   - Then the 4-on-the-floor pattern — does it breathe or fatigue?
//   - Then the sparse pattern — can it hold the room alone?
//   - Report back on the four questions in my message.
// ============================================================================


// ---------------------------------------------------------------------------
// BOOT — same options as the teaching patch.
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
// Anatomy, in musical terms:
//
//   FUNDAMENTAL PITCH ENVELOPE
//     Starts at 120Hz, drops to 55Hz (A1) over 35ms, curved exponentially
//     (fast at first, settling at the end). The curve matters — a linear
//     drop sounds like a siren; an exponential drop sounds like a kick.
//     The ratio (120 → 55, roughly 2.2x) and the duration (35ms) together
//     define the kick's character:
//       - Higher start pitch or longer drop = more "boom", more 909-like.
//       - Lower start pitch or shorter drop = more "thump", more 808-like,
//         closer to Hood.
//     We're starting closer to Hood: moderate ratio, short drop.
//
//   AMPLITUDE ENVELOPE
//     Instant attack (0ms), 400ms decay, exponential curve. No sustain or
//     release — this is a one-shot. Exponential decay is what gives it the
//     "settling" quality — a linear decay sounds mechanical; exponential
//     decays the way physical things decay (struck bells, plucked strings,
//     resonating air columns).
//
//   WAVESHAPING
//     Gentle tanh saturation applied to the sine. A pure sine at 55Hz on a
//     truthful monitoring chain sounds pathetic on its own — too little
//     harmonic content for the ear to lock onto. Mild saturation adds odd
//     harmonics (mostly 3rd, some 5th) which sit above the fundamental and
//     give the kick a "present" quality without making it harsh. We're
//     using tanh specifically because it's soft-clipping — it saturates
//     gently as input rises, never hard-clipping. This is the same
//     principle as an overdriven tube: musical distortion, not digital
//     clipping.
//
//   FRONT-EDGE CLICK
//     A very short (~4ms) band-passed noise burst layered with the kick at
//     low amplitude. This is the oldest trick in the drum machine book —
//     the transient click gives the kick a "front" that cuts through on
//     small systems and in busy mixes. For Hood-style work we want this
//     near-subliminal: you notice its absence more than its presence. If
//     you can consciously hear it clicking, it's too loud.
//
//   NO LOW-PASSING, NO COMPRESSION
//     Not adding them here. The kick is meant to stand bare. If it needs
//     help later it can have it in arrangement/mixing, but the SynthDef
//     should produce a kick that's already right.

(
SynthDef(\a02kick, {
    arg amp = 0.7,           // overall kick level. 0.7 is hot-ish —
                             // we want it to sit proud in the mix and we
                             // have the safety limiter catching peaks.

        startFreq = 120,     // pitch envelope top. Try 100–140 to taste.
        endFreq = 55,        // A1 — the fundamental. Per SESSIONS.md.
        pitchEnvDur = 0.035, // 35ms pitch drop. Try 0.02–0.05.
        pitchCurve = -8,     // negative = exponential (fast early, slow late).
                             // -4 is gentler, -12 is more aggressive.

        ampDecay = 0.4,      // 400ms decay. Try 0.25–0.55.
        ampCurve = -4,       // exponential amp decay.

        saturation = 1.5,    // tanh drive amount. 1.0 = clean, 3.0 = gritty.
                             // 1.5 is gentle warmth. More than 2.5 starts
                             // sounding obvious / 909-ish.

        clickAmp = 0.15,     // front-edge click level, relative to kick.
                             // Should be subliminal. Try 0.08–0.25.
        clickFreq = 3500,    // centre freq of the click noise burst. Higher
                             // = more "tick"; lower = more "thud transient".

        out = 0;             // output bus. 0 = main stereo out.

    var pitchEnv, ampEnv, body, click, sig;

    // Pitch envelope: starts high, drops to endFreq, exponential curve.
    // The Env.new constructor lets us specify the curve shape; -8 is
    // quite exponential (most of the drop happens in the first third).
    pitchEnv = EnvGen.kr(
        Env.new([startFreq, endFreq], [pitchEnvDur], [pitchCurve])
    );

    // Amplitude envelope: instant attack, exponential decay, one-shot.
    // doneAction: 2 frees the synth once the envelope finishes — no
    // lingering ghosts on the server.
    ampEnv = EnvGen.kr(
        Env.new([0, 1, 0], [0.001, ampDecay], [0, ampCurve]),
        doneAction: 2
    );

    // The kick body: sine at the pitch-enveloped frequency, amplitude-
    // enveloped, then softly saturated. Order matters here — we shape
    // amplitude BEFORE saturation so the saturation responds to the
    // kick's dynamic shape (louder in the attack, barely touching the
    // decay tail). This is how a physical speaker cone overdriving works.
    body = SinOsc.ar(pitchEnv) * ampEnv;
    body = (body * saturation).tanh;   // soft-clip saturation
    body = body * amp;

    // The front-edge click: very short burst of band-passed white noise.
    // Attack 0, decay 4ms. The envelope's so short the noise barely has
    // time to register as noise — it reads as a transient.
    click = WhiteNoise.ar() * EnvGen.kr(Env.perc(0.0001, 0.004));
    click = BPF.ar(click, clickFreq, 0.5);   // band-pass around clickFreq,
                                             // Q=0.5 (wide-ish)
    click = click * clickAmp * amp;

    sig = body + click;

    // Output to both stereo channels. The kick is mono by nature — we're
    // just duplicating so both monitors see it. Stereo widening on a kick
    // is a beginner mistake that kills low-end focus.
    Out.ar(out, sig ! 2);
}).add;
)


// ---------------------------------------------------------------------------
// SAFETY LIMITER — same as the teaching patch.
// ---------------------------------------------------------------------------
//
// Limits the main output bus at -6dB (0.5 linear). Put this on the tail
// so it processes after every other synth.

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
//
// Evaluate this line over and over. Listen to the isolated kick. Is the
// front edge too sharp? Not sharp enough? Is the fundamental locking
// into the room or disappearing? Is the decay right?

Synth(\a02kick);

// Try it with tweaked parameters to hear what each control does:

Synth(\a02kick, [\startFreq, 100, \pitchEnvDur, 0.02]);     // shorter, less boom
Synth(\a02kick, [\startFreq, 150, \pitchEnvDur, 0.05]);     // longer, more boom
Synth(\a02kick, [\saturation, 1.0]);                         // pure sine, no drive
Synth(\a02kick, [\saturation, 2.5]);                         // obvious grit
Synth(\a02kick, [\clickAmp, 0]);                             // no click at all
Synth(\a02kick, [\clickAmp, 0.4]);                           // click too prominent
Synth(\a02kick, [\ampDecay, 0.2]);                           // short — tighter
Synth(\a02kick, [\ampDecay, 0.6]);                           // long — more room


// ---------------------------------------------------------------------------
// TEST 2 — 4-on-the-floor at 128 BPM.
// ---------------------------------------------------------------------------
//
// Evaluate this to start a steady kick pattern. Evaluate it again or
// Cmd+. to stop.
//
// 128 BPM is the centre of the Hood/Detroit tempo range. We'll probably
// end up closer to 125 or 124 for a02 specifically — Hood's work often
// sits just below the obvious — but 128 is a good diagnostic tempo
// because it's the neutral default of the genre.
//
// A Routine is a block of code that runs asynchronously — it can wait
// between events. .play sends it to the SystemClock.

(
~kickLoop = Routine({
    loop {
        Synth(\a02kick);
        0.46875.wait;   // 128 BPM = 60/128 = 0.46875 seconds per beat
    }
}).play;
)

// To stop the loop specifically (without killing other synths):

~kickLoop.stop;


// ---------------------------------------------------------------------------
// TEST 3 — Sparse pattern (the real test).
// ---------------------------------------------------------------------------
//
// Hood-style work is about how the kick sits against silence. A steady
// 4-on-the-floor tells you whether the kick is rhythmically functional;
// a sparse pattern tells you whether it's structurally interesting.
//
// This pattern drops the third beat of every other bar. Listen to the
// missing beats as much as the played ones — that's the compositional
// principle of the whole track. What's absent does work.

(
~sparseKickLoop = Routine({
    var bar = 0;
    loop {
        // Beat 1 — always play
        Synth(\a02kick);
        0.46875.wait;

        // Beat 2 — always play
        Synth(\a02kick);
        0.46875.wait;

        // Beat 3 — skip every other bar
        if(bar.even) { Synth(\a02kick) };
        0.46875.wait;

        // Beat 4 — always play
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
// END OF PATCH.
//
// Dale — report back on:
//   1. Front edge: too clicky, about right, or disappears?
//   2. Fundamental: 55Hz working on the Volt, or does it need to move?
//   3. Pitch drop: fast/slow/right?
//   4. Decay: right for Hood, or too long/short?
//
// Also: does the sparse pattern (test 3) do what it should — make you
// hear the silence between the hits as structural? Or does it just sound
// like a missing beat?
// ============================================================================
