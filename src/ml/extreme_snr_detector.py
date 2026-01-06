"""
extreme_snr_detector.py
极端低 SNR 检测算法 (-30dB 到 -15dB)
"""
import numpy as np
from collections import Counter
from ..core import config, dsp


class ExtremeSNRDetector:
    """
    专为极端低 SNR 环境设计的 DTMF 检测器
    使用多帧投票 + 能量积累 + 相关检测
    """
    
    def __init__(self, frame_length=0.1, hop_length=0.05, min_votes=3):
        """
        :param frame_length: 每帧长度 (秒)
        :param hop_length: 帧移 (秒)
        :param min_votes: 最少需要的投票数
        """
        self.frame_length = frame_length
        self.hop_length = hop_length
        self.min_votes = min_votes
        
        # 预计算理想 DTMF 模板（用于相关检测）
        self.templates = {}
        for key in config.keys:
            self.templates[key] = self._generate_template(key)
    
    def _generate_template(self, key, duration=0.1):
        """生成理想 DTMF 模板"""
        fL, fH = config.freq_map[key]
        t = np.linspace(0, duration, int(config.fs * duration), endpoint=False)
        template = np.sin(2 * np.pi * fL * t) + np.sin(2 * np.pi * fH * t)
        # 归一化
        template = template / np.sqrt(np.sum(template**2))
        return template
    
    def _goertzel_energy_vector(self, signal):
        """计算 7 个频点的能量向量"""
        all_freqs = config.low_freqs + config.high_freqs
        energies = [dsp.goertzel(signal, f) for f in all_freqs]
        return np.array(energies)
    
    def _correlation_detect(self, signal):
        """使用互相关检测"""
        best_key = None
        best_corr = -1
        
        for key, template in self.templates.items():
            # 裁剪信号长度以匹配模板
            sig_trimmed = signal[:len(template)]
            if len(sig_trimmed) < len(template):
                continue
            
            # 归一化信号
            sig_norm = sig_trimmed / (np.sqrt(np.sum(sig_trimmed**2)) + 1e-10)
            
            # 计算相关系数
            corr = np.abs(np.dot(sig_norm, template))
            
            if corr > best_corr:
                best_corr = corr
                best_key = key
        
        return best_key, best_corr
    
    def detect(self, signal, method='vote'):
        """
        极端 SNR 检测
        :param signal: 输入信号
        :param method: 'vote' | 'accumulate' | 'correlation'
        :return: (predicted_key, confidence)
        """
        if method == 'vote':
            return self._multi_frame_vote(signal)
        elif method == 'accumulate':
            return self._energy_accumulation(signal)
        elif method == 'correlation':
            return self._correlation_detect(signal)
        else:
            return self._multi_frame_vote(signal)
    
    def _multi_frame_vote(self, signal):
        """多帧投票法"""
        frame_samples = int(self.frame_length * config.fs)
        hop_samples = int(self.hop_length * config.fs)
        
        votes = []
        n_frames = 0
        
        for start in range(0, len(signal) - frame_samples + 1, hop_samples):
            frame = signal[start:start + frame_samples]
            key = dsp.identify_key(frame)
            if key:
                votes.append(key)
            n_frames += 1
        
        if not votes:
            return None, 0.0
        
        # 投票
        vote_count = Counter(votes)
        winner, count = vote_count.most_common(1)[0]
        confidence = count / n_frames
        
        return winner, confidence
    
    def _energy_accumulation(self, signal):
        """能量累积法：对整个信号进行能量累积"""
        # 使用整个信号长度
        l_powers = [dsp.goertzel(signal, f) for f in config.low_freqs]
        h_powers = [dsp.goertzel(signal, f) for f in config.high_freqs]
        
        # 找最大能量点
        best_l = config.low_freqs[np.argmax(l_powers)]
        best_h = config.high_freqs[np.argmax(h_powers)]
        
        # 计算置信度
        sorted_l = sorted(l_powers, reverse=True)
        sorted_h = sorted(h_powers, reverse=True)
        conf = min(sorted_l[0] / (sorted_l[1] + 1e-10),
                   sorted_h[0] / (sorted_h[1] + 1e-10)) / 10
        conf = min(conf, 1.0)
        
        for key, (fL, fH) in config.freq_map.items():
            if fL == best_l and fH == best_h:
                return key, conf
        
        return None, 0.0


def test_extreme_snr():
    """测试极端 SNR 环境下各方法的性能"""
    print("=" * 70)
    print("Extreme Low SNR Detection Test (-30dB to -15dB)")
    print("=" * 70)
    
    detector = ExtremeSNRDetector(frame_length=0.1, hop_length=0.03)
    
    snr_range = [-30, -25, -20, -15]
    iterations = 100
    # 使用更长的信号 (500ms) 以增加能量积累
    test_duration = 0.5
    
    print(f"\nSignal Duration: {test_duration*1000:.0f}ms")
    print(f"Frame Length: {detector.frame_length*1000:.0f}ms, Hop: {detector.hop_length*1000:.0f}ms")
    print()
    print(f"{'SNR':>6} | {'Goertzel':>10} | {'Vote':>10} | {'Accum':>10} | {'Corr':>10} | {'Best':>10}")
    print("-" * 75)
    
    for snr in snr_range:
        results = {'goertzel': 0, 'vote': 0, 'accumulate': 0, 'correlation': 0}
        
        for _ in range(iterations):
            key = np.random.choice(config.keys)
            signal = dsp.generate_dtmf(key, snr_db=snr, duration=test_duration)
            
            # 标准 Goertzel
            if dsp.identify_key(signal) == key:
                results['goertzel'] += 1
            
            # 多帧投票
            pred, _ = detector.detect(signal, method='vote')
            if pred == key:
                results['vote'] += 1
            
            # 能量累积
            pred, _ = detector.detect(signal, method='accumulate')
            if pred == key:
                results['accumulate'] += 1
            
            # 相关检测
            pred, _ = detector.detect(signal, method='correlation')
            if pred == key:
                results['correlation'] += 1
        
        # 计算准确率
        accs = {k: v/iterations for k, v in results.items()}
        best = max(accs, key=accs.get)
        
        print(f"{snr:>5}dB | {accs['goertzel']:>9.1%} | {accs['vote']:>9.1%} | "
              f"{accs['accumulate']:>9.1%} | {accs['correlation']:>9.1%} | {best:>10}")
    
    print("-" * 75)


if __name__ == "__main__":
    test_extreme_snr()
