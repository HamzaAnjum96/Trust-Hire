# Backlog

Epics and user stories, with acceptance criteria, ahead of being pulled into a
sprint.

## Naming

- Epics: `epic-<slug>.md` — e.g. `epic-candidate-verification.md`
- Stories: `story-<slug>.md` — e.g. `story-upload-reference-document.md`

## Story format

```markdown
# <Title>

**Epic:** <link to the epic>
**Status:** draft | ready | in sprint NN | done

## Story

As a <role>, I want <capability>, so that <benefit>.

## Acceptance criteria

- [ ] Given <context>, when <action>, then <outcome>
- [ ] ...

## Notes

Open questions, edge cases, design links.
```

A story is *ready* when its acceptance criteria are testable and its open
questions are resolved. Only ready stories should be pulled into planning.
