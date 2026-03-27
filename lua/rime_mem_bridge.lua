require("librime_rust_mem")

local init_fn = __rime_mem_init
local log_event_fn = __rime_mem_log_event
local suggest_fn = __rime_mem_suggest
local log_shown_fn = __rime_mem_log_shown
local log_negative_fn = __rime_mem_log_negative
local normalize_token_fn = __rime_mem_normalize_token
local json = __rime_mem_json

local M = {}

local function encode_table(value)
    return json.encode(value or {})
end

local function decode_json(raw)
    if raw == nil or raw == "" then
        return nil
    end
    return json.decode(raw)
end

function M.init(opts)
    return init_fn(encode_table(opts))
end

function M.log_event(evt)
    return log_event_fn(encode_table(evt))
end

function M.suggest(req)
    local raw = suggest_fn(encode_table(req))
    return decode_json(raw)
end

function M.log_shown(evt)
    return log_shown_fn(encode_table(evt))
end

function M.log_negative(evt)
    return log_negative_fn(encode_table(evt))
end

function M.normalize_token(raw)
    if raw == nil or raw == "" then
        return nil
    end
    return normalize_token_fn(raw)
end

return M
