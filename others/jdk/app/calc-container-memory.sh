#!/bin/bash

# 字节转换函数
bytes_to_human() {
    local bytes=$1
    local units=('B' 'KB' 'm' 'g' 'TB')
    local unit=0
    
    while [ $bytes -ge 1024 ] && [ $unit -lt 4 ]; do
        bytes=$((bytes / 1024))
        unit=$((unit + 1))
    done
    
    echo "${bytes}${units[$unit]}"
}

# 获取总内存（字节）
get_total_memory_bytes() {
    # 方法1：使用 /proc/meminfo（最可靠）
    local mem_kb=$(grep 'MemTotal:' /proc/meminfo | awk '{print $2}')
    echo $((mem_kb * 1024))
    
    # 方法2：使用 free
    # free -b | grep '^Mem:' | awk '{print $2}'
}

# 获取容器内存限制
get_memory_limit() {
    local cgroup_file="/sys/fs/cgroup/memory/memory.limit_in_bytes"
    local max_limit="9223372036854771712"  # 0x7FFFFFFFFFFFF000 无限制的标识
    
    if [ -f "$cgroup_file" ]; then
        local limit=$(cat "$cgroup_file")
        
        # 如果 limit 是最大值，表示没有限制或限制在系统级别
        if [ "$limit" -ge "$max_limit" ]; then
            # 尝试从/proc/meminfo获取（如果有lxcfs）
            if [ -f "/proc/meminfo" ]; then
                local mem_kb=$(grep 'MemTotal:' /proc/meminfo | awk '{print $2}')
                echo $((mem_kb * 1024))
            else
                # 默认 2 GB
                echo $((2048 * 1024 * 1024))
            fi
        else
            echo "$limit"
        fi
    else
        # 尝试从/proc/meminfo获取（如果有lxcfs）
        if [ -f "/proc/meminfo" ]; then
            local mem_kb=$(grep 'MemTotal:' /proc/meminfo | awk '{print $2}')
            echo $((mem_kb * 1024))
        else
            echo $((2048 * 1024 * 1024))
        fi
    fi
}

# 计算可用内存的80%（考虑容器开销）
calculate_percent_memory() {
    local total_bytes=$1
    local percent=${2:-80}  # 默认80%

    local result=$((total_bytes * percent / 100))
    # 调整为偶数（某些JVM优化）
    result=$(( (result + 1) & ~1 ))

    echo $result
}

# 使用示例
TOTAL_MEM=$(bytes_to_human $(get_total_memory_bytes))
TOTAL_MEM_LIMIT=$(bytes_to_human $(get_memory_limit))
CALC_PERCENT_MEM=$(bytes_to_human $(calculate_percent_memory $(get_memory_limit) 50))
echo "Total System Memory: $TOTAL_MEM"
echo "Container Memory Limit: $TOTAL_MEM_LIMIT"
echo "Calculated Percent Memory: $CALC_PERCENT_MEM"
