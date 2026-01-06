# Xilinx ISE 14.7 操作指南 - AX309 FPGA 项目

本指南将带您一步步在 Xilinx ISE 14.7 中创建工程、导入代码、综合并烧录到 AX309 开发板。

## 第一步：新建工程 (Create New Project)

1.  打开桌面上的 **Xilinx ISE Design Suite 14.7** -> **ISE Design Tools** -> **Project Navigator**。
2.  点击菜单栏 **File** -> **New Project...**。
3.  **Project Wizard (1/5)**:
    *   **Name**: 输入工程名称，例如 `DTMF_FPGA`。
    *   **Location**: 选择一个保存路径（建议**不要**包含中文或空格）。
    *   **Top-level source type**: 选择 `HDL`。
    *   点击 **Next**。
4.  **Project Settings**:
    请严格按照 AX309 开发板参数选择：
    *   **Family**: `Spartan6`
    *   **Device**: `XC6SLX9`
    *   **Package**: `FTG256`
    *   **Speed**: `-2` (通常是 -2，如果是 -3 也可以选)
    *   **Preferred Language**: `VHDL`
    *   点击 **Next**，然后点击 **Finish**。

## 第二步：添加源文件 (Add Sources)

1.  在左侧 **Hierarchy** 面板中，右键点击工程名（`xc6slx9-2ftg256`），选择 **Add Copy of Source...**。
2.  浏览到本项目所在的文件夹 `c:\Users\33587\Desktop\DTMF\fpga\`。
3.  **全选**以下文件并点击 **Open**：
    *   `dtmf_pkg.vhd`
    *   `sine_lut.vhd`
    *   `dtmf_generator.vhd`
    *   `pwm_audio.vhd`
    *   `key_debounce.vhd`
    *   `ax309_top.vhd`
    *   `ax309.ucf` (这是引脚约束文件)
    *   *(注意：不要添加 dataset_tb.vhd，除非你是要做仿真)*
4.  在弹出的对话框中，确保 **Association** 选为 `All`，点击 **OK**。

## 第三步：编译与生成 (Synthesize & Generate)

1.  在左侧 **Hierarchy** 面板中，选中顶层文件 **`ax309_top`** (通常会有三个小方块图标)。
2.  在下方的 **Processes** 面板中：
    *   双击 **Synthesize - XST**。观察下方 Console 窗口，等待出现 "Process \"Synthesize - XST\" completed successfully"（绿色对钩）。
    *   双击 **Implement Design** (这会自动运行 Translate, Map, Place & Route)。等待全部打钩。
    *   双击 **Generate Programming File**。
3.  如果一切顺利，Console 会显示 "Process \"Generate Programming File\" completed successfully"。此时工程目录下会生成 `ax309_top.bit` 文件。

## 第四步：烧录到开发板 (Program)

*您可以使用 Xilinx 自带的 iMPACT 工具，或者使用 ALINX 提供的下载工具（推荐）。*

### 方法 A: 使用 iMPACT (需要 Xilinx Platform Cable USB 下载器)
1.  在 **Processes** 面板中，展开 **Configure Target Device**，双击 **Manage Configuration Project (iMPACT)**。
2.  在 iMPACT 中，双击 **Boundary Scan**。
3.  右键空白处 -> **Initialize Chain**。
4.  它应该能识别到芯片 `xc6slx9`。
5.  在弹出的对话框中选择刚才生成的 `.bit` 文件 (`ax309_top.bit`)。
6.  可能会询问是否添加 SPI/BPI Flash，选择 **No** (或者是，如果您想固化程序)。
    *   *如果要固化（断电不丢失）：需生成 .mcs 文件并烧写 SPI Flash。*
7.  右键点击芯片图标 -> **Program**。
8.  看到 **Program Succeeded** 蓝色大字即成功。

### 方法 B: 使用 ALINX 下载工具 (如果是 USB 直连)
如果您的板子不需要昂贵的 Xilinx 下载器，而是直接 USB 线连接，请使用卖家提供的工具加载 `.bit` 文件并点击“下载”。

## 第五步：功能测试

1.  烧录成功后，板子即刻开始工作。
2.  按一下 `KEY1` (C3)、`KEY2`、`KEY3` 或 `KEY4`。
3.  观察板子上的 **LED** 是否亮起。
4.  聆听板子上的 **蜂鸣器**，是否发出不同的双音（哔——啵——）。

---
**常见问题**:
*   **综合报错？** 检查 Hierarchy 中是否正确选中了 `ax309_top` 作为 Top Module（右键 -> Set as Top Module）。
*   **没有声音？** 确认 `ax309.ucf` 中的 `audio_pwm` 引脚是否对应 `J11` (Buzzer)。
