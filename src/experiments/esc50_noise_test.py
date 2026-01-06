"""
ESC-50 环境噪声四算法对比实验
算法：Goertzel, Random Forest, MUSIC, Adaptive
"""
import numpy as np
import os
import glob
import matplotlib.pyplot as plt
from scipy.io import wavfile
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from src.core import config, dsp
from src.ml.enhanced_classifier import EnhancedClassifier
from src.core.music import MusicDetector
from src.ml.adaptive_detector import AdaptiveDetector

def load_esc50_noise(esc50_path, duration_samples, target_fs=8000):
    """从 ESC-50 数据集加载随机噪声"""
    noise_files = glob.glob(os.path.join(esc50_path, "*.wav"))
    if not noise_files:
        # Fallback to gaussian noise if dataset missing
        return np.random.randn(duration_samples)
    
    idx = np.random.randint(len(noise_files))
    try:
        fs_orig, data = wavfile.read(noise_files[idx])
    except:
        return np.random.randn(duration_samples)
        
    if len(data.shape) > 1:
        data = data[:, 0]
    data = data.astype(float) / 32768.0
    
    step = max(1, fs_orig // target_fs)
    data = data[::step]
    
    if len(data) < duration_samples:
        data = np.tile(data, int(np.ceil(duration_samples / len(data))))
    
    start = np.random.randint(0, max(1, len(data) - duration_samples))
    return data[start:start + duration_samples]

def run_esc50_comparison():
    print("=" * 60)
    print("ESC-50 Real-World Noise Comparison (4 Algorithms)")
    print("=" * 60)
    
    esc50_path = "datasets/esc50/audio"
    
    # 1. 初始化各算法
    print("Initializing Algorithms...")
    
    # ML
    rf_classifier = EnhancedClassifier()
    rf_classifier.train(samples_per_key=200)
    
    # MUSIC
    music = MusicDetector(fs=config.fs, n_elements=80, n_signals=4)
    
    # Adaptive (需初始化)
    adaptive = AdaptiveDetector()
    adaptive.initialize()
    
    # 测试参数
    snr_range = np.arange(-20, 16, 5)
    iterations = 50 # 略微减少次数以节省时间
    
    # 自适应需要长信号 (1s)，其他固定 200ms
    dur_std = 0.2
    dur_long = 1.0
    
    # 结果容器
    acc_goertzel = []
    acc_rf = []
    acc_music = []
    acc_adaptive = []
    
    for snr in snr_range:
        c_g = 0
        c_rf = 0
        c_m = 0
        c_a = 0
        
        for _ in range(iterations):
            key = np.random.choice(config.keys)
            
            # 生成 1s 长信号供自适应使用
            clean_long = dsp.generate_dtmf(key, snr_db=None, duration=dur_long)
            noise_long = load_esc50_noise(esc50_path, len(clean_long))
            
            # 混合噪声
            sig_power = np.mean(clean_long**2)
            noise_power = np.mean(noise_long**2)
            desired_noise_power = sig_power / (10**(snr/10))
            if noise_power > 0:
                noise_long = noise_long * np.sqrt(desired_noise_power / noise_power)
            
            sig_long_noisy = clean_long + noise_long
            
            # 截取 200ms 供标准算法使用
            sig_std_noisy = sig_long_noisy[:int(dur_std * config.fs)]
            
            # --- 检测 ---
            
            # 1. Goertzel (200ms)
            if dsp.identify_key(sig_std_noisy) == key:
                c_g += 1
                
            # 2. Random Forest (200ms)
            if rf_classifier.predict(sig_std_noisy) == key:
                c_rf += 1
                
            # 3. MUSIC (200ms)
            # MUSIC 容易崩溃，加 try-except
            try:
                pred_m, _ = music.detect(sig_std_noisy)
                if pred_m == key:
                    c_m += 1
            except:
                pass
                
            # 4. Adaptive (Variable Time, max 1s)
            try:
                pred_a, _ = adaptive.detect(sig_long_noisy)
                if pred_a == key:
                    c_a += 1
            except:
                pass
        
        acc_goertzel.append(c_g / iterations)
        acc_rf.append(c_rf / iterations)
        acc_music.append(c_m / iterations)
        acc_adaptive.append(c_a / iterations)
        
        print(f"SNR={snr:3d}dB | G:{acc_goertzel[-1]:.0%} | RF:{acc_rf[-1]:.0%} | MU:{acc_music[-1]:.0%} | AD:{acc_adaptive[-1]:.0%}")
    
    # 绘图
    plt.figure(figsize=(10, 6))
    plt.plot(snr_range, acc_goertzel, 'b-o', label='Goertzel (200ms)')
    plt.plot(snr_range, acc_rf, 'g-s', label='Random Forest (200ms)')
    plt.plot(snr_range, acc_music, 'm-x', label='MUSIC (200ms)')
    plt.plot(snr_range, acc_adaptive, 'r-^', label='Adaptive (Var-Time)', linewidth=2)
    
    plt.xlabel('SNR (dB)')
    plt.ylabel('Accuracy')
    plt.title('Real-World Noise (ESC-50) Robustness Comparison')
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.ylim(0, 1.05)
    
    out_path = os.path.join(config.IMG_DIR, 'esc50_noise_comparison.png')
    plt.savefig(out_path, dpi=150)
    print(f"\nPlot saved to {out_path}")

if __name__ == "__main__":
    run_esc50_comparison()
