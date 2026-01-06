import numpy as np
import matplotlib.pyplot as plt
import os
import subprocess
from scipy.io import wavfile
from ..core import config
from ..core import dsp

def save_wav(path, rate, data):
    """保存 WAV 文件，确保转换为 int16"""
    scaled = (data * 32767 / np.max(np.abs(data))).astype(np.int16)
    wavfile.write(path, rate, scaled)

def plot_accuracy_curve(snr_vals, acc_vals):
    plt.figure(figsize=(10, 6))
    plt.plot(snr_vals, acc_vals, marker='o', linestyle='-', color='b')
    plt.title('DTMF Recognition Accuracy vs SNR')
    plt.xlabel('SNR (dB)')
    plt.ylabel('Accuracy')
    plt.grid(True)
    out_path = os.path.join(config.IMG_DIR, 'dtmf_accuracy_curve.png')
    plt.savefig(out_path)
    print(f"Saved: {out_path}")

def plot_spectrum(key='5'):
    sig_test = dsp.generate_dtmf(key)
    n = len(sig_test)
    Y = np.fft.fft(sig_test) / n
    frq = (np.arange(n) * config.fs / n)[:n//2]
    
    plt.figure(figsize=(10, 5))
    plt.plot(frq, abs(Y[:n//2]), 'r')
    plt.title(f'Frequency Spectrum of DTMF Key {key}')
    plt.xlabel('Frequency (Hz)')
    plt.xlim(0, 2000)
    plt.grid(True)
    out_path = os.path.join(config.IMG_DIR, 'dtmf_spectrum.png')
    plt.savefig(out_path)
    print(f"Saved: {out_path}")

def plot_goertzel_energy(key='5'):
    sig_test = dsp.generate_dtmf(key)
    all_targets = config.low_freqs + config.high_freqs
    powers = [dsp.goertzel(sig_test, f) for f in all_targets]
    
    plt.figure(figsize=(10, 5))
    plt.bar([str(f) for f in all_targets], powers, color='green')
    plt.title(f'Goertzel Energy Distribution for Key {key}')
    plt.xlabel('Target Frequencies (Hz)')
    plt.ylabel('Detected Power')
    plt.grid(True, axis='y', alpha=0.3)
    out_path = os.path.join(config.IMG_DIR, 'dtmf_goertzel_test.png')
    plt.savefig(out_path)
    print(f"Saved: {out_path}")

def generate_spectrogram_ffmpeg():
    print("Simulating sequence dialing and generating spectrogram with FFmpeg...")
    sequence = ['1', '2', '3', '4', '5', '6']
    full_signal = []
    for k in sequence:
        # 每一位按键信号 + 间隔
        s = dsp.generate_dtmf(k, snr_db=30)
        full_signal.append(s)
        full_signal.append(np.zeros(int(config.fs * 0.05)))
    
    final_audio = np.concatenate(full_signal)
    wav_path = os.path.join(config.WAV_DIR, 'dial_sequence.wav')
    save_wav(wav_path, config.fs, final_audio)
    
    spectro_path = os.path.join(config.IMG_DIR, 'dtmf_spectrogram.png')
    ffmpeg_cmd = [
        'ffmpeg', '-y', '-i', wav_path,
        '-lavfi', 'showspectrumpic=s=1024x512:mode=combined:color=rainbow',
        spectro_path
    ]
    subprocess.run(ffmpeg_cmd)
    print(f"Spectrogram generated: {spectro_path}")

def generate_waveform_ffmpeg(key='5'):
    print("Generating Waveform Plot with FFmpeg...")
    sig_test = dsp.generate_dtmf(key)
    wave_wav_path = os.path.join(config.WAV_DIR, 'temp_wave.wav')
    # 使用完整信号，避免样本过少导致 FFmpeg 绘图失败
    save_wav(wave_wav_path, config.fs, sig_test)
    
    waveform_path = os.path.join(config.IMG_DIR, 'dtmf_waveform.png')
    ffmpeg_cmd = [
        'ffmpeg', '-y', '-i', wave_wav_path,
        '-lavfi', 'showwavespic=s=1024x400:colors=cyan|white:split_channels=1',
        '-frames:v', '1',
        waveform_path
    ]
    subprocess.run(ffmpeg_cmd)
    if os.path.exists(wave_wav_path): os.remove(wave_wav_path)
    print(f"Waveform generated: {waveform_path}")

def generate_noise_comparison_ffmpeg(key='5'):
    print("Generating Noise Comparison Plot with FFmpeg...")
    # 增加到 200ms (0.2s)
    clean_sig = dsp.generate_dtmf(key, duration=0.2)
    noisy_sig = dsp.generate_dtmf(key, snr_db=-5, duration=0.2)
    
    path_clean = os.path.join(config.WAV_DIR, 'temp_clean.wav')
    path_noisy = os.path.join(config.WAV_DIR, 'temp_noisy.wav')
    save_wav(path_clean, config.fs, clean_sig)
    save_wav(path_noisy, config.fs, noisy_sig)
    
    noise_comp_path = os.path.join(config.IMG_DIR, 'dtmf_noise_comparison.png')
    ffmpeg_cmd = [
        'ffmpeg', '-y',
        '-i', path_clean,
        '-i', path_noisy,
        '-filter_complex',
        '[0:a]showwavespic=s=1024x300:colors=cyan:scale=lin[v0];'
        '[1:a]showwavespic=s=1024x300:colors=orange:scale=lin[v1];'
        '[v0][v1]vstack=inputs=2[out]',
        '-map', '[out]',
        noise_comp_path
    ]
    subprocess.run(ffmpeg_cmd)
    for f in [path_clean, path_noisy]:
        if os.path.exists(f): os.remove(f)
    print(f"Noise comparison generated: {noise_comp_path}")
