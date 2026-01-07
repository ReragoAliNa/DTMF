package com.example.dtmf_web.controller;

import com.example.dtmf_web.service.DtmfService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/dtmf")
@CrossOrigin(origins = "*")
public class DtmfController {

    @Autowired
    private DtmfService dtmfService;

    // 运行实验 (支持噪声类型和频率偏移)
    @GetMapping("/test")
    public Map<String, Object> test(
            @RequestParam char key,
            @RequestParam double snr,
            @RequestParam(defaultValue = "false") boolean adaptive,
            @RequestParam(defaultValue = "GAUSSIAN") String noiseType,
            @RequestParam(defaultValue = "0") double freqOffset) {
        return dtmfService.runExperiment(key, snr, adaptive, noiseType, freqOffset);
    }

    // 对比实验 (支持噪声类型和频率偏移)
    @GetMapping("/compare")
    public Map<String, Object> compare(
            @RequestParam char key,
            @RequestParam double snr,
            @RequestParam(defaultValue = "GAUSSIAN") String noiseType,
            @RequestParam(defaultValue = "0") double freqOffset) {
        return dtmfService.runComparison(key, snr, noiseType, freqOffset);
    }

    // ========== 电话模式 API ==========

    // 开始新的电话会话
    @PostMapping("/phone/start")
    public Map<String, Object> startPhoneSession() {
        return dtmfService.startPhoneSession();
    }

    // 按键并保存音频 (实时识别)
    @PostMapping("/phone/press")
    public Map<String, Object> pressKey(
            @RequestParam char key,
            @RequestParam(defaultValue = "0.2") double duration,
            @RequestParam(required = false) Double snr,
            @RequestParam(defaultValue = "GAUSSIAN") String noiseType,
            @RequestParam(defaultValue = "unknown") String source,
            @RequestBody(required = false) Map<String, Object> body) {

        // Extract waveform from body if present (for FPGA raw data)
        double[] fpgaWaveform = null;
        if (body != null && body.containsKey("waveform")) {
            @SuppressWarnings("unchecked")
            java.util.List<Number> waveformList = (java.util.List<Number>) body.get("waveform");
            fpgaWaveform = waveformList.stream().mapToDouble(Number::doubleValue).toArray();
        }

        return dtmfService.pressKeyAndSave(key, duration, snr, noiseType, source, fpgaWaveform);
    }

    // 结束电话会话
    @PostMapping("/phone/end")
    public Map<String, Object> endPhoneSession() {
        return dtmfService.endPhoneSession();
    }

    // 获取最新按键 (Polling)
    @GetMapping("/phone/last-key")
    public Map<String, Object> getLastKey(@RequestParam(defaultValue = "0") long since) {
        return dtmfService.getLastKey(since);
    }

    // 获取会话状态
    @GetMapping("/phone/status")
    public Map<String, Object> getSessionStatus() {
        return dtmfService.getSessionStatus();
    }

    // 列出所有保存的电话会话
    @GetMapping("/phone/sessions")
    public Map<String, Object> listSessions() {
        return dtmfService.listPhoneSessions();
    }

    // 分析指定会话,识别电话号码
    @GetMapping("/phone/analyze")
    public Map<String, Object> analyzeSession(
            @RequestParam String sessionName,
            @RequestParam(required = false) String duration) {
        return dtmfService.analyzePhoneSession(sessionName, duration);
    }

    // 删除指定会话
    @DeleteMapping("/phone/session")
    public Map<String, Object> deleteSession(@RequestParam String sessionName) {
        return dtmfService.deletePhoneSession(sessionName);
    }
}
