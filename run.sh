#!/bin/bash

# DTMF Project Master Run Script
# 双音多频信号处理项目主运行脚本

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

show_usage() {
    echo -e "${BLUE}DTMF Signal Synthesis and Recognition Project${NC}"
    echo "Usage: ./run.sh [command]"
    echo ""
    echo "Commands:"
    echo "  gui       Launch the Java Web GUI (Interactive demo)"
    echo "  bridge    Start the FPGA-to-Java serial bridge (Python)"
    echo "  all       Start both GUI and Bridge together"
    echo "  stop      Stop the running GUI server (kill port 8081)"
    echo "  sim       Run basic Python simulation (Generates plots in images/)"
    echo "  exp       Run performance comparison experiments"
    echo "  report    Build the LaTeX report (PDF)"
    echo "  clean     Remove temporary files and build artifacts"
    echo "  help      Show this help message"
}

stop_gui() {
    echo -e "${YELLOW}Stopping any process on port 8081...${NC}"
    PID=$(lsof -ti:8081 2>/dev/null)
    if [ -n "$PID" ]; then
        kill -9 $PID 2>/dev/null
        echo -e "${GREEN}Process $PID killed.${NC}"
    else
        echo -e "${BLUE}No process running on port 8081.${NC}"
    fi
}

run_gui() {
    # 自动检查并关闭占用端口的进程
    PID=$(lsof -ti:8081 2>/dev/null)
    if [ -n "$PID" ]; then
        echo -e "${YELLOW}Port 8081 is in use (PID: $PID). Stopping it...${NC}"
        kill -9 $PID 2>/dev/null
        sleep 1
    fi
    
    echo -e "${GREEN}Starting Java Web GUI on http://localhost:8081...${NC}"
    cd java-web
    ./mvnw spring-boot:run
}

run_bridge() {
    # Kill any existing bridge process
    pkill -f fpga_uart_bridge.py 2>/dev/null
    sleep 0.5
    
    echo -e "${GREEN}Starting FPGA-to-Java Serial Bridge...${NC}"
    
    # Check if venv exists
    if [ ! -d "venv" ]; then
        echo -e "${RED}Python venv not found. Creating...${NC}"
        python3 -m venv venv
        source venv/bin/activate
        pip install pyserial requests numpy
    fi
    
    ./venv/bin/python ./bridge/fpga_uart_bridge.py
}

run_all() {
    echo -e "${BLUE}Starting all services...${NC}"
    
    # Start GUI in background
    run_gui &
    GUI_PID=$!
    
    # Wait a bit for GUI to start
    sleep 3
    
    # Start bridge in foreground
    run_bridge
    
    # When bridge exits, kill GUI
    kill $GUI_PID 2>/dev/null
}

run_sim() {
    echo -e "${GREEN}Running Basic Python Simulation...${NC}"
    export PYTHONPATH=$PYTHONPATH:.
    venv/bin/python3 -m src.main
}

run_exp() {
    echo -e "${GREEN}Running Performance Comparison Experiments...${NC}"
    export PYTHONPATH=$PYTHONPATH:.
    echo "1. Realistic Noise Test:"
    venv/bin/python3 -m src.experiments.realistic_noise_test
    echo "2. Extreme Talk-off Test:"
    venv/bin/python3 -m src.experiments.extreme_talkoff_test
}

build_report() {
    echo -e "${GREEN}Building LaTeX Report...${NC}"
    
    # 保存当前目录
    ORIG_DIR=$(pwd)
    
    # 创建 build 目录
    mkdir -p docs/build
    
    # 切换到 docs/src 目录进行编译 (这样可以正确找到 dtmf_content.tex)
    cd docs/src
    
    # 使用 XeLaTeX 编译 (更好的中文支持)
    # 如果系统没有 xelatex，回退到 pdflatex
    if command -v xelatex &> /dev/null; then
        echo -e "${BLUE}Using XeLaTeX for better CJK support...${NC}"
        xelatex -interaction=nonstopmode -output-directory=../build dtmf_report.tex
        xelatex -interaction=nonstopmode -output-directory=../build dtmf_report.tex
    else
        echo -e "${YELLOW}XeLaTeX not found, using pdflatex...${NC}"
        pdflatex -interaction=nonstopmode -output-directory=../build dtmf_report.tex
        pdflatex -interaction=nonstopmode -output-directory=../build dtmf_report.tex
    fi
    
    # 返回原目录
    cd "$ORIG_DIR"
    
    if [ -f "docs/build/dtmf_report.pdf" ]; then
        cp docs/build/dtmf_report.pdf docs/dtmf_report.pdf
        echo -e "${GREEN}Report generated at: docs/dtmf_report.pdf${NC}"
    else
        echo -e "${RED}Error: PDF generation failed.${NC}"
    fi
}

clean_project() {
    echo -e "${YELLOW}Cleaning project artifacts...${NC}"
    # Python caches
    find . -type d -name "__pycache__" -exec rm -rf {} +
    # Java build
    rm -rf java-web/target
    # LaTeX build
    rm -rf docs/build
    # Temp files
    rm -f test_pattern.png java-web/HELP.md
    # Empty directories
    find . -type d -empty -delete
    echo "Done."
}

# Main logic
case "$1" in
    gui)
        run_gui
        ;;
    bridge)
        run_bridge
        ;;
    all)
        run_all
        ;;
    stop)
        stop_gui
        pkill -f fpga_uart_bridge.py 2>/dev/null
        ;;
    sim)
        run_sim
        ;;
    exp)
        run_exp
        ;;
    report)
        build_report
        ;;
    clean)
        clean_project
        ;;
    help|*)
        show_usage
        ;;
esac
