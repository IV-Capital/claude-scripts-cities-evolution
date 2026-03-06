#!/usr/bin/env bash
# SessionStart hook: detect fork setup state and guide user accordingly.

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
GUIDE="$PROJECT_DIR/docs/ref/NICHE_STYLE_GUIDE.md"

# Branch 1: No NICHE_STYLE_GUIDE — fork not configured
if [ ! -f "$GUIDE" ]; then
    cat <<'MSG'
Обнаружен форк без настроенного профиля канала.
Файл docs/ref/NICHE_STYLE_GUIDE.md не найден.
Предложи пользователю выполнить /setup-channel для интерактивной настройки
репозитория под его YouTube-канал и нишу.
Шаблон: docs/NICHE_STYLE_GUIDE_TEMPLATE.md
MSG
    exit 0
fi

# Branch 2: Guide exists but section 9 has placeholders — video not configured
if grep -q '{{VIDEO_TITLE}}\|{{VIDEO_TOPIC}}\|{{KEY_INSIGHT}}' "$GUIDE"; then
    cat <<'MSG'
Профиль канала настроен, но информация о текущем видео не заполнена
(секция 9 содержит плейсхолдеры).
Предложи пользователю выполнить /setup-video для заполнения темы,
тезиса и параметров нового видео.
MSG
    exit 0
fi

# Branch 3: Everything configured — check pricing
cat <<'MSG'
Проверь актуальность прайсинга AI-видеосервисов.
Текущие цены хранятся в:
- .claude/skills/sora-2-pro-prompting/references/COSTS_AND_LIMITS.md
- .claude/skills/kling-video-prompting/SKILL.md (строка с Ultra $180/mo)
- .claude/skills/google-flow-prompting/references/ULTRA_PRICING.md
- .claude/skills/production-cost-estimator/SKILL.md (таблицы цен)

Выполни WebSearch запросы:
1. "OpenAI Sora Pro pricing 2026" — сравни с Sora COSTS_AND_LIMITS.md
2. "Kling AI pricing plans 2026" — сравни с Kling SKILL.md
3. "Google AI Ultra pricing Flow Veo 2026" — сравни с Flow ULTRA_PRICING.md
4. "ElevenLabs pricing plans 2026" — сравни с production-cost-estimator

Если цены изменились — обнови соответствующие reference-файлы и
production-cost-estimator/SKILL.md. Сообщи пользователю о найденных изменениях.
Если цены актуальны — кратко подтверди (одна строка).
MSG
exit 0
