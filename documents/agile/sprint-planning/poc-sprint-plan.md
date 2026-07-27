# Trust Hire
## Sprint Plan (POC)

Version: 0.1

---

# Vision

Trust Hire is a location-first hiring platform built for Pakistan's informal workforce.

Instead of expecting users to fill in long forms, the app lets people communicate naturally.

A job post should feel like sending a WhatsApp message rather than filling out government paperwork.

Examples:

- Record a voice note
- Add a few pictures
- Type a short title if desired
- Drop the job roughly on a map
- Choose when the work needs to happen

The goal is reducing friction.

The platform adapts to the users—not the other way around.

---

# POC Goals

The Proof of Concept should demonstrate:

- Posting jobs
- Browsing nearby jobs
- Viewing job details
- Basic search/filter
- Offline local persistence
- Modern mobile UX

Not included:

- Accounts
- Authentication
- Backend
- Payments
- Messaging
- Notifications
- Real-time updates

---

# Technical Constraints

## No backend

The application runs entirely locally.

Data loads from startup JSON files.

Changes exist only on the current device.

Restarting the application restores the original seed data.

---

## Seed Data

At startup:

```
assets/
    seed/
        jobs.json
        users.json
```

The app copies these into local storage.

All editing happens only against local storage.

---

## Local Persistence

Examples:

Android/iOS

- Hive
- Isar
- SQLite
- Local JSON

The implementation choice is not important during the POC.

---

# Core Job Model

Minimal required information.

```
Job

id

title

location

radius

scheduledTime

voiceNote

photos[]

shortDescription

createdAt
```

Everything else is optional.

The philosophy is:

Missing information is acceptable.

---

# Design Principles

## 1. Map First

The map is the product.

Jobs exist on a map.

Not inside long lists.

---

## 2. Flexible Posting

Do NOT require:

- long descriptions
- categories
- fixed forms
- mandatory fields

Users should be able to post with:

- voice only
- photos only
- title only

or any combination.

---

## 3. Reduce Typing

Every additional field reduces adoption.

Prioritize:

Voice

Pictures

Location

Time

Everything else is optional.

---

# Sprint 0
Repository Setup

Goal

Project skeleton.

Deliverables

- Git repository
- Project created
- Folder structure
- README
- Seed data folder
- Basic theme
- Navigation scaffold

Definition of Done

Application launches.

---

# Sprint 1
Map Screen

Goal

Display jobs on a map.

Deliverables

- Map component
- Current location
- Load jobs.json
- Job markers
- Marker clustering (optional)
- Tap marker

Definition of Done

User can browse seeded jobs.

---

# Sprint 2
Job Details

Goal

Display a job.

Deliverables

- Bottom sheet
- Photo gallery
- Voice playback
- Time
- Distance
- Description
- Map preview

Definition of Done

Every seeded job opens correctly.

---

# Sprint 3
Create Job

Goal

Create jobs locally.

Deliverables

- Select map location
- Select radius
- Add photos
- Record voice
- Optional title
- Optional description
- Pick date/time
- Save locally

Definition of Done

New jobs appear immediately.

Persist until app uninstall.

---

# Sprint 4
Editing

Goal

Modify local jobs.

Deliverables

- Edit
- Delete
- Replace photos
- Replace voice note

Definition of Done

CRUD completed.

---

# Sprint 5
Discovery

Goal

Finding nearby work.

Deliverables

- Search
- Time filter
- Distance filter
- "Today's Jobs"
- "Near Me"

Definition of Done

Jobs easily discoverable.

---

# Sprint 6
Polish

Goal

Make the app feel real.

Deliverables

- Animations
- Loading states
- Empty states
- Error states
- Better icons
- Better typography

Definition of Done

Feels like a production mobile application.

---

# Stretch Goals

These are nice to have.

## Voice Transcription

Automatically generate a short summary from voice.

---

## AI Summary

Summarise:

"I need a plumber tomorrow morning"

↓

"Plumber • Tomorrow 9am"

---

## Smart Categories

Generated automatically.

Users never choose categories.

---

## Better Map

Heat maps

Popular areas

Density

---

## Job Images

Multiple photos.

Swipe gallery.

---

## Radius Display

Show work area as a semi-transparent circle.

---

## Dark Mode

Support both themes.

---

# Folder Structure

```
lib/

    app/

    core/

    features/

        map/

        jobs/

        create_job/

        settings/

    models/

    services/

    widgets/

assets/

    images/

    seed/

    audio/
```

---

# UX Principles

- One-handed usage
- Large tap targets
- Minimal typing
- Voice before keyboard
- Pictures before paragraphs
- Fast interactions
- No unnecessary validation

---

# Success Criteria

A person should be able to:

1. Open the app
2. See nearby jobs
3. Tap a marker
4. Listen to a voice note
5. View pictures
6. Create a new job
7. See it appear immediately

No internet connection required.

No login required.

No backend required.

If those tasks work smoothly, the POC is successful.

---

# Future (Post-POC)

After validating the concept:

- Authentication
- Cloud backend
- Real-time updates
- Messaging
- Push notifications
- Employer profiles
- Worker profiles
- Ratings
- Payments
- AI-assisted posting
- Moderation
- Analytics
