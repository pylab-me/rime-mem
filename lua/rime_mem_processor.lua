local bridge = require("rime_mem_bridge")
local rime_mem_context = require("rime_mem_context")

local K_NOOP = 2
local initialized_runtime_key = nil

local function maybe_log_negative_feedback(env, selected_text)
    local pending = env.rime_mem_last_feedback
    env.rime_mem_last_feedback = nil
    if not pending or not pending.entries then return end

    for _, entry in ipairs(pending.entries) do
        if entry.text ~= selected_text then
            bridge.log_negative({
                ts_ms = os.time() * 1000,
                schema_id = pending.schema_id,
                pinyin_norm = pending.pinyin_norm,
                feedback_token = entry.feedback_token,
                prev_token1 = pending.prev_token1,
                prev_token2 = pending.prev_token2,
                source = "rime",
            })
        end
    end
end

local function is_text_input_key(key)
    local repr = key:repr()
    if repr:match("^[a-z]$") then return true end
    if repr:match("^[0-9]$") then return true end
    if repr == "space" then return true end
    return repr:match("^[%p]$") ~= nil
end

local function _init(env)
    local config = env.engine.schema.config
    env.schema_id = config:get_string("schema/schema_id") or "rime_mem"
    env.rime_mem_enabled_option = config:get_string("rime_mem/option_name") or "user_history"
    env.rime_mem_db_path = config:get_string("rime_mem/db_path") or "user_history.db"
    env.rime_mem_features = config:get_string("rime_mem/features") or "hc"
    env.rime_mem_suggest_limit = config:get_int("rime_mem/suggest_limit") or 5

    local runtime_key = table.concat({
        env.rime_mem_db_path,
        env.rime_mem_features,
    }, "|")

    if initialized_runtime_key ~= runtime_key then
        bridge.init({
            db_path = env.rime_mem_db_path,
            features = env.rime_mem_features,
        })
        initialized_runtime_key = runtime_key
    end

    env.rime_mem_commit_connection = env.engine.context.commit_notifier:connect(function(ctx)
        if not env.engine.context:get_option(env.rime_mem_enabled_option) then return end

        local normalized_commit_text = rime_mem_context.normalize_token(ctx:get_commit_text())
        if not normalized_commit_text then return end

        local rime_ctx = rime_mem_context.get_context(env)
        maybe_log_negative_feedback(env, normalized_commit_text)
        if rime_mem_context.is_history_query_input(rime_ctx.pinyin) then
            bridge.log_event({
                ts_ms = os.time() * 1000,
                schema_id = rime_ctx.schema_id,
                pinyin_norm = rime_ctx.pinyin,
                committed_word = normalized_commit_text,
                prev_token1 = rime_ctx.prev_token1,
                prev_token2 = rime_ctx.prev_token2,
                source = "rime",
                commit_len = #normalized_commit_text,
            })
        end
        rime_mem_context.push_committed_word(env, normalized_commit_text)
    end)
end

local function _process(key, env)
    local ctx = env.engine.context

    if key:repr() == "BackSpace" and not ctx:is_composing() then
        local words = env.rime_mem_words or {}
        if #words > 0 then table.remove(words, #words) end
        return K_NOOP
    end

    if not is_text_input_key(key) then return K_NOOP end

    return K_NOOP
end

local function _fini(env)
    if env.rime_mem_commit_connection and env.rime_mem_commit_connection.disconnect then
        env.rime_mem_commit_connection:disconnect()
    end
    env.rime_mem_commit_connection = nil
    env.rime_mem_last_feedback = nil
end

return {
    init = _init,
    func = _process,
    fini = _fini,
}
