#!/bin/bash

# 兼容入口：历史上 daily_tweet_crawler 和 service_scripts 各有一份 start/stop 脚本
# 为避免“start 用一套、stop 用另一套”造成 PID 文件/cron 监控混乱，这里统一转发到 service_scripts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/../service_scripts/start_service_project_twitterapi.sh" "$@"

show_monitor() {
    local monitor_script="$SCRIPT_DIR/service_project_monitor.sh"
    local monitor_log="$SCRIPT_DIR/monitor_project.log"
    print_info "=== 项目推文监控状态 (TwitterAPI) ==="
    local existing_cron=$(crontab -l 2>/dev/null | grep -F "$monitor_script")
    if [ -n "$existing_cron" ]; then
        print_success "项目推文监控定时任务: 已启用"
        echo "  $existing_cron"
    else
        print_warning "项目推文监控定时任务: 未启用"
    fi
    if [ -f "$monitor_log" ]; then
        print_info "最近监控日志 (最新10行):"
        echo "----------------------------------------"
        tail -n 10 "$monitor_log"
    else
        print_info "监控日志: 无记录"
    fi
}

show_help() {
    echo "Twitter项目推文数据爬取服务管理脚本 (TwitterAPI版)"
    echo ""
    echo "使用方法:"
    echo "  $0 [命令] [参数]"
    echo ""
    echo "命令:"
    echo "  start [间隔] [页数] [每页条数] [小时限制]  启动服务 (默认: 60分钟, 50页, 100条, 3小时)"
    echo "  stop                                   停止服务"
    echo "  restart [间隔] [页数] [每页条数] [小时限制] 重启服务"
    echo "  status                                 查看服务状态"
    echo "  once [页数] [每页条数] [小时限制]         执行单次爬取"
    echo "  logs [行数]                            查看日志"
    echo "  monitor                                查看监控状态和日志"
    echo "  help                                   显示帮助"
    echo ""
    echo "示例:"
    echo "  $0 start                    # 使用默认配置启动"
    echo "  $0 start 10                 # 10分钟间隔启动"
    echo "  $0 start 60 50 100 24       # 60分钟间隔，50页，每页100条，24小时时间限制"
    echo "  $0 once                     # 执行单次爬取"
    echo "  $0 once 50 100 12           # 单次爬取50页，每页100条，12小时时间限制"
    echo "  $0 logs 100                 # 查看最新100行日志"
    echo "  $0 monitor                  # 查看监控状态"
}

case "$1" in
    "start")
        start_service "$2" "$3" "$4" "$5"
        ;;
    "stop")
        stop_service
        ;;
    "restart")
        restart_service "$2" "$3" "$4" "$5"
        ;;
    "status")
        check_status
        if [ -f "$LOG_FILE" ]; then
            print_info "最新日志:"
            echo "----------------------------------------"
            tail -n 5 "$LOG_FILE"
        fi
        ;;
    "once")
        run_once "$2" "$3" "$4"
        ;;
    "logs")
        show_logs "$2"
        ;;
    "monitor")
        show_monitor
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        print_error "未知命令: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
