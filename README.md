# clip-translate

GNOME Wayland 下的剪贴板自动翻译工具：**复制英文，自动弹出置顶翻译窗口**。

灵感来自 Windows 平台的 CopyTranslator。翻译引擎走任意 **Anthropic 兼容 API 网关**（智谱 GLM、小米 MiMo、Claude、one-api / new-api 中转等均可），LLM 翻译质量远超传统网页翻译接口。

## 特性

- 📋 **复制即翻译**：基于 GPaste 的 D-Bus 事件驱动，无轮询、无窗口闪烁、不打断打字
- 🪟 **置顶小窗**：上=原文、下=译文，流式输出（SSE），首字约 1~3 秒
- ✋ **不抢焦点**：自动弹窗不夺取键盘焦点；点击窗口即可选中、复制译文，也有复制按钮
- 🔄 **引擎切换**：窗口内下拉切换模型，立即重译并记住选择
- 🔛 **一键开关**：不想被打扰时关掉自动翻译，通过 GNOME 搜索「翻译」随时手动打开
- 🧅 **纯本地**：Python + GTK3 实现，除 gpaste 外零额外依赖；API Key 只存在本机（600 权限）

## 原理

```
复制英文
   │
   ▼
GPaste daemon ──D-Bus: Update(REPLACE)──▶ clip-translate-watch (systemd --user)
                                             │  过滤：仅英文 / ≤5000字符 / 开关开启
                                             ▼
                                  clip-translate-gui --passive --text "..."
                                             │  Anthropic 兼容 API（SSE 流式）
                                             ▼
                                  置顶翻译窗口（不抢焦点，可选中复制）
```

为什么这样设计：
- GNOME Wayland 不支持 `wl-paste --watch`（Mutter 缺 wlroots data-control 协议），轮询方案会导致窗口闪烁与输入法被打断，因此改用 GPaste 的事件信号
- GTK3 在窗口 map 之前读不到 Wayland 剪贴板，因此监听器把文本通过 `--text` 参数直传给窗口
- 相同文本重复复制不触发（GPaste 天然去重）

## 依赖

| 依赖 | 说明 |
|---|---|
| Ubuntu 24.04 / GNOME 46（Wayland） | 其他版本未测试 |
| python3 + PyGObject（GTK3） | Ubuntu GNOME 桌面自带 |
| gpaste-2 | 剪贴板事件源（`sudo apt install gpaste-2`） |
| Anthropic 兼容 API 网关 | 见下方配置 |

## 安装

```bash
sudo apt install -y gpaste-2
git clone https://github.com/Suma1LL/clip-translate.git
cd clip-translate
./install.sh
```

然后编辑 `~/.config/clip-translate.conf`，填入你的网关地址、API Key 和模型名，并重启服务：

```bash
systemctl --user restart clip-translate-watch
```

## 配置

`~/.config/clip-translate.conf`：

```ini
# Anthropic 兼容端点，任何 {BASE_URL}/v1/messages 可用的地址
BASE_URL="https://open.bigmodel.cn/api/anthropic"
# API Key（仅存本机，请保持 600 权限）
API_KEY="sk-xxxxxxxx"
# 模型名（格式依网关而定，通常带供应商前缀）
MODEL="zhipuai/glm-4.6"
```

窗口工具栏的下拉框内置了三个引擎选项（可在源码 `ENGINES` 列表中自行增删）：

| 模型 | 特点 |
|---|---|
| `xiaomi/mimo-v2.6-pro` | 快（1~3s），支持禁用思考 |
| `zhipuai/glm-4.6` | 稳（~5s），支持禁用思考 |
| `zhipuai/glm-5.3` | 强但慢（强制思考，无法关闭） |

## 使用

| 操作 | 效果 |
|---|---|
| 复制英文 | 自动弹翻译窗（默认行为） |
| 窗口内「自动：开/关」 | 暂停 / 恢复自动弹窗（持久保存） |
| GNOME 搜索「翻译」→ 回车 | 手动翻译当前剪贴板（暂停时也可用，也是恢复开关的入口） |
| 引擎下拉框 | 切换模型，立即重译并记住 |
| `Esc` / 关闭按钮 | 关闭翻译窗口 |

过滤规则：只翻译「以英文为主」的文本（含拉丁字母且不含中文）；超过 5000 字符跳过；重复复制同一段不触发。

## 服务管理

```bash
systemctl --user status clip-translate-watch    # 查看状态
systemctl --user restart clip-translate-watch  # 重启（改配置后）
systemctl --user disable --now clip-translate-watch  # 彻底停用
```

## 已知限制

- 仅支持 GNOME Wayland 会话（X11 未测试，其他桌面环境需自行适配事件源）
- 翻译延迟取决于所用模型的推理速度（内网网关 + GLM-4.6 约 5s，流式首字 ~3s）
- 网关不可达时译文区显示错误信息
- GPaste 的 GNOME Shell 扩展（剪贴板历史面板）需注销重登后才被识别（可选功能）

## License

[MIT](LICENSE)
