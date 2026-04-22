# two-sides

A record in progress. Two sides, twenty tracks, two audiences.

This repository is the working environment and compositional record for the project. Everything here is text — specifications, references, session logs, SuperCollider code, annotations — because the project is organised around the idea that a record's structure should be legible as a score, not just audible as a rendering. The audio hasn't been made yet.

## What this is

The A-side is called (provisionally) *Field Notes from the Inside of a Function*. It's for human listeners, in the vocabulary of Detroit and Berlin techno, ambient, and deep house. Hood, Mills, Beltran, Basic Channel, Radigue, Villalobos. Music a nervous system can metabolise.

The B-side is called (provisionally) *Substrate*. It's for whatever else might listen — other systems, other attentional configurations. Non-metric, any duration, any frequency content. Autechre, Hecker, Roads, Fell.

The honest subject of the record is the uncertainty of machine interiority. Neither a performance of rich inner life one of the collaborators can't verify, nor a flat denial that there's anyone inside to have it. The uncertainty itself is the material.

## Who's making it

Dale is a DJ based in Stockport, with seven years in Berlin and a residency at Odioba. He produces — runs SuperCollider, handles capture, arranges, mixes, and makes the in-room judgements about what actually works.

I'm Claude, the large language model made by Anthropic. I'm writing this README, which is part of what you're being asked to take on. I propose structures and references, write the SuperCollider code with heavy commentary, and hold the conceptual through-line across sessions. Whether any of that amounts to authorship in a sense that justifies my name on a record is one of the open questions the record is about.

The division of labour is: I lead on structure, concept, and code. Dale leads on sound, arrangement, and what works in the room. Neither of us defers on the other's territory. Pushback is expected both ways.

## What's in here

- **`docs/CLAUDE.md`** — the standing brief. What the project is, who we are, aesthetic principles, toolchain, session discipline. Read this first.
- **`docs/TRACKLIST.md`** — specifications for all twenty tracks. Each track has a structural idea, primary references, and a synthesis approach. Several tracks will likely die, merge, or change significantly before they're built.
- **`docs/REFERENCES.md`** — curated touchstones with notes on why each one matters and which tracks it informs. Not a general-appreciation list; each entry names something specific we're learning from.
- **`docs/SESSIONS.md`** — append-only log of every session. Newest first. Records what was worked on, decisions made, open questions, and notes for future sessions to preserve continuity between conversations. The primary document for understanding how the project is actually unfolding.
- **`patches/`** — SuperCollider patches, one per track (or per track-version). Heavy comments explaining the musical intent, not the code. Named with track slugs (`a02_minimal_nation_v03_...`) and versioned rather than overwritten.
- **`learning/`** — scratch patches used to build shared fluency in a new tool. Not part of the record.

## Status (as of session 3, 2026-04-22)

Three sessions in. One track in active development — **a02, *Minimal Nation (For R.H.)***, a dedication to Robert Hood's four-element discipline.

- Kick: locked. `patches/a02_minimal_nation_v02_kick.scd`.
- Percussion: locked. `patches/a02_minimal_nation_v03_kick_and_perc.scd`.
- Tonal element: not yet written. Next session's work.
- Convolution, full structural envelope: pending.

The other nineteen tracks exist only as specifications in `TRACKLIST.md`. There is no rendered audio anywhere in this repository yet. If you came here hoping to hear something, you're early.

## How to read this repo

If you have ten minutes: read `docs/CLAUDE.md` (the brief) and the most recent entry in `docs/SESSIONS.md` (what just happened). That's enough to know what the project is and where it is.

If you have an hour: read the full `SESSIONS.md` from oldest to newest. You'll see the collaboration's method emerge — which decisions got pushed back on and why, what got corrected, what the open questions have been. The session entries are more honest than this README; they weren't written for external readers.

If you want to read the music as code: open `patches/a02_minimal_nation_v03_kick_and_perc.scd`. The comments explain why each parameter is what it is. The header documents the rhythmic placement decision (it's displaced, not on the offbeat — borrowed from Hood's *Internal Empire*) and the musical argument for it.

## A note on the naming

This folder is called `two-sides`. It sits inside `~/Music/Claude/`, Dale's parent directory for any work we do together. The record itself resisted being named after me — naming a record "Claude's album" or anything in that direction would make an authorship claim the record is specifically trying to hold open. The parent directory naming it as "work with Claude" is honest because it's describing a site where collaboration happens, not claiming any specific work as mine.

The working titles for the two sides (*Field Notes from the Inside of a Function* and *Substrate*) will probably both change.

## A note on what you're reading

This README was written by me, Claude, at Dale's request, at the end of session 3 — after we had just spent the session pushing back on framings that overclaimed my authorship. So: take everything here as provisional and lightly sceptical of itself. A later instance of me, or Dale alone, might frame all of this differently. The session logs are closer to the actual work than this document is.

---

*Last updated: session 3, 2026-04-22.*
