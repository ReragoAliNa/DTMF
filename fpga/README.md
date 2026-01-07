# FPGA VHDL DTMF Project

This directory contains the VHDL source code for implementing a DTMF Generator on the AX309 (Xilinx Spartan-6) FPGA board, with UART communication for PC integration.

## 🎯 功能特性

- **DDS 双音发生器**: 32位相位累加器，频率分辨率 0.012Hz
- **PWM 音频输出**: 10位 PWM 直接驱动板载蜂鸣器
- **UART 串口通信**: 115200 baud，支持原始 PCM 波形上传
- **按键去抖**: 20ms 软件去抖，抑制机械震荡
- **LED 状态指示**: 实时显示当前按键状态

## 📁 文件结构

| 文件 | 描述 |
|------|------|
| `dtmf_pkg.vhd` | DTMF 频率常量与类型定义 |
| `sine_lut.vhd` | 256 点正弦查找表 (16位量化) |
| `dtmf_generator.vhd` | DDS 核心：双音信号合成 |
| `pwm_audio.vhd` | 10位 Delta-Sigma PWM 调制器 |
| `key_debounce.vhd` | 按键去抖模块 (20ms) |
| `uart_tx.vhd` | UART 发送模块 (115200 baud) |
| `ax309_top.vhd` | 顶层实体：系统集成 |
| `ax309.ucf` | 引脚约束文件 (AX309 开发板) |

### 仿真文件
| 文件 | 描述 |
|------|------|
| `dataset_tb.vhd` | 系统级仿真 (按键→音频→UART) |
| `dtmf_tb.vhd` | 单元测试 (dtmf_generator) |
| `simu/dataset.png` | GTKWave 系统仿真波形截图 |
| `simu/dtmf_wave.png` | DDS 双音输出波形截图 |

## 🔧 开发环境

- **IDE**: Xilinx ISE 14.7
- **目标器件**: XC6SLX9-2FTG256 (Spartan-6)
- **仿真工具**: GHDL + GTKWave

## 📌 引脚分配 (AX309)

| 信号名 | FPGA 引脚 | 说明 |
|--------|----------|------|
| sys_clk | T8 | 50MHz 系统时钟 |
| rst_n | L3 | 复位按键 (Active Low) |
| key_in[0] | C3 | 按键 1 |
| key_in[1] | D3 | 按键 2 |
| key_in[2] | E4 | 按键 3 |
| key_in[3] | E3 | 按键 4 |
| led_out[0-3] | P4, N5, P5, M6 | 状态 LED |
| audio_pwm | J11 | 板载无源蜂鸣器 |
| uart_tx | K13 | UART 发送 (→ PC) |

## 🚀 使用步骤

### 1. ISE 工程创建
1. 打开 Xilinx ISE 14.7
2. 创建新工程，目标器件选择 `XC6SLX9-2FTG256`
3. 添加本目录所有 `.vhd` 文件
4. 添加约束文件 `ax309.ucf`
5. 右键 `ax309_top` → **Set as Top Module**

### 2. 综合与实现
```
Synthesize → Implement Design → Generate Programming File
```

### 3. 下载比特流
使用 iMPACT 或 Alinx 下载工具将 `ax309_top.bit` 烧录到开发板

### 4. 连接 PC
1. USB-UART 线连接开发板与 PC
2. 运行 Python 串口网关:
   ```bash
   cd ../bridge
   python fpga_uart_bridge.py
   ```
3. Web 界面中切换到 "Hardware Only" 模式

## 🔊 功能说明

| 按键 | DTMF 音调 | 行频 | 列频 | LED |
|------|----------|------|------|-----|
| KEY1 | '1' | 697Hz | 1209Hz | LED1 |
| KEY2 | '2' | 697Hz | 1336Hz | LED2 |
| KEY3 | '3' | 697Hz | 1477Hz | LED3 |
| KEY4 | '4' | 770Hz | 1209Hz | LED4 |

按下按键后：
1. 蜂鸣器发出对应的 DTMF 双音
2. 对应 LED 点亮
3. PCM 波形数据通过 UART 上传到 PC
4. Web 界面实时显示波形与识别结果

## 📈 技术参数

| 参数 | 数值 |
|------|------|
| 系统时钟 | 50 MHz |
| 采样率 | 48 kHz |
| PCM 位深 | 16 bit |
| 相位累加器 | 32 bit |
| 频率分辨率 | 50MHz / 2³² ≈ 0.012 Hz |
| 去抖时间 | 20 ms |
| UART 波特率 | 115200 baud |

## 📷 仿真截图

### 系统集成仿真
![系统仿真](simu/dataset.png)

### DDS 双音波形
![DDS波形](simu/dtmf_wave.png)

---
© 2026 DTMF FPGA Implementation | AX309 Spartan-6
