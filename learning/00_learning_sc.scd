// ============================================================================
// 00_learning_sc.scd — Getting fluent enough in SuperCollider to read our code
// ============================================================================
//
// Dale — this is a teaching patch. It's not part of the album. Its only job
// is to get you to the point where you can read a SynthDef and know what each
// part is doing. Everything we build for the record is made of SynthDefs, so
// this is the single most important concept to get solid.
//
// HOW TO USE THIS FILE:
//   SuperCollider doesn't run top-to-bottom like a script. You evaluate one
//   block at a time. A "block" is code between two blank lines, OR code
//   wrapped in parentheses. You evaluate by clicking inside the block and
//   pressing Cmd+Return on macOS. The Post window at the bottom of the IDE
//   will tell you what happened.
//
//   DO NOT select-all and run the whole file. Go block by block, in order,
//   reading the comments first. If something doesn't behave as described,
//   stop and tell me.
//
// SAFETY:
//   Monitor volume at zero before you start. Bring it up only once the first
//   sound is playing and you know what it sounds like. SC can produce loud
//   accidents when you're learning. There's a limiter at the end of this file
//   we'll install after the first few exercises, but your physical volume
//   knob is the only limiter that genuinely can't be bypassed.
// ============================================================================


// ---------------------------------------------------------------------------
// STEP 1 — The language/server split, and why SC has two things running.
// ---------------------------------------------------------------------------
//
// When you launched SuperCollider, two separate programs started:
//
//   sclang  — the LANGUAGE.  This is what you're typing into. It's a text
//             interpreter. It doesn't make sound. Its job is to send
//             instructions to the server over the network (even though
//             "the network" is usually just localhost on your own machine).
//
//   scsynth — the SERVER.    This is the audio engine. It makes sound.
//             It doesn't understand our code directly — it understands
//             simple messages like "make a sine wave at 440Hz on bus 0".
//             sclang translates our code into those messages and sends them.
//
// This split is why you'll see two separate status indicators at the
// bottom-right of the IDE: "Interpreter" (that's sclang) and "Server"
// (that's scsynth). They can be in different states. The interpreter can
// be alive and running while the server is off, and vice versa.
//
// Why does this matter? Because when something goes wrong, knowing which
// half is the problem is half the debugging. If the interpreter is dead,
// no code will run at all. If the server is dead, code will run but nothing
// will make sound.
//
// Evaluate the line below (click in it, Cmd+Return). It should post your
// server's current state to the Post window. If you haven't booted the
// server yet, it'll say something like "a Server" and list it as not running.

s.serverRunning;


// ---------------------------------------------------------------------------
// STEP 2 — Point the server at the Volt 1 and boot it.
// ---------------------------------------------------------------------------
//
// Before booting, we tell the server which audio device to use. If we don't
// do this, it'll use whatever macOS has set as default, which is a source
// of confusion we don't need.
//
// Server.default.options.* are settings that only take effect on boot/reboot.
// Change them, THEN boot. If the server is already running when you change
// these, you need to s.reboot for them to take effect.
//
// Evaluate this whole block as one — put your cursor inside the parentheses
// and Cmd+Return. SC will evaluate everything inside the parens together.

(
Server.default.options.outDevice = "Volt 1";
Server.default.options.inDevice = "Volt 1";      // tell SC to use Volt for input too
Server.default.options.sampleRate = 48000;
Server.default.options.numOutputBusChannels = 2;
Server.default.options.numInputBusChannels = 2;  // matches the Volt's 2 inputs
Server.default.options.memSize = 8192 * 32;
)

// Now boot the server. Evaluate this line:

s.boot;

// Watch the Post window. You should see a sequence of messages ending with
// something like "Shared memory server interface initialized" and the
// "Server:" indicator at the bottom-right should turn active (coloured, not
// grey) with a small percentage of CPU usage.
//
// If boot fails, the two most likely causes are:
//   1. Another app is holding the Volt 1 exclusively (close it).
//   2. The Volt 1 is set to a different sample rate somewhere else (check
//      Audio MIDI Setup.app → Volt 1 → Format).


// ---------------------------------------------------------------------------
// STEP 3 — Your first sound. One line. A sine wave at 440Hz.
// ---------------------------------------------------------------------------
//
// VOLUME CHECK: Monitor knob near zero before you evaluate this.
//
// { SinOsc.ar(440) * 0.1 }.play;
//
// Let me explain this before you run it:
//
//   { ... }        — curly braces wrap a "function". Think of it as a recipe.
//   SinOsc.ar(440) — a sine oscillator, running at "audio rate" (ar), at 440Hz.
//                    440Hz is concert A. Middle-of-the-keyboard pitch.
//   * 0.1          — multiply the output by 0.1, i.e. reduce amplitude to 10%.
//                    SynthDefs output at full scale (-1 to +1) by default.
//                    0.1 is a safe listening level to start with.
//   .play          — take this function, compile it into a synth, send it to
//                    the server, start it running. The result is a "Synth" —
//                    a running voice on the server.
//
// Evaluate it. Bring your monitor volume up slowly. You should hear a steady
// sine tone.

{ SinOsc.ar(440) * 0.1 }.play;

// To stop ALL sound immediately, press Cmd+. (Cmd-period). This is the
// universal "stop everything on the server" shortcut in SC. Learn it now —
// you will use it constantly. It's the equivalent of muting the master
// but at the engine level: every running synth is killed.
//
// Try it now. Cmd+. should silence the sine.


// ---------------------------------------------------------------------------
// STEP 4 — A sine that fades out on its own, and a variable to hold it.
// ---------------------------------------------------------------------------
//
// The sine above ran forever until you Cmd+. killed it. Usually we want
// sounds that have an envelope — they start, do something, and end.
//
// Also, instead of just firing {...}.play and losing the handle to it, we'll
// store the running synth in a variable so we can control it explicitly.
//
// In SC, ~name (tilde-name) is a "global" variable. It persists across
// blocks. Regular variables (var x) only exist inside one block.
// We'll use ~ variables a lot so we can refer to running synths later.

(
~mySine = { SinOsc.ar(220) * 0.1 * EnvGen.kr(Env.perc(0.01, 2.0), doneAction: 2) }.play;
)

// What's new:
//   220Hz            — one octave below 440. Lower.
//   EnvGen.kr(...)   — an envelope generator running at "control rate" (kr).
//                      Control rate is lower-resolution than audio rate —
//                      fine for envelopes and modulation, cheap on CPU.
//   Env.perc(0.01,2) — a percussive envelope: 10ms attack, 2 second decay.
//   doneAction: 2    — when the envelope finishes, FREE this synth. Without
//                      this, the synth would stay on the server forever,
//                      silent but consuming resources. Always use
//                      doneAction: 2 on one-shot sounds.
//
// You should have heard a quick pluck-like sine that faded over ~2 seconds.
// After the fade, the synth freed itself — you don't need to Cmd+. it.


// ---------------------------------------------------------------------------
// STEP 5 — SynthDef: the reusable template.
// ---------------------------------------------------------------------------
//
// Everything above used {...}.play, which compiles on the fly. Fine for
// exploration, bad for a record. For the album, every sound is going to be
// a SynthDef — a named, reusable template we can trigger with different
// arguments.
//
// Here's the same sine, as a SynthDef:

(
SynthDef(\learningSine, {
    arg freq = 220, amp = 0.1, dur = 2.0;
    var sig, env;

    env = EnvGen.kr(Env.perc(0.01, dur), doneAction: 2);
    sig = SinOsc.ar(freq) * amp * env;

    Out.ar(0, sig ! 2);   // "! 2" duplicates the mono signal into both
                          // stereo channels. Out.ar(0, ...) sends to the
                          // main stereo output (bus 0 and 1).
}).add;
)

// When you evaluate that block, SC compiles the SynthDef and sends it to the
// server. You should see "SynthDef learningSine added" in the Post window.
// The SynthDef is now LIVING on the server, ready to be instantiated.
//
// Now play one:

Synth(\learningSine);

// That should fire the default: 220Hz, amp 0.1, 2s decay.
// Play it with different arguments:

Synth(\learningSine, [\freq, 440, \dur, 0.5]);   // higher, shorter
Synth(\learningSine, [\freq, 110, \dur, 4.0, \amp, 0.2]);   // lower, longer, louder
Synth(\learningSine, [\freq, 55,  \dur, 0.3, \amp, 0.3]);   // ← this is close
                                                            //   to the a02 kick
                                                            //   fundamental
//
// Notice: 55Hz on a near-flat monitor sounds puny without amplitude
// shaping and harmonics. That's expected. The a02 kick isn't just a sine —
// it's a sine with a pitch envelope (the "drop") that gives it punch, which
// is what we'll build when we get to the real patch.


// ---------------------------------------------------------------------------
// STEP 6 — A safety limiter on the master output.
// ---------------------------------------------------------------------------
//
// Everything above played directly to the output with only our amp values
// as protection. That's fine for quiet experimentation, bad as a habit.
//
// SC has no master bus in the way a DAW does — every synth writes to Out.ar
// directly, and signals sum there. Nothing stops two synths at amp 0.5 each
// from summing to 1.0 and clipping. Or worse, a feedback loop hitting 30.0
// and shredding your monitors.
//
// The fix is to put a Limiter on a group that runs AFTER everything else.
// Here's a simple safety limiter. Evaluate it after the server is booted
// and leave it running for the rest of the session:

(
SynthDef(\safetyLimiter, {
    var sig = In.ar(0, 2);   // read the master output bus (2 channels)
    sig = Limiter.ar(sig, 0.5, 0.01);   // hard limit at -6dB (0.5 = -6dBFS)
    ReplaceOut.ar(0, sig);   // write it BACK to the same bus, replacing
                             // the unlimited signal
}).add;
)

// Instantiate it AFTER all your sound-making synths by running it last.
// For a teaching patch this is fine; for the real a02 patch I'll set up
// proper group ordering so the limiter is always last automatically.

~limiter = Synth.tail(nil, \safetyLimiter);

// .tail means "put this synth at the END of the default group", so it
// processes after everything else. Now every sound you make will be
// limited at -6dB before it leaves the server.
//
// Test it by firing a loud one:

Synth(\learningSine, [\freq, 220, \amp, 0.9, \dur, 1.0]);   // amp 0.9, would
                                                            //  normally clip;
                                                            //  limiter catches it.


// ---------------------------------------------------------------------------
// STEP 7 — A couple more shortcuts you'll use constantly.
// ---------------------------------------------------------------------------
//
// Cmd+.         — kill all running synths (the panic button).
// Cmd+Return    — evaluate block under cursor.
// Cmd+D         — open the help browser on the thing your cursor is on.
//                 (Try putting your cursor on "SinOsc" and pressing Cmd+D —
//                 the help is excellent.)
// Cmd+\         — clear the Post window.
//
// That's the whole basic kit.


// ---------------------------------------------------------------------------
// When you're done with this session: reboot or quit.
// ---------------------------------------------------------------------------
//
// When you're finished playing, it's good hygiene to free the server:

s.quit;

// Or just quit the whole IDE. Nothing persists between sessions — the
// SynthDefs above vanish when the server quits. For the real project we'll
// have .scd files that get evaluated at session start to rebuild state.
//
// ============================================================================
// END OF TEACHING PATCH.
//
// If all of the above worked — you heard sines, you heard the envelope
// shape the tone, you understood that SynthDef is a template and Synth is
// an instance of it, and you can read a SynthDef and guess what it does —
// you're ready for the a02 patch.
//
// If any step didn't work or didn't make sense, tell me which one. Don't
// skip over it. The a02 patch is built entirely out of the concepts in
// this file; if any of them are shaky, the real patch will feel like
// hieroglyphics.
// ============================================================================
