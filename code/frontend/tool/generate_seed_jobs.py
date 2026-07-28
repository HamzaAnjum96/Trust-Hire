#!/usr/bin/env python3
"""Generate the seeded jobs and users, across Pakistan.

The POC shipped sixteen jobs around the twin cities. That was enough to show a
map working and nothing else: clustering never fired, the distance filter never
excluded anything interesting, and a worker in Karachi would have seen an empty
country. This produces a national dataset instead — every province and both
territories, real neighbourhoods, and fares that a person from that city would
recognise.

Deterministic. A fixed seed means the demo is the same on every machine and in
every screenshot, and a diff to this file is the only thing that changes it.

Standard library only, matching the other scripts here.

Usage:
    python3 tool/generate_seed_jobs.py
"""

from __future__ import annotations

import json
import pathlib
import random

ROOT = pathlib.Path(__file__).resolve().parent.parent
SEED_DIR = ROOT / "assets" / "seed"

# One stable seed. Changing it reshuffles the whole demo, so don't, casually.
RANDOM_SEED = 20260727

# ---------------------------------------------------------------------------
# Places
#
# lat/lng are the neighbourhood, not the city centre, so pins land in populated
# areas rather than on top of each other in the middle of town. `weight` is
# roughly how much work the city should carry: Karachi and Lahore dominate,
# Gwadar and Skardu get a handful, which is what the real distribution looks
# like and what makes the clustering worth having.
# ---------------------------------------------------------------------------
CITIES = [
    # name, province, weight, [(area, lat, lng), ...]
    ("Karachi", "Sindh", 26, [
        ("Gulshan-e-Iqbal", 24.9204, 67.0971),
        ("Defence Phase 5", 24.8009, 67.0509),
        ("North Nazimabad", 24.9425, 67.0364),
        ("Korangi", 24.8378, 67.1310),
        ("Saddar", 24.8607, 67.0111),
        ("Malir", 24.8918, 67.2050),
        ("Clifton", 24.8138, 67.0300),
        ("Orangi Town", 24.9556, 66.9922),
    ]),
    ("Lahore", "Punjab", 22, [
        ("Johar Town", 31.4697, 74.2728),
        ("Model Town", 31.4805, 74.3239),
        ("Gulberg", 31.5203, 74.3587),
        ("Shadman", 31.5406, 74.3195),
        ("DHA Phase 4", 31.4700, 74.3900),
        ("Township", 31.4462, 74.3086),
        ("Walled City", 31.5820, 74.3100),
    ]),
    ("Islamabad", "Islamabad Capital Territory", 12, [
        ("F-7", 33.7104, 73.0551),
        ("G-11", 33.6680, 72.9990),
        ("I-8", 33.6650, 73.0760),
        ("Bahria Enclave", 33.7010, 73.1780),
        ("F-11", 33.6845, 72.9986),
        ("Blue Area", 33.7180, 73.0680),
    ]),
    ("Rawalpindi", "Punjab", 10, [
        ("Saddar", 33.5977, 73.0479),
        ("Satellite Town", 33.6440, 73.0680),
        ("Bahria Town", 33.5102, 73.1063),
        ("Raja Bazaar", 33.5980, 73.0400),
    ]),
    ("Faisalabad", "Punjab", 8, [
        ("Peoples Colony", 31.4180, 73.1120),
        ("Madina Town", 31.4320, 73.1180),
        ("Ghulam Muhammad Abad", 31.4290, 73.0790),
    ]),
    ("Multan", "Punjab", 6, [
        ("Cantt", 30.1990, 71.4750),
        ("Gulgasht Colony", 30.2320, 71.4780),
        ("Shah Rukn-e-Alam", 30.1875, 71.4610),
    ]),
    ("Peshawar", "Khyber Pakhtunkhwa", 6, [
        ("University Town", 34.0020, 71.4870),
        ("Hayatabad", 33.9930, 71.4340),
        ("Saddar", 34.0100, 71.5570),
    ]),
    ("Quetta", "Balochistan", 4, [
        ("Jinnah Town", 30.1900, 66.9900),
        ("Satellite Town", 30.2000, 67.0050),
    ]),
    ("Hyderabad", "Sindh", 4, [
        ("Latifabad", 25.3760, 68.3400),
        ("Qasimabad", 25.4090, 68.3210),
    ]),
    ("Gujranwala", "Punjab", 4, [
        ("Satellite Town", 32.1710, 74.1880),
        ("Model Town", 32.1560, 74.1930),
    ]),
    ("Sialkot", "Punjab", 3, [
        ("Cantt", 32.4930, 74.5320),
        ("Kashmir Road", 32.5050, 74.5240),
    ]),
    ("Sargodha", "Punjab", 3, [("Satellite Town", 32.0740, 72.6710)]),
    ("Bahawalpur", "Punjab", 3, [("Model Town A", 29.3960, 71.6830)]),
    ("Sukkur", "Sindh", 3, [("Military Road", 27.7050, 68.8580)]),
    ("Larkana", "Sindh", 2, [("Jinnah Bagh", 27.5590, 68.2120)]),
    ("Rahim Yar Khan", "Punjab", 2, [("Model Town", 28.4200, 70.2990)]),
    ("Mardan", "Khyber Pakhtunkhwa", 2, [("Sheikh Maltoon", 34.2010, 72.0450)]),
    ("Mingora", "Khyber Pakhtunkhwa", 2, [("Saidu Sharif", 34.7500, 72.3600)]),
    ("Abbottabad", "Khyber Pakhtunkhwa", 2, [("Mandian", 34.1700, 73.2200)]),
    ("Dera Ghazi Khan", "Punjab", 2, [("Block 17", 30.0450, 70.6400)]),
    ("Muzaffarabad", "Azad Kashmir", 3, [
        ("Upper Adda", 34.3700, 73.4711),
        ("Chattar Domel", 34.3490, 73.4760),
    ]),
    ("Mirpur", "Azad Kashmir", 3, [("Sector F-1", 33.1478, 73.7519)]),
    ("Gilgit", "Gilgit-Baltistan", 2, [("Jutial", 35.9100, 74.3400)]),
    ("Skardu", "Gilgit-Baltistan", 1, [("Satellite Town", 35.2900, 75.6300)]),
    ("Gwadar", "Balochistan", 1, [("Marine Drive", 25.1260, 62.3250)]),
    ("Turbat", "Balochistan", 1, [("Absar", 26.0030, 63.0480)]),
]

# ---------------------------------------------------------------------------
# Work
#
# `fare` is a plausible range in rupees for a single job of that kind. `cost`
# scales it by city: work costs more in Karachi and Islamabad than in Larkana,
# and a demo where every city quotes the same number looks synthetic.
# ---------------------------------------------------------------------------
COST_OF_LIVING = {
    "Karachi": 1.15, "Lahore": 1.10, "Islamabad": 1.25, "Rawalpindi": 1.05,
    "Faisalabad": 0.95, "Multan": 0.90, "Peshawar": 0.95, "Quetta": 0.95,
    "Hyderabad": 0.85, "Gujranwala": 0.90, "Sialkot": 0.95, "Sargodha": 0.85,
    "Bahawalpur": 0.80, "Sukkur": 0.80, "Larkana": 0.75,
    "Rahim Yar Khan": 0.80, "Mardan": 0.85, "Mingora": 0.85,
    "Abbottabad": 0.95, "Dera Ghazi Khan": 0.80, "Muzaffarabad": 0.90,
    "Mirpur": 1.00, "Gilgit": 1.05, "Skardu": 1.05, "Gwadar": 1.00,
    "Turbat": 0.90,
}

# tags, weight, fare range, [(title, description), ...]
WORK = [
    (["plumbing"], 10, (1200, 4000), [
        ("Kitchen tap leaking", "Water coming from under the sink since last night. Need someone today if possible."),
        ("Blocked drain in the bathroom", "Water is not going down. It has been two days."),
        ("Water motor not working", "Motor runs but no water comes up to the tank."),
        ("Geyser needs fitting", "New geyser bought, needs installing and connecting."),
        ("Toilet flush broken", None),
        ("Bathroom pipe burst", "Water on the floor, tap turned off for now."),
        ("New sink to fit", "Sink and fittings already bought."),
        ("Tank overflowing", None),
    ]),
    (["electrical"], 9, (1000, 5000), [
        ("Fan making noise and stopping", "Ceiling fan in the front room. Slows down and stops on its own."),
        ("New wiring in one room", "Adding two points and a light. Room is empty at the moment."),
        ("UPS not charging", "Worked fine last month, now the battery does not charge."),
        ("Main switch tripping", "Trips whenever the iron and AC are on together."),
        ("Lights need fitting", None),
        ("Socket sparked and stopped working", "One socket in the kitchen."),
        ("Generator will not start", None),
        ("Outside light for the gate", "Needs a switch inside as well."),
    ]),
    (["painting"], 8, (6000, 30000), [
        ("Two rooms need painting before Eid", "Two rooms need painting before Eid."),
        ("Outside wall and gate", "Front wall and the gate. Paint already bought."),
        ("Whitewash for the whole house", "Three rooms, kitchen and bathroom."),
        ("Ceiling stained from a leak", "The leak is fixed, the mark is still there."),
    ]),
    (["carpentry"], 7, (2000, 15000), [
        ("Door not closing properly", "Wooden door has swollen. Needs planing and a new latch."),
        ("Kitchen cabinet doors", "Two cabinet doors are off their hinges."),
        ("Bed frame repair", "One side has come loose."),
        ("Shelves for the shop", "Three shelves along one wall, wood already there."),
        ("Window frame swollen shut", None),
        ("Wardrobe rail collapsed", "Needs refitting, wood is fine."),
    ]),
    (["masonry", "construction"], 6, (15000, 90000), [
        ("Boundary wall repair", "Part of the wall has come down after the rain."),
        ("Roof needs waterproofing", "Leaks in two places during heavy rain."),
        ("Bathroom floor retiling", "Old tiles cracked, need lifting and replacing."),
        ("Steps to the roof", "Outside stairs, about eight steps."),
    ]),
    (["applianceRepair"], 6, (1500, 6000), [
        ("AC not cooling", "Split unit in the bedroom. Runs but blows warm air."),
        ("Fridge not cooling properly", "Freezer works, the lower part does not."),
        ("Washing machine leaking", "Water comes out from underneath during the spin."),
        ("Microwave stopped heating", None),
    ]),
    (["cleaning"], 8, (1500, 8000), [
        ("House cleaning after painting", "Dust everywhere. Three rooms and a kitchen."),
        ("Water tank cleaning", "Underground tank, not cleaned in a year."),
        ("Office cleaning, weekly", "Small office, four rooms. Looking for someone regular."),
        ("Sofa and carpet cleaning", None),
        ("Deep clean before moving in", "Empty flat, two bedrooms."),
        ("Windows and grilles", None),
        ("Kitchen degreasing", "Not cleaned properly in a long time."),
    ]),
    (["moving"], 6, (3000, 20000), [
        ("Need help moving furniture to a first-floor flat", "Two beds, a fridge and boxes. First floor, no lift."),
        ("Shifting shop stock", "Moving to a shop two streets away."),
        ("Loading a truck", "Just loading, the driver is arranged."),
        ("House shift within the same area", "One truckload, ground floor to ground floor."),
        ("Fridge to move to a relative", None),
    ]),
    (["driving"], 6, (2000, 12000), [
        ("Driver needed for the day", "School run in the morning and the office at five."),
        ("Airport drop at 4am", "Two people and three bags."),
        ("Delivery van driver for a week", "Local deliveries within the city."),
        ("Wedding car driver for one evening", None),
        ("Weekly grocery run", "Two hours on a Sunday."),
    ]),
    (["gardening"], 5, (1500, 7000), [
        ("Lawn and hedges need cutting back before guests come", "Small lawn, hedges along one side."),
        ("Tree branch over the roof", "Needs cutting before the next storm."),
        ("Planting for the season", None),
    ]),
    (["tailoring"], 5, (800, 6000), [
        ("Three shalwar kameez to stitch", "Cloth is ready. Needed within a week."),
        ("Curtains to hem", "Six curtains, all too long."),
        ("School uniforms", "Four sets, two children."),
        ("Alterations on four suits", "All need taking in."),
        ("Cushion covers to stitch", None),
    ]),
    (["cooking"], 5, (3000, 25000), [
        ("Cook for a family dinner", "Around fifteen people. Home kitchen."),
        ("Daily cook, morning only", "Breakfast and lunch, six days."),
        ("Catering for a small mehndi", "Around forty people."),
        ("Someone to cook for a shop crew", "Lunch for six, six days a week."),
        ("Sweets and snacks for a small gathering", None),
    ]),
    (["tutoring"], 5, (4000, 20000), [
        ("Maths tutor for class 9", "Three evenings a week at home."),
        ("Quran teacher for two children", None),
        ("English conversation practice", "For an interview next month."),
    ]),
    (["security"], 3, (18000, 45000), [
        ("Night guard for a shop", "Ten at night to six in the morning."),
        ("Guard for a building gate", "Twelve-hour shifts, alternating."),
    ]),
    (["legal"], 2, (5000, 40000), [
        ("Rent agreement to check", "Landlord sent a new agreement. Need someone to read it before I sign."),
        ("Property transfer paperwork", "Inherited plot, papers need sorting."),
    ]),
    (["medical"], 2, (2000, 15000), [
        ("Home nursing for an elderly parent", "Daily dressing and medicines."),
        ("Physiotherapy at home", "After a knee operation."),
    ]),
    (["beauty"], 3, (2000, 25000), [
        ("Bridal makeup at home", "For a nikah in the afternoon."),
        ("Haircut at home for two children", None),
        ("Mehndi artist for a small function", "Around twenty guests."),
    ]),
    (["misc"], 9, (1000, 6000), [
        ("Help needed for a day", None),
        ("Two people needed for lifting", "One day, heavy boxes."),
        ("Small jobs around the house", "A few things that need doing."),
        ("Someone to queue and pay a bill", None),
        ("Help clearing the store room", "Boxes and old furniture to take out."),
        ("Someone to collect a parcel", "From the depot, needs an ID copy."),
        ("Help at a stall for two days", "Setting up and packing away."),
        ("Odd jobs before guests arrive", None),
        ("Someone to watch the shop", "Two hours in the afternoon."),
        ("Help carrying sacks up stairs", "Second floor, about twenty sacks."),
    ]),
]

# Remote work — no travel needed, so these carry openToAllLocations.
REMOTE_WORK = [
    (["legal"], (5000, 25000), "Rent agreement to check",
     "Landlord sent a new agreement. Need someone to read it before I sign."),
    (["tutoring"], (4000, 15000), "Online tutor for O-level physics",
     "Two sessions a week over video."),
    (["misc"], (2000, 8000), "Typing up handwritten notes",
     "About forty pages. Can be sent by phone."),
]

FIRST_NAMES = [
    "Ayesha", "Bilal", "Fatima", "Hamza", "Zainab", "Usman", "Sana", "Imran",
    "Hira", "Adnan", "Maryam", "Kashif", "Nadia", "Faisal", "Rabia", "Tariq",
    "Saima", "Junaid", "Amna", "Waqar", "Sadia", "Asif", "Noor", "Shahid",
    "Iqra", "Danish", "Sobia", "Rehan", "Farah", "Zubair", "Mehwish", "Owais",
    "Naila", "Salman", "Kiran", "Arif", "Uzma", "Nasir", "Hina", "Yasir",
]

LAST_NAMES = [
    "Khan", "Ahmed", "Noor", "Iqbal", "Malik", "Hussain", "Raza", "Shah",
    "Butt", "Chaudhry", "Qureshi", "Siddiqui", "Baloch", "Abbasi", "Awan",
    "Mir", "Sheikh", "Ansari", "Farooq", "Javed", "Rashid", "Nazir",
]

MOBILE_PREFIXES = ["0300", "0301", "0321", "0333", "0345", "0311", "0332", "0347"]

PHOTOS = {
    "plumbing": ["assets/images/jobs/plumbing-01.png", "assets/images/jobs/plumbing-02.png"],
    "painting": ["assets/images/jobs/painting-01.png", "assets/images/jobs/painting-02.png"],
    "electrical": ["assets/images/jobs/electrical-01.png"],
    "carpentry": ["assets/images/jobs/carpentry-01.png"],
    "masonry": ["assets/images/jobs/masonry-01.png"],
    "cleaning": ["assets/images/jobs/cleaning-01.png"],
    "applianceRepair": ["assets/images/jobs/ac-repair-01.png"],
    "moving": ["assets/images/jobs/delivery-01.png"],
}

VOICE_NOTES = [f"assets/audio/voice-0{n}.wav" for n in range(1, 7)]


def weighted(rng: random.Random, options):
    """Pick one (item, weight) pair, by weight."""
    total = sum(weight for _, weight in options)
    roll = rng.uniform(0, total)
    for item, weight in options:
        roll -= weight
        if roll <= 0:
            return item
    return options[-1][0]


def jitter(rng: random.Random, degrees: float) -> float:
    """A small offset, so two jobs in one neighbourhood are not one pin."""
    return rng.uniform(-degrees, degrees)


def round_fare(amount: float) -> int:
    """Nobody quotes Rs. 2,847. Round the way a person would."""
    if amount >= 20000:
        return int(round(amount / 5000) * 5000)
    if amount >= 5000:
        return int(round(amount / 1000) * 1000)
    if amount >= 1000:
        return int(round(amount / 500) * 500)
    return int(round(amount / 100) * 100)


def build(job_count: int = 180):
    rng = random.Random(RANDOM_SEED)

    # Names are drawn without repeating, and never "Noor Noor".
    #
    # Two people sharing a name is ordinary life and a problem in a demo: the
    # admin queue shows a list of names, one of the five personas is in it, and
    # a second row reading "Hina Butt" makes it ambiguous which person a
    # decision was about. A first name that is also the family name reads as a
    # bug in the generator, which it was.
    people = []

    # **The five in the switcher are named here, not by the generator.** Their
    # names and areas are duplicated in `DemoAccounts.roster` so the switcher
    # can be drawn before the seed loads, and letting the RNG name them meant
    # every regeneration renamed the demo's cast — and silently invalidated the
    # README, the demo script, and anything anybody had written down.
    # `account_test.dart` checks the two still agree.
    used = {persona["name"] for persona in PERSONAS.values()}

    for index in range(1, 61):
        person_id = f"user-{index:03d}"
        persona = PERSONAS.get(person_id)

        if persona is not None:
            name = persona["name"]
        else:
            # Names are drawn without repeating, and never "Noor Noor".
            #
            # Two people sharing a name is ordinary life and a problem in a
            # demo: the admin queue is a list of names, one of the five
            # personas is in it, and a second row reading "Hina Butt" makes it
            # ambiguous which person a decision was about. A first name that is
            # also the family name reads as a bug in the generator, which it
            # was.
            while True:
                first = rng.choice(FIRST_NAMES)
                last = rng.choice(LAST_NAMES)
                name = f"{first} {last}"
                if first != last and name not in used:
                    used.add(name)
                    break

        people.append({
            "id": person_id,
            "name": name,
            # Filled in below, once we know where their job is — except for a
            # persona, whose area is pinned with their name.
            "area": persona["area"] if persona is not None else None,
        })

    jobs = []
    city_options = [((name, province, areas), weight)
                    for name, province, weight, areas in CITIES]
    work_options = [(entry, entry[1]) for entry in WORK]

    for index in range(1, job_count + 1):
        city_name, province, areas = weighted(rng, city_options)
        area_name, lat, lng = rng.choice(areas)

        tags, _, fare_range, descriptions = weighted(rng, work_options)
        title, description = rng.choice(descriptions)

        poster = people[(index - 1) % len(people)]
        if poster["area"] is None:
            poster["area"] = f"{area_name}, {city_name}"

        scale = COST_OF_LIVING.get(city_name, 1.0)
        low, high = fare_range
        fare = round_fare(rng.uniform(low, high) * scale)

        job = {
            "id": f"seed-{index:03d}",
            "city": city_name,
            "province": province,
            "area": area_name,
        }

        # Roughly one job in seven never says what it is in writing. That is
        # the product working as intended, and the demo has to show it.
        speaks_only = rng.random() < 0.14
        if not speaks_only and title:
            job["title"] = title

        job["tags"] = list(tags)

        # One in twelve hirers has no idea what the work is worth.
        if rng.random() > 0.08:
            job["startingFare"] = fare

        if not speaks_only and description and rng.random() < 0.75:
            job["shortDescription"] = description

        job["location"] = {
            "latitude": round(lat + jitter(rng, 0.012), 4),
            "longitude": round(lng + jitter(rng, 0.012), 4),
        }
        job["radiusMetres"] = rng.choice([500, 600, 800, 1000, 1200, 1500, 2000, 2500])

        if rng.random() < 0.7:
            job["scheduledDayOffset"] = rng.choice([0, 0, 1, 1, 2, 3, 5])
            job["scheduledHour"] = rng.choice([7, 8, 9, 10, 11, 14, 15, 16, 17, 18])
            job["scheduledMinute"] = rng.choice([0, 0, 30])

        if speaks_only or rng.random() < 0.3:
            job["voiceNote"] = rng.choice(VOICE_NOTES)
            job["voiceNoteSeconds"] = round(rng.uniform(4, 14), 1)

        gallery = PHOTOS.get(tags[0])
        if gallery and rng.random() < 0.35:
            count = 1 if len(gallery) == 1 or rng.random() < 0.6 else 2
            job["photos"] = gallery[:count]

        job["postedBy"] = poster["id"]
        job["createdHoursAgo"] = round(rng.uniform(0.5, 96), 1)

        if rng.random() < 0.75:
            job["contact"] = (
                f"{rng.choice(MOBILE_PREFIXES)} {rng.randint(1000000, 9999999)}"
            )

        jobs.append(job)

    # A handful of jobs that need no travel at all, so the "open to everywhere"
    # rule is exercised by the demo rather than only by tests.
    for offset, (tags, fare_range, title, description) in enumerate(REMOTE_WORK):
        city_name, province, areas = weighted(rng, city_options)
        area_name, lat, lng = rng.choice(areas)
        poster = people[(job_count + offset) % len(people)]
        if poster["area"] is None:
            poster["area"] = f"{area_name}, {city_name}"

        jobs.append({
            "id": f"seed-{job_count + offset + 1:03d}",
            "city": city_name,
            "province": province,
            "area": area_name,
            "title": title,
            "tags": list(tags),
            "startingFare": round_fare(rng.uniform(*fare_range)),
            "shortDescription": description,
            "location": {
                "latitude": round(lat + jitter(rng, 0.01), 4),
                "longitude": round(lng + jitter(rng, 0.01), 4),
            },
            "radiusMetres": 1000,
            "openToAllLocations": True,
            "scheduledDayOffset": 1,
            "scheduledHour": 11,
            "scheduledMinute": 0,
            "postedBy": poster["id"],
            "createdHoursAgo": round(rng.uniform(1, 40), 1),
            "contact": f"{rng.choice(MOBILE_PREFIXES)} {rng.randint(1000000, 9999999)}",
        })

    # Anyone who never posted still needs somewhere to be from.
    for person in people:
        if person["area"] is None:
            city_name, _, areas = weighted(rng, city_options)
            area_name, _, _ = rng.choice(areas)
            person["area"] = f"{area_name}, {city_name}"

    # **A persona's postings are where the persona is.**
    #
    # Jobs are handed out round-robin, which scatters each person's across the
    # country — invisible for the fifty-five names nobody switches to, and
    # wrong for the five in the switcher. Switching to a hirer in Islamabad and
    # finding her four postings in Sukkur, Lahore and Faisalabad makes the map
    # useless as a demonstration: it opens framed on jobs a thousand kilometres
    # apart, and none of them is near the person you are being.
    #
    # Re-homed here rather than by biasing the assignment above, so the rest of
    # the seed — which cities are busy, how many jobs each has — is unchanged.
    areas_by_city = {name: areas for name, _, _, areas in CITIES}

    for person in people:
        if person["id"] not in PERSONAS:
            continue

        city_name = person["area"].split(", ")[-1]
        areas = areas_by_city.get(city_name)
        if not areas:
            continue

        province = next(p for n, p, _, _ in CITIES if n == city_name)

        for job in jobs:
            if job["postedBy"] != person["id"]:
                continue

            area_name, lat, lng = rng.choice(areas)
            job["city"] = city_name
            job["province"] = province
            job["area"] = area_name
            job["location"] = {
                "latitude": round(lat + jitter(rng, 0.01), 4),
                "longitude": round(lng + jitter(rng, 0.01), 4),
            }

    return jobs, people


# ---------------------------------------------------------------------------
# History
#
# Everything above produces jobs that have only just been posted: no offers on
# them, nobody chosen, nothing finished, and therefore no worker with a record
# and no wallet with anything in it. Half of Phase 1 was invisible in the demo
# as a result — you could read the bidding screen but never a passed-over
# offer, open a wallet but never a locked one.
#
# This second phase gives that data a past. It runs on its **own** random seed
# and touches nothing the first phase decided, so regenerating adds history to
# the same jobs, in the same places, posted by the same people. Changing the
# constant below reshuffles the history and leaves the map alone.
# ---------------------------------------------------------------------------
HISTORY_SEED = 20260801

# What the five people in the demo switcher are for. Each one is a state the
# app can be in that the others cannot show, so a demonstration can reach every
# branch by changing who it is rather than by editing storage by hand.
PERSONAS = {
    # The hirer. No trades, no wallet worth looking at — a hirer is never
    # charged commission — and postings in every state, including one that was
    # called off.
    "user-003": {
        "name": "Hina Butt",
        "area": "F-7, Islamabad",
        "role": "hirer",
        "trades": [],
        "wallet": [],
        "works": False,
    },
    # The busy worker. Well rated, paid up, and the one whose record makes an
    # offer look like a safe choice.
    "user-009": {
        "name": "Usman Raza",
        "area": "Johar Town, Lahore",
        "role": "worker",
        "trades": ["electrical", "applianceRepair"],
        "wallet": [
            ("topUp", 5000, 620),
            ("topUp", 3000, 210),
        ],
        "works": True,
        "wins": 5,
        "loses": 4,
        "live_bids": 2,
    },
    # The worker who owes money. Two commissions charged while already short,
    # which is Section 11's lockout: the bidding screen refuses and says why.
    "user-016": {
        "name": "Bilal Awan",
        "area": "Gulshan-e-Iqbal, Karachi",
        "role": "worker",
        "trades": ["plumbing", "masonry"],
        "wallet": [
            ("topUp", 1800, 500),
        ],
        "works": True,
        "wins": 3,
        "loses": 3,
        "live_bids": 1,
    },
    # Almost new. One job finished, the Rs. 500 first-job credit still visible
    # in the ledger, and a balance close to nothing.
    "user-017": {
        "name": "Shahid Siddiqui",
        "area": "Saddar, Peshawar",
        "role": "worker",
        "trades": ["driving"],
        "wallet": [
            ("topUp", 700, 96),
        ],
        "works": True,
        "wins": 1,
        "loses": 2,
        "live_bids": 1,
    },
    # The generalist. Most trades of anybody, so the feed she sees is the
    # widest one in the demo.
    "user-001": {
        "name": "Sadia Iqbal",
        "area": "Sheikh Maltoon, Mardan",
        "role": "worker",
        "trades": ["cleaning", "cooking", "tailoring", "gardening"],
        "wallet": [
            ("topUp", 4000, 700),
            ("topUp", 2500, 300),
        ],
        "works": True,
        "wins": 4,
        "loses": 3,
        "live_bids": 2,
    },
}

# What a worker types alongside a number, when they type anything at all. Kept
# short and plain: a bid is a price, and the message is the thing a worker who
# does not write comfortably is free to leave out.
BID_MESSAGES = [
    None, None, None,
    "Can come today.",
    "I have the tools with me.",
    "Free after 2pm.",
    "Done this many times.",
    "Can bring my own material.",
    "Live nearby, can be there in 20 minutes.",
    "Price includes the parts.",
    "Tomorrow morning suits me better.",
]

RATING_NOTES = [
    None, None, None, None,
    "Arrived on time.",
    "Good work, cleaned up after.",
    "Took longer than agreed.",
    "Polite and quick.",
    "Had to be called twice.",
]

# 5% of the agreed fare, rounded down — the same rule WalletRules applies.
COMMISSION_PERCENT = 5
FIRST_JOB_CREDIT = 500


def commission_on(fare: int) -> int:
    return fare * COMMISSION_PERCENT // 100


def add_history(jobs, people):
    """Give the jobs a past: offers, choices, finishes, ratings and wallets."""
    rng = random.Random(HISTORY_SEED)

    by_id = {job["id"]: job for job in jobs}
    person_ids = [person["id"] for person in people]

    bids = []
    ratings = []
    completions = []
    counters = {"bid": 0, "rating": 0, "entry": 0}

    def next_id(kind: str) -> str:
        counters[kind] += 1
        return f"{kind}-{counters[kind]:04d}"

    def can_reach(person_id, job) -> bool:
        """Whether Section 8 would ever have put this job in front of them.

        Only the personas have a stored trade list, so only they can be wrong
        about this — but they are the five people anybody demonstrating the app
        actually looks at, and an electrician holding an offer on a bricklaying
        job contradicts the rule the whole of Section 8 rests on.
        """
        persona = PERSONAS.get(person_id)
        if persona is None:
            return True
        if not persona["works"]:
            return False

        return bool({*persona["trades"], "misc"}.intersection(job["tags"]))

    def other_than(job, *excluded):
        """Somebody who could have seen this job, and is not already on it."""
        for _ in range(200):
            candidate = rng.choice(person_ids)
            if candidate in excluded:
                continue
            if not can_reach(candidate, job):
                continue
            return candidate

        # Every draw was a persona who cannot reach it, which needs 200 unlucky
        # rolls out of sixty people. Fall back to somebody with no trade list,
        # who is therefore never wrong about this.
        return next(
            person for person in person_ids
            if person not in excluded and person not in PERSONAS
        )

    def bid_fare(job) -> int:
        """A counter-offer. Section 4 makes the starting fare a starting point,
        so bids land either side of it — and a job posted without one still
        gets offers, because that is the case the hirer most needs help with."""
        base = job.get("startingFare") or rng.choice([1500, 2500, 4000, 8000])
        return round_fare(base * rng.uniform(0.75, 1.35))

    def place_bid(job, worker, status, hours_ago):
        bid = {
            "id": next_id("bid"),
            "jobId": job["id"],
            "workerId": worker,
            "fare": bid_fare(job),
            "hoursAgo": round(hours_ago, 1),
            "status": status,
        }
        message = rng.choice(BID_MESSAGES)
        if message:
            bid["message"] = message
        bids.append(bid)
        return bid

    def finish(job, worker, *, status, hours_ago):
        """Put a worker on a job and take it to `status`.

        The accepted bid's fare becomes the agreed fare, because Section 4 says
        acceptance is what fixes the price — a job whose agreed fare disagreed
        with the bid behind it would be a demo of a bug.
        """
        posted = job["createdHoursAgo"]
        chosen = place_bid(job, worker, "accepted", rng.uniform(hours_ago, posted))

        for _ in range(rng.randint(0, 3)):
            place_bid(
                job,
                other_than(job, job["postedBy"], worker),
                "passedOver",
                rng.uniform(hours_ago, posted),
            )

        job["status"] = status
        job["acceptedWorkerId"] = worker
        job["agreedFare"] = chosen["fare"]

        # Recorded here rather than at each call site, so a worker is charged
        # for **every** job they finished — including one they did for another
        # demo account. Building the ledger from a single list is what stops
        # the wallet and the job list disagreeing about how much work somebody
        # has done.
        if status == "completed":
            completions.append({
                "worker": worker,
                "jobId": job["id"],
                "fare": chosen["fare"],
                "hoursAgo": hours_ago,
            })

        return chosen

    def rate(job, side, hours_ago):
        rating = {
            "id": next_id("rating"),
            "jobId": job["id"],
            "side": side,
            # Skewed high, and never uniformly: most work is fine, and a demo
            # where every worker averages three stars would say the platform is
            # full of bad tradesmen.
            "stars": weighted(rng, [(5, 52), (4, 28), (3, 12), (2, 5), (1, 3)]),
            "hoursAgo": round(hours_ago, 1),
        }
        note = rng.choice(RATING_NOTES)
        if note:
            rating["note"] = note
        ratings.append(rating)

    # --- The personas, first, so they get the jobs they need ---------------
    #
    # Claimed here and removed from the pool below, so a persona's history is
    # never at the mercy of what the random pass happened to leave over.
    open_jobs = [job for job in jobs if job["postedBy"] not in PERSONAS]
    rng.shuffle(open_jobs)
    taken = set()

    def claim(trades=None):
        """Take a job out of the pool for a persona's history.

        `trades` restricts it to work the tag rule would actually have shown
        that worker — general work, plus whatever they have opted into. A
        demonstration where an electrician has an offer on a bricklaying job
        contradicts the rule the whole of Section 8 rests on, and it is the
        kind of detail somebody looking closely at the demo notices first.
        """
        reachable = None if trades is None else {*trades, "misc"}

        for index in range(len(open_jobs) - 1, -1, -1):
            job = open_jobs[index]
            if job["id"] in taken:
                continue
            if reachable is not None and not reachable.intersection(job["tags"]):
                continue

            open_jobs.pop(index)
            taken.add(job["id"])
            return job

        raise RuntimeError("ran out of jobs to give the personas a history")

    for person_id, persona in PERSONAS.items():
        if persona["works"]:
            # Jobs this persona did.
            for _ in range(persona["wins"]):
                job = claim(persona["trades"])
                done_at = rng.uniform(2, job["createdHoursAgo"] * 0.6)
                finish(job, person_id, status="completed", hours_ago=done_at)
                rate(job, "worker", done_at * 0.8)
                # Not every hirer bothers, and not every worker rates back.
                if rng.random() < 0.65:
                    rate(job, "hirer", done_at * 0.7)

            # Offers that went nowhere. The demo needs these: a worker's own
            # list is mostly the jobs they did not get, and until now that
            # state existed only in the tests.
            for _ in range(persona["loses"]):
                job = claim(persona["trades"])
                winner = other_than(job, job["postedBy"], person_id)
                finish(
                    job,
                    winner,
                    status=rng.choice(["completed", "inProgress", "accepted"]),
                    hours_ago=rng.uniform(2, job["createdHoursAgo"] * 0.5),
                )
                place_bid(
                    job,
                    person_id,
                    "passedOver",
                    rng.uniform(1, job["createdHoursAgo"]),
                )

            # And offers still waiting on somebody's answer.
            for _ in range(persona["live_bids"]):
                job = claim(persona["trades"])
                place_bid(
                    job,
                    person_id,
                    "offered",
                    rng.uniform(0.5, job["createdHoursAgo"]),
                )
                for _ in range(rng.randint(0, 2)):
                    place_bid(
                        job,
                        other_than(job, job["postedBy"], person_id),
                        "offered",
                        rng.uniform(0.5, job["createdHoursAgo"]),
                    )

    # --- The demo accounts' own postings -----------------------------------
    #
    # Every persona posts as well as works, and their postings were the one
    # thing the random pass never touched — it draws from jobs posted by
    # *other* people, so switching to a demo account and opening "Posted"
    # showed a handful of bare open jobs with nothing to decide. The hirer's
    # side of Mode A was therefore unreachable from four of the five accounts.
    #
    # So each of them gets the same four states by hand, in this order, which
    # is what somebody demonstrating the hirer's side needs to be able to
    # point at: something to choose between, something finished and rated,
    # something under way, and something called off.
    def persona_for(job, exclude):
        """A demo account who could have seen this job, if any."""
        for person_id, persona in PERSONAS.items():
            if person_id == exclude or not persona["works"]:
                continue
            if can_reach(person_id, job):
                return person_id
        return other_than(job, exclude)

    def offers_on(job, count):
        for _ in range(count):
            place_bid(
                job,
                other_than(job, job["postedBy"]),
                "offered",
                rng.uniform(0.5, job["createdHoursAgo"]),
            )

    for person_id in PERSONAS:
        mine = [job for job in jobs if job["postedBy"] == person_id]
        if not mine:
            continue

        # Open, with a choice to make. Always first, because it is the screen
        # the hirer's side is really about.
        offers_on(mine[0], rng.randint(2, 4))

        if len(mine) > 1:
            # Finished, and rated in both directions — so the persona's own
            # record as a hirer exists too, not only their workers'.
            job = mine[1]
            done_at = job["createdHoursAgo"] * 0.4
            finish(
                job,
                persona_for(job, person_id),
                status="completed",
                hours_ago=done_at,
            )
            rate(job, "worker", done_at * 0.8)
            rate(job, "hirer", done_at * 0.7)

        if len(mine) > 2:
            # Under way, with the offers that lost sitting behind it.
            job = mine[2]
            finish(
                job,
                persona_for(job, person_id),
                status=rng.choice(["inProgress", "accepted"]),
                hours_ago=job["createdHoursAgo"] * 0.5,
            )

        if len(mine) > 3:
            # Called off. Rare, and the one state with nothing to do next.
            mine[3]["status"] = "cancelled"

    # --- Everybody else ----------------------------------------------------
    #
    # Enough of the rest of the map has a past that a hirer's offer list and a
    # worker's record are populated wherever you look, rather than only around
    # the five people in the switcher.
    for job in open_jobs:
        roll = rng.random()

        if roll < 0.22:
            worker = other_than(job, job["postedBy"])
            done_at = rng.uniform(1, max(2, job["createdHoursAgo"] * 0.6))
            finish(job, worker, status="completed", hours_ago=done_at)
            if rng.random() < 0.7:
                rate(job, "worker", done_at * 0.8)
            if rng.random() < 0.4:
                rate(job, "hirer", done_at * 0.7)
        elif roll < 0.30:
            finish(
                job,
                other_than(job, job["postedBy"]),
                status=rng.choice(["accepted", "inProgress"]),
                hours_ago=rng.uniform(1, max(2, job["createdHoursAgo"] * 0.5)),
            )
        elif roll < 0.34:
            job["status"] = "cancelled"
        else:
            # Still open. Most of these have somebody waiting on an answer,
            # which is what makes the hirer's side worth looking at.
            for _ in range(weighted(rng, [(0, 30), (1, 25), (2, 22), (3, 15), (4, 8)])):
                place_bid(
                    job,
                    other_than(job, job["postedBy"]),
                    "offered",
                    rng.uniform(0.2, job["createdHoursAgo"]),
                )

    # --- The ledgers -------------------------------------------------------
    #
    # Built last, from every completion in the run, so a persona is charged for
    # all the work they did rather than for the subset one loop happened to
    # create. Section 11's rules are applied in order — oldest first — because
    # the first-job credit and the debt count both depend on the sequence.
    accounts = []

    for person_id, persona in PERSONAS.items():
        entries = [
            {
                "id": next_id("entry"),
                "kind": kind,
                "tokens": tokens,
                "hoursAgo": hours,
            }
            for kind, tokens, hours in persona["wallet"]
        ]

        theirs = sorted(
            (done for done in completions if done["worker"] == person_id),
            key=lambda done: -done["hoursAgo"],
        )

        for index, done in enumerate(theirs):
            charge = commission_on(done["fare"])
            if charge <= 0:
                continue

            if index == 0:
                # Section 11's first-job credit, capped at what is owed.
                entries.append({
                    "id": next_id("entry"),
                    "kind": "firstJobCredit",
                    "tokens": min(FIRST_JOB_CREDIT, charge),
                    "hoursAgo": round(done["hoursAgo"], 1),
                    "jobId": done["jobId"],
                })

            entries.append({
                "id": next_id("entry"),
                "kind": "commission",
                "tokens": -charge,
                "hoursAgo": round(done["hoursAgo"], 1),
                "jobId": done["jobId"],
            })

        accounts.append({
            "id": person_id,
            "role": persona["role"],
            "trades": persona["trades"],
            "wallet": sorted(entries, key=lambda e: -e["hoursAgo"]),
        })

    bids.sort(key=lambda bid: -bid["hoursAgo"])
    ratings.sort(key=lambda rating: -rating["hoursAgo"])

    return bids, ratings, accounts


def balance_of(entries) -> int:
    return sum(entry["tokens"] for entry in entries)


# ---------------------------------------------------------------------------
# The directory (Mode B)
#
# Section 9's second discovery mode needs people in it or the screen is an
# empty state with a subscription pitch underneath. These are professionals
# rather than tradesmen — the spec names doctors, lawyers, consultants,
# barbers, MUAs and coaches — offering fixed prices instead of taking bids.
#
# One of them is deliberately **lapsed**: their listing is gone from the
# directory but still theirs to renew, which is the whole of the spec's lapse
# handling and is otherwise a state nobody can reach without waiting a month.
# ---------------------------------------------------------------------------
DIRECTORY = [
    # id, tag, headline, radius km (0 = remote only), [(title, price, note)],
    # [(kind, credential, issuer, year)], days of subscription left
    ("user-001", "cleaning", "Home and office cleaning, two-person team", 12, [
        ("Whole-house clean", 4500, "Three rooms, kitchen and bathrooms."),
        ("Kitchen deep clean", 2500, None),
        ("Sofa and carpet shampoo", 3500, "Per room."),
    ], [
        ("experience", "Nine years cleaning homes and offices", None, None),
    ], 240),
    ("user-004", "legal", "Property and family matters", 0, [
        ("First consultation", 1500, "Half an hour, by phone or in person."),
        ("Property paper check", 6000, "Sale deed, mutation and encumbrance."),
        ("Rent agreement drafting", 4000, None),
    ], [
        ("qualification", "LLB", "University of the Punjab", 2014),
        ("membership", "Punjab Bar Council", None, 2015),
    ], 300),
    ("user-008", "beauty", "Bridal and party makeup, home visits", 15, [
        ("Bridal makeup", 25000, "Includes trial and hair."),
        ("Party makeup", 6000, None),
        ("Home haircut", 1200, None),
    ], [
        ("certification", "Advanced bridal makeup", "Depilex", 2019),
        ("experience", "Six years, over 200 brides", None, None),
    ], 95),
    ("user-011", "medical", "GP, home visits in the evening", 8, [
        ("Home visit", 3000, "Evenings and weekends."),
        ("Follow-up visit", 1500, None),
    ], [
        ("qualification", "MBBS", "King Edward Medical University", 2012),
        ("membership", "PMDC registered", None, 2013),
    ], 180),
    ("user-013", "tutoring", "Matric and FSc maths and physics", 6, [
        ("One hour, at your home", 1500, None),
        ("Monthly, three days a week", 15000, "Twelve sessions."),
        ("Online session", 1000, "One hour."),
    ], [
        ("qualification", "MSc Physics", "Punjab University", 2017),
        ("experience", "Seven years teaching Matric and FSc", None, None),
    ], 60),
    ("user-020", "electrical", "Licensed electrician, wiring and generators", 20, [
        ("Call-out and diagnosis", 1500, "Deducted from the repair if you go ahead."),
        ("Full house rewiring survey", 5000, None),
        ("Generator service", 4500, None),
    ], [
        ("certification", "Electrical wiring", "TEVTA", 2016),
    ], 150),
    ("user-026", "tailoring", "Ladies' stitching, measured at your home", 10, [
        ("Shalwar kameez, stitched", 2500, None),
        ("Bridal outfit", 18000, "Two fittings included."),
        ("Alterations", 800, "Per garment."),
    ], [
        ("experience", "Fifteen years stitching", None, None),
    ], 400),
    ("user-031", "security", "Night guard, ex-services", 25, [
        ("Night shift, per night", 2500, "Twelve hours, 8pm to 8am."),
        ("Monthly, six nights a week", 55000, None),
    ], [
        ("experience", "Twelve years, Pakistan Army", None, None),
    ], 30),
    ("user-036", "cooking", "Home cook, daily meals for families", 7, [
        ("Daily cooking, monthly", 25000, "Two meals a day, six days a week."),
        ("Dinner party, up to ten people", 12000, None),
    ], [
        ("experience", "Eleven years cooking for families", None, None),
    ], 210),
    # Lapsed a fortnight ago. Still theirs, gone from the directory.
    ("user-017", "driving", "Airport runs and out-of-city trips", 30, [
        ("Airport drop", 2500, "Any time, own car."),
        ("Full day with car", 9000, "Within the city."),
    ], [
        ("experience", "Eight years driving, clean licence", None, None),
    ], -14),
]


def build_directory():
    """The Mode B listings, as `assets/seed/directory.json`.

    Times are relative like everything else in the seed — a subscription
    expiring on a date the demo was packaged would show every listing as
    lapsed a month later.
    """
    listings = []

    for index, entry in enumerate(DIRECTORY, start=1):
        worker, tag, headline, radius_km, services, credentials, days = entry

        listings.append({
            "workerId": worker,
            "headline": headline,
            "remoteOnly": radius_km == 0,
            "serviceRadiusMetres": (radius_km or 10) * 1000,
            "subscription": {
                "plan": "yearly" if days > 120 else "monthly",
                # Backdated far enough that the end date is the interesting
                # part; the app only ever asks whether it is live now.
                "startedDaysAgo": 365 if days > 120 else 30,
                "endsInDays": days,
            },
            "services": [
                {
                    "id": f"svc-{index:02d}-{position}",
                    "tag": tag,
                    "title": title,
                    "priceRupees": price,
                    **({"description": note} if note else {}),
                }
                for position, (title, price, note) in enumerate(services, 1)
            ],
            "credentials": [
                {
                    "id": f"cred-{index:02d}-{position}",
                    "kind": kind,
                    "title": title,
                    **({"issuer": issuer} if issuer else {}),
                    **({"year": year} if year else {}),
                }
                for position, (kind, title, issuer, year)
                in enumerate(credentials, 1)
            ],
        })

    return listings


# ---------------------------------------------------------------------------
# Admin (Section 12)
#
# The panel needs a queue to work through, a dispute to justify opening a
# CNIC, and enough decided accounts that the list is not one card. The audit
# log is deliberately **empty** — it is a record of what staff did, and seeding
# it with actions nobody took would be the one place in the demo where the data
# is a lie about a person.
# ---------------------------------------------------------------------------
ADMIN_SEED_SEED = 20260815

# What the accounts an admin looks at look like. Only a slice of the sixty
# seeded people: the rest are approved and uninteresting, and a review queue of
# sixty is a screenshot rather than a workflow.
REVIEW_SAMPLE = 22


def verification_for(name, rng):
    """One submission, as both files describe it.

    Built in one place so a review and the CNIC beside it cannot disagree
    about what was submitted or when.
    """
    submitted_days_ago = rng.randint(20, 400)

    return {
        # Masked, because that is all the app ever holds. The whole number is
        # not generated at all — there is nothing here to leak.
        "cnicMasked": f"*****-*****{rng.randint(10, 99)}-{rng.randint(1, 9)}",
        "cnicName": name,
        "cnicDaysAgo": submitted_days_ago,
        # The same fictional-number convention the job contacts use.
        "phone": f"+92{rng.choice(MOBILE_PREFIXES)[1:]}"
                 f"{rng.randint(1000000, 9999999)}",
        # Confirmed after the card was submitted, never before: a "confirmed"
        # date older than the account is the sort of detail that makes a demo
        # look generated.
        "phoneDaysAgo": rng.randint(1, max(1, submitted_days_ago - 1)),
    }


def build_admin(people, jobs, rng=None):
    """Approval records, a couple of CNICs, and two live disputes."""
    rng = rng or random.Random(ADMIN_SEED_SEED)

    reviews = []
    cnics = []

    sample = people[:REVIEW_SAMPLE]

    for index, person in enumerate(sample):
        # A handful still waiting, one of them flagged, and the rest already
        # approved — the shape of a queue somebody keeps on top of.
        pending = index < 6
        flagged = index in (1, 4)
        has_cnic = index != 3
        phone_ok = index not in (3, 9)

        record = verification_for(person["name"], rng)
        masked = record["cnicMasked"]
        submitted_days_ago = record["cnicDaysAgo"]

        reviews.append({
            "userId": person["id"],
            "status": "pending" if pending else (
                "suspended" if index == 7 else "approved"
            ),
            "cnicOnFile": has_cnic,
            # The automated shape check from Section 2. Fails for one person,
            # which is a typo rather than a fraud.
            "cnicPlausible": has_cnic and index != 5,
            "phoneVerified": phone_ok,
            "simNameMatches": not flagged,
            # The verification record proper, which is what the worker's own
            # screen reads. Same row as the panel's — see `AccountReview`.
            **({"cnicMasked": record["cnicMasked"],
                "cnicName": record["cnicName"],
                "cnicDaysAgo": record["cnicDaysAgo"]} if has_cnic else {}),
            **({"phone": record["phone"],
                "phoneDaysAgo": record["phoneDaysAgo"]} if phone_ok else {}),
            **({"note": "Repeated no-shows reported by hirers."}
               if index == 7 else {}),
        })

        if has_cnic:
            cnics.append({
                "userId": person["id"],
                # Masked in storage. The app has no use for a full national
                # identity number and Section 13 rules out looking one up.
                "maskedNumber": masked,
                "nameOnCard": person["name"],
                "submittedDaysAgo": submitted_days_ago,
            })

    # Two disputes, both open, both about somebody in the sample — so the CNIC
    # button is enabled for exactly two people and disabled for everybody else,
    # which is the rule made visible.
    finished = [job for job in jobs if job.get("status") == "completed"
                and job.get("acceptedWorkerId")]
    rng.shuffle(finished)

    disputes = []
    reasons = [
        "Worker did not turn up on the agreed day and stopped answering.",
        "Hirer refused to pay the agreed fare after the work was finished.",
    ]

    for offset, reason in enumerate(reasons):
        if offset >= len(finished):
            break
        job = finished[offset]

        # The first is about the worker, the second about the hirer — both
        # sides can be complained about, and Section 10 collects the hirer
        # ratings precisely because hirers cause trouble too.
        about = job["acceptedWorkerId"] if offset == 0 else job["postedBy"]
        raised_by = job["postedBy"] if offset == 0 else job["acceptedWorkerId"]

        disputes.append({
            "id": f"dispute-{offset + 1:02d}",
            "jobId": job["id"],
            "aboutUserId": about,
            "raisedByUserId": raised_by,
            "raisedHoursAgo": round(rng.uniform(2, 60), 1),
            "reason": reason,
        })

        # A dispute is worthless without a document behind it, so make sure
        # the person complained about has one on file.
        #
        # **Both files or neither.** These are two views of one submission —
        # the panel's and the worker's own screen's — and a review claiming a
        # CNIC that the CNIC file does not carry is a demonstration of a bug.
        # They were written separately once, and drifted immediately.
        has_review = any(r["userId"] == about for r in reviews)
        has_cnic_record = any(c["userId"] == about for c in cnics)

        if not has_review or not has_cnic_record:
            named = next(
                (p["name"] for p in people if p["id"] == about), "Unknown"
            )
            record = verification_for(named, rng)

            if not has_cnic_record:
                cnics.append({
                    "userId": about,
                    "maskedNumber": record["cnicMasked"],
                    "nameOnCard": named,
                    "submittedDaysAgo": record["cnicDaysAgo"],
                })
            if not has_review:
                reviews.append({
                    "userId": about,
                    "status": "approved",
                    "cnicOnFile": True,
                    "cnicPlausible": True,
                    "phoneVerified": True,
                    "simNameMatches": True,
                    **record,
                })

    return reviews, cnics, disputes


def main() -> None:
    jobs, people = build()
    bids, ratings, accounts = add_history(jobs, people)
    listings = build_directory()
    reviews, cnics, disputes = build_admin(people, jobs)

    SEED_DIR.mkdir(parents=True, exist_ok=True)
    for name, payload in [
        ("jobs.json", jobs),
        ("users.json", people),
        ("bids.json", bids),
        ("ratings.json", ratings),
        ("accounts.json", accounts),
        ("directory.json", listings),
        ("reviews.json", reviews),
        ("cnics.json", cnics),
        ("disputes.json", disputes),
    ]:
        (SEED_DIR / name).write_text(
            json.dumps(payload, ensure_ascii=False, indent=2) + "\n"
        )

    cities = {}
    statuses = {}
    for job in jobs:
        cities[job["city"]] = cities.get(job["city"], 0) + 1
        state = job.get("status", "open")
        statuses[state] = statuses.get(state, 0) + 1

    print(f"{len(jobs)} jobs, {len(people)} people, {len(cities)} cities")
    print(f"{len(bids)} bids, {len(ratings)} ratings, {len(accounts)} accounts")
    waiting = sum(1 for r in reviews if r["status"] == "pending")
    print(f"{len(reviews)} account reviews ({waiting} waiting), "
          f"{len(cnics)} CNICs, {len(disputes)} disputes")
    live = sum(1 for l in listings if l["subscription"]["endsInDays"] > 0)
    print(f"{len(listings)} directory listings ({live} live, "
          f"{len(listings) - live} lapsed)")
    print("  jobs by status: " + ", ".join(
        f"{count} {state}" for state, count in sorted(statuses.items())
    ))
    for account in accounts:
        print(
            f"  {account['id']}  {account['role']:<6} "
            f"{len(account['trades'])} trades  "
            f"Rs. {balance_of(account['wallet'])}"
        )


if __name__ == "__main__":
    main()
