local bridge = require("rime_mem_bridge")
local rime_mem_context = require("rime_mem_context")

local K_NOOP = 2
local initialized_db_path = nil

local function is_text_input_key(key)
    local repr = key:repr()
    if repr:match("^[a-z]$") then
        return true
    end
    if repr:match("^[0-9]$") then
        return true
    end
    if repr == "space" then
        return true
    end
    return repr:match("^[%p]$") ~= nil
end

local function _init(env)
    local config = env.engine.schema.config
    env.schema_id = config:get_string("schema/schema_id") or "rime_mem"
    env.rime_mem_enabled_option = config:get_string("rime_mem/option_name") or "user_history"
    env.rime_mem_db_path = config:get_string("rime_mem/db_path") or "user_history.db"

    if initialized_db_path ~= env.rime_mem_db_path then
        bridge.init({
            db_path = env.rime_mem_db_path
        })
        initialized_db_path = env.rime_mem_db_path
    end

    env.rime_mem_commit_connection = env.engine.context.commit_notifier:connect(function(ctx)
        if not env.engine.context:get_option(env.rime_mem_enabled_option) then
            return
        end

        local normalized_commit_text = rime_mem_context.normalize_token(ctx:get_commit_text())
        if not normalized_commit_text then
            return
        end

        local rime_ctx = rime_mem_context.get_context(env)
        bridge.log_event({
            ts_ms = os.time() * 1000,
            schema_id = rime_ctx.schema_id,
            pinyin_norm = rime_ctx.pinyin,
            committed_word = normalized_commit_text,
            left1 = rime_ctx.left1,
            left2 = rime_ctx.left2,
            source = "rime",
            commit_len = #normalized_commit_text,
        })
        rime_mem_context.push_committed_word(env, normalized_commit_text)
    end)
end

local function _process(key, env)
    if key:repr() == "BackSpace" and not env.engine.context:is_composing() then
        local words = env.rime_mem_words or {}
        if #words > 0 then
            table.remove(words, #words)
        end
        return K_NOOP
    end

    if not is_text_input_key(key) then
        return K_NOOP
    end

    return K_NOOP
end

local function _fini(env)
    if env.rime_mem_commit_connection and env.rime_mem_commit_connection.disconnect then
        env.rime_mem_commit_connection:disconnect()
    end
    env.rime_mem_commit_connection = nil
end

return {
    init = _init,
    func = _process,
    fini = _fini
}
