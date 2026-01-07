# DTMF Signal Synthesis and Recognition
# 双音多频信号的合成与识别

本项目是一个完整的 DTMF (Dual-Tone Multi-Frequency) 信号处理实验演示系统，涵盖了从理论仿真到实时交互式 Web 应用，再到 FPGA 硬件实现的**全栈全链路**实现。

## 🌟 项目亮点

- **高性能核心**: 基于 Goertzel 算法的亚毫秒级信号检测
- **自适应检测**: 创新的"自适应积分时长"算法 (40ms-1000ms)，在 -20dB 强噪声环境下仍保持高准确率
- **现代化 UI**: 基于 Spring Boot + Chart.js 的赛博朋克风格 Web 交互界面，三种工作模式
- **FPGA 硬件**: 完整的 VHDL 实现，包含 DDS 双音发生器、PWM 音频输出、UART 串口通信
- **软硬协同**: Python 串口网关实现 FPGA 与 Web 系统的实时数据交互
- **全方位测试**: 支持高斯白噪声、粉红噪声、脉冲噪声及 ESC-50 真实环境噪声

## 📂 项目结构

```text
Class-Design-Personal/
├── src/                        # 【核心算法库 - Python】
│   ├── core/                   # 信号处理核心 (Goertzel, DFT, 信号合成)
│   ├── ml/                     # 智能检测模块 (自适应检测, CNN, KNN)
│   ├── experiments/            # 仿真与对比测试脚本
│   └── main.py                 # 全流程自动化仿真入口
│
├── java-web/                   # 【交互式演示系统 - Spring Boot】
│   ├── src/main/java/          # Java 后端 (RESTful API, 信号处理服务)
│   ├── src/main/webapp/        # Web 前端 (JSP, Chart.js, Web Audio API)
│   └── pom.xml                 # Maven 依赖配置
│
├── fpga/                       # 【FPGA 硬件实现 - VHDL】
│   ├── dtmf_generator.vhd      # DDS 双音信号发生器
│   ├── pwm_audio.vhd           # PWM 音频输出模块
│   ├── uart_tx.vhd             # UART 串口发送模块
│   ├── ax309_top.vhd           # 顶层模块 (AX309 Spartan-6)
│   ├── ax309.ucf               # 引脚约束文件
│   └── simu/                   # GTKWave 仿真波形截图
│
├── bridge/                     # 【软硬件桥接 - Python】
│   └── fpga_uart_bridge.py     # UART 串口网关 (FPGA → Web)
│
├── docs/                       # 【实验报告 - LaTeX】
│   ├── src/                    # 报告源码 (分章节编写)
│   └── dtmf_report.pdf         # 编译生成的完整 PDF 报告 (31页)
│
├── images/                     # 【实验结果可视化】
│   ├── PC/                     # Web 界面截图 (13张)
│   ├── fpga/                   # FPGA 开发板照片与仿真波形
│   └── theory/                 # 理论分析图示
│
├── audio/                      # 【音频样本库】
│   └── call_*/                 # 电话模式录制的会话文件
│
├── datasets/                   # 【外部数据集】
│   └── esc50/                  # ESC-50 环境噪声数据集
│
└── run.sh                      # 【万能入口脚本】
```

## 🖥️ 三种工作模式

### 1. 实验模式 (Experiment Mode)
- 单信号检测与算法对比
- 可调参数：SNR (-20dB ~ +30dB)、噪声类型、频率偏移
- 实时波形与 Goertzel 能量分布可视化

### 2. 电话模式 (Phone Mode)
- 虚拟 16 键 DTMF 拨号盘
- 软件信号发生器：后端合成加噪信号
- FPGA 硬件信号源：物理按键触发 DDS 双音
- 实时识别与音频播放

### 3. 分析模式 (Analysis Mode)
- 批量分析已录制的电话会话
- 自适应模式 vs 手动时长调节 (40ms-1000ms)
- 单文件细节透视：波形与能量分布回放

## 🚀 快速开始

### 1. 启动交互式 Web 演示
```bash
./run.sh gui
```
访问 `http://localhost:8081` 进入图形化交互界面。

### 2. 运行 Python 仿真
```bash
./run.sh sim
```

### 3. 执行对比实验
```bash
./run.sh exp
```

### 4. 编译 LaTeX 报告
```bash
./run.sh report
```

### 5. 启动 FPGA 串口网关
```bash
./run.sh bridge
```

### 6. 清理项目
```bash
./run.sh clean
```

## 🛠 技术栈

| 层级 | 技术 |
|------|------|
| **算法核心** | Python 3.14, NumPy, SciPy |
| **Web 后端** | Java 21, Spring Boot 3.x, Maven |
| **Web 前端** | HTML5, CSS3, Chart.js, Web Audio API |
| **硬件实现** | VHDL, Xilinx ISE 14.7, Spartan-6 FPGA |
| **软硬桥接** | Python pyserial, HTTP REST |
| **文档排版** | LaTeX (XeLaTeX + ctex) |

## 📊 性能指标

| 指标 | 数值 |
|------|------|
| 检测延迟 (Fast) | < 40ms |
| 检测延迟 (Deep) | ~1000ms |
| 最低可检测 SNR | -25dB (自适应模式) |
| 频率精度 | ±1.5% (符合 ITU-T Q.23) |
| 端到端延迟 (FPGA→Web) | ~150ms |

## 📝 实验结论

1. **Goertzel 优于 ML**: 在 DTMF 频率检测场景下，Goertzel 算法在计算效率和抗噪性上优于通用机器学习分类器
2. **自适应增益**: 通过动态调节窗口时长 (40ms-1s)，系统可成功将检测门限从 -15dB 扩展至 -25dB
3. **软硬协同**: FPGA DDS 产生的真实 DTMF 信号经 UART 传输后，Java 后端可正确识别

---
© 2026 DTMF Signal Processing Course Design | [ReragoAliNa](https://github.com/ReragoAliNa)
