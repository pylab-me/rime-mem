local bridge = require("rime_mem_bridge")
local rime_mem_context = require("rime_mem_context")

local function source_to_comment(source)
    if source == "prev_pinyin" or source == "prev2_pinyin" then
        return "[HC]"
    end
    if source == "prev" or source == "prev2" then
        return "[C]"
    end
    return "[H]"
end

local function translator(input, seg, env)
    local enabled_option = env.rime_mem_enabled_option or "user_history"
    local limit = env.rime_mem_limit or 8

    if not env.engine.context:get_option(enabled_option) then
        return
    end
    if input == nil or input == "" then
        return
    end
    if seg == nil then
        return
    end
    if not env.engine.context:is_composing() then
        return
    end

    local rime_ctx = rime_mem_context.get_context(env)
    local result = bridge.suggest({
        schema_id = rime_ctx.schema_id,
        pinyin_norm = input,
        left1 = rime_ctx.left1,
        left2 = rime_ctx.left2,
        limit = limit,
    })

    if not result or not result.candidates then
        return
    end

    local shown_words = {}
    local end_pos = seg._end or seg["end"] or seg.start

    for _, item in ipairs(result.candidates) do
        local text = item.word
        if type(text) == "string" and text ~= "" then
            shown_words[#shown_words + 1] = text
            yield(Candidate("history", seg.start, end_pos, text, source_to_comment(item.source)))
        end
    end

    if #shown_words > 0 then
        bridge.log_shown({
            ts_ms = os.time() * 1000,
            schema_id = rime_ctx.schema_id,
            pinyin_norm = input,
            words = shown_words,
            left1 = rime_ctx.left1,
            left2 = rime_ctx.left2,
        })
    end
end

return translator
