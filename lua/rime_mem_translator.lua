local bridge = require("rime_mem_bridge")
local rime_mem_context = require("rime_mem_context")

local function yield_candidates(seg, candidates)
    local shown_entries = {}
    local end_pos = seg._end or seg["end"] or seg.start

    for _, item in ipairs(candidates or {}) do
        local text = item.text
        if type(text) == "string" and text ~= "" then
            shown_entries[#shown_entries + 1] = {
                text = text,
                feedback_token = item.feedback_token,
            }
            yield(Candidate("history", seg.start, end_pos, text, item.comment or ""))
        end
    end

    return shown_entries
end

local function translator(input, seg, env)
    local ctx = env.engine.context
    local enabled_option = env.rime_mem_enabled_option or "user_history"
    local suggest_limit = env.rime_mem_suggest_limit or 6

    if not ctx:get_option(enabled_option) then return end
    if seg == nil then return end
    if input ~= nil and input ~= "" and not ctx:is_composing() then return end

    local rime_ctx = rime_mem_context.get_context(env)
    if input == nil or input == "" then return end
    if not rime_mem_context.is_history_query_input(input) then return end

    local result = bridge.suggest({
        schema_id = rime_ctx.schema_id,
        pinyin_norm = input,
        prev_token1 = rime_ctx.prev_token1,
        prev_token2 = rime_ctx.prev_token2,
        limit = suggest_limit,
    })

    if not result or not result.candidates then return end

    local shown_entries = yield_candidates(seg, result.candidates)
    env.rime_mem_last_feedback = nil
    if #shown_entries > 0 then
        local feedback_tokens = {}
        for _, entry in ipairs(shown_entries) do
            feedback_tokens[#feedback_tokens + 1] = entry.feedback_token
        end
        env.rime_mem_last_feedback = {
            schema_id = rime_ctx.schema_id,
            pinyin_norm = input,
            prev_token1 = rime_ctx.prev_token1,
            prev_token2 = rime_ctx.prev_token2,
            entries = shown_entries,
        }
        bridge.log_shown({
            ts_ms = os.time() * 1000,
            schema_id = rime_ctx.schema_id,
            pinyin_norm = input,
            feedback_tokens = feedback_tokens,
            prev_token1 = rime_ctx.prev_token1,
            prev_token2 = rime_ctx.prev_token2,
        })
    end
end

return translator
