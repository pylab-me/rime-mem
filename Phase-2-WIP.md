# Phase 2 配置（测试中）

> 配置项见：`rime_mem_settings.yaml`

在你的 `{方案}.custom.yaml` 中引用它：

```yaml
patch:
  "__include": rime_mem_settings.yaml
  # 你还可以在下面继续写其他 patch 内容，它们会一并合并
  "key_binder/bindings":
    - { when: paging, accept: comma, send: Page_Up }
```

## 当前已知问题

* 某些理想中的 UI 交互仍依赖 librime 提供更底层的能力

  * 要实现“用户完全不操作、idle n 秒后自动弹出”这件事，纯 Lua 这一层做得不够稳，也不值得继续绕
  * 当前的折中方案是：commit 后按一次空格触发 prediction