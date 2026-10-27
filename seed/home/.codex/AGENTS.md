# tabsh board

When the user's task is done (not paused, not waiting on them), run `/usr/local/bin/tabsh status completed --note '<one line: what you did>'` to mark this terminal's card done on the tabsh board. Outside a tabsh terminal it only prints "not inside a tabsh terminal"; ignore that. Never set any other tabsh status yourself: hooks handle those, and archiving is the user's.
