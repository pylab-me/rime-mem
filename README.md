# rime-mem

**Enhancing Rime with smarter memory and contextual prediction.** / **让 Rime 拥有更聪明的“记忆”与联想能力。**

## 它能做什么

在日常输入中，我们经常会遇到这些场景：

- 刚输入过的词，希望接下来能优先出现
- 正在写一段内容时，希望输入法能根据上下文给出更合理的候选
- 用久了以后，希望输入法能逐渐“记住”自己的用词习惯

`rime-mem` 就是为了让 Rime 在这些场景下表现得更好而设计的。

它不是一个独立输入法，而是为 Rime 增加的一层“记忆增强”能力。

## 主要功能

**记忆输入习惯**  
不只是查静态词库，而是会结合你的历史输入，让常用词更容易被选到。

**理解上下文**  
在连续输入时，能结合前面已经输入的内容，给出更符合当前语境的候选词。

**长期使用，越用越顺**  
使用时间越长，对个人用词习惯的“记忆”就越准确。

**保持流畅体验**  
这些增强能力都在后台运行，不影响输入本身的流畅度。

## 适合谁用

- 希望输入体验尽可能简洁、依赖少、不臃肿
- 觉得 Rime 默认候选还不够“懂你”
- 希望输入法能逐渐记住自己的用词习惯
- 在连续输入场景（如写作、聊天）中，希望体验更顺畅
- 愿意尝试让输入法变得更聪明一点

## 简单说明

这个项目把“记忆”相关的能力做成了一个独立模块，尽量不干扰 Rime 本身的稳定性和灵活性。你只需要正常使用输入法，就能逐渐感受到候选词变得更贴合自己的习惯。

## 模块的配置项

```yaml
rime_mem:
  # Phase 1 capabilities
  db_path: "user_history.db"
  suggest_limit: 5

# Phase 2 capabilities (experimental)
# prediction_timeout_ms: 1800
# predict_limit: 5
# max_iterations: 1
# auto_prediction: true
````

## Phase 1 配置（当前发布版本）

> 相关文件：
> [https://github.com/pylab-me/rime-mem/releases/tag/staging](https://github.com/pylab-me/rime-mem/releases/tag/staging)

> Phase 1 提供基于上下文的 suggestion：在连续输入文本时，当你开始输入拼音字母，输入法会根据前文给出更合适的下一个词语候选。

1. 在输入方案配置中，分别为 `processors`、`translators`、`filters` 打上补丁，加入以下项目：

```yaml
"processors":
  - lua_processor@rime_mem_processor
"translators":
  - lua_translator@rime_mem_translator
"filters":
  - lua_filter@rime_mem_filter
```

2. 将 `lua` 目录中的 6 个 `rime_mem_*.lua` 文件放入你的 `lua/` 目录
3. 将 `registration_example.lua` 中的内容加入 `rime.lua`

## Phase 2 配置（测试中）

> 配置项见：`rime_mem_settings.yaml`

在你的 `{方案}.custom.yaml` 中引用它：

```yaml
patch:
  "__include": rime_mem_settings.yaml
  # 你还可以在下面继续写其他 patch 内容，它们会一并合并
  "key_binder/bindings":
    - { when: paging, accept: comma, send: Page_Up }
```

### 当前已知问题

* 某些理想中的 UI 交互仍依赖 librime 提供更底层的能力

  * 要实现“用户完全不操作、idle n 秒后自动弹出”这件事，纯 Lua 这一层做得不够稳，也不值得继续绕
  * 当前的折中方案是：commit 后按一次空格触发 prediction

---

如果你对 Rime 的体验有更高期待，欢迎关注这个项目。

---

## 开发过程

* 开发前：一开始其实只是在改输入法相关的 bug，后来逐渐演化成了一个可以单独发布的版本

  * 之前看到不少讨论都提到想要「[上下文调频功能](https://github.com/rime/librime/issues/897)」
* 开发时：曾经有一个版本会尝试预测下一个标点符号，现在已经移除

## TODO

* [ ] 丢弃“大字典”方案

  * 在 2026 年的当下，我认为已经没有必要继续使用一个大型 YAML 充当字库；这部分会放到另外的 repo 处理
  * 本地测试中，我正在验证连续单词输出，以及输入超过 2 个字母后的单词提示
* [ ] 为 `rime-mem` 启用 UI 联想

  * 参考手机输入法的联想交互，但会克制连续触发的频率
* [ ] 安装与部署界面化
* [ ] 探索更极致的个人化场景

  * 在较新的系统下，尝试引入 keyring

---

## 关于开源与合作 | Open Source & Collaboration

这个项目目前不是完全开源。

与 Rime 的集成层、配置文件、Lua 侧实现等外围部分，会尽量保持开放；但核心算法部分暂时不会公开。原因也很直接：我希望先继续把它打磨成熟，而不是过早把最关键的部分直接放出去。

我并不排斥开源。相反，如果未来有合适的团队、产品方向，或者能够长期维护这套能力的条件，我愿意认真讨论进一步开放核心部分的可能性。

如果你正在做输入法、文本输入体验，或相关方向的产品，欢迎联系交流。

This project is currently released in a partially open form.

The surrounding parts — such as the Rime integration layer, configuration files, and Lua-side implementation — are open and will remain open as much as possible. The core algorithm, however, is kept private for now. The reason is straightforward: I would rather continue refining it into a mature and practical solution than release its most critical part prematurely.

I do not reject open source as a principle. If, in the future, there is a suitable team, product direction, or a sustainable long-term maintenance path, I would be very open to discussing a broader release of the core.

If you are working on input methods, text input systems, or related products, I would be glad to connect.
