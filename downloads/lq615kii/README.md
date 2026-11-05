# Epson LQ-615KII 实验测试包

[下载 ZIP](https://raw.githubusercontent.com/rz199821/rz199821.github.io/main/downloads/lq615kii/LQ615KII-test-kit.zip)

包含分析报告、实验滤镜 C 源码、校准样张、离线测试与 macOS 安装/撤销说明，不包含 Epson 原始驱动程序或厂商 DLL/EXE。

解压后先阅读 `LQ615KII-test-kit/prototype/README.zh-CN.md`。

这是 180×180 dpi、24 针 ESC *39 的实验原型，不是已验证的完整 macOS 驱动。Linux 离线测试已通过；macOS 编译、CUPS 发送、通信、物理边距、走纸和退纸仍需实机验证。

如需核对下载内容，参见 [SHA256SUMS.txt](SHA256SUMS.txt)。

## 241 × 140 mm 手动单张更新

[下载241×140单张校准包](https://raw.githubusercontent.com/rz199821/rz199821.github.io/main/downloads/lq615kii/LQ615KII-241x140-test.zip)

包含已生成的D4前导PRN，不必重新编译。按新包README直接USB发送；macOS26.3.1已实测拒绝原始队列。带D4前导的旧校准图已有用户报告能出图，新241×140页长与定位仍待实机验证。包内无用户序列号、照片或原始日志。
