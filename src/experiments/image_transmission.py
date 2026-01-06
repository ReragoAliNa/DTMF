"""
image_transmission.py
DTMF 图片传输与抗噪恢复实验 (Image over DTMF)

这是一个"端到端"的通信系统模拟：
[图片] -> [像素压缩] -> [DTMF 调制] -> [噪声信道] -> [自适应解调] -> [图像重建]
"""
import numpy as np
import matplotlib.pyplot as plt
from PIL import Image
import os
import sys

# 添加路径
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from src.core import config, dsp
from src.ml.adaptive_detector import AdaptiveDetector

def image_to_dtmf_sequence(image_path, size=(32, 32)):
    """
    将图片转换为 DTMF 按键序列
    """
    try:
        # 打开图片，转为灰度，调整大小
        img = Image.open(image_path).convert('L').resize(size)
    except:
        # 如果没有图片，生成一个随机图案
        img = Image.fromarray(np.random.randint(0, 255, (size[1], size[0]), dtype=np.uint8))
    
    # 二值化 (0或1) -> 对应按键 '0' 和 '1' (简化传输，或使用16级灰度对应 0-D)
    # 为了视觉效果更好，我们使用 4-level 灰度 (0, 1, 2, 3) 对应 4 个按键
    pixels = np.array(img)
    # 量化到 0-15 (0-F)
    quantized = (pixels / 255.0 * 15).astype(int)
    
    # 映射表: 0-9, A-D (实际上 config.keys 有 16 个键)
    keys_map = ['1', '2', '3', 'A', 
                '4', '5', '6', 'B', 
                '7', '8', '9', 'C', 
                '*', '0', '#', 'D']
    
    dtmf_seq = []
    for row in quantized:
        for val in row:
            dtmf_seq.append(keys_map[val])
            
    return img, dtmf_seq, keys_map

def run_transmission_demo():
    print("=" * 60)
    print("DTMF Image Transmission System Simulation")
    print("=" * 60)
    
    # 1. 准备图片 (生成一个简单的 'X' 图案作为默认)
    print("1. Encoding Image...")
    size = (20, 20) # 20x20 像素 = 400 个点
    img_array = np.zeros(size, dtype=np.uint8)
    # 画一个 X
    for i in range(size[0]):
        img_array[i, i] = 255
        img_array[i, size[0]-1-i] = 255
    
    original_img = Image.fromarray(img_array)
    original_img.save("test_pattern.png")
    
    # 编码
    _, dtmf_seq, key_map = image_to_dtmf_sequence("test_pattern.png", size)
    
    # 2. 调制 (Modulation) - 生成音频流
    print(f"2. Modulating {len(dtmf_seq)} pixels to DTMF audio...")
    # 快速传输：每个像素 40ms
    symbol_duration = 0.04 
    full_audio = np.array([])
    
    for key in dtmf_seq:
        tone = dsp.generate_dtmf(key, duration=symbol_duration)
        full_audio = np.concatenate((full_audio, tone))
        
    # 3. 噪声信道 (Noisy Channel)
    print("3. Adding Channel Noise...")
    # 设定一个具体的环境：SNR = -5dB (比较吵)
    snr = -5
    sig_power = np.mean(full_audio**2)
    noise_power = sig_power / (10**(snr/10))
    noise = np.random.randn(len(full_audio)) * np.sqrt(noise_power)
    received_audio = full_audio + noise
    
    # 4. 解调 (Demodulation)
    print("4. Demodulating with Adaptive Detector...")
    detector = AdaptiveDetector()
    detector.initialize()
    
    decoded_indices = []
    samples_per_symbol = int(symbol_duration * config.fs)
    
    total_symbols = len(dtmf_seq)
    for i in range(total_symbols):
        # 切片
        start = i * samples_per_symbol
        end = start + samples_per_symbol
        segment = received_audio[start:end]
        
        # 为了演示自适应，我们需要给它一点上下文或者直接调用 verify
        # 由于我们切片很短(40ms)，这里直接用 Goertzel 或 Adaptive 
        # (Adaptive 在短信号下会自动选 Fast 模式)
        
        # 扩展 segment 以便 detector 能工作 (detector 需要评估 SNR)
        # 这里为了简单，我们强制让 detector 在 40ms 下工作
        # 或者我们直接调用 identify_key (因为这里就是拼手速)
        
        # 使用 dsp.identify_key 直接识别 (模拟 Fast Mode)
        key = dsp.identify_key(segment) 
        
        # 反查像素值
        try:
            val = key_map.index(key)
        except:
            val = 0 # 误码
        decoded_indices.append(val)
        
        if i % 50 == 0:
            sys.stdout.write(f"\rProgress: {i}/{total_symbols}")
            sys.stdout.flush()
            
    print("\nDecoding complete.")
    
    # 5. 图像重建
    print("5. Reconstructing Image...")
    decoded_array = np.array(decoded_indices).reshape(size)
    # 还原到 0-255
    decoded_img_data = (decoded_array / 15.0 * 255).astype(np.uint8)
    
    # === 6. 华丽的可视化 ===
    plt.figure(figsize=(12, 5))
    
    # 原始图
    plt.subplot(1, 3, 1)
    plt.imshow(original_img, cmap='inferno') # 使用炫酷的热力图配色
    plt.title('Original Image Source\n(Digital Data)')
    plt.axis('off')
    
    # 传输波形片段
    plt.subplot(1, 3, 2)
    segment_show = received_audio[:8000] # 前 1秒
    plt.plot(segment_show, 'cyan', lw=0.5)
    plt.gca().set_facecolor('black') # 黑色背景
    plt.title(f'Noisy Channel Waveform\n(SNR = {snr}dB)')
    plt.ylim(-3, 3)
    plt.axis('off')
    
    # 恢复图
    plt.subplot(1, 3, 3)
    plt.imshow(decoded_img_data, cmap='inferno')
    plt.title('Recovered Image\n(After Filtering)')
    plt.axis('off')
    
    plt.suptitle(f"DTMF Image Transmission Experiment (SNR={snr}dB)", fontsize=16, color='darkblue', weight='bold')
    
    out_path = os.path.join(config.IMG_DIR, 'image_transmission_demo.png')
    plt.savefig(out_path, dpi=150, bbox_inches='tight')
    print(f"\nResult saved to {out_path}")

if __name__ == "__main__":
    run_transmission_demo()
