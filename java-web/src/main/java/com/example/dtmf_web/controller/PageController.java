package com.example.dtmf_web.controller;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

/**
 * 页面控制器 - 负责返回JSP视图
 */
@Controller
public class PageController {

    /**
     * 首页 - DTMF信号处理实验演示系统
     */
    @GetMapping("/")
    public String index(Model model) {
        model.addAttribute("title", "DTMF 信号处理实验演示系统");
        model.addAttribute("version", "2.0");
        return "index";
    }

    /**
     * 实验模式页面
     */
    @GetMapping("/experiment")
    public String experiment(Model model) {
        model.addAttribute("title", "实验模式 - DTMF");
        return "experiment";
    }

    /**
     * 电话模式页面
     */
    @GetMapping("/phone")
    public String phone(Model model) {
        model.addAttribute("title", "电话模式 - DTMF");
        return "phone";
    }

    /**
     * 音频分析页面
     */
    @GetMapping("/analyze")
    public String analyze(Model model) {
        model.addAttribute("title", "音频分析 - DTMF");
        return "analyze";
    }
}
