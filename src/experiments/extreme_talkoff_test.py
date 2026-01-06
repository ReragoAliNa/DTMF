"""
extreme_talkoff_test.py
极端语音干扰测试 - Talk-off 是 Goertzel 的阿喀琉斯之踵
"""
import numpy as np
import matplotlib.pyplot as plt
import os
from ..core import config
from ..core import dsp


def generate_talkoff_signal():
    """
    生成"Talk-off"干扰信号
    这是一种恰好包含 DTMF 频率的语音模拟信号
    会导致 Goertzel 误识别
    """
    t = np.linspace(0, config.duration, int(config.fs * config.duration), endpoint=False)
    
    # 随机选择一个"假"按键的频率组合
    fake_key = np.random.choice(config.keys)
    fL, fH = config.freq_map[fake_key]
    
    # 生成包含这些频率的"语音"，但加上谐波和调制
    signal = np.zeros_like(t)
    
    # 基频 + 一些偏移
    signal += 0.5 * np.sin(2 * np.pi * (fL + np.random.uniform(-20, 20)) * t)
    signal += 0.5 * np.sin(2 * np.pi * (fH + np.random.uniform(-20, 20)) * t)
    
    # 加入谐波（真语音有谐波，DTMF 没有）
    for harmonic in [2, 3, 4]:
        signal += 0.15 * np.sin(2 * np.pi * fL * harmonic * t + np.random.uniform(0, 2*np.pi))
    
    # 加入其他随机频率（模拟语音的丰富频谱）
    for _ in range(5):
        f = np.random.uniform(200, 2000)
        signal += 0.2 * np.sin(2 * np.pi * f * t + np.random.uniform(0, 2*np.pi))
    
    # 幅度调制（语音的包络变化）
    envelope = 0.7 + 0.3 * np.sin(2 * np.pi * 5 * t)  # 5Hz 调制
    signal = signal * envelope
    
    return signal, fake_key


def run_talkoff_test():
    """
    Talk-off 测试：谁能更好地拒绝"假信号"
    """
    from ..ml.spectrogram_cnn import SpectrogramCNNClassifier
    
    print("=" * 60)
    print("Talk-off Test: Rejecting False DTMF Signals")
    print("=" * 60)
    
    # 训练 CNN（同时用真实 DTMF 和 talk-off 样本）
    print("\nTraining CNN with DTMF + Talk-off data...")
    
    cnn = SpectrogramCNNClassifier()
    X_train, y_train = [], []
    
    # 真实 DTMF 样本
    print("  Generating real DTMF samples...")
    for key in config.keys:
        for _ in range(200):
            snr = np.random.uniform(-10, 20)
            signal = dsp.generate_dtmf(key, snr_db=snr)
            spec = cnn._signal_to_features(signal)
            X_train.append(spec)
            y_train.append(cnn.key_to_idx[key])
    
    # 同时生成一些混淆样本用于训练
    print("  Generating confusing samples for robustness...")
    for key in config.keys:
        for _ in range(50):
            # 加入语音干扰的 DTMF
            signal = dsp.generate_dtmf(key)
            talkoff, _ = generate_talkoff_signal()
            mixed = signal + 0.3 * talkoff
            spec = cnn._signal_to_features(mixed)
            X_train.append(spec)
            y_train.append(cnn.key_to_idx[key])
    
    X_train = np.array(X_train)
    y_train = np.array(y_train)
    cnn.input_shape = X_train[0].shape
    
    from sklearn.model_selection import train_test_split
    X_tr, X_val, y_tr, y_val = train_test_split(X_train, y_train, test_size=0.2, random_state=42)
    cnn._train_pytorch(X_tr, y_tr, X_val, y_val, epochs=40)
    cnn.is_trained = True
    
    # 测试场景：DTMF + 不同强度的 Talk-off 干扰
    print("\nTesting: DTMF with Talk-off interference...")
    
    talkoff_levels = np.linspace(0, 2, 21)  # Talk-off 能量相对于 DTMF 的比例
    iterations = 100
    
    goertzel_acc = []
    cnn_acc = []
    
    for level in talkoff_levels:
        g_correct, c_correct = 0, 0
        
        for _ in range(iterations):
            true_key = np.random.choice(config.keys)
            dtmf_signal = dsp.generate_dtmf(true_key, snr_db=10)  # 清晰的 DTMF
            talkoff_signal, fake_key = generate_talkoff_signal()
            
            # 混合信号
            mixed = dtmf_signal + level * talkoff_signal
            
            # Goertzel 识别
            detected = dsp.identify_key(mixed)
            if detected == true_key:
                g_correct += 1
            
            # CNN 识别
            detected = cnn.predict(mixed)
            if detected == true_key:
                c_correct += 1
        
        goertzel_acc.append(g_correct / iterations)
        cnn_acc.append(c_correct / iterations)
        
        print(f"  Talk-off level {level:.1f}x: Goertzel={goertzel_acc[-1]:.1%}, CNN={cnn_acc[-1]:.1%}")
    
    # 绘图
    plt.figure(figsize=(12, 7))
    plt.plot(talkoff_levels, goertzel_acc, 'b-o', label='Goertzel', linewidth=2, markersize=6)
    plt.plot(talkoff_levels, cnn_acc, 'm-^', label='CNN', linewidth=2, markersize=6)
    
    # 填充优势区域
    g_arr, c_arr = np.array(goertzel_acc), np.array(cnn_acc)
    plt.fill_between(talkoff_levels, g_arr, c_arr,
                     where=c_arr > g_arr,
                     alpha=0.3, color='purple', label='CNN wins')
    plt.fill_between(talkoff_levels, g_arr, c_arr,
                     where=g_arr > c_arr,
                     alpha=0.3, color='blue', label='Goertzel wins')
    
    plt.axhline(y=0.95, color='orange', linestyle=':', alpha=0.7)
    plt.xlabel('Talk-off Interference Level (relative to DTMF)', fontsize=12)
    plt.ylabel('Accuracy', fontsize=12)
    plt.title('Talk-off Test: DTMF Detection Under Voice-like Interference', fontsize=14)
    plt.legend(loc='lower left', fontsize=10)
    plt.grid(True, alpha=0.3)
    plt.ylim(0, 1.05)
    
    out_path = os.path.join(config.IMG_DIR, 'talkoff_test.png')
    plt.savefig(out_path, dpi=150, bbox_inches='tight')
    print(f"\nPlot saved: {out_path}")
    
    # 总结
    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    
    # 找到准确率下降到 90% 以下的拐点
    g_threshold = next((i for i, acc in enumerate(goertzel_acc) if acc < 0.9), len(goertzel_acc))
    c_threshold = next((i for i, acc in enumerate(cnn_acc) if acc < 0.9), len(cnn_acc))
    
    print(f"Goertzel drops below 90% at: Talk-off level {talkoff_levels[g_threshold] if g_threshold < len(talkoff_levels) else '>2.0'}x")
    print(f"CNN drops below 90% at: Talk-off level {talkoff_levels[c_threshold] if c_threshold < len(talkoff_levels) else '>2.0'}x")
    
    avg_g = np.mean(goertzel_acc)
    avg_c = np.mean(cnn_acc)
    print(f"\nOverall average: Goertzel={avg_g:.1%}, CNN={avg_c:.1%}")
    
    if avg_c > avg_g:
        print(f"\n🎉 CNN outperforms Goertzel by {(avg_c - avg_g)*100:.1f}% on Talk-off test!")
    else:
        print(f"\nGoertzel still wins by {(avg_g - avg_c)*100:.1f}%")


if __name__ == "__main__":
    run_talkoff_test()
