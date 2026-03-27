local function filter(input, env)
    local seen = {}
    local enabled_option = env.rime_mem_enabled_option or "user_history"

    for cand in input:iter() do
        if env.engine.context:get_option(enabled_option) then
            if not seen[cand.text] then
                yield(cand)
                seen[cand.text] = true
            end
        else
            yield(cand)
        end
    end
end

return filter
