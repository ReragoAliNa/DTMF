"""
adaptive_detector.py
自适应时域积分检测系统 (Adaptive Variable Integration Time Detector)

设计理念：
- 传统的固定时长检测在低 SNR 下能量积累不足，在高 SNR 下又浪费时间。
- 本设计采用"渐进式检测"策略：
  1. 先用超短窗口 (40ms) 进行快速扫描
  2. 若信噪比低或置信度不足，自动延长积分时间 (200ms)
  3. 在极端环境下，启用深度积分模式 (1000ms)
- 意义：实现了响应速度与鲁棒性的自适应平衡，是真正的工程优化。
"""
import numpy as np
import matplotlib.pyplot as plt
from ..core import config, dsp

class AdaptiveDetector:
    def __init__(self, quick_snr_threshold=10, standard_snr_threshold=0):
        """
        :param quick_snr_threshold: 允许快速模式的最低 SNR (dB)
        :param standard_snr_threshold: 允许标准模式的最低 SNR (dB)
        """
        self.quick_snr_threshold = quick_snr_threshold  # >10dB 用快速模式 (40ms)
        self.standard_snr_threshold = standard_snr_threshold # >0dB 用标准模式 (200ms)
        self.is_ready = True
    
    def initialize(self):
        print("Initializing Variable Integration Time Detector...")
        print("Ready.")
        
    def estimate_quality(self, signal):
        """
        估计信号质量 (SNR 和 峰值显著性)
        与 Java 端 DtmfService.estimateQuality 完全一致
        
        使用频域方法：计算 DTMF 双频峰值能量与噪声能量的比值
        """
        all_freqs = config.low_freqs + config.high_freqs  # 8个DTMF频率
        energies = [dsp.goertzel(signal, f) for f in all_freqs]
        total_energy = sum(energies)
        
        # 找出低频组最大值 (索引 0-3)
        max_low = max(energies[:4])
        max_low_idx = energies[:4].index(max_low)
        
        # 找出高频组最大值 (索引 4-7)
        max_high = max(energies[4:])
        max_high_idx = 4 + energies[4:].index(max_high)
        
        # 信号能量 = 两个主频能量之和
        signal_energy = max_low + max_high
        
        # 噪声能量 = 其他6个频率的能量之和
        noise_energy = sum(e for i, e in enumerate(energies) 
                          if i != max_low_idx and i != max_high_idx)
        noise_energy = max(noise_energy, 1e-10)  # 避免除零
        
        # SNR = 10 * log10(信号能量 / 噪声能量)
        snr = 10 * np.log10(signal_energy / noise_energy)
        
        # 峰值比：双峰能量占总能量的比例
        peak_ratio = signal_energy / (total_energy + 1e-10)
            
        return snr, peak_ratio

    def detect(self, long_signal, verbose=False):
        """
        基于 ΔSNR 增益公式的自适应动态时长检测
        
        核心逻辑（与 Java 端 DtmfService.adaptiveDetect 完全一致）：
        ΔSNR = 10 * log10(T2/T1)
        => T2 = T1 * 10^((TARGET_SNR - current_snr) / 10)
        
        :param long_signal: 输入的长信号缓存 (最长 1s)
        :return: (result_key, mode_string)
        """
        fs = config.fs
        
        # 常量定义（与 Java 端一致）
        MIN_DURATION = 0.04   # 最短 40ms
        MAX_DURATION = 1.0    # 最长 1000ms
        TARGET_SNR = 5.0      # 目标 SNR (dB)
        BASE_DURATION = 0.04  # 基准时长 40ms
        
        # 1. 用短窗口(40ms)快速估算当前 SNR
        len_quick = int(MIN_DURATION * fs)
        if len(long_signal) < len_quick:
            return dsp.identify_key(long_signal), "Insufficient"
            
        sig_quick = long_signal[:len_quick]
        current_snr, peak_ratio = self.estimate_quality(sig_quick)
        
        if verbose:
            print(f"  [Probe 40ms] SNR: {current_snr:.1f}dB, PeakRatio: {peak_ratio:.1f}")
        
        # 2. 计算所需的时长
        if current_snr >= TARGET_SNR:
            # SNR 足够，使用最短时长
            required_duration = MIN_DURATION
        else:
            # 需要延长积分时间
            # SNR 增益需要: TARGET_SNR - currentSnr
            # 时间比例: 10^((TARGET_SNR - currentSnr) / 10)
            snr_gap_db = TARGET_SNR - current_snr
            time_ratio = 10 ** (snr_gap_db / 10.0)
            required_duration = BASE_DURATION * time_ratio
            
            # 限制在最大时长范围内
            required_duration = min(required_duration, MAX_DURATION)
        
        # 确保时长在有效范围内
        required_duration = max(MIN_DURATION, min(MAX_DURATION, required_duration))
        
        # 限制不超过实际信号长度
        max_available = len(long_signal) / fs
        required_duration = min(required_duration, max_available)
        
        if verbose:
            print(f"  [Adaptive] Required: {required_duration*1000:.0f}ms")
        
        # 3. 截取所需时长的信号并进行检测
        len_final = int(required_duration * fs)
        sig_final = long_signal[:len_final]
        result = dsp.identify_key(sig_final)
        
        # 4. 生成模式描述
        duration_ms = int(required_duration * 1000)
        if duration_ms <= 50:
            mode = f"Fast({duration_ms}ms)"
        elif duration_ms <= 250:
            mode = f"Standard({duration_ms}ms)"
        else:
            mode = f"Deep({duration_ms}ms)"
        
        return result, mode


def run_adaptive_demo():
    """
    演示自适应时间积分的效果
    """
    print("=" * 70)
    print("Adaptive Variable Integration Time Analysis")
    print("System balances Response Time vs Accuracy automatically")
    print("=" * 70)
    
    detector = AdaptiveDetector(quick_snr_threshold=10, standard_snr_threshold=0) # Tighter thresholds
    detector.initialize()
    
    test_cases = [
        ("Excellent", 30),
        ("Good", 15),
        ("Fair", 5),
        ("Poor", -5),
        ("Critical", -15),
        ("Extreme", -25)
    ]
    
    print(f"\n{'Condition':<15} | {'Real SNR':<10} | {'Mode Selected':<18} | {'Result':<6}")
    print("-" * 65)
    
    for label, snr in test_cases:
        key = '5'
        # 生成 1秒长的信号供自适应调用
        long_signal = dsp.generate_dtmf(key, snr_db=snr, duration=1.0)
        
        result, mode = detector.detect(long_signal, verbose=False)
        match = "PASS" if result == key else "FAIL"
        
        print(f"{label:<15} | {snr:>3}dB       | {mode:<18} | {match:<6}")
    print("-" * 65)


def run_comparison_experiment():
    """
    对比实验：固定 200ms vs 自适应
    """
    print("\nRunning Performance Comparison...")
    detector = AdaptiveDetector()
    snr_range = range(-25, 21, 5)
    
    # 存储结果
    acc_std = [] # 固定 200ms (传统)
    acc_apt = [] # 自适应
    avg_dur = [] # 自适应平均耗时
    
    for snr in snr_range:
        c_std = 0
        c_apt = 0
        dur_sum = 0
        iters = 100
        
        for _ in range(iters):
            key = np.random.choice(config.keys)
            # 生成长信号
            sig_long = dsp.generate_dtmf(key, snr_db=snr, duration=1.0)
            
            # 1. 传统方法 (强制截取 200ms)
            sig_200 = sig_long[:int(0.2*config.fs)]
            if dsp.identify_key(sig_200) == key:
                c_std += 1
                
            # 2. 自适应方法
            res, mode = detector.detect(sig_long)
            if res == key:
                c_apt += 1
            
            # 记录耗时
            if "40ms" in mode: dur_sum += 0.04
            elif "200ms" in mode: dur_sum += 0.2
            else: dur_sum += 1.0
            
        acc_std.append(c_std/iters)
        acc_apt.append(c_apt/iters)
        avg_dur.append(dur_sum/iters)
        
        print(f"SNR={snr:3d}dB | Std(200ms):{acc_std[-1]:.0%} | Adapt:{acc_apt[-1]:.0%} | Time:{avg_dur[-1]*1000:.0f}ms")

    # 绘制双轴图
    fig, ax1 = plt.subplots(figsize=(10, 6))
    
    ax1.plot(snr_range, acc_std, 'b--o', label='Standard (Fixed 200ms)')
    ax1.plot(snr_range, acc_apt, 'g-^', label='Adaptive (Variable Time)', linewidth=2)
    ax1.set_xlabel('SNR (dB)')
    ax1.set_ylabel('Accuracy', color='k')
    ax1.set_ylim(0, 1.05)
    ax1.legend(loc='upper left')
    ax1.grid(True, alpha=0.3)
    
    ax2 = ax1.twinx()
    ax2.plot(snr_range, [d*1000 for d in avg_dur], 'r:', label='Avg Detection Time', linewidth=2)
    ax2.set_ylabel('Time Cost (ms)', color='r')
    ax2.set_ylim(0, 1100)
    ax2.legend(loc='center right')
    
    plt.title('Adaptive Time-Integration Performance Analysis')
    out_path = config.IMG_DIR + '/adaptive_time_analysis.png'
    plt.savefig(out_path)
    print(f"\nPlot saved to {out_path}")

if __name__ == "__main__":
    run_comparison_experiment()
