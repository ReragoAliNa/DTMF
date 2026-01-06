# DTMF Signal Synthesis and Recognition
# 双音多频信号的合成与识别

本项目是一个完整的 DTMF 信号处理实验演示系统，涵盖了从理论仿真到实时交互式 Web 应用的全流程实现。项目采用 **Python (核心算法与仿真)** + **Java Spring Boot (交互式 Web 演示)** 的混合架构。

## 🌟 项目亮点

- **高性能核心**: 基于 Goertzel 算法的亚毫秒级信号检测。
- **自适应检测**: 创新的“自适应积分时长”算法，在 -20dB 强噪声环境下仍保持高准确率。
- **现代化 UI**: 基于 Spring Boot + Chart.js 的赛博朋克风格 Web 交互界面。
- **全方位测试**: 包含高斯白噪声、工频干扰、单频压制及脉冲噪声的鲁棒性测试。

## 📂 项目结构详细统计

本项目实现了从信号生成、算法验证到交互式演示的闭环架构。以下为详细的文件分布：

```text
Class-Design-Personal/
├── src/                        # 【核心算法库 - Python】
│   ├── core/                   # 信号处理核心
│   │   ├── dsp.py              # Goertzel 算法与信号合成实现
│   │   ├── config.py           # DTMF 标准频率与系统参数配置
│   │   └── music.py            # (实验) MUSIC 高分辨率频率估计算法
│   ├── ml/                     # 智能检测模块
│   │   ├── adaptive_detector.py # 自适应积分时长逻辑 (核心改进)
│   │   ├── enhanced_classifier.py # 基于统计特征的分类器
│   │   └── spectrogram_cnn.py   # 基于 CNN 的频谱图像识别
│   ├── experiments/            # 仿真与对比测试脚本
│   │   ├── realistic_noise_test.py # 真实信道噪声鲁棒性测试
│   │   ├── extreme_talkoff_test.py # 语声抑制与误触发测试
│   │   └── window_length_study.py  # 窗口长度对检测性能的影响
│   └── main.py                 # 全流程自动化仿真入口
│
├── java-web/                   # 【交互式演示系统 - Spring Boot】
│   ├── src/main/java/          # Java 业务层 (处理 API 请求与仿真调度)
│   ├── src/main/resources/     # Web 资源 (赛博朋克风格前端实现)
│   ├── pom.xml                 # Maven 依赖配置
│   └── mvnw                    # Maven 包装脚本
│
├── docs/                       # 【实验报告与文档 - LaTeX】
│   ├── src/                    # 报告源码 (分章节编写)
│   ├── references/             # 参考文献与模板
│   └── dtmf_report.pdf         # 编译生成的完整 PDF 报告
│
├── images/                     # 【实验结果可视化】(包含 9 张核心图表)
│   ├── dtmf_accuracy_curve.png # SNR-准确率特性曲线
│   ├── dtmf_spectrum.png       # 信号功率谱分析
│   └── ...                     # 其他时域波形与对比热力图
│
├── audio/                      # 【音频样本库】
│   ├── dial_sequence.wav       # 标准拨号演示序列
│   └── saved_sessions/         # 实验捕获的带噪音频记录
│
├── datasets/                   # 【外部数据集】
│   └── esc50/                  # 环境背景噪声源 (2000+ 样本)
│
└── run.sh                      # 【万能入口脚本】支持一键启动 GUI/仿真/编译
```

### 📊 仓库数据摘要
- **后端代码**: Java (Spring Boot) + Python 3.14 (Hybrid Implementation)
- **仿真脚本**: 10+ 独立组件
- **静态资源**: 时频域分析图表共 9 张
- **一键控制**: 集成 GUI 启动、仿真运行、实验对比及报告编译 4 大功能


## 🚀 快速开始

项目配有 `run.sh` 脚本，可一键执行所有操作。

### 1. 启动交互式 Web 演示 (推荐)
```bash
./run.sh gui
```
访问 `http://localhost:8081` 即可进入图形化交互界面。

### 2. 运行 Python 仿真
生成时域波形图、频谱图以及 Goertzel 能量图：
```bash
./run.sh sim
```

### 3. 执行对比实验
运行不同 SNR 下的算法准确率测试：
```bash
./run.sh exp
```

### 4. 编译 LaTeX 报告
```bash
./run.sh report
```

### 5. 清理项目
```bash
./run.sh clean
```

## 🛠 技术栈

- **Python**: NumPy, SciPy, Matplotlib (数据处理与仿真)
- **Java**: Spring Boot 4.0, Maven (Web 控制后端)
- **Frontend**: HTML5, Chart.js (实时数据可视化)
- **LaTeX**: 用于撰写专业学术报告

## 📝 实验结论

1. **Goertzel 优于 ML**: 在 DTMF 特征频率检测场景下，基于匹配滤波器原理的 Goertzel 算法在工程效率和抗噪性上优于通用机器学习分类器。
2. **自适应增益**: 通过自适应调节窗口时长（40ms-1s），系统可成功将检测门限从 -15dB 扩展至 -25dB，实现了极低信噪比下的鲁棒解析。

---
&copy; 2026 DTMF Signal Processing Course Design
