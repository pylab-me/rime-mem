local M = {}
local bridge = require("rime_mem_bridge")

function M.normalize_token(raw)
    return bridge.normalize_token(raw)
end

function M.get_context(env)
    local ctx = env.engine.context
    local schema_id = env.engine.schema.schema_id
    local input = ctx.input
    local pinyin = ""
    local segment = ctx.composition:back()
    if segment then
        pinyin = input:sub(segment.start + 1, segment._end)
    end

    return {
        schema_id = schema_id,
        pinyin = pinyin,
        input = input,
        left1 = M.get_last_word(env, 1),
        left2 = M.get_last_word(env, 2)
    }
end

function M.get_last_word(env, offset)
    local words = env.rime_mem_words or {}
    return M.normalize_token(words[#words - (offset or 1) + 1])
end

function M.push_committed_word(env, word)
    local normalized_word = M.normalize_token(word)
    if not normalized_word then
        return
    end

    env.rime_mem_words = env.rime_mem_words or {}
    table.insert(env.rime_mem_words, normalized_word)
    if #env.rime_mem_words > 8 then
        table.remove(env.rime_mem_words, 1)
    end
end

return M
