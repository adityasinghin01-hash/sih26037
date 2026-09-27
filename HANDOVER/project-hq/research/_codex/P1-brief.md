PHASE P1 - THE INDIAN ROAD DIFFICULTY CATALOGUE. This becomes the requirement list for a full
self-driving system for Indian roads (simulation first). Goal: cover EVERY hard situation a car
faces in India, not just the PS's five scenarios.

My findings so far (verified by me from MoRTH "Road Accidents in India 2023",
https://morth.gov.in/backend/documents/uploaded/Road-Accident-in-India-2023-Publications.pdf):
- 4,80,583 accidents, 1,72,890 deaths in 2023. Two-wheeler riders 44.8% of deaths, pedestrians 20.4%.
- Overspeeding 68.1% of deaths; wrong-side driving 5.5% (3rd highest violation).
- Collision types (accidents share): hit from back 23%, head-on 18%, hit from side 15%, hit & run 14%,
  run off road 4%, overturn 4%, parked vehicle 3%.
- Junction accidents 2023: T 40,440; four-arm 23,171; Y 16,417; staggered 15,457; roundabout 13,182.
  Uncontrolled junctions ~15.9% of all accidents.
- Road features: curves 58,626 accidents; potholes 5,840 accidents / 2,161 deaths; culverts 10,308;
  road works 9,425; steep grade 5,094.
- Weather: rainy 37,316; foggy/misty 34,266 accidents. Time: 18:00-21:00 highest (20.8%).
- Pedestrians killed: 35,203; top crime vehicles two-wheelers 28.2%, cars/LMV 24.7%.
- Two-wheeler "seepage" gap in dense Indian traffic: mean 0.906 m (ScienceDirect 2026,
  S1389128626005220) - UNVERIFIED by me beyond the search snippet; please confirm.
- Stray cattle: Haryana Assembly (Aug 2022) 3,383 stray-cattle accidents, 919 killed in 5 years.

YOUR JOB: build the full catalogue. Aim for 60+ distinct difficulty items grouped into families:
(A) other road users' behaviour (cut-ins, lane-splitting two-wheelers, wrong-way riders, sudden
braking, U-turns across traffic, overloaded vehicles, autos stopping anywhere, buses pulling
out, tractor-trolleys, pushcarts, cycle-rickshaws, animal-drawn carts, convoys, VIP/ambulance...)
(B) pedestrians (jaywalking, hand-raise to stop traffic, children, crowds, vendors on road,
processions/baraat...) (C) animals (cattle standing/lying/herds, dogs, monkeys, buffalo...)
(D) road geometry/surface (no markings, potholes, speed breakers unmarked, broken edges, drop-offs,
unpaved, waterlogging, construction diversions, narrow gallis, ghats/hairpins, level crossings,
median gaps, service roads...) (E) junctions/rules (unsignalled, roundabouts, informal right of
way, police hand signals, signal jumping, informal merging...) (F) communication (horn, headlight
flash, hand signals from drivers/riders, indicator misuse) (G) environment (rain, fog, dust,
night with no streetlights, glare, high-beam from oncoming, monsoon floods) (H) sensor/perception
traps (occlusion by buses, reflective surfaces, dense crowds, unusual vehicles, jugaad vehicles,
poor/absent signage, Devanagari/regional signs) (I) edge/rare events (animal sudden dash, tyre
burst ahead, falling load, landslide, tree fall, protests/road blocks).
For EACH item give: 1-line description; evidence (a number + working source URL, or
"common knowledge - UNVERIFIED"); severity (high/med/low) and frequency (high/med/low) with
reasoning; which system layer must handle it (perception / prediction / planning / safety /
control / HMI-communication); what the SIMULATION must model to test it.
Also: find any existing formal taxonomy/ODD catalogue for Indian roads (e.g. ARAI, TiHAN, IIT
papers, SAE J3016 ODD, BSI PAS 1883, ASAM OpenODD) and cite it.
Be concise (table form). Flag everything you cannot verify. I will check every source.
