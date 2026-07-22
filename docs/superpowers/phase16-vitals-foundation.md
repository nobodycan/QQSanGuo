# Phase 16 Vitals Foundation

- Added versioned vitals state with HP, MP, max values, alive state, and death count.
- Damage, recovery, and revival clamp values deterministically.
- Death is idempotent: additional damage after death cannot emit another death transition.
- Dead actors do not receive recovery; revival explicitly restores a valid alive state.

`test_vitals` covers overkill, repeated damage, dead recovery, capped revival, and negative recovery input.
