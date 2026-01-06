"""
realistic_noise_test.py
使用更真实的噪声类型测试 CNN vs Goertzel
"""
import numpy as np
import matplotlib.pyplot as plt
import os
from ..core import config
from ..core import dsp


def add_impulse_noise(signal, impulse_rate=0.01, impulse_amplitude=3.0):
    """
    添加脉冲噪声（模拟电火花干扰）
    impulse_rate: 脉冲出现的概率
    impulse_amplitude: 脉冲幅度（相对于信号）
    """
    noisy = signal.copy()
    impulse_mask = np.random.random(len(signal)) < impulse_rate
    impulses = np.random.choice([-1, 1], size=len(signal)) * impulse_amplitude
    noisy[impulse_mask] += impulses[impulse_mask]
    return noisy


def add_pink_noise(signal, snr_db):
    """
    添加粉红噪声（1/f 噪声，低频能量更强）
    模拟真实环境噪声
    """
    n = len(signal)
    
    # 生成白噪声
    white = np.random.randn(n)
    
    # FFT 变换
    fft_white = np.fft.rfft(white)
    
    # 应用 1/f 滤波器（粉红化）
    freqs = np.fft.rfftfreq(n)
    freqs[0] = 1e-10  # 避免除零
    pink_filter = 1 / np.sqrt(freqs)
    pink_filter[0] = 0
    
    fft_pink = fft_white * pink_filter
    pink = np.fft.irfft(fft_pink, n)
    
    # 调整到目标 SNR
    signal_power = np.mean(signal**2)
    snr_linear = 10**(snr_db / 10)
    noise_power = signal_power / snr_linear
    current_power = np.mean(pink**2)
    
    if current_power > 0:
        pink = pink * np.sqrt(noise_power / current_power)
    
    return signal + pink


def add_voice_interference(signal, interference_level=0.5):
    """
    添加模拟语音干扰（随机多频率组合）
    这是 Goertzel 的"杀手"——因为语音可能恰好包含 DTMF 频率
    """
    t = np.linspace(0, config.duration, len(signal), endpoint=False)
    
    # 生成随机的语音模拟频率（在人声范围 100-3000Hz）
    num_components = np.random.randint(5, 15)
    voice = np.zeros_like(signal)
    
    for _ in range(num_components):
        freq = np.random.uniform(100, 3000)
        amplitude = np.random.uniform(0.1, 0.5)
        phase = np.random.uniform(0, 2*np.pi)
        voice += amplitude * np.sin(2 * np.pi * freq * t + phase)
    
    # 添加一些谐波（语音特征）
    fundamental = np.random.uniform(100, 300)  # 基频
    for harmonic in range(2, 8):
        voice += np.random.uniform(0.05, 0.2) * np.sin(2 * np.pi * fundamental * harmonic * t)
    
    return signal + voice * interference_level


def add_frequency_drift(signal, drift_hz=10):
    """
    模拟频率漂移（信道失真）
    drift_hz: 频率偏移量
    """
    # 这个比较复杂，简化处理：对信号进行轻微的时间拉伸/压缩
    stretch_factor = 1 + drift_hz / 1000  # 约 1% 的变化
    n_new = int(len(signal) / stretch_factor)
    indices = np.linspace(0, len(signal) - 1, n_new).astype(int)
    stretched = signal[indices]
    
    # 补齐长度
    if len(stretched) < len(signal):
        stretched = np.pad(stretched, (0, len(signal) - len(stretched)))
    else:
        stretched = stretched[:len(signal)]
    
    return stretched


def generate_dtmf_with_realistic_noise(key, noise_type='mixed', severity=0.5):
    """
    生成带有真实噪声的 DTMF 信号
    noise_type: 'impulse', 'pink', 'voice', 'drift', 'mixed'
    severity: 噪声严重程度 0-1
    """
    signal = dsp.generate_dtmf(key)
    
    if noise_type == 'impulse':
        return add_impulse_noise(signal, impulse_rate=0.02*severity, impulse_amplitude=2+3*severity)
    
    elif noise_type == 'pink':
        snr = 20 - 30 * severity  # severity=0 -> SNR=20dB, severity=1 -> SNR=-10dB
        return add_pink_noise(signal, snr)
    
    elif noise_type == 'voice':
        return add_voice_interference(signal, interference_level=0.3 + 0.7*severity)
    
    elif noise_type == 'drift':
        drifted = add_frequency_drift(signal, drift_hz=5 + 20*severity)
        # 也加一点白噪声
        return dsp.generate_dtmf(key, snr_db=15-10*severity)  # 用原始函数加噪
    
    elif noise_type == 'mixed':
        # 混合所有噪声类型
        sig = signal.copy()
        sig = add_impulse_noise(sig, impulse_rate=0.01*severity, impulse_amplitude=1+2*severity)
        sig = add_pink_noise(sig, snr_db=15-20*severity)
        sig = add_voice_interference(sig, interference_level=0.2*severity)
        return sig
    
    return signal


def run_realistic_noise_comparison():
    """
    在真实噪声环境下对比 Goertzel 和 CNN
    """
    from ..ml.spectrogram_cnn import SpectrogramCNNClassifier
    
    print("=" * 60)
    print("Realistic Noise Comparison: Goertzel vs CNN")
    print("=" * 60)
    
    # 用真实噪声数据重新训练 CNN
    print("\nStep 1: Training CNN with realistic noise data...")
    
    cnn = SpectrogramCNNClassifier()
    
    # 手动生成训练数据（包含各种噪声）
    X_train, y_train = [], []
    samples_per_key = 400
    
    print("Generating training data with realistic noise...")
    for key in config.keys:
        for _ in range(samples_per_key):
            noise_type = np.random.choice(['impulse', 'pink', 'voice', 'mixed'])
            severity = np.random.uniform(0, 1)
            signal = generate_dtmf_with_realistic_noise(key, noise_type, severity)
            spec = cnn._signal_to_features(signal)
            X_train.append(spec)
            y_train.append(cnn.key_to_idx[key])
    
    X_train = np.array(X_train)
    y_train = np.array(y_train)
    cnn.input_shape = X_train[0].shape
    
    # 训练
    from sklearn.model_selection import train_test_split
    X_tr, X_val, y_tr, y_val = train_test_split(X_train, y_train, test_size=0.2, random_state=42)
    cnn._train_pytorch(X_tr, y_tr, X_val, y_val, epochs=50)
    cnn.is_trained = True
    
    # 测试各种噪声类型
    print("\nStep 2: Testing with different noise types...")
    
    noise_types = ['impulse', 'pink', 'voice', 'mixed']
    severity_levels = np.linspace(0, 1, 11)
    iterations = 100
    
    results = {nt: {'goertzel': [], 'cnn': []} for nt in noise_types}
    
    for noise_type in noise_types:
        print(f"\n  Testing noise type: {noise_type}")
        for severity in severity_levels:
            g_correct, c_correct = 0, 0
            
            for _ in range(iterations):
                key = np.random.choice(config.keys)
                signal = generate_dtmf_with_realistic_noise(key, noise_type, severity)
                
                if dsp.identify_key(signal) == key:
                    g_correct += 1
                if cnn.predict(signal) == key:
                    c_correct += 1
            
            results[noise_type]['goertzel'].append(g_correct / iterations)
            results[noise_type]['cnn'].append(c_correct / iterations)
        
        print(f"    Goertzel avg: {np.mean(results[noise_type]['goertzel']):.1%}")
        print(f"    CNN avg:      {np.mean(results[noise_type]['cnn']):.1%}")
    
    # 绘图
    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    axes = axes.flatten()
    
    titles = {
        'impulse': 'Impulse Noise (Electrical Interference)',
        'pink': 'Pink Noise (Environmental)',
        'voice': 'Voice Interference (Talk-off Test)',
        'mixed': 'Mixed Realistic Noise'
    }
    
    for idx, noise_type in enumerate(noise_types):
        ax = axes[idx]
        ax.plot(severity_levels, results[noise_type]['goertzel'], 'b-o', 
                label='Goertzel', linewidth=2, markersize=6)
        ax.plot(severity_levels, results[noise_type]['cnn'], 'm-^', 
                label='CNN', linewidth=2, markersize=6)
        
        # 高亮 CNN 优势区域
        g_arr = np.array(results[noise_type]['goertzel'])
        c_arr = np.array(results[noise_type]['cnn'])
        ax.fill_between(severity_levels, g_arr, c_arr,
                        where=c_arr > g_arr,
                        alpha=0.3, color='purple', label='CNN advantage')
        
        ax.set_title(titles[noise_type], fontsize=12)
        ax.set_xlabel('Noise Severity (0=clean, 1=severe)')
        ax.set_ylabel('Accuracy')
        ax.legend(loc='lower left')
        ax.grid(True, alpha=0.3)
        ax.set_ylim(0, 1.05)
    
    plt.suptitle('DTMF Detection: Goertzel vs CNN in Realistic Noise', fontsize=14, y=1.02)
    plt.tight_layout()
    
    out_path = os.path.join(config.IMG_DIR, 'realistic_noise_comparison.png')
    plt.savefig(out_path, dpi=150, bbox_inches='tight')
    print(f"\nPlot saved: {out_path}")
    
    # 总结
    print("\n" + "=" * 60)
    print("SUMMARY: Average accuracy across all severity levels")
    print("=" * 60)
    for noise_type in noise_types:
        g_avg = np.mean(results[noise_type]['goertzel'])
        c_avg = np.mean(results[noise_type]['cnn'])
        winner = "CNN ✓" if c_avg > g_avg else "Goertzel ✓"
        print(f"  {noise_type:10s}: Goertzel={g_avg:.1%}, CNN={c_avg:.1%}  → {winner}")


if __name__ == "__main__":
    run_realistic_noise_comparison()
