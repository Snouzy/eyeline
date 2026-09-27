# Lessons

The first four come from the `trace` project and still apply here.

- **Answer a direct question at the end of the turn.** I answered "how do I launch the app" at the start of a long turn, then did 20 tool calls. The user asked the same question again. When a turn has a question and work, put the answer in the final message too.
- **Size estimates: count the rules, not only the feature.** I estimated a settings window at 70 lines. It took 200, because the agreed rules added validation and edge cases. Estimate after the rules are known, and give a range.
- **zsh does not split an unquoted variable.** `swiftc $FLAGS` passes one argument. Write the flags inline, or use `${=FLAGS}`.
- **Stacked pull requests do not move to `main` by themselves.** GitHub moves the next pull request to `main` after a merge only when the merged branch is deleted. With a solo repo, open each pull request against `main`, one at a time. After the user says "merged", check `origin/main` before the next step.
- **Check each setting at the ends of its range.** The fade kept three lines visible below the reading line. At 34 pt that looked right; at 12 pt with tight spacing, most of the screen went black and the user had to point at it. A value in lines or in points depends on the other settings: take a screenshot at the minimum and at the maximum of each slider before calling a change done.
