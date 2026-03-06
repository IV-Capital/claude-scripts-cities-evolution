---
name: production-cost-estimator
description: |
  Рассчитывает примерную стоимость продакшена видео на основе сцен скрипта:
  модели генерации, длительности клипов, озвучки ElevenLabs. Формирует COST_ESTIMATE.md.
  Вызывается вручную после Phase 5 (Integration).
disable-model-invocation: true
allowed-tools: Bash,Read
---

# Production Cost Estimator

Рассчитывает примерную стоимость продакшена YouTube-видео на основе финализированного
скрипта. Парсит SCRIPT.md (visual layer) и TELEPROMPTER.md (narration), сверяет
с таблицами цен из reference-файлов скиллов, формирует COST_ESTIMATE.md.

**Когда использовать:** После Phase 5 (Integration & Assembly), перед Human Checkpoint 5.
Все модели сцен должны быть финализированы.

---

## 1. Таблицы цен (LAST_UPDATED: 2026-03)

> Цены взяты из reference-файлов установленных скиллов. При расхождении —
> сверяй с актуальными файлами:
> - `.claude/skills/sora-2-pro-prompting/references/COSTS_AND_LIMITS.md`
> - `.claude/skills/kling-video-prompting/SKILL.md` (секция Credit costs)
> - `.claude/skills/google-flow-prompting/references/ULTRA_PRICING.md`

### Sora 2 Pro (Pro subscription: $200/mo, 10,000 credits)

**Credit cost per clip (16:9 widescreen):**

| Resolution | 5s | 10s | 15s | 20s | 25s |
|---|---|---|---|---|---|
| 480p | 25 | 50 | 100 | 150 | ~200 |
| 720p | 60 | 180 | 360 | 540 | ~700 |
| 1080p | 200 | 600 | 1,300 | 2,000 | ~2,500 |

**Approximate credits/second:** 480p ~5, 720p ~17, 1080p ~50

**Effective cost per clip (Pro subscription, 1080p 10s):**
- Priority credits: ~$12.00/clip (первые ~16 клипов)
- Relaxed mode: ~$0 marginal (unlimited, 3–30 мин ожидания)
- Credit pack (10K/$70): ~$4.20/clip

**API pricing (per second):**
- sora-2 720p: $0.10/s
- sora-2-pro 720p: $0.30/s
- sora-2-pro 1024p: $0.50/s

### Kling AI (Ultra subscription: $180/mo, 26,000 credits)

| Operation | Credits | Effective cost |
|---|---|---|
| T2V 5s Standard (720p) | 10 | ~$0.07 |
| T2V 5s Professional (1080p) | 35 | ~$0.24 |
| T2V 10s Professional (1080p) | 70 | ~$0.49 |
| T2V 10s Pro + Audio (2.6) | 50–200 | ~$0.35–$1.38 |
| Video extend (+5s) | 10–35 | ~$0.07–$0.24 |
| I2V 5s Professional | 35 | ~$0.24 |

**Cost per second (Professional):** ~$0.049/s
**Failed generation overhead:** 15–25% (credits consumed, no refund)

### Google Flow (Ultra subscription: $249.99/mo, 25,000 credits)

| Model | Credits/output | Effective cost |
|---|---|---|
| **Veo 3.1 Fast** | **0 (FREE)** | **$0.00** |
| **Veo 3.1 Quality** | 100 | ~$1.00 |
| Veo 2 Fast | 10 | ~$0.10 |
| Veo 2 Quality | 100 | ~$1.00 |
| Video edit (extend/insert/remove) | 20 | ~$0.20 |
| Image generation (Imagen 4) | 0 | $0.00 |
| 1080p / 4K upscaling | 0 | $0.00 |

**Caution:** Cost is per OUTPUT, not per request. 4 outputs = 4× credits.
Extension chain (3 extensions): 100 + 60 = 160 credits.

**Effective cost per credit:** $249.99 ÷ 25,000 = $0.01/credit
(Introductory: $124.99 ÷ 25,000 = $0.005/credit)

### ElevenLabs Voice Generation

| Plan | Price | Characters | Overage |
|---|---|---|---|
| Creator | $22/mo | 100,000 chars | $0.24/1K chars |
| Pro | $99/mo | 500,000 chars | $0.24/1K chars |
| Scale | $330/mo | 2,000,000 chars | $0.12/1K chars |

**Estimation factors:**
- Average YouTube script (15–20 min video): 15,000–25,000 characters
- [audio tags] (e.g., `[laughs]`, `[whispers]`) are NOT counted as spoken characters
- Typical waste factor: 1.2× (re-takes, pronunciation fixes)

---

## 2. Методология расчёта

### Step 1: Парсинг SCRIPT.md — Visual layer

Для каждой сцены извлечь:
- **Model:** (Sora 2 / Kling / Flow / Stock footage / Static image)
- **Duration:** (в секундах)
- **Resolution:** (480p / 720p / 1080p / 4K)
- **Type:** (Video / Image)

Если Model = Stock footage или Static image → стоимость = $0 (бесплатные источники).

### Step 2: Cost lookup per scene

По таблицам из Step 1 определить credit cost каждой сцены:

**Sora 2:**
- Найти ячейку в credit table по Resolution × Duration
- Разделить на 10,000 × $200 = стоимость в долларах (priority credits)
- ИЛИ пометить как Relaxed mode ($0 marginal) если есть запас

**Kling:**
- Standard или Professional mode × Duration
- Разделить на 26,000 × $180

**Flow:**
- Veo 3.1 Fast: $0
- Veo 3.1 Quality: 100 cr × quantity
- Veo 2 Fast: 10 cr × quantity

### Step 3: Парсинг TELEPROMPTER.md — Narration characters

1. Считать полный текст TELEPROMPTER.md
2. Удалить все `[audio tags]` (текст в квадратных скобках) — они не озвучиваются
3. Удалить markdown разметку (заголовки, разделители)
4. Подсчитать количество символов чистого текста
5. Применить waste factor: × 1.2

### Step 4: ElevenLabs cost

По количеству символов и тарифному плану:
- Если chars ≤ plan limit → стоимость = план/месяц (пропорционально доле от лимита)
- Если chars > plan limit → plan cost + overage × excess chars

### Step 5: Буфер на регенерацию (25%)

Video generation cost × 1.25 = adjusted video cost.
Обоснование: ~15–25% генераций требуют повтора (артефакты, неправильное
движение, filter rejection, failed generations).

### Step 6: Итого

```
Grand Total = Adjusted Video Cost + ElevenLabs Cost + Subscription Costs (pro-rated)
```

---

## 3. Формат вывода — COST_ESTIMATE.md

```markdown
# Production Cost Estimate
**Video:** {Title}
**Date:** {Date}
**Scenes:** {N}

## Per-Scene Breakdown

| Scene | Model | Duration | Resolution | Credits | Cost |
|---|---|---|---|---|---|
| 01 | Sora 2 Quality | 10s | 1080p | 600 | $12.00 |
| 02 | Flow Veo 3.1 Fast | 8s | 1080p | 0 | $0.00 |
| 03 | Kling Professional | 10s | 1080p | 70 | $0.49 |
| ... | ... | ... | ... | ... | ... |

## Video Generation Summary

| Service | Scenes | Total Credits | Cost (subscription) |
|---|---|---|---|
| Sora 2 Pro | {N} | {credits} | ${cost} |
| Kling Ultra | {N} | {credits} | ${cost} |
| Flow Ultra (Quality) | {N} | {credits} | ${cost} |
| Flow Ultra (Fast) | {N} | 0 | $0.00 |
| Stock footage | {N} | — | $0.00 |
| Static image | {N} | — | $0.00 |
| **Subtotal** | {total} | — | **${total}** |
| **+ 25% regen buffer** | — | — | **${buffer}** |

## ElevenLabs Voice Generation

| Metric | Value |
|---|---|
| Narration characters (clean) | {N} |
| With waste factor (×1.2) | {N} |
| Plan | {Creator/Pro/Scale} |
| Cost | ${cost} |

## Subscription Costs (Monthly)

| Service | Plan | Monthly Cost | Used by this video |
|---|---|---|---|
| Sora 2 | Pro | $200.00 | Yes/No |
| Kling | Ultra | $180.00 | Yes/No |
| Google Flow | Ultra | $249.99 | Yes/No |
| ElevenLabs | {plan} | ${cost} | Yes |
| **Total subscriptions** | — | **${total}** | — |

## Grand Total

| Component | Cost |
|---|---|
| Video generation (with 25% buffer) | ${cost} |
| ElevenLabs narration | ${cost} |
| **Total per-video cost** | **${total}** |
| Monthly subscriptions (if all active) | ${subs} |

## Budget Optimization Suggestions

{List of specific suggestions to reduce cost, e.g.:
- Scene 07: Replace Sora 2 Quality ($12.00) → Flow Veo 3.1 Fast ($0.00) — no humans, after 3min mark
- Scene 12: Reduce duration 15s → 10s — saves 700 Sora credits
- Switch {N} non-hero scenes to Kling Standard: save ${amount}
- Use Sora Relaxed mode for scenes 04, 06, 09: save ${amount} in priority credits}
```

---

## 4. Оптимизация бюджета — чеклист

При формировании COST_ESTIMATE.md, проверь каждую из этих оптимизаций:

1. **Non-human scenes на Sora 2** → Переключить на Flow Fast (бесплатно) или Kling Standard
2. **Scenes после 3 мин на Premium** → Переключить на Economy tier (per ai-service-selector)
3. **Sora 1080p B-roll** → Draft at 480p (25 cr/5s vs 200 cr/5s = 8× экономия)
4. **Sora excess scenes** → Использовать Relaxed mode ($0 marginal)
5. **Flow Quality для non-hero** → Переключить на Flow Fast (100 cr → 0)
6. **Kling Professional для simple shots** → Переключить на Standard (70 cr → 20 cr)
7. **Длинные клипы (>10s)** → Разбить на 2 × shorter, может быть дешевле
8. **ElevenLabs overage** → Апгрейд плана может быть дешевле (Pro vs Creator + overage)
9. **Batch Sora в off-peak Relaxed** → Планировать 10+ clips на ночь
10. **Flow dual-output** → При итерации генерировать 1 output, не 2–4

---

## 5. Пример — 15-сценный скрипт

```markdown
# Production Cost Estimate
**Video:** "Как AI меняет медицину в 2026"
**Date:** 2026-03-06
**Scenes:** 15

## Per-Scene Breakdown

| Scene | Model | Duration | Resolution | Credits | Cost |
|---|---|---|---|---|---|
| 01 (Hook) | Sora 2 Quality | 10s | 1080p | 600 | $12.00 |
| 02 (Intro) | Kling Professional | 10s | 1080p | 70 | $0.49 |
| 03 (Context) | Flow Veo 3.1 Quality | 8s | 1080p | 100 | $1.00 |
| 04 | Flow Veo 3.1 Fast | 8s | 1080p | 0 | $0.00 |
| 05 | Flow Veo 3.1 Fast | 8s | 1080p | 0 | $0.00 |
| 06 | Kling Standard | 10s | 720p | 20 | $0.14 |
| 07 | Flow Veo 3.1 Fast | 8s | 1080p | 0 | $0.00 |
| 08 (Hero) | Sora 2 Quality | 10s | 1080p | 600 | $12.00 |
| 09 | Flow Veo 3.1 Fast | 8s | 1080p | 0 | $0.00 |
| 10 | Flow Veo 3.1 Fast | 8s | 1080p | 0 | $0.00 |
| 11 | Kling Standard | 10s | 720p | 20 | $0.14 |
| 12 | Flow Veo 3.1 Fast | 8s | 1080p | 0 | $0.00 |
| 13 | Flow Veo 3.1 Fast | 8s | 1080p | 0 | $0.00 |
| 14 | Stock footage | — | — | — | $0.00 |
| 15 (CTA) | Flow Veo 3.1 Quality | 8s | 1080p | 100 | $1.00 |

## Video Generation Summary

| Service | Scenes | Total Credits | Cost |
|---|---|---|---|
| Sora 2 Pro | 2 | 1,200 | $24.00 |
| Kling Ultra | 3 | 110 | $0.77 |
| Flow Ultra (Quality) | 2 | 200 | $2.00 |
| Flow Ultra (Fast) | 7 | 0 | $0.00 |
| Stock footage | 1 | — | $0.00 |
| **Subtotal** | 15 | — | **$26.77** |
| **+ 25% regen buffer** | — | — | **$6.69** |

## ElevenLabs Voice Generation

| Metric | Value |
|---|---|
| Narration characters (clean) | 18,200 |
| With waste factor (×1.2) | 21,840 |
| Plan | Creator ($22/mo) |
| Cost | $22.00 |

## Grand Total

| Component | Cost |
|---|---|
| Video generation (with 25% buffer) | $33.46 |
| ElevenLabs narration | $22.00 |
| **Total per-video cost** | **$55.46** |
| Monthly subscriptions (Sora+Kling+Flow+EL) | $651.99 |
```
