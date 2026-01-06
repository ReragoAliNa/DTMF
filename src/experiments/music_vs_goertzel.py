"""
Goertzel vs MUSIC Algorithm Comparison
对比经典 Goertzel 算法与现代 MUSIC 谱估计算法
"""
import numpy as np
import matplotlib.pyplot as plt
import os
import sys

# 添加项目根目录到 path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from src.core import config, dsp
from src.core.music import MusicDetector

def run_comparison():
    print("=" * 60)
    print("Goertzel vs MUSIC Algorithm Comparison")
    print("=" * 60)
    
    # 初始化 MUSIC 检测器
    # 信号时长 50ms -> 400 samples
    # 子空间维数 M = 120 (需 < 400)
    # 信号源数 p = 4 (双音)
    music = MusicDetector(fs=config.fs, n_elements=100, n_signals=4)
    
    snr_range = np.arange(-25, 16, 5)
    iterations = 100
    test_duration = 0.05 # 50ms 短信号测试
    
    goertzel_acc = []
    music_acc = []
    
    for snr in snr_range:
        g_correct = 0
        m_correct = 0
        
        for _ in range(iterations):
            key = np.random.choice(config.keys)
            signal = dsp.generate_dtmf(key, snr_db=snr, duration=test_duration)
            
            # 1. Goertzel
            if dsp.identify_key(signal) == key:
                g_correct += 1
                
            # 2. MUSIC
            pred_key, _ = music.detect(signal)
            if pred_key == key:
                m_correct += 1
                
        goertzel_acc.append(g_correct / iterations)
        music_acc.append(m_correct / iterations)
        
        print(f"SNR={snr:3d}dB | Goertzel: {goertzel_acc[-1]:.1%} | MUSIC: {music_acc[-1]:.1%}")
        
    # 绘图
    plt.figure(figsize=(10, 6))
    plt.plot(snr_range, goertzel_acc, 'b-o', label='Goertzel (Matched Filter)')
    plt.plot(snr_range, music_acc, 'r-s', label='MUSIC (Subspace)')
    
    plt.xlabel('SNR (dB)')
    plt.ylabel('Accuracy')
    plt.title(f'Algorithm Comparison (Signal Duration: {test_duration*1000:.0f}ms)')
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.ylim(0, 1.05)
    
    out_path = os.path.join(config.IMG_DIR, 'music_vs_goertzel.png')
    plt.savefig(out_path)
    print(f"\nPlot saved to {out_path}")

if __name__ == "__main__":
    run_comparison()
