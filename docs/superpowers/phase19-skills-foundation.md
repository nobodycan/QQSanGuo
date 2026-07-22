# Phase 19 Skills Foundation

- Added data-driven SkillBook definitions, known skills, unlock-level checks, MP validation, and tick cooldowns.
- Added pilot level-1 basic attack and level-3 active strike definitions in regression coverage.
- Cast failures are explicit for locked skills, insufficient MP, and active cooldowns.

`test_skill_book` covers unlock boundaries, MP consumption, cooldown rejection, and cooldown completion.
