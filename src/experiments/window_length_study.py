"""
window_length_study.py
研究信号窗口长度对不同检测算法性能的影响
对比算法：Goertzel, Random Forest (ML), MUSIC
测试窗口：40ms, 100ms, 200ms
"""
import numpy as np
import matplotlib.pyplot as plt
import os
import sys

# 添加项目根目录到 path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from src.core import config, dsp
from src.core.music import MusicDetector
from src.ml.enhanced_classifier import EnhancedClassifier

def run_study():
    print("=" * 60)
    print("Signal Window Length vs Algorithm Accuracy Study")
    print("=" * 60)
    
    # 1. 准备模型
    print("Training ML Classifier...")
    ml_clf = EnhancedClassifier()
    ml_clf.train(samples_per_key=200) # 快速训练
    
    print("Initializing MUSIC...")
    # MUSIC 参数随长度变化，这里设个通用的
    music = MusicDetector(fs=config.fs, n_elements=50, n_signals=4)
    
    window_lengths = [0.04, 0.10, 0.20] # 40ms, 100ms, 200ms
    snr_range = range(-20, 11, 5) # -20, -15, ..., 10
    
    results = {} # {window_len: {algo: [acc]}}
    
    for length in window_lengths:
        print(f"\nTesting Window Length: {length*1000:.0f}ms")
        
        # MUSIC 需要调整子空间维数 (不能超过样本数)
        n_samples = int(length * config.fs)
        music_M = min(100, n_samples // 3)
        music.M = music_M
        
        res_g = []
        res_ml = []
        res_music = []
        
        for snr in snr_range:
            c_g = 0
            c_ml = 0
            c_music = 0
            iterations = 100
            
            for _ in range(iterations):
                key = np.random.choice(config.keys)
                sig = dsp.generate_dtmf(key, snr_db=snr, duration=length)
                
                # Goertzel
                if dsp.identify_key(sig) == key:
                    c_g += 1
                
                # ML
                if ml_clf.predict(sig) == key:
                    c_ml += 1
                    
                # MUSIC
                pred, _ = music.detect(sig)
                if pred == key:
                    c_music += 1
            
            res_g.append(c_g/iterations)
            res_ml.append(c_ml/iterations)
            res_music.append(c_music/iterations)
            print(f"  SNR={snr:3d}dB | G:{res_g[-1]:.0%} | ML:{res_ml[-1]:.0%} | MU:{res_music[-1]:.0%}")
            
        results[length] = {
            'Goertzel': res_g,
            'Random Forest': res_ml,
            'MUSIC': res_music
        }
    
    # === 绘图 ===
    fig, axes = plt.subplots(1, 3, figsize=(18, 5), sharey=True)
    
    for i, length in enumerate(window_lengths):
        ax = axes[i]
        dat = results[length]
        
        ax.plot(snr_range, dat['Goertzel'], 'b-o', label='Goertzel')
        ax.plot(snr_range, dat['Random Forest'], 'g-s', label='Random Forest')
        ax.plot(snr_range, dat['MUSIC'], 'r-^', label='MUSIC')
        
        ax.set_title(f'Window Length: {length*1000:.0f}ms')
        ax.set_xlabel('SNR (dB)')
        ax.grid(True, alpha=0.3)
        ax.set_ylim(0, 1.05)
        
        if i == 0:
            ax.set_ylabel('Accuracy')
            ax.legend(loc='lower right')
            
    plt.suptitle('Impact of Signal Duration on Detection Algorithms', fontsize=16)
    plt.tight_layout()
    
    out_path = os.path.join(config.IMG_DIR, 'window_length_study.png')
    plt.savefig(out_path, dpi=150)
    print(f"\nStudy plot saved to {out_path}")

if __name__ == "__main__":
    run_study()
