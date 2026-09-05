# REF-13 · ADITYA'S 43 PHOTOGRAPHS — THE ATMOSPHERE HE ACTUALLY WANTS
**Written 4 Sep 2026 from 43 photographs he supplied.** Two places: **Prayagraj** (Ganga–Yamuna
plains, hazy) and **Manali / Lahaul** (Himalaya, alpine). Stored in `real-clouds/src/ref_01..43.jpeg`.
**These are HIS OWN photographs, so unlike `trees/` and `real-india/` they can go in the film** —
as sky planes, as texture reference, as anything.
Every number below is **measured off the pixels**, not described.

## 0 · WHAT HE ASKED FOR, IN HIS WORDS — and it is not a time of day
> *"A time when the sun rays are very good and peaceful, when the sky is very good, with very good
> clouds… I can see clouds in the air, different kinds of clouds: dense clouds, light clouds, every
> kind of cloud, properly harmonizing with each other. The light is going above the clouds, beyond
> the clouds, coming through the streets, houses, and everything."*

**He corrected "afternoon" himself.** The target is not an hour on a clock — it is a CONDITION:
1. **Multiple cloud TYPES in one sky**, at different heights, reading as different things.
2. **Blue holes between them** — the sky is never uniformly covered.
3. **The sun behind or above the cloud**, not beside it, so light comes *through*.
4. **That light reaching the ground** — down into streets and onto houses.
**Every one of those four is a geometry-and-occlusion problem, not a shader problem.** That is the
single most important thing this study establishes.

## 1 · THE SKY — measured, and it settles the Nishita target
| set | R | G | B | sat % | brightness | hue |
|---|---|---|---|---|---|---|
| **Alpine sky, all** | 142.1 | 164.9 | 193.7 | **27.2** | 166.9 | 213.0° |
| … toward zenith | 130.9 | 157.7 | 190.8 | **32.6** | 159.8 | 212.8° |
| … middle | 144.0 | 167.9 | 197.4 | 27.5 | 169.8 | 213.1° |
| … toward horizon | 154.5 | 170.8 | 192.7 | **19.8** | 172.7 | 214.4° |
| **Plains sky (Prayagraj), all** | 138.0 | 162.1 | 179.0 | 23.4 | 159.7 | 202.0° |
| … toward zenith | 146.4 | 171.5 | 191.4 | 24.2 | 169.8 | 204.8° |
| … toward horizon | 137.5 | 160.2 | 172.6 | **20.9** | 156.8 | 197.6° |
| **bus_02 video, for cross-check** | 160.4 | 186.3 | 219.2 | 26.3 | 188.6 | 213.6° |
| **dashcam dawn — what S0 uses NOW** | 191.0 | 188.0 | 183.0 | **4.6** | 187.0 | warm grey |

**THREE INDEPENDENT SOURCES AGREE: the sky he wants is ~23–27 % saturation, hue 202–214°, and it
DESATURATES TOWARD THE HORIZON** — 32.6 % at zenith falling to 19.8 % at the horizon in the alpine
set, 24.2 → 20.9 in the plains set. **The gradient is the thing, not the average.**
This confirms REF-06 §6, which read the same effect off the bus footage by eye.
**Against S0's current 4.6 %, this is a five-fold change in saturation. It is not a tweak.**
**Hue 202° (plains) vs 213° (alpine) is real** — the plains sky is measurably *greener/warmer*
because of the aerosol load. **Najibabad is plains. Build 202–206°, not 213°.**

## 2 · CLOUD COVER — the distribution, and why "25 % thin stratus" was wrong
39 of the 43 photographs contain real sky. Cover measured as bright, near-neutral pixels inside the
sky region:
| band | cover | photos | share |
|---|---|---|---|
| near-clear | 0–15 % | 13 | 33 % |
| scattered | 15–40 % | 6 | 15 % |
| **broken** | **40–70 %** | **11** | **28 %** |
| overcast | 70–100 % | 9 | 23 % |
**Median 45 %. Range 1 % to 100 %.**
**S0 currently specifies "thin, wispy, warm-lit cirrus streaks — NOT cumulus", ~25 % cover.
That is wrong for what he wants.** The photographs he chose to send are dominated by the
**broken** band, and the ones that match his description word for word — **ref_29, ref_42, ref_41,
ref_25, ref_22** — measure **45–68 %**.
**BUILD TARGET: 50 ± 15 % cover, in the broken band, never uniform.**

## 3 · CLOUD STRUCTURE — read off ref_29, ref_42, ref_39, ref_15, ref_22
**ref_29 is the reference frame for "every kind of cloud harmonising".** In one photograph:
- **Flat-based dark stratocumulus** filling the top third — a *level, horizontal base* and a lumpy
  top. Underside grey-blue, top white.
- **Bright cauliflower cumulus** in the middle band, lit from above.
- **Torn fractus shreds** — small, wispy, no defined base — drifting across the blue holes.
- **Blue holes of very different sizes**, from a thumbnail to a third of the frame.
- **A cap cloud sitting directly ON the peak** (orographic), touching the rock.
**THE RULE THAT MAKES IT READ: every cloud base sits at the SAME HEIGHT.** The bases line up
horizontally across the whole frame because they all form at the condensation level. **A sky with
cloud bases at random heights is the tell.** Our build must place bases on one plane and vary only
the tops. **Nothing in REF-12 said this and it is the most important structural fact here.**

**Vertical structure, ref_15:** two layers coexisting — **thick cumulus hugging the ridge at low
level, thin fibrous cirrus streaks high above it**, and they do not interact. **Two separate
systems at two heights is what makes a sky look deep.**

**ref_39 and ref_22: cloud POURING OVER a ridge** — the base is *below* the summit, so rock emerges
through it. **A cloud layer that intersects terrain is free realism and we have a 170 m hill.**

## 4 · THE LIGHT HE WANTS — ref_42, and it is an OCCLUSION problem
**ref_42 is his description, photographed.** The sun sits **just behind a pine ridge**, hidden.
What is visible:
- The whole lower half of the frame is a **soft luminous veil** — not hard beams. Shafts are
  *diffuse* because the scattering medium is deep and the occluders are small and many.
- **Backlit trees are near-silhouette but NOT black** — the veil lifts them. Measured: the shaded
  hillside still sits at brightness ~95/255, nowhere near zero.
- **Cloud edges near the sun blow to pure white with a soft halo** — this is **halation**, and it is
  exactly the REF-12 §4 parameter (coverage 3–6).
- The blue sky at top-left, far from the sun, stays deep and saturated. **The glow is LOCAL to the
  sun's angular neighbourhood** and falls off fast.
**METHOD, and every piece already exists:** sun **behind** a treeline or ridge · bounded volume with
**anisotropy 0.35** (forward scatter, already in our haze) · **many small occluders** rather than
one big one · halation on the cloud shader.
**REF-12 §6 said "without occluders there is fog, not shafts". ref_42 proves it and adds the
correction: the occluders must be MANY and SMALL. A single ridge gives a hard edge; a pine canopy
gives the veil he is asking for.**

## 5 · ATMOSPHERIC PERSPECTIVE — measured in bands off ref_31
**ref_31 is our world seen from our own hill:** a north-Indian town at the foot of the Shivaliks,
flat-roofed concrete houses, a temple shikhara above the roofline, a **braided river with pale sand
banks**, a **forested sal ridge**, and a **far blue range** behind it.
| depth | what | sat % | brightness | local contrast |
|---|---|---|---|---|
| foreground foliage | 0–20 m | **53.4** | 66.3 | 43.1 |
| town roofs | 200–800 m | 42.0 | 79.7 | 45.7 |
| river + sand | ~1.2 km | 22.8 | 106.6 | 45.6 |
| near sal ridge | ~2 km | 20.4 | 100.7 | 26.7 |
| mid ridge | ~5 km | 22.7 | 130.1 | 29.1 |
| **far range** | ~15 km | **18.7** | 161.9 | **20.7** |
| sky | ∞ | 14.0 | 188.9 | 22.3 |
**TWO LAWS, both measured:**
1. **Saturation collapses 53 → 19 % with distance**, converging on the sky.
2. **LOCAL CONTRAST collapses too — 43 → 21.** Haze does not only wash colour out, it flattens
   detail. **Our haze does the first and not the second.** Distant geometry must additionally lose
   contrast, which in practice means **do not put crisp detail past ~2 km; let the volume do it.**
3. **The far range is the LEAST saturated thing in frame — less than the sky itself.** A distant
   ridge painted "pale blue" is wrong; it should be pale *grey-blue and flatter than the sky*.

## 6 · LAND — ref_21, ref_15, ref_33, ref_34, ref_39, and it feeds component 2 directly
**Scree and alluvial fans (ref_21, ref_15):** **every gully mouth has a fan spreading below it**,
pale, triangular, apex at the gully, spreading downslope. **This is REF-07 §4's debris law made
visible: the fans ARE the gullies' output.** Build the gullies with the Eroder and put the fans
where its `deposit` group says they are — **do not place them by hand.**
**The upper slopes are bare rock and scree; grass survives only where soil can lodge.** In ref_33
the grass grows in pockets *between* rock plates and stops dead at the scree line.

**Rock is FOLIATED, not rounded (ref_33, ref_34):** flat slabby plates splitting along bedding, tan
/ ochre / grey, stacked at an angle. **Not spheres. Not Voronoi lumps.** The scree below is the same
rock in smaller plates — **same shape, smaller, which is the causal rule again.**

**The braided river (ref_21):** the Malin at scale. **Pale grey-tan gravel bars**, water milky
grey-green with sediment (measured alpine water **R143 G148 B156, sat 8.7 %** — nearly colourless,
just bright). **Channels split and rejoin around bars; the bars are the same material as the banks.**
Confirms REF-07 §10b: cut the channel, drop a level plane, and the bars fall out for free.
**Plains water (Prayagraj, ref_05): R128 G141 B145, sat 12.4 %** — a flat pale sheet, no visible
depth colour at all, because it is shallow and silt-laden.

**Terracing (ref_39, ref_31):** cultivated terraces cut into every workable slope, as thin
horizontal steps. **They read at 2 km as fine horizontal lines** and they are what tells you people
live there.

## 7 · VEGETATION — colour, and it corrects a likely error
| | R | G | B | sat % |
|---|---|---|---|---|
| **alpine green** | 64.7 | 85.8 | 43.7 | **51.3** |
| **plains green** | 92.3 | 116.1 | 95.0 | **31.0** |
**Plains vegetation is 20 points LESS saturated and much lighter than alpine** — dust and haze sit
on it. **Najibabad is plains: build ~31 %, not 51 %.** A saturated alpine green in our world would
read as wrong immediately.
**Grass is never one colour (ref_33):** in a single square metre there are **bright yellow-green new
blades, deep blue-green clumps, dark olive broadleaf weeds, and pale straw dead matter at the base**
— plus **clumped wildflowers, yellow / white / blue, in patches and never spread.**
**That is four greens plus a dead layer plus flower clumps, in one scatter.** REF-11 §2's seven
layers are confirmed; what is added is that **the COLOUR must vary within a layer, not only between
layers** — and REF-11 §3's root-to-tip ramp is only half of it.

**Trees (ref_42, ref_31):** the pines are **chir/deodar — long bare trunks with foliage only in the
top third**, so you see *through* the lower forest. **Sal on the ridges reads as a continuous
lumpy dark mass with no visible trunks**, exactly REF-06 §3's "closed from 1 m up".
**ref_31 shows REF-06 §4's skyline rule directly: building–tree–building–tree**, trees filling every
gap, crowns above the rooflines.

## 8 · THE TOWN — ref_31, and it validates S0 §5
Flat-roofed concrete, 1–3 storeys, packed with no setbacks. Palette read off the photograph:
**cream, yellow ochre, pink, white, pale blue, and a lot of unpainted grey render.**
**Roof clutter is the texture: blue and red plastic water tanks on almost every roof**, dishes,
parapets. **A temple shikhara, red-orange, is the one thing that rises above the roofline.**
Confirms REF-03 and S0 §5 without amendment. **The water tanks being COLOURED (blue, red) rather
than black is the one correction — S1 specifies "black 1000 L tanks"; ref_31 shows blue and red
dominating.**

## 9 · WHAT THIS CHANGES IN THE BUILD — the list
1. **S0 §2's sky is wrong for what he wants** — 4.6 % → ~23 % saturation, hue ~204°, with a
   measured zenith→horizon desaturation gradient.
2. **S0 §2's cloud is wrong** — "thin wispy cirrus, not cumulus, 25 %" → **broken cumulus +
   stratocumulus + fractus, 50 ± 15 %, all bases on ONE level.**
3. **The sky-plane technique (REF-12 §2) is UNBLOCKED.** It was deferred for want of a sky
   photograph. We now have 43, they are his, and they can ship.
4. **God rays get a method:** sun behind a ridge/canopy, many small occluders, halation on.
5. **Haze must kill CONTRAST as well as saturation** past ~2 km.
6. **Vegetation saturation drops to ~31 %** for the plains.
7. **The Eroder's `deposit` group places the scree fans** — measured, not painted.
8. **Water tanks are blue and red**, not black.

## 10 · HONEST LIMITS
- **Not one photograph is of Najibabad**, and none is late September. Prayagraj is the right
  *atmosphere* but a different city; Manali is a different *landform* entirely. **The hill and the
  Malin borrow their FORM from Lahaul, their COLOUR from the plains set.** Said plainly so nobody
  later mistakes an alpine reference for a local one.
- **Cloud cover was measured by a brightness/saturation threshold**, which cannot tell thin white
  cloud from bright haze. Treat the band (near-clear / scattered / broken / overcast) as reliable
  and the exact percentage as ±10.
- **No photograph here is at 1.3 m from a road**, which is our camera. They are all standing eye
  height or elevated viewpoints. The composition lessons transfer; the framing does not.
- **Sun elevation was not derivable** from these photographs — no reliable shadow-length pair — so
  the time of day still comes from the astronomy, not from the pictures.
