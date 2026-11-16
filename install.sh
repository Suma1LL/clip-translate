#!/usr/bin/env bash
# clip-translate 一键安装（Ubuntu 24.04 / GNOME Wayland）
set -e
cd "$(dirname "$0")"

# 依赖检查
if ! command -v gpaste-client >/dev/null 2>&1; then
    echo "缺少 gpaste-2，请先执行: sudo apt install -y gpaste-2" >&2
    exit 1
fi
python3 -c "import gi; gi.require_version('Gtk','3.0')" 2>/dev/null \
    || { echo "缺少 PyGObject(GTK3)，请执行: sudo apt install -y python3-gi gir1.2-gtk-3.0" >&2; exit 1; }

# 安装文件
mkdir -p ~/.local/bin ~/.config/systemd/user ~/.local/share/applications
cp clip-translate-gui clip-translate-watch ~/.local/bin/
chmod +x ~/.local/bin/clip-translate-gui ~/.local/bin/clip-translate-watch
cp clip-translate-watch.service ~/.config/systemd/user/
cp clip-translate.desktop ~/.local/share/applications/

# 初始化配置（不覆盖已有配置）
if [ ! -f ~/.config/clip-translate.conf ]; then
    cp clip-translate.conf.example ~/.config/clip-translate.conf
    chmod 600 ~/.config/clip-translate.conf
    echo ">>> 已创建 ~/.config/clip-translate.conf"
    echo ">>> 请编辑该文件填入 BASE_URL / API_KEY / MODEL，然后执行："
    echo ">>>   systemctl --user restart clip-translate-watch"
fi

# 启动服务
systemctl --user daemon-reload
systemctl --user enable --now clip-translate-watch
echo "安装完成：复制一段英文试试。"
