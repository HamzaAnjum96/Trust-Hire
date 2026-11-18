# The structure revamp: trades are the spine

Date: 2026-11-18. The owner, after 0.24: "I am unhappy with the UI revamp. It
should have done more than refont and re[colour]." The palette and type of
0.24 stay (DESIGN.md); this changes how the screens are organised.

## How it was chosen

Impeccable's surface round, unattended (the owner asked not to be asked).
Seven structures for the Jobs destination and the shell, ordered by fit:

1. the map with a persistent draggable sheet of jobs;
2. the map with a carousel of job cards;
3. a list-first departure board grouped by when;
4. a split home: summary strip, map block and list in one scroll;
5. a "needs you" home: offers and messages above nearby work;
6. a trade hub: trades as the index, with live counts near you;
7. search-first.

`concept-seed --scope surface --mode operate` dealt 6, 2 and 3; **6 leads**
(seed b1c9ee8466e07f045a00193c9ebbb90e). Built unattended, as the playbook
says when nobody can be asked.

## The translation

A hub of same-size tiles (icon, trade, count) is the category's default and
Impeccable's craft floor refuses it; the world already says rows, not cards,
and columns that never move. So the hub is a **trade board**: one row per
trade near you, read down like a departures board, in fixed columns.

| Trade | Jobs | Nearest | Fares |
| --- | --- | --- | --- |
| Plumbing | 4 | 1.2 km | Rs. 1,500–7,000 |

## First viewport (Jobs, on a phone)

The search bar with Ask; the quick filters; "Work near you" with the count;
the trade board; then the jobs themselves, nearest first. The map is one tap
away on the same switch as before, and on a desktop the map stays beside it.

## Signature interaction

Tap a trade: its row glows turmeric, and the list under it and the pins on
the map narrow to that trade. Tap it again for every trade. The job in hand
still glows turmeric wherever it appears.

## Across the app

- **Jobs:** the board leads; the map is the other view.
- **The job sheet:** a ticket. Trade and title first, then a fact bar of
  fare, when and distance, then the voice note and the details; the action
  stays at the foot.
- **Directory:** the same board, for people: trade, how many listed, prices
  from.
- **Profile:** who is logged in, with Log in or Log out; the role as a
  segmented control; the record and the settings grouped under it.

## Honest risk

The map was the first thing anyone saw; now a list is. Location still leads
in the data (each trade carries its nearest job's distance, each row its
distance), and the map is one tap away.

## 0.29 and 0.30: the job sheet's ticket, and the trades prompt on the board

- **0.29** — a job's sheet opens on a ticket: fare, when, and distance in one
  tinted strip. They are what a worker decides on, and they were three rows
  apart.
- **0.30** — "Add a trade" left the map. It was a dismissible card over the
  thing it was about; now it is the trade board's last row, with how many
  jobs a trade would add, and it needs no dismissing.

## 0.31 to 0.34: smaller moves from the same review

- **0.31** — a job's area map follows the *Area* row instead of ending the
  sheet below the phone number.
- **0.32** — the Directory's "Only people who travel to me" checkbox became
  the first filter chip, *Travel to me*: a row of height back before the
  first person.
- **0.33** — the trade board drops its fares column below 350px, so the
  desktop rail no longer breaks a trade's name over two lines; its rows carry
  a semantic tap for screen readers.
- **0.34** — one page transition, fade-forwards, on every OS the browser
  reports. A pushed screen zoomed on Windows and Linux and slid on a Mac.

**Motion, reviewed.** What is left all explains a change of state: the
selected pin grows, a chosen tag tile fills, page dots move, the board and the
map cross-fade when you switch view, and a pushed screen fades forwards. The
list's entrance stagger went in 0.26; it replayed on every filter.

