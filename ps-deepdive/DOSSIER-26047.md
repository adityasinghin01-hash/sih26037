# DOSSIER 2 — SIH26047
## Patient Case-Taking Software ("MediKiosk")
**Ministry of Ayush · dept: All India Institute of Ayurveda (AIIA) · Software · Theme: MedTech / BioTech / HealthTech**

Research date 27–28 Aug 2026. Written for the KIET team of 6.
Companion: `DOSSIER-26037.md`. Official PS text: `SIH26047-official-text.md`.

> **Read this first.** This dossier corrects two claims I made in the earlier comparison. Both were
> wrong in the same direction — they overstated 26047's novelty. See §2 and §7. Per
> `scoring-honesty-rule`, novelty is scored last, after the sweep, and the sweep went badly.

---

# 1. THE PS, DECODED

Unusually, the ministry has already designed the product. It is named ("MediKiosk") and specified
as four modules. This matters more than it looks: **there is very little room for our own idea, and
every competing team will build the same four modules.**

| Module | What it does |
|---|---|
| **A — Conversational history engine** | Voice + touch clinical interview in Indian languages. Adaptive follow-ups (the PS names the **SOCRATES** framework for pain history). Red-flag detection for emergencies → priority triage. **AYUSH mode capturing Dashavidha Pariksha** (Prakriti, Vikriti, Sara, Samhanana, Pramana, Satmya, Sattva, Ahara Shakti, Vyayama Shakti, Vaya). |
| **B — Document digitisation** | OCR of handwritten + printed prescriptions, lab reports, discharge summaries, multilingual. Extract diagnoses, medicines with dosages, investigation values. Chronological timeline. Abnormal-value and drug-interaction flags. |
| **C — Summary generator** | Physician-ready structured summary (Chief complaint → HPI → past medical/surgical → drug & allergy → family → personal → ROS → prior investigations), on screen before the patient enters. Editable, never autonomous diagnosis. Bilingual. |
| **D — Consent, privacy, ABDM** | DPDP Act 2023 + ABDM consent framework. ABHA authentication, FHIR push to hospital HIS, session data cleared after submission, audio-guided consent for low-literacy patients. |

**The problem framing, which is genuinely excellent and not ours to defend:**
- **BMJ Open 2017**, 67-country study — India's average primary-care consultation is **just over 2 minutes**, among the shortest in the world.
- Tertiary government hospitals register **4,000–10,000 OPD patients/day**.
- Classical teaching: a well-conducted history yields the correct diagnosis in **70–80% of cases**.
- Ayurvedic intake (Trividha, Ashtavidha, Dashavidha Pariksha) is *far more* extensive than
  allopathic intake — so the time squeeze is worse at an AYUSH hospital, not better.

**Judged by:** Ministry of Ayush via AIIA. Unlike MathWorks, this is a ministry PS — so the pitch,
the beneficiary story and the policy fit all carry weight alongside the build.

---

# 2. PAST SIH AYUSH PS AND WHO WON THEM — and the correction I owe you

## SIH 2025: "API to Bridge AYUSH NAMASTE and ICD-11 for EMR Compliance"
**Winners: Team Passengers (Islamic University of Science and Technology, CSE) and Code Vaidyas
(VIT Chennai), sharing ₹1.5 lakh.** Their solution lets EMR systems search and map traditional
medicine diagnoses (Ayurveda, Siddha, Unani) via NAMASTE codes and auto-link them to ICD-11 codes
for dual coding and interoperability.

**Public GitHub implementations of that exact PS now exist** — e.g. `the-mayankjha/AyushSyncAPI`
and `CodexRaunak/NAMASTE-ICD-11-Integration`.

> ### CORRECTION
> In the earlier comparison I recommended leading 26047 with "the Dashavidha Pariksha + NAMASTE
> angle, which no competitor has." **That was wrong.** The NAMASTE ↔ ICD-11 TM2 dual-coding piece
> was a Smart India Hackathon problem statement *last year*, it was won by two teams, and there is
> open-source code for it on GitHub. It is not a moat. It is a solved SIH problem with published
> solutions, and any judge who followed SIH 2025 will recognise it instantly.

## SIH 2024 Ayush problem statements (hosted at IIT Tirupati, 22 teams, 36 hours)
| Team | What they built |
|---|---|
| Kode Crafts | Secure portal for AYUSH startup registrations |
| Sahvrindam, Carbon Daters | Innovation-tracking systems for AYUSH institutions |
| Stack Squad | Virtual herbal garden / medicinal plants education platform |
| Pragati Mitra | Automated annual report portal |

**The pattern across Ayush PS history:** they are overwhelmingly **portal and administrative
software**, won with clean full-stack CRUD work. SIH26047 is a far heavier technical ask than
anything the Ayush ministry has previously set — multimodal ASR, handwritten OCR, clinical
summarisation, FHIR integration. That is a double-edged finding: **less precedent to be compared
against, but also a ministry whose evaluators may be calibrated on portals, not on ML systems.**

---

# 3. THE SAME PROBLEM AT OTHER HACKATHONS

ABDM-adjacent hackathons are now a genre of their own, run by the National Health Authority:
- **ABDM Hackathon Series** — first edition in Pune
- **NHCX Hackathon** (National Health Claims Exchange), winners showcased at **IIT Hyderabad,
  March 2026**
- **AB PM-JAY Auto-Adjudication Hackathon**, with the **IndiaAI Mission and IISc Bengaluru** — an
  explicit call for *India-specific AI models* in healthcare

**What this tells us:** the ABDM/FHIR integration layer is a well-trodden hackathon surface in
India. Building "we connected to ABHA and pushed FHIR" will not read as novel to anyone who has
watched this space — it is the assumed baseline, not the contribution.

---

# 4 & 5. COMPETITOR CHECK — the section that decides this PS

## The big one: Google AMIE, published in *Nature*
**"Towards conversational diagnostic artificial intelligence," Nature, June 2025.**
AMIE (Articulate Medical Intelligence Explorer) is an LLM optimised for diagnostic dialogue,
trained via self-play in a simulated environment. In a randomised, double-blind crossover study
with patient-actors, **AMIE outperformed primary care physicians** across the evaluated axes —
**including history-taking**, diagnostic accuracy, management, communication and empathy.

Follow-ups: a **multimodal** AMIE (Nature Medicine) and an AMIE for **disease management**
(Nature, 2026).

**Why this is the hardest fact in this dossier.** The core of Module A is "an AI conducts an
adaptive clinical history interview." Google has published, in Nature, that an LLM does that better
than doctors. This is the `india-idea-viability-filters` ChatGPT test failing at the top of the
stack — not a hypothetical frontier-model risk, a peer-reviewed, named, citable one.

Fair counterweight, stated honestly: AMIE is a **research system**, not deployed; it is text/English
oriented; it does not do Hindi-and-regional-language kiosk interaction with low-literacy patients;
it does not read handwritten Indian prescriptions; it has no ABDM integration. So AMIE does not
*build our product*. But it does mean the interview itself cannot be our claimed innovation.

## Already deployed in an Indian government hospital
**PGI Chandigarh AI kiosk.** Patients select Punjabi, Hindi or English, answer spoken questions;
the system generates a **13-digit ID** and the patient's **medical and personal history as a QR
code the doctor scans** to prescribe. Staff can pass the medical-summary QR between shifts.
PGIMER is separately rolling out a **C-DAC-built mobile app** with QR patient ID, digital queue
tokens, indoor navigation and multilingual support, piloting in the Nehru Hospital OPD.

**This is Modules A + C, running, in exactly our target setting.**

## The rest of the field
| Who | What | Scale |
|---|---|---|
| **ZINI** (Delhi, f. 2017, Dr Rohit Sharma) | Explicitly a **"history-taking bot"**, built on Indian population data, regional languages (Punjabi, Hindi), plus OPD management system, medical API, "5-minute clinic" | STPI ₹25 lakh NGIS grant 2021; Startup Punjab seed 2021; Pre-Series A 2022 (Solarus Group) |
| **Infermedica Intake** | Pre-visit history, allergies, medications; triage + probable conditions; EHR integration | Published outcome: **visit time 20 min → 12.5 min** |
| **Ada Health** | Intelligent care navigation | **60M+ users**, deployed at large health systems |
| **A-HMIS** (Ayush Grid) | Ayush HMIS with **double coding** (Ayush morbidity + ICD-10); **already ABDM-integrated** — creates ABHA, handles registration and follow-up | **126+ hospitals** under Research Councils and National Institutes |
| **ABDM Scan & Share** | QR-based instant OPD registration | **25 crore registrations**, 5,435 facilities, 546 districts (Aug 2026). Wait times ~1 hr → 2–5 min. NHA pays hospitals incentives per transaction |
| **HealthPlix H.A.L.O.** | Ambient AI listening during consultation, extracting clinical info | Commercial, Indian |
| **Xunfei Healthcare** | "Prediagnosis Medical History Taking System" | Commercial, China |

---

# 6. THE DATA — what works and what does not

| Asset | Status | Numbers |
|---|---|---|
| **AI4Bharat / IndicASR, IndicTTS** | ✅ **Free and open** | 22 languages, MIT / Apache-2.0 / CC-BY-4.0. Hindi WER **~12–18% clean, 22–30% telephony**. IndicTTS MOS 3.6–3.9 |
| **Bhashini** | ✅ Government model hub | Per-model licensing, often Apache-2.0 |
| **MIRAGE** (arXiv 2410.09729) | ⚠️ **Public release NOT confirmed** | 743,118 simulated annotated prescription images from **1,133 doctors across India**; fine-tuned Qwen-VL, LLaVA-1.6, Idefics2; **82% accuracy extracting medication names and dosages** |
| IEEE DataPort handwritten/printed Rx set | ✅ Available | 11,340 images after augmentation |
| **Prakriti200** (arXiv 2510.06262) | ✅ Public | 24-item questionnaire dataset, AYUSH/CCRAS-aligned |
| **NAMASTE / ICD-11 TM2** | ✅ Public | **1,941** Ayush morbidity codes mapped; TM2 live on WHO ICD-11 browser **Feb 2025** |
| **ABDM Sandbox** | ⚠️ **UNVERIFIED** | Live at `sandbox.abdm.gov.in` (301 → `/sandbox/v3`, HTTP 200). But `/applications/register` returned **HTTP 503**, and signup documents require **organisation details + internal approval, 3–4 days** |

**The two data problems, stated plainly:**
1. **82% is the published ceiling on the thing that matters most.** MIRAGE's 82% is for medication
   names and dosages — the single most safety-critical field in the whole system. And the dataset
   itself may not be downloadable, in which case we are training on the 11,340-image set instead of
   743k.
2. **ABDM access is the government-rail check, and it is unproven.** Per our standing rule, assume
   closed until proven open. A student team with no registered organisation may not clear approval
   inside our timeline.

---

# 7. NOVELTY SCAN — the honest verdict

I went looking for one unoccupied component. There isn't one.

| Component of the PS | Occupied by |
|---|---|
| Conversational adaptive history taking | **AMIE (Nature, outperforms PCPs)**, ZINI, Ada, Infermedica |
| Voice kiosk history in an Indian government hospital | **PGI Chandigarh — deployed** |
| Structured physician-ready summary | Infermedica, HealthPlix H.A.L.O., every ambient-scribe product |
| NAMASTE ↔ ICD-11 TM2 dual coding | **Won at SIH 2025 by two teams; open-source on GitHub** |
| Prakriti / Dashavidha assessment by ML | Saturated — **97–99% published accuracies**, Prakriti200 dataset, DoshaMitra, multiple ensemble papers |
| ABHA / registration / FHIR push | **Scan & Share (25 crore), A-HMIS (126+ hospitals)**, NHA hackathon series |
| Handwritten Indian prescription OCR | MIRAGE (82%), several published works |

**What remains genuinely unoccupied is the integration** — nobody has shipped all of it as one
kiosk flow. That is real, but it is **engineering, not novelty**, and `hackathon-master-criteria`
scores novelty separately for a reason.

## The two angles that could still be defended

**(a) Uncertainty-aware intake — "the system that knows when it misheard."**
Every system above assumes the transcript is correct. In a noisy Indian OPD at **22–30% WER**, it
frequently is not, and a confidently-wrong medical history is a safety event, not an inconvenience.
A system that *detects its own uncertainty* and escalates to touch input or a human — rather than
silently generating a plausible wrong history — is a real, unaddressed problem. Conformal
prediction applies here as cleanly as it does in 26037.
*Risk:* it is subtle, and hard to make legible to a judge in 60 seconds.

**(b) Ayurvedic depth as the moat.**
AMIE, Ada and Infermedica all do **allopathic** history. **None does Dashavidha Pariksha.** No
global player will ever build it — it is structurally Indian in exactly the sense
`india-idea-viability-filters` means. Note the distinction that matters: **Prakriti is only one of
the ten factors.** The saturated ML literature is on Prakriti classification; the full ten-fold
Dashavidha intake, captured conversationally, is much less worked.
*Risk:* it narrows the product to AYUSH OPDs, shrinking the impact story — and AIIA is ~1,500
patients/day, not the 4,000–10,000 the PS's own background invokes.

---

# 8. TARGET USER BASE

**Primary:** the **Ayurvedic physician at AIIA New Delhi**, ~1,500 OPD patients/day, who is expected
to perform a ten-fold Dashavidha Pariksha in a slot measured in single-digit minutes.
**Secondary:** the **126+ Ayush hospitals** already running A-HMIS under the Research Councils and
National Institutes — a real, countable installed base with an existing integration path.
**Tertiary:** the low-literacy, elderly, first-visit patient the PS names — the population that
smartphone-based tele-triage structurally excludes.

**The weakness we must own:** we have **no field access**. Nobody on the team has a medical or
Ayush contact, and we cannot reliably observe a real OPD before the internal hackathon. One of
Aditya's own stated aims for this exercise was *"a better understanding of the user base."* On this
PS we would be designing for a user we have never watched work. Doctor relatives can be consulted
after committing, but that is domain knowledge, not observation.

**And the metric problem, which is the Tenable failure returning:** the headline claim is
consultation time saved. Proving it needs a real OPD time-motion study we cannot run. Any number we
show would be self-generated — exactly what sank Tenable.

---

# 9. FEASIBILITY — and here 26047 is genuinely strong

| Factor | Assessment |
|---|---|
| **Stack fit** | ✅ **Much better than 26037.** Web frontend + Python backend + ML is precisely what this team already does. Aditya has backend/auth experience. No unfamiliar toolchain, no GUI 3D editor, no licence dependency. |
| **Vibecodeable** | ✅ React/Next + FastAPI + PyTorch is the best-supported stack for AI-assisted coding. The opposite of Simulink. |
| **Supercomputer use** | ✅ Fine-tuning a VLM (Qwen-VL / LLaVA) for prescription OCR is a legitimate 4–5 day training job and is the strongest technical differentiator available here. |
| **7-day build** | ⚠️ Four modules is a lot, **but it degrades gracefully** — a demo with A, B and C and a mocked D still demonstrates the idea. 26037 does not degrade like this; a broken simulation is just broken. |
| **ABDM sandbox** | ⚠️ Unverified. If refused, Module D becomes a mock and the FHIR claim becomes a slide, not a demo. |
| **Live demo risk** | ⚠️ A voice demo in a noisy 36-hour hackathon hall at 22–30% WER can fail in front of judges. Mitigate with a touch fallback path rehearsed in advance. |

---

# 10. SCORING

Method and blocking rule consistent with `FINAL-hard-verification.md`: simple mean, **any axis ≤4
blocks the idea in Pass 1.** Both ideas re-scored with the supercomputer priced in and 26037's
licence resolved.

### Pass 1 — full criteria (Novelty ON)

| Idea | Prob | User | Demo | Judge | Novel | Feas | Imp | Score | Verdict |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|---|
| **26037** AV path planning | 7 | 7 | **9** | **9** | 6 | 7 | 6 | **7.3** | ✅ **PASS — no blocked axis** |
| **26047** Patient case-taking | **9** | **9** | 7 | 8 | **4** | 7 | **8** | 7.4 | ⛔ **BLOCKED on Novelty** |

### Pass 2 — Novelty switched off

| Idea | Prob | User | Demo | Judge | Feas | Imp | Score |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| **26047** | 9 | 9 | 7 | 8 | 7 | 8 | **8.0** |
| **26037** | 7 | 7 | 9 | 9 | 7 | 6 | **7.5** |

### Why each number

**26047 Novel 4 — the blocking score.** AMIE outperforms physicians at history-taking in *Nature*;
PGI Chandigarh has the kiosk deployed; the NAMASTE piece was won at SIH last year with public code;
Prakriti ML sits at 97–99%. A hostile judge scores this a **3**. I cannot honestly put it above 4.
**26047 Prob 9 / User 9 / Imp 8** — the best-evidenced problem in the entire 226-PS set, published
by a third party, cited by the ministry itself, with a countable installed base.
**26047 Feas 7** — up from 6: the stack fits the team, and the supercomputer makes the OCR model
real. Held back by unverified ABDM access and the 82% OCR ceiling.

**26037 Feas 7** — up from the conditional 8/4: **licence access is resolved** (full TAH stack minus
RoadRunner, with a working fallback), so the only remaining risk is the learning curve on a
toolchain nobody has touched, inside 7 days.
**26037 Novel 6** — the planning seam is real and verified empty, but the pipeline is largely
MathWorks reference examples.

---

# 11. VERDICT

**26047 has the better problem, the better impact, and the better fit with this team's actual
skills. It fails on novelty, and it fails hard enough to block.**

That is the uncomfortable shape of this decision. If SIH did not score novelty, 26047 would win at
8.0 and I would recommend it without hesitation. But SIH does score novelty, the ministry has
already seen the NAMASTE half solved at its own hackathon, and the closest analogue to the whole
product is running in a government hospital in Chandigarh.

**Recommendation: SIH26037.** It is the only one of the two with no blocked axis. It has the best
demo and judge-legibility of anything we have screened; a verified empty seam (planning, not
perception); a world-class free dataset family that suits the supercomputer; the field-data access
we actually have (road video) rather than the access we lack (OPD observation); no government rail;
no unprovable physical claim; and a direct winning precedent in TwinX.

**The cost of choosing it is real and should be said out loud:** seven days on a toolchain nobody
on the team has opened. That is a training problem, and training problems can be attacked with time
starting today. Novelty problems cannot — 26047's novelty gap cannot be closed by working harder.

**If the team overrules this and takes 26047 anyway** — a legitimate call given the stack fit — then
lead with **Dashavidha Pariksha depth plus uncertainty-aware intake**, never with "AI history
taking," and name AMIE and the PGI kiosk on your own slide before a judge names them for you.
