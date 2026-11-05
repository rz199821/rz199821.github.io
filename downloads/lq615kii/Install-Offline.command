#!/bin/bash
set -euo pipefail
umask 077
cd "$(dirname "$0")"
bundle="$PWD"
prefix='/Library/Printers/LQ615KII-Local'
queue='LQ615KII_Local241'
fail() { printf '\n安装未完成：%s\n' "$*" >&2; exit 1; }
[ "$(uname -s)" = Darwin ] || fail '请在Mac上运行。'
[ -x /usr/libexec/cups/backend/usb ] || fail '没有找到macOS USB打印后端。'
[ "$#" -eq 1 ] || fail "用法：bash Install-Offline.command '此前确认过的USB地址'"
uri="$1"
case "$uri" in
 usb://EPSON/LQ-615KII\?serial=?*) ;;
 *) fail '需要此前确认过的LQ-615KII USB地址，不能凭空填写。';;
esac
case "$uri" in
 *[$'\n\r\t ']* ) fail 'USB地址包含无效空白。';;
esac
[ ! -e "$prefix" ] || fail '目标驱动目录已经存在。为保留已有安装，请先使用对应卸载程序或发来状态，不要覆盖。'
if /usr/bin/lpstat -p "$queue" >/dev/null 2>&1; then fail '同名队列已经存在，不会覆盖。'; fi
# Support an existing unmodified 0.1 checkout without another download.
if ! /usr/bin/grep -q '^#define _DARWIN_C_SOURCE 1$' lq615filter.c; then
 /bin/cp -n lq615filter.c lq615filter.c.before-offline-fix
 /usr/bin/perl -0pi -e 's/\A#define _POSIX_C_SOURCE 200809L\r?\n/#if defined(__APPLE__)\n#define _DARWIN_C_SOURCE 1\n#else\n#define _POSIX_C_SOURCE 200809L\n#endif\n/' lq615filter.c
 /usr/bin/grep -q '^#define _DARWIN_C_SOURCE 1$' lq615filter.c || fail '源码格式不符，未继续安装，请发来错误。'
fi
mkdir -p .build/module-cache
printf '正在本机编译PDF转换器与系统打印滤镜…\n'
xcrun swiftc -O -module-cache-path "$bundle/.build/module-cache" pdf615.swift -o .build/pdf615
xcrun clang -O2 -Wall -Wextra -Werror -std=c11 pbmto615.c -o .build/pbmto615
xcrun clang -O2 -Wall -Wextra -Werror -std=c11 lq615filter.c -lcups -o .build/lq615filter
for program in pdf615 pbmto615 lq615filter; do
 /usr/bin/codesign --force --sign - --timestamp=none --identifier "local.lq615kii.$program" ".build/$program"
 /usr/bin/codesign --verify --strict ".build/$program"
done
# Noninteractive render in the logged-in user's context before installing.
[ "$(.build/pdf615 count demo-241x140.pdf)" = 1 ] || fail '演示PDF页数自检失败。'
.build/pdf615 render demo-241x140.pdf 1 .build/preflight.pbm - 90 128 ink-center 0 0 > .build/preflight.log
.build/pbmto615 --d4 --paper=241x140-original < .build/preflight.pbm > .build/preflight.prn
[ -s .build/preflight.prn ] || fail '转换自检未产生数据。'
printf '使用此前确认的USB地址登记离线队列；当前不查询设备，也不发送测试页。\n'
printf '\n接下来需要Mac管理员密码。只安装独立驱动和队列，不改变默认打印机，不发送测试页。\n'
sudo -v
sudo -n /usr/bin/install -d -o root -g wheel -m 755 "$prefix"
printf 'local.lq615kii.systemqueue.v1\n' > .build/OWNER
sudo -n /usr/bin/install -o root -g wheel -m 644 .build/OWNER "$prefix/OWNER"
for program in pdf615 pbmto615 lq615filter; do sudo -n /usr/bin/install -o root -g wheel -m 755 ".build/$program" "$prefix/$program"; done
sudo -n /usr/bin/install -o root -g wheel -m 644 LQ615KII-241x140.ppd "$prefix/LQ615KII-241x140.ppd"
# Validate absolute filter paths only after the root-owned helpers exist.
if command -v cupstestppd >/dev/null 2>&1; then cupstestppd LQ615KII-241x140.ppd; fi
# Exercise the actual installed filter once as this user; do NOT send to USB.
printf '检查已安装滤镜（只生成文件，不打印）…\n'
PPD="$prefix/LQ615KII-241x140.ppd" "$prefix/lq615filter" 1 "$USER" Install-Self-Test 1 '' "$bundle/demo-241x140.pdf" > .build/installed-selftest.prn 2> .build/installed-selftest.log || fail "已安装滤镜自检失败，未注册队列。请查看.build/installed-selftest.log；可用Uninstall.command撤销。"
[ -s .build/installed-selftest.prn ] || fail '已安装滤镜未生成自检数据。'
printf '注册系统打印队列…\n'
if ! sudo -n /usr/sbin/lpadmin -p "$queue" -D 'LQ-615KII 241x140 Local PDF' -L 'USB - manual single sheet' -v "$uri" -P "$prefix/LQ615KII-241x140.ppd" -o printer-is-shared=false -o LQScale=S90 -o LQInk=Standard -o LQX=0 -o LQY=0 -E; then
 fail 'macOS未接受队列注册。V5仍可使用；请发来此处错误，并用Uninstall.command撤销本次独立安装。不要重复执行-m raw。'
fi
/usr/bin/lpstat -p "$queue" -v "$queue"
/usr/bin/lpoptions -p "$queue" -l > .build/queue-options.txt
/usr/bin/grep -q '^LQScale/' .build/queue-options.txt || fail '系统队列没有显示预期驱动选项，请发来状态。'
printf '\n离线队列注册成功。尚未连接设备，不能据此判断实际打印成功。\n'
printf '下一步：打开241×140mm PDF → Command+P → LQ-615KII 241x140 Local PDF。\n'
printf '纸型选241 x 140 mm；应用缩放保持100%%，驱动默认会执行90%%，避免重复缩小。\n'
printf '接回同一台USB打印机后，先选1页、1份试打印；以后无需启动本脚本或V5。\n'
