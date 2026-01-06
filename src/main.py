"""
DTMF Signal Synthesis and Recognition
双音多频信号的合成与识别

Project Structure:
    python/
    ├── core/           # 核心模块
    │   ├── config.py   # 配置参数
    │   └── dsp.py      # DSP 算法 (Goertzel)
    ├── ml/             # 机器学习模块
    │   ├── ml_classifier.py      # KNN 分类器
    │   ├── enhanced_classifier.py # 增强型分类器
    │   ├── spectrogram_cnn.py    # CNN 分类器
    │   └── adaptive_detector.py  # 自适应检测器
    ├── experiments/    # 实验脚本
    │   ├── realistic_noise_test.py   # 真实噪声测试
    │   └── extreme_talkoff_test.py   # Talk-off 测试
    ├── utils/          # 工具模块
    │   └── visualize.py   # 可视化
    └── main.py         # 主程序入口

Usage:
    python main.py                          # 运行基础仿真
    python ml/adaptive_detector.py          # 运行算法对比实验
    python experiments/extreme_talkoff_test.py  # 运行 Talk-off 测试
"""

from .core import config, dsp
from .utils import visualize

def main():
    print("=== Starting DTMF Simulation ===")
    
    # 1. 运行性能测试并绘图
    print("Running performance test...")
    snr_vals, acc_vals = dsp.run_performance_test()
    visualize.plot_accuracy_curve(snr_vals, acc_vals)
    
    # 2. 生成频谱分析图
    visualize.plot_spectrum(key='5')
    
    # 3. 生成 Goertzel 能量图
    visualize.plot_goertzel_energy(key='5')
    
    # 4. 生成语谱图 (FFmpeg)
    visualize.generate_spectrogram_ffmpeg()
    
    # 5. 生成波形图 (FFmpeg)
    visualize.generate_waveform_ffmpeg(key='5')
    
    # 6. 生成噪声对比图 (FFmpeg)
    visualize.generate_noise_comparison_ffmpeg(key='5')
    
    print("=== All tasks completed successfully ===")

if __name__ == "__main__":
    main()
