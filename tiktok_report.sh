#!/bin/bash

################################################################################
# TikTok Report Tool for Termux
# A comprehensive reporting utility for TikTok issues
# Author: redmi14
# License: MIT
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_DIR="${HOME}/.tiktok_reports"
LOG_DIR="${REPORT_DIR}/logs"
DATA_DIR="${REPORT_DIR}/data"

# Create necessary directories
mkdir -p "${REPORT_DIR}" "${LOG_DIR}" "${DATA_DIR}"

################################################################################
# Utility Functions
################################################################################

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "${LOG_DIR}/tiktok_report.log"
}

success() {
    echo -e "${GREEN}✓ $1${NC}" | tee -a "${LOG_DIR}/tiktok_report.log"
}

error() {
    echo -e "${RED}✗ ERROR: $1${NC}" | tee -a "${LOG_DIR}/tiktok_report.log"
}

warning() {
    echo -e "${YELLOW}⚠ WARNING: $1${NC}" | tee -a "${LOG_DIR}/tiktok_report.log"
}

header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

################################################################################
# System Information Collection
################################################################################

get_system_info() {
    local info_file="${DATA_DIR}/system_info.txt"
    
    {
        echo "# System Information"
        echo "Timestamp: $(date)"
        echo ""
        
        echo "## Device Info"
        echo "Device: $(getprop ro.product.model 2>/dev/null || echo 'N/A')"
        echo "Manufacturer: $(getprop ro.product.manufacturer 2>/dev/null || echo 'N/A')"
        echo "Android Version: $(getprop ro.build.version.release 2>/dev/null || echo 'N/A')"
        echo "Android SDK: $(getprop ro.build.version.sdk 2>/dev/null || echo 'N/A')"
        echo ""
        
        echo "## Termux Info"
        echo "Termux Version: $(termux-info 2>/dev/null | head -1 || echo 'N/A')"
        echo "Termux Arch: $(dpkg --print-architecture 2>/dev/null || echo 'N/A')"
        echo ""
        
        echo "## Storage Info"
        df -h | head -5
        echo ""
        
        echo "## Memory Info"
        free -h 2>/dev/null || echo "N/A"
        echo ""
        
        echo "## Installed Packages"
        dpkg -l | grep -E 'python|curl|wget' || echo "N/A"
        
    } > "${info_file}"
    
    echo "${info_file}"
}

################################################################################
# TikTok Account Information
################################################################################

collect_tiktok_account_info() {
    local account_file="${DATA_DIR}/tiktok_account.txt"
    
    {
        echo "# TikTok Account Information"
        echo "Report Date: $(date)"
        echo ""
        
        read -p "Enter TikTok Username: " username
        read -p "Enter TikTok UID: " uid
        read -p "Enter Account Status: " status
        read -p "Enter Issue Type: " issue_type
        
        echo "Username: $username"
        echo "UID: $uid"
        echo "Account Status: $status"
        echo "Issue Type: $issue_type"
        echo ""
        
        echo "## Issue Description"
        read -p "Describe the issue in detail: " issue_desc
        echo "$issue_desc"
        
    } > "${account_file}"
    
    echo "${account_file}"
}

################################################################################
# Network Diagnostics
################################################################################

run_network_diagnostics() {
    local network_file="${DATA_DIR}/network_diagnostics.txt"
    
    {
        echo "# Network Diagnostics"
        echo "Timestamp: $(date)"
        echo ""
        
        echo "## Network Connectivity"
        if ping -c 1 8.8.8.8 &> /dev/null; then
            echo "Internet: ✓ Connected"
        else
            echo "Internet: ✗ Disconnected"
        fi
        echo ""
        
        echo "## DNS Resolution"
        nslookup api.tiktok.com 2>/dev/null | head -10 || echo "N/A"
        echo ""
        
        echo "## IP Information"
        curl -s https://ipinfo.io || echo "N/A"
        echo ""
        
        echo "## TikTok API Status"
        curl -s -o /dev/null -w "Status: %{http_code}\n" https://www.tiktok.com || echo "N/A"
        
    } > "${network_file}"
    
    echo "${network_file}"
}

################################################################################
# App Performance Metrics
################################################################################

collect_performance_metrics() {
    local perf_file="${DATA_DIR}/performance_metrics.txt"
    
    {
        echo "# Performance Metrics"
        echo "Timestamp: $(date)"
        echo ""
        
        echo "## CPU Usage"
        top -bn1 | head -10
        echo ""
        
        echo "## Memory Usage"
        ps aux | sort -k 3 -r | head -5
        echo ""
        
        echo "## Storage Usage"
        du -sh ~ 2>/dev/null
        echo ""
        
        echo "## Process Information"
        ps aux | grep -i tiktok || echo "No TikTok process found"
        
    } > "${perf_file}"
    
    echo "${perf_file}"
}

################################################################################
# Generate Report
################################################################################

generate_report() {
    local report_file="${REPORT_DIR}/tiktok_report_$(date +%Y%m%d_%H%M%S).md"
    
    header "Generating TikTok Report"
    
    log "Collecting system information..."
    local sys_info=$(get_system_info)
    success "System info collected"
    
    log "Collecting TikTok account information..."
    local account_info=$(collect_tiktok_account_info)
    success "Account info collected"
    
    log "Running network diagnostics..."
    local network_info=$(run_network_diagnostics)
    success "Network diagnostics completed"
    
    log "Collecting performance metrics..."
    local perf_info=$(collect_performance_metrics)
    success "Performance metrics collected"
    
    # Combine all information into report
    {
        echo "# TikTok Report"
        echo "Generated: $(date)"
        echo ""
        
        echo "---"
        echo ""
        
        cat "${sys_info}"
        echo ""
        echo "---"
        echo ""
        
        cat "${account_info}"
        echo ""
        echo "---"
        echo ""
        
        cat "${network_info}"
        echo ""
        echo "---"
        echo ""
        
        cat "${perf_info}"
        echo ""
        
    } > "${report_file}"
    
    success "Report generated: ${report_file}"
    echo "${report_file}"
}

################################################################################
# Export and Share Functions
################################################################################

export_report() {
    local report_file="$1"
    local export_format="${2:-txt}"
    
    if [ ! -f "${report_file}" ]; then
        error "Report file not found: ${report_file}"
        return 1
    fi
    
    local export_file="${REPORT_DIR}/export_$(date +%Y%m%d_%H%M%S).${export_format}"
    
    case "${export_format}" in
        txt)
            cp "${report_file}" "${export_file}"
            ;;
        json)
            echo "{\"report\": $(cat "${report_file}" | jq -Rs .)}" > "${export_file}"
            ;;
        html)
            echo "<html><body><pre>$(cat "${report_file}")</pre></body></html>" > "${export_file}"
            ;;
        *)
            error "Unsupported export format: ${export_format}"
            return 1
            ;;
    esac
    
    success "Report exported to: ${export_file}"
}

upload_report() {
    local report_file="$1"
    
    if [ ! -f "${report_file}" ]; then
        error "Report file not found: ${report_file}"
        return 1
    fi
    
    log "Uploading report..."
    
    # Create a simple upload mechanism
    # Users can customize this with their own upload server
    
    # Option 1: Save to shareable location
    local share_location="${REPORT_DIR}/shared/"
    mkdir -p "${share_location}"
    cp "${report_file}" "${share_location}/"
    
    success "Report saved to: ${share_location}"
    warning "Configure upload server in config for automatic uploads"
}

################################################################################
# Main Menu
################################################################################

show_menu() {
    clear
    echo ""
    header "TikTok Report Tool for Termux"
    echo ""
    echo "1) Generate New Report"
    echo "2) View Recent Reports"
    echo "3) Export Report"
    echo "4) View System Info"
    echo "5) Run Network Test"
    echo "6) View Logs"
    echo "7) Clean Old Reports"
    echo "8) Exit"
    echo ""
    read -p "Select an option [1-8]: " choice
}

view_recent_reports() {
    echo ""
    header "Recent Reports"
    ls -lht "${REPORT_DIR}"/*.md 2>/dev/null | head -10 || echo "No reports found"
}

view_logs() {
    echo ""
    header "Report Logs"
    tail -50 "${LOG_DIR}/tiktok_report.log" || echo "No logs found"
}

clean_old_reports() {
    echo ""
    header "Cleaning Old Reports"
    read -p "Delete reports older than (days) [default: 30]: " days
    days=${days:-30}
    
    find "${REPORT_DIR}" -name "*.md" -type f -mtime +${days} -delete
    success "Old reports cleaned (older than ${days} days)"
}

################################################################################
# Main Function
################################################################################

main() {
    log "TikTok Report Tool Started"
    
    while true; do
        show_menu
        
        case "${choice}" in
            1)
                report_file=$(generate_report)
                echo ""
                success "Report completed: ${report_file}"
                read -p "Press Enter to continue..."
                ;;
            2)
                view_recent_reports
                read -p "Press Enter to continue..."
                ;;
            3)
                echo ""
                read -p "Enter report file path: " report_path
                read -p "Select export format (txt/json/html) [default: txt]: " format
                format=${format:-txt}
                export_report "${report_path}" "${format}"
                read -p "Press Enter to continue..."
                ;;
            4)
                sys_info=$(get_system_info)
                cat "${sys_info}"
                read -p "Press Enter to continue..."
                ;;
            5)
                run_network_diagnostics > /dev/null
                cat "${DATA_DIR}/network_diagnostics.txt"
                read -p "Press Enter to continue..."
                ;;
            6)
                view_logs
                read -p "Press Enter to continue..."
                ;;
            7)
                clean_old_reports
                read -p "Press Enter to continue..."
                ;;
            8)
                success "Exiting TikTok Report Tool"
                log "TikTok Report Tool Stopped"
                exit 0
                ;;
            *)
                error "Invalid option. Please try again."
                sleep 2
                ;;
        esac
    done
}

################################################################################
# Script Entry Point
################################################################################

if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
