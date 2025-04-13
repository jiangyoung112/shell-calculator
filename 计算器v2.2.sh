#!/bin/bash

# 在脚本开头添加版本信息
VERSION="2.2"
LAST_UPDATED="2025-04-13"

# 颜色定义
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m' # 无颜色

# 历史记录文件
HISTORY_FILE="$HOME/.calculator_history"

# 初始化历史记录
init_history() {
    if [ ! -f "$HISTORY_FILE" ]; then
        touch "$HISTORY_FILE"
        echo "时间戳|操作|结果" >> "$HISTORY_FILE"
    fi
}

# 记录历史
record_history() {
    echo "$(date '+%Y-%m-%d %H:%M:%S')|$1|$2" >> "$HISTORY_FILE"
}

# 基本计算
basic_calculation() {
    echo -e "${CYAN}请选择运算类型："
    echo "1) 加法  2) 减法  3) 乘法  4) 除法"
    echo "5) 幂运算  6) 平方根  7) 百分比"
    read -p "输入选择 [1-7] > " choice
    
    case $choice in
        1) op="+" ;;
        2) op="-" ;;
        3) op="*" ;;
        4) op="/" ;;
        5) op="^" ;;
        6) op="sqrt" ;;
        7) op="%" ;;
        *) echo -e "${RED}无效选择！${NC}"; return ;;
    esac

    if [ "$op" != "sqrt" ]; then
        read -p "输入第一个数字: " num1
        if [ "$op" != "%" ]; then
            read -p "输入第二个数字: " num2
        fi
    else
        read -p "输入要计算平方根的数字: " num1
    fi

    case $op in
        "+") result=$(echo "$num1 + $num2" | bc -l) ;;
        "-") result=$(echo "$num1 - $num2" | bc -l) ;;
        "*") result=$(echo "$num1 * $num2" | bc -l) ;;
        "/") 
            if [ $(echo "$num2 == 0" | bc) -eq 1 ]; then
                echo -e "${RED}错误：除数不能为零！${NC}"
                return
            fi
            result=$(echo "scale=4; $num1 / $num2" | bc -l)
            ;;
        "^") result=$(echo "$num1 ^ $num2" | bc -l) ;;
        "sqrt")
            if [ $(echo "$num1 < 0" | bc) -eq 1 ]; then
                echo -e "${RED}错误：负数没有实数平方根！${NC}"
                return
            fi
            result=$(echo "scale=4; sqrt($num1)" | bc -l)
            ;;
        "%") result=$(echo "scale=2; ($num1 * $num2)/100" | bc -l) ;;
    esac

    echo -e "${GREEN}计算结果: $result${NC}"
    record_history "基本计算 $op" "$result"
}

# 科学计算
scientific_calculation() {
    echo -e "${CYAN}请选择科学运算："
    echo "1) 三角函数  2) 对数  3) 自然对数  4) 阶乘"
    read -p "输入选择 [1-4] > " choice
    
    read -p "输入数字: " num
    num=$(echo "scale=4; $num" | bc -l)

    case $choice in
        1)
            echo -e "1) 正弦  2) 余弦  3) 正切"
            read -p "选择三角函数 [1-3] > " trig
            case $trig in
                1) result=$(echo "s($num)" | bc -l) ;;  # 正弦
                2) result=$(echo "c($num)" | bc -l) ;;  # 余弦
                3) result=$(echo "s($num)/c($num)" | bc -l) ;;  # 正切
                *) echo -e "${RED}无效选择！${NC}"; return ;;
            esac
            ;;
        2)
            read -p "输入底数: " base
            result=$(echo "l($num)/l($base)" | bc -l)  # 换底公式
            ;;
        3) result=$(echo "l($num)" | bc -l) ;;  # 自然对数
        4)
            if [ $(echo "$num < 0" | bc) -eq 1 ]; then
                echo -e "${RED}错误：负数没有阶乘！${NC}"
                return
            fi
            result=1
            for ((i=1; i<=${num%.*}; i++)); do
                result=$(echo "$result * $i" | bc)
            done
            ;;
        *) echo -e "${RED}无效选择！${NC}"; return ;;
    esac

    echo -e "${GREEN}计算结果: $result${NC}"
    record_history "科学计算" "$result"
}

# 单位转换

# 单位转换配置（可扩展）
declare -A UNIT_GROUPS=(
    ["length"]="长度" 
    ["weight"]="重量"
    ["temperature"]="温度"
    ["area"]="面积"
    ["volume"]="体积"
    ["speed"]="速度"
    ["data"]="数据存储"
    ["pressure"]="压力"
)

declare -A UNIT_CONVERSIONS=(
    # 长度基准单位：米(m)
    ["length_m"]=1
    ["length_km"]=1000
    ["length_cm"]=0.01
    ["length_mm"]=0.001
    ["length_ft"]=0.3048
    ["length_in"]=0.0254
    ["length_mi"]=1609.34
    
    # 重量基准单位：千克(kg)
    ["weight_kg"]=1
    ["weight_g"]=0.001
    ["weight_lb"]=0.453592
    ["weight_oz"]=0.0283495
    ["weight_st"]=6.35029
    
    # 温度基准单位：摄氏度(℃)
    ["temperature_℃"]=1
    ["temperature_℉"]=1  # 特殊处理
    
    # 面积基准单位：平方米(m²)
    ["area_m2"]=1
    ["area_km2"]=1000000
    ["area_ha"]=10000
    ["area_acre"]=4046.86
    ["area_ft2"]=0.092903
    
    # 体积基准单位：升(L)
    ["volume_L"]=1
    ["volume_m3"]=1000
    ["volume_ml"]=0.001
    ["volume_gal"]=3.78541
    ["volume_qt"]=0.946353
    
    # 速度基准单位：米/秒(m/s)
    ["speed_m/s"]=1
    ["speed_km/h"]=0.277778
    ["speed_mph"]=0.44704
    ["speed_knot"]=0.514444
    
    # 数据基准单位：字节(B)
    ["data_B"]=1
    ["data_KB"]=1024
    ["data_MB"]=1048576
    ["data_GB"]=1073741824
    ["data_TB"]=1099511627776
    
    # 压力基准单位：帕斯卡(Pa)
    ["pressure_Pa"]=1
    ["pressure_kPa"]=1000
    ["pressure_bar"]=100000
    ["pressure_atm"]=101325
    ["pressure_psi"]=6894.76
)

# 单位转换函数
unit_conversion() {
    echo -e "${CYAN}请选择转换类别："
    
    # 显示可用类别
    local i=1
    declare -A category_map
    for key in "${!UNIT_GROUPS[@]}"; do
        echo "$i) ${UNIT_GROUPS[$key]}"
        category_map[$i]=$key
        ((i++))
    done
    
    while true; do
        read -p "输入选择 [1-${#UNIT_GROUPS[@]}] > " category_choice
        [[ "$category_choice" == "q" ]] && return
        local category=${category_map[$category_choice]}
        [ -n "$category" ] && break
        echo -e "${RED}无效选择，请重新输入！${NC}"
    done

    # 获取该类别下所有单位
    local -a units
    for key in "${!UNIT_CONVERSIONS[@]}"; do
        if [[ $key == "${category}_"* ]]; then
            units+=("${key#*_}")
        fi
    done

    # 显示可用单位
    echo -e "\n${CYAN}请选择源单位："
    local i=1
    declare -A unit_map
    for unit in "${units[@]}"; do
        echo "$i) $unit"
        unit_map[$i]=$unit
        ((i++))
    done
    
    while true; do
        read -p "输入源单位 [1-${#units[@]}] > " source_choice
        [[ "$source_choice" == "q" ]] && return
        local source_unit=${unit_map[$source_choice]}
        [ -n "$source_unit" ] && break
        echo -e "${RED}无效选择，请重新输入！${NC}"
    done

    # 显示目标单位
    echo -e "\n${CYAN}请选择目标单位："
    local i=1
    for unit in "${units[@]}"; do
        echo "$i) $unit"
        ((i++))
    done
    
    while true; do
        read -p "输入目标单位 [1-${#units[@]}] > " target_choice
        [[ "$target_choice" == "q" ]] && return
        local target_unit=${unit_map[$target_choice]}
        [ -n "$target_unit" ] && break
        echo -e "${RED}无效选择，请重新输入！${NC}"
    done

    # 获取转换因子
    local source_key="${category}_${source_unit}"
    local target_key="${category}_${target_unit}"
    local source_factor=${UNIT_CONVERSIONS[$source_key]}
    local target_factor=${UNIT_CONVERSIONS[$target_key]}

    # 特殊处理温度转换
    if [ "$category" == "temperature" ]; then
        handle_temperature "$source_unit" "$target_unit"
        return
    fi

    # 常规转换处理
    while true; do
        read -p "输入要转换的数值 (输入 q 返回) > " input
        [[ "$input" == "q" ]] && return
        
        if [[ "$input" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
            local base_value=$(echo "scale=10; $input * $source_factor" | bc)
            local result=$(echo "scale=4; $base_value / $target_factor" | bc)
            
            echo -e "${GREEN}转换结果: $input $source_unit = $result $target_unit${NC}"
            record_history "单位转换" "$category: $input $source_unit → $result $target_unit"
            break
        else
            echo -e "${RED}错误：请输入有效数字！${NC}"
        fi
    done
}

# 温度特殊处理
handle_temperature() {
    local from=$1
    local to=$2
    
    while true; do
        read -p "输入温度值 (输入 q 返回) > " temp
        [[ "$temp" == "q" ]] && return
        
        if [[ "$temp" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
            case "$from→$to" in
                "℃→℉")
                    result=$(echo "scale=2; ($temp * 9/5) + 32" | bc)
                    ;;
                "℉→℃")
                    result=$(echo "scale=2; ($temp - 32) * 5/9" | bc)
                    ;;
                *)
                    result=$temp  # 相同单位
                    ;;
            esac
            echo -e "${GREEN}转换结果: $temp $from = $result $to${NC}"
            record_history "单位转换" "temperature: $temp $from → $result $to"
            break
        else
            echo -e "${RED}错误：请输入有效数字！${NC}"
        fi
    done
}

# 新增方程求解函数
equation_solver() {
    echo -e "${CYAN}请选择方程类型："
    echo "1) 一元一次方程 (ax + b = 0)"
    echo "2) 一元二次方程 (ax² + bx + c = 0)"
    echo "3) 二元一次方程组"
    read -p "输入选择 [1-3] > " eq_type

    case $eq_type in
        1)
            solve_linear
            ;;
        2)
            solve_quadratic
            ;;
        3)
            solve_system
            ;;
        *)
            echo -e "${RED}无效选择！${NC}"
            return
            ;;
    esac
}

# 一元一次方程求解
solve_linear() {
    echo -e "${YELLOW}解一元一次方程 ax + b = 0${NC}"
    
    while true; do
        read -p "输入系数 a: " a
        if valid_number $a; then break; fi
    done
    
    while true; do
        read -p "输入系数 b: " b
        if valid_number $b; then break; fi
    done

    if [ $(echo "$a == 0" | bc) -eq 1 ]; then
        if [ $(echo "$b == 0" | bc) -eq 1 ]; then
            echo -e "${GREEN}无穷解${NC}"
        else
            echo -e "${GREEN}无解${NC}"
        fi
    else
        solution=$(echo "scale=4; -$b / $a" | bc)
        echo -e "${GREEN}方程解: x = $solution${NC}"
        record_history "方程求解" "一次方程 ${a}x + $b = 0 → x=$solution"
    fi
}

# 一元二次方程求解
solve_quadratic() {
    echo -e "${YELLOW}解一元二次方程 ax² + bx + c = 0${NC}"
    
    while true; do
        read -p "输入系数 a: " a
        if valid_number $a; then break; fi
    done
    
    while true; do
        read -p "输入系数 b: " b
        if valid_number $b; then break; fi
    done
    
    while true; do
        read -p "输入系数 c: " c
        if valid_number $c; then break; fi
    done

    if [ $(echo "$a == 0" | bc) -eq 1 ]; then
        echo -e "${RED}错误：二次项系数不能为零！${NC}"
        return
    fi

    discriminant=$(echo "scale=10; $b^2 - 4*$a*$c" | bc)
    
    if [ $(echo "$discriminant > 0" | bc) -eq 1 ]; then
        sqrt_d=$(echo "sqrt($discriminant)" | bc)
        x1=$(echo "scale=4; (-$b + $sqrt_d)/(2*$a)" | bc)
        x2=$(echo "scale=4; (-$b - $sqrt_d)/(2*$a)" | bc)
        echo -e "${GREEN}实根解:"
        echo "x₁ = $x1"
        echo "x₂ = $x2${NC}"
        record_history "方程求解" "二次方程 ${a}x² + ${b}x + $c = 0 → x1=$x1, x2=$x2"
    elif [ $(echo "$discriminant == 0" | bc) -eq 1 ]; then
        x=$(echo "scale=4; -$b/(2*$a)" | bc)
        echo -e "${GREEN}重根解: x = $x${NC}"
        record_history "方程求解" "二次方程 ${a}x² + ${b}x + $c = 0 → 重根x=$x"
    else
        real_part=$(echo "scale=4; -$b/(2*$a)" | bc)
        imaginary_part=$(echo "scale=4; sqrt(-$discriminant)/(2*$a)" | bc)
        echo -e "${GREEN}复数解:"
        echo "x₁ = ${real_part} + ${imaginary_part}i"
        echo "x₂ = ${real_part} - ${imaginary_part}i${NC}"
        record_history "方程求解" "二次方程 ${a}x² + ${b}x + $c = 0 → 复数解"
    fi
}

# 二元一次方程组求解
solve_system() {
    echo -e "${YELLOW}解二元一次方程组："
    echo "a₁x + b₁y = c₁"
    echo "a₂x + b₂y = c₂${NC}"
    
    while true; do
        read -p "输入 a₁: " a1
        if valid_number $a1; then break; fi
    done
    while true; do
        read -p "输入 b₁: " b1
        if valid_number $b1; then break; fi
    done
    while true; do
        read -p "输入 c₁: " c1
        if valid_number $c1; then break; fi
    done
    while true; do
        read -p "输入 a₂: " a2
        if valid_number $a2; then break; fi
    done
    while true; do
        read -p "输入 b₂: " b2
        if valid_number $b2; then break; fi
    done
    while true; do
        read -p "输入 c₂: " c2
        if valid_number $c2; then break; fi
    done

    determinant=$(echo "scale=10; $a1*$b2 - $a2*$b1" | bc)
    
    if [ $(echo "$determinant == 0" | bc) -eq 1 ]; then
        echo -e "${GREEN}方程组无解或有无穷多解${NC}"
        record_history "方程求解" "方程组无解/无穷解"
    else
        x=$(echo "scale=4; ($c1*$b2 - $c2*$b1)/$determinant" | bc)
        y=$(echo "scale=4; ($a1*$c2 - $a2*$c1)/$determinant" | bc)
        echo -e "${GREEN}方程解:"
        echo "x = $x"
        echo "y = $y${NC}"
        record_history "方程求解" "方程组解 x=$x, y=$y"
    fi
}

# 数值验证函数（新增）
valid_number() {
    [[ "$1" =~ ^-?[0-9]+(\.[0-9]*)?$ ]] && return 0
    echo -e "${RED}错误：请输入有效数字！${NC}"
    return 1
}

# 新增金融计算函数
financial_calculation() {
    echo -e "${CYAN}请选择金融计算类型："
    echo "1) 复利终值计算"
    echo "2) 复利现值计算"
    echo "3) 计算必要利率"
    echo "4) 计算投资期限"
    echo "5) 年金终值计算"
    read -p "输入选择 [1-5] > " finance_type

    case $finance_type in
        1) compound_future_value ;;
        2) compound_present_value ;;
        3) calculate_required_rate ;;
        4) calculate_investment_period ;;
        5) annuity_future_value ;;
        *) echo -e "${RED}无效选择！${NC}"; return ;;
    esac
}

# 公共输入函数
input_financial_params() {
    local params=()
    
    while true; do
        read -p "年利率(%) [默认5%]: " rate
        rate=${rate:-5}
        if valid_percentage $rate; then break; fi
    done

    while true; do
        read -p "投资年限 [默认10]: " years
        years=${years:-10}
        if valid_number $years; then break; fi
    done

    while true; do
        read -p "年复利次数 [1-365，默认12]: " compound_times
        compound_times=${compound_times:-12}
        if [[ "$compound_times" =~ ^[1-9][0-9]*$ ]]; then break; fi
        echo -e "${RED}请输入正整数！${NC}"
    done

    params=("$rate" "$years" "$compound_times")
    echo "${params[@]}"
}

# 复利终值计算
compound_future_value() {
    echo -e "${YELLOW}=== 复利终值计算 ===${NC}"
    echo "公式：FV = PV × (1 + r/n)^(nt)"
    
    while true; do
        read -p "输入本金金额: " principal
        if valid_number $principal; then break; fi
    done

    read -ra params <<< "$(input_financial_params)"
    rate=${params[0]}
    years=${params[1]}
    compound_times=${params[2]}

    r=$(echo "scale=10; $rate/100" | bc)
    fv=$(echo "scale=4; $principal * (1 + $r/$compound_times)^($compound_times*$years)" | bc -l)
    
    echo -e "${GREEN}终值金额：¥$(printf "%'.2f" $fv)${NC}"
    record_history "金融计算" "复利终值：本金¥$principal → $years年后 ¥$fv"
}

# 复利现值计算
compound_present_value() {
    echo -e "${YELLOW}=== 复利现值计算 ===${NC}"
    echo "公式：PV = FV / (1 + r/n)^(nt)"
    
    while true; do
        read -p "输入目标金额: " fv
        if valid_number $fv; then break; fi
    done

    read -ra params <<< "$(input_financial_params)"
    rate=${params[0]}
    years=${params[1]}
    compound_times=${params[2]}

    r=$(echo "scale=10; $rate/100" | bc)
    pv=$(echo "scale=4; $fv / (1 + $r/$compound_times)^($compound_times*$years)" | bc -l)
    
    echo -e "${GREEN}需要现值：¥$(printf "%'.2f" $pv)${NC}"
    record_history "金融计算" "复利现值：目标¥$fv → 现值 ¥$pv"
}

# 计算必要利率
calculate_required_rate() {
    echo -e "${YELLOW}=== 必要收益率计算 ===${NC}"
    echo "公式：r = n × [(FV/PV)^(1/(nt)) - 1]"
    
    while true; do
        read -p "输入当前本金: " pv
        if valid_number $pv; then break; fi
    done

    while true; do
        read -p "输入目标金额: " fv
        if valid_number $fv; then break; fi
    done

    while true; do
        read -p "投资年限: " years
        if valid_number $years; then break; fi
    done

    while true; do
        read -p "年复利次数 [1-365]: " compound_times
        if [[ "$compound_times" =~ ^[1-9][0-9]*$ ]]; then break; fi
        echo -e "${RED}请输入正整数！${NC}"
    done

    rate=$(echo "scale=2; $compound_times * ( e(l($fv/$pv)/($compound_times*$years)) - 1 ) * 100" | bc -l)
    
    echo -e "${GREEN}需要年利率：${rate}%${NC}"
    record_history "金融计算" "必要利率：¥$pv→¥$fv → 需${rate}%"
}

# 新增验证函数
valid_percentage() {
    [[ "$1" =~ ^[0-9]+(\.[0-9]+)?$ ]] && return 0
    echo -e "${RED}错误：请输入有效百分比！${NC}"
    return 1
}

# 年金终值计算（需补充）
annuity_future_value() {
    echo -e "${YELLOW}=== 年金终值计算 ===${NC}"
    echo "公式：FV = PMT × [( (1+r/n)^(nt) - 1 ) / (r/n)]"
    
    while true; do
        read -p "每期投入金额: " pmt
        if valid_number $pmt; then break; fi
    done

    read -ra params <<< "$(input_financial_params)"
    rate=${params[0]}
    years=${params[1]}
    compound_times=${params[2]}

    r=$(echo "scale=10; $rate/100" | bc)
    fv=$(echo "scale=4; $pmt * ( (1 + $r/$compound_times)^($compound_times*$years) - 1 ) / ($r/$compound_times)" | bc -l)
    
    echo -e "${GREEN}年金终值：¥$(printf "%'.2f" $fv)${NC}"
}
# 新增复数计算函数
complex_calculation() {
    echo -e "${CYAN}请选择复数运算类型："
    echo "1) 加法       2) 减法"
    echo "3) 乘法       4) 除法"
    echo "5) 模长计算   6) 共轭复数"
    echo "7) 极坐标转换 8) 复幂运算"
    read -p "输入选择 [1-8] > " choice

    case $choice in
        1) complex_add ;;
        2) complex_sub ;;
        3) complex_mul ;;
        4) complex_div ;;
        5) complex_abs ;;
        6) complex_conj ;;
        7) complex_polar ;;
        8) complex_pow ;;
        *) echo -e "${RED}无效选择！${NC}"; return ;;
    esac
}
# 复幂运算（需补充）
complex_pow() {
    input_complex "输入底数"
    a_real=$real
    a_imag=$imag
    
    while true; do
        read -p "输入指数: " exponent
        if valid_number $exponent; then break; fi
    done

    # 使用极坐标公式计算
    modulus=$(echo "sqrt($a_real^2 + $a_imag^2)^$exponent" | bc -l)
    argument=$(echo "a($a_imag/$a_real)*$exponent" | bc -l)
    
    res_real=$(echo "$modulus * c($argument)" | bc -l)
    res_imag=$(echo "$modulus * s($argument)" | bc -l)
    
    result=$(format_complex $res_real $res_imag)
    echo -e "${GREEN}计算结果: $result${NC}"
}

# 复数输入函数
input_complex() {
    local prompt=$1
    echo -e "${YELLOW}$prompt${NC}"
    
    while true; do
        read -p "实部: " real
        if valid_number $real; then break; fi
    done
    
    while true; do
        read -p "虚部: " imag
        if valid_number $imag; then break; fi
    done
}

# 格式化复数显示
format_complex() {
    local real=$1
    local imag=$2
    
    if [ $(echo "$imag == 0" | bc) -eq 1 ]; then
        echo "$real"
    elif [ $(echo "$real == 0" | bc) -eq 1 ]; then
        echo "${imag}i"
    else
        imag_sign="+"
        [ $(echo "$imag < 0" | bc) -eq 1 ] && imag_sign="-"
        imag=${imag#-}
        [ "$imag" == "1" ] && imag=""
        echo "${real} ${imag_sign} ${imag}i"
    fi
}

# 复数加法
complex_add() {
    input_complex "输入第一个复数"
    a_real=$real
    a_imag=$imag
    
    input_complex "输入第二个复数"
    b_real=$real
    b_imag=$imag

    res_real=$(echo "$a_real + $b_real" | bc)
    res_imag=$(echo "$a_imag + $b_imag" | bc)
    
    result=$(format_complex $res_real $res_imag)
    echo -e "${GREEN}计算结果: $result${NC}"
    record_history "复数运算" "加法 → $result"
}

# 复数乘法
complex_mul() {
    input_complex "输入第一个复数"
    a_real=$real
    a_imag=$imag
    
    input_complex "输入第二个复数"
    b_real=$real
    b_imag=$imag

    res_real=$(echo "$a_real*$b_real - $a_imag*$b_imag" | bc)
    res_imag=$(echo "$a_real*$b_imag + $a_imag*$b_real" | bc)
    
    result=$(format_complex $res_real $res_imag)
    echo -e "${GREEN}计算结果: $result${NC}"
    record_history "复数运算" "乘法 → $result"
}

# 复数模长
complex_abs() {
    input_complex "输入复数"
    modulus=$(echo "sqrt($real^2 + $imag^2)" | bc -l)
    echo -e "${GREEN}模长: $(printf "%.4f" $modulus)${NC}"
    record_history "复数运算" "模长 → $modulus"
}

# 极坐标转换
complex_polar() {
    input_complex "输入复数"
    modulus=$(echo "sqrt($real^2 + $imag^2)" | bc -l)
    argument=$(echo "a($imag/$real)" | bc -l)  # 辐角计算
    
    # 调整象限
    if [ $(echo "$real < 0" | bc) -eq 1 ]; then
        argument=$(echo "$argument + 3.14159265358979323846" | bc -l)
    fi
    
    echo -e "${GREEN}极坐标形式:"
    echo "模长: $(printf "%.4f" $modulus)"
    echo "辐角: $(printf "%.4f 弧度" $argument) ≈ $(echo "180*a(1)*$argument/3.14159265358979323846" | bc -l | xargs printf "%.2f°)")${NC}"
    record_history "复数运算" "极坐标 → 模长$modulus, 辐角$argument"
}

# 复数除法（需要处理分母为0）
complex_div() {
    input_complex "输入被除数"
    a_real=$real
    a_imag=$imag
    
    while true; do
        input_complex "输入除数"
        b_real=$real
        b_imag=$imag
        
        denominator=$(echo "$b_real^2 + $b_imag^2" | bc)
        if [ $(echo "$denominator == 0" | bc) -eq 1 ]; then
            echo -e "${RED}错误：除数不能为零！${NC}"
        else
            break
        fi
    done

    res_real=$(echo "scale=4; ($a_real*$b_real + $a_imag*$b_imag)/$denominator" | bc -l)
    res_imag=$(echo "scale=4; ($a_imag*$b_real - $a_real*$b_imag)/$denominator" | bc -l)
    
    result=$(format_complex $res_real $res_imag)
    echo -e "${GREEN}计算结果: $result${NC}"
    record_history "复数运算" "除法 → $result"
}
# 新增中文大写转换函数
chinese_number_converter() {
    echo -e "${CYAN}=== 中文大写数字转换 ==="
    echo -e "支持范围：0.00 - 999999999999.99${NC}"
    
    while true; do
        read -p "请输入金额数字 (输入q返回) > " amount
        
        [[ "$amount" == "q" ]] && return
        
        if [[ ! "$amount" =~ ^-?[0-9]+(\.[0-9]{1,2})?$ ]]; then
            echo -e "${RED}错误：请输入有效金额（最多两位小数）！${NC}"
            continue
        fi

        # 去除负号（金额通常不用负号）
        amount=${amount#-}
        
        # 拆分整数和小数部分
        integer_part=$(echo "$amount" | cut -d. -f1)
        decimal_part=$(echo "$amount" | cut -d. -f2 | awk '{printf "%-02s", $0}')
        
        # 执行转换
        result=$(convert_to_chinese "$integer_part" "$decimal_part")
        
        echo -e "${GREEN}中文大写：${result}${NC}"
        record_history "中文大写转换" "$amount → $result"
    done
}

# 核心转换函数
convert_to_chinese() {
    local integer=$1
    local decimal=$2
    
    # 数字映射表
    local num_map=("零" "壹" "贰" "叁" "肆" "伍" "陆" "柒" "捌" "玖")
    local unit_map=("" "拾" "佰" "仟")
    local section_unit=("" "万" "亿" "万亿")
    
    local result=""
    
    # 处理整数部分
    if [ "$integer" -eq 0 ]; then
        result+="零"
    else
        local section_index=0
        while [ "$integer" -gt 0 ]; do
            local section=$((integer % 10000))
            integer=$((integer / 10000))
            
            local section_str=$(convert_section $section)
            
            # 添加节单位（万/亿）
            if [ -n "$section_str" ]; then
                result="${section_str}${section_unit[section_index]}${result}"
            fi
            
            ((section_index++))
        done
    fi
    
    # 添加元单位
    result+="元"
    
    # 处理小数部分
    if [ -z "$decimal" ] || [ "$decimal" == "00" ]; then
        result+="整"
    else
        # 角处理
        local jiao=${decimal:0:1}
        if [ "$jiao" -ne 0 ]; then
            result+="${num_map[jiao]}角"
        fi
        
        # 分处理
        local fen=${decimal:1:1}
        if [ "$fen" -ne 0 ]; then
            result+="${num_map[fen]}分"
        fi
        
        # 当只有分时显示
        if [ "$jiao" -eq 0 ] && [ "$fen" -ne 0 ]; then
            result+="零${num_map[fen]}分"
        fi
    fi
    
    # 清理多余的零
    result=$(echo "$result" | sed -E 's/零{2,}/零/g')
    result=$(echo "$result" | sed -E 's/零([万亿])/\1/g')
    result=${result//零元/元}
    
    echo "$result"
}

# 转换四位数字段
convert_section() {
    local num=$1
    local str=""
    
    for ((i=0; i<4; i++)); do
        local digit=$((num % 10))
        num=$((num / 10))
        
        if [ "$digit" -ne 0 ]; then
            str="${num_map[digit]}${unit_map[i]}${str}"
        else
            str="零${str}"
        fi
    done
    
    # 处理末尾的零
    str=$(echo "$str" | sed -E 's/零+$//')
    
    # 处理中间的多个零
    str=$(echo "$str" | sed -E 's/零+/零/g')
    
    echo "$str"
}

# 显示历史
show_history() {
    echo -e "\n${YELLOW}=== 计算历史记录 ===${NC}"
    column -t -s "|" "$HISTORY_FILE"
    echo
}

# 帮助信息
show_help() {
    clear
    echo -e "${BLUE}=== 多功能计算器使用说明 ==="
    echo "1. 基本计算：支持四则运算、幂运算、平方根和百分比"
    echo "2. 科学计算：包含三角函数、对数和阶乘运算"
    echo "3. 单位转换：支持温度、长度、重量和数据存储单位转换"
    echo "4. 历史记录：自动保存最近100条计算记录"
    echo "5. 输入 q 可随时退出当前操作"
    echo "6. 使用 bc 命令进行高精度计算"
    echo -e "===============================${NC}\n"
}

# 新增更新日志函数
show_changelog() {
    clear
    echo -e "${CYAN}=== 更新日志 v$VERSION ==="
    echo -e "${YELLOW}[v2.2] 2024-04-05${NC}"
    echo "  - 数学盒子升级至v2.2"
    echo "  - 新增质数验证功能"
    echo "  - 添加斐波那契数列生成器"
    echo "  - 集成经典数学谜题合集"
    echo "  - 优化算法性能"
    echo -e "${YELLOW}[v2.1] 2025-02-09${NC}"
    echo "  - 数学盒子同步升级至v1.1"
    echo "  - 新增掷骰子功能"
    echo "  - 新增抛硬币功能"
    echo "  - 添加ASCII艺术效果"
    echo -e "${YELLOW}[v2.0.0] 2025-02-09${NC}"
    echo "  - 新增数学盒子功能集"
    echo "  - 整合经典猜数游戏"
    echo -e "${YELLOW}[v1.4.0] 2025-02-09${NC}"
    echo "  - 新增中文大写金额转换功能"
    echo "  - 符合GB/T 15835-2011国家标准"
    echo -e "${YELLOW}[v1.3.0] 2025-02-08${NC}"
    echo "  - 新增复数计算模块"
    echo "  - 添加更新日志功能"
    echo "  - 修复一些bug"
    echo "  - 优化单位转换模块"
    echo "  - 重构单位转换系统"
    echo "  - 新增压力/速度单位转换"
    echo -e "${YELLOW}[v1.2.0] ${NC}"
    echo "  - 新增金融计算功能（复利/年金）"
    echo "  - 添加货币格式化显示"
    echo -e "${YELLOW}[v1.1.0] ${NC}"
    echo "  - 新增方程求解功能"
    echo "  - 添加二次方程复数解支持"
    echo -e "${YELLOW}[v1.0.0] ${NC}"
    echo "  - 初始版本发布"
    echo "  - 包含基本计算和科学函数"
    echo -e "${CYAN}===========================${NC}"
}

# 在脚本开头添加数学盒子版本号
MATH_BOX_VER="1.1"



# 新增数学盒子菜单
math_box() {
    while true; do
        clear
        echo -e "${CYAN}=== 数学盒子 ===${NC}"
        echo "1) 猜数游戏"
        echo "2) 掷骰子"
        echo "3) 抛硬币"
        echo "4) 质数验证器"
        echo "5) 斐波那契数列生成器"
        echo "6) 数学谜题合集"
        echo "7) 返回主菜单"
        echo "8) 骰子增强（测试）"
        echo "9) 硬币统计（测试）"
        
        read -p "请选择 [1-5] > " choice
        
        case $choice in
            1) play_guessing_game ;;
            2) dice_roller ;;
            3) coin_flipper ;;
            4) prime_checker ;;
            5) fibonacci_generator  ;;
            6) math_puzzles  ;;
            7) break ;;
            8) multi_dice_roller ;;
            9) coin_statistics ;;
            
            *) echo -e "${RED}无效输入！${NC}"; sleep 1 ;;
        esac
    done
}

# 开发中功能提示
developing_feature() {
    echo -e "${YELLOW}[!] $1 正在紧张开发中..."
    echo -e "敬请期待下一个版本！${NC}"
    sleep 2
}

# 集成猜数游戏（需从原脚本移植）
play_guessing_game() {
    # 初始化默认范围
    min=1
    max=100
    
    # 处理启动参数
    if [ $# -eq 2 ]; then
        # 验证参数是否为整数
        if [[ ! $1 =~ ^-?[0-9]+$ || ! $2 =~ ^-?[0-9]+$ ]]; then
            echo -e "\033[31m错误：参数必须是整数！\033[0m"
            echo "用法：$0 [最小值 最大值]"
            exit 1
        fi
        
        # 自动排序大小值
        if [ $1 -lt $2 ]; then
            min=$1
            max=$2
        else
            min=$2
            max=$1
        fi
    elif [ $# -ne 0 ]; then
        echo -e "\033[33m用法：$0 [最小值 最大值]\033[0m"
        exit 1
    fi
    
    # 范围有效性检查
    if [ $min -eq $max ]; then
        echo -e "\033[31m错误：范围不能相同！\033[0m"
        exit 1
    fi
    
    while true; do
    
        echo -e "${GREEN}"
        echo "  \\O/   "
        echo "   |    "
        echo "  / \\   "
        echo -e "${NC}"
        
        # 生成目标数字
        target=$(( RANDOM % (max - min + 1) + min ))
        count=0
        
        echo -e "\n\033[34m欢迎来到猜数游戏（范围：$min ~ $max）\033[0m"
        echo "我已经想好了一个范围内的整数，快来猜猜看吧！"
        if (( target == 666 )); then
            echo -e "\033[31m警告：你唤醒了恶魔数字！\033[0m"
    elif (( target % 100 == 0 )); then
            echo -e "\033[33m恭喜触发百年一遇的整数！\033[0m"
    fi
        while true; do
            read -p "请输入你的猜测（输入q退出）：" guess
            
            # 检查退出
            if [[ "$guess" == "q" ]]; then
                echo -e "\033[33m游戏结束，正确答案是$target\033[0m"
                exit 0
            fi
    
            # 输入验证
            if [[ ! "$guess" =~ ^-?[0-9]+$ ]]; then
                echo -e "\033[31m错误：请输入有效的整数！\033[0m"
                continue
            fi
    
            if (( guess < min || guess > max )); then
                echo -e "\033[31m注意：数字必须在${min}到${max}之间！\033[0m"
                continue
            fi
    
            ((count++))
    
            # 判断结果
            if (( guess == target )); then
                echo -e "\033[32m恭喜！你在第${count}次猜中了正确答案 $target！\033[0m"
                
                break
            elif (( guess < target )); then
                echo -e "\033[36m提示：你猜的数字\033[1m太小了\033[0m\033[36m，继续努力！\033[0m"
            else
                echo -e "\033[35m提示：你猜的数字\033[1m太大了\033[0m\033[35m，继续努力！\033[0m"
            fi
        done
    
        # 重玩逻辑
        read -p "再玩一次？（y/n）[默认使用当前范围] " choice
        case "$choice" in
            [Yy]*) 
                read -p "是否修改数字范围？（y/n）" change_range
                if [[ "$change_range" =~ ^[Yy] ]]; then
                    while true; do
                        read -p "请输入新的最小值：" new_min
                        read -p "请输入新的最大值：" new_max
                        
                        if [[ ! $new_min =~ ^-?[0-9]+$ || ! $new_max =~ ^-?[0-9]+$ ]]; then
                            echo -e "\033[31m错误：必须输入整数！\033[0m"
                            continue
                        fi
                        
                        if [ $new_min -eq $new_max ]; then
                            echo -e "\033[31m错误：范围不能相同！\033[0m"
                            continue
                        fi
                        
                        # 自动排序
                        if [ $new_min -gt $new_max ]; then
                            temp=$new_min
                            new_min=$new_max
                            new_max=$temp
                        fi
                        
                        min=$new_min
                        max=$new_max
                        echo -e "\033[32m范围已更新为：$min ~ $max\033[0m"
                        break
                    done
                fi
                continue 
                ;;
            *) 
                echo -e "\033[33m感谢游玩，再见！\033[0m"
                break 
                ;;
        esac
    done
}
# 新增骰子功能
dice_roller() {
    local dice=$((RANDOM % 6 + 1))
    local color
    
    case $dice in
        1) color=$RED ;;
        2) color=$GREEN ;;
        3) color=$YELLOW ;;
        4) color=$BLUE ;;
        5) color=$MAGENTA ;;
        6) color=$CYAN ;;
    esac

    echo -e "${color}"
    echo "┌───────┐"
    echo "│       │"
    echo "│   $dice   │"
    echo "│       │"
    echo -e "└───────┘${NC}"
    record_history "数学盒子" "掷骰子 → $dice点"
    sleep 1
}

# 新增抛硬币功能 
coin_flipper() {
    local result=$((RANDOM % 2))
    local coin_art
    
    if [ $result -eq 0 ]; then
        coin_art="\e[33m
        ███████████
        █ 正面   █
        ███████████
        ${NC}"
        record_history "数学盒子" "抛硬币 → 正面"
    else
        coin_art="\e[33m
        ███████████
        █ 反面   █
        ███████████
        ${NC}"
        record_history "数学盒子" "抛硬币 → 反面"
    fi
    
    echo -e "$coin_art"
    sleep 1
}

multi_dice_roller() {
    read -p "输入骰子数量: " count
    read -p "输入骰子面数: " faces
    
    total=0
    for ((i=1; i<=count; i++)); do
        roll=$((RANDOM % faces + 1))
        echo "骰子$i: $roll"
        total=$((total + roll))
    
    done
    echo "总计: $total"
    sleep 2
}

coin_statistics() {
    heads=0
    tails=0
    
    for ((i=1; i<=100; i++)); do
        result=$((RANDOM % 2))
        [ $result -eq 0 ] && ((heads++)) || ((tails++))
    
    done
    echo "实验结果（百次抛掷）:"
    echo "正面: ${heads}次"
    echo "反面: ${tails}次"
    sleep 2
}
# 质数验证功能
prime_checker() {
    echo -e "${YELLOW}=== 质数验证器 ===${NC}"
    while true; do
        read -p "输入要验证的正整数 (q退出) > " num
        
        [[ "$num" == "q" ]] && break
        
        if [[ ! "$num" =~ ^[0-9]+$ ]] || ((num < 2)); then
            echo -e "${RED}错误：请输入大于1的正整数！${NC}"
            continue
        fi
        
        is_prime=1
        sqrt_num=$(echo "sqrt($num)" | bc)
        
        for ((i=2; i<=sqrt_num; i++)); do
            if ((num % i == 0)); then
                is_prime=0
                break
            fi
        done

        if ((is_prime)); then
            echo -e "${GREEN}$num 是质数${NC}"
            record_history "质数验证" "$num → 质数"
        else
            echo -e "${BLUE}$num 是合数${NC}"
            record_history "质数验证" "$num → 合数"
        fi
    done
}

# 斐波那契生成器
fibonacci_generator() {
    echo -e "${YELLOW}=== 斐波那契生成器 ===${NC}"
    while true; do
        read -p "输入要生成的项数 (1-50, q退出) > " count
        
        [[ "$count" == "q" ]] && break
        
        if [[ ! "$count" =~ ^[0-9]+$ ]] || ((count < 1 || count > 50)); then
            echo -e "${RED}请输入1-50之间的整数！${NC}"
            continue
        fi

        a=0
        b=1
        echo -n -e "${GREEN}"
        for ((i=1; i<=count; i++)); do
            printf "%'d " $a
            fn=$((a + b))
            a=$b
            b=$fn
            
            # 每行显示5个数字
            ((i % 5 == 0)) && echo
        done
        echo -e "${NC}"
        record_history "斐波那契" "生成${count}项"
    done
}

# 数学谜题合集
math_puzzles() {
    while true; do
        clear
        echo -e "${CYAN}=== 数学谜题合集 ===${NC}"
        echo "1) 水壶量水问题"
        echo "2) 鸡兔同笼问题"
        echo "3) 三人过桥问题"
        echo "4) 返回上级菜单"
        
        read -p "请选择谜题 [1-4] > " puzzle
        
        case $puzzle in
            1) water_jug_problem ;;
            2) chicken_rabbit_problem ;;
            3) bridge_crossing_problem ;;
            4) break ;;
            *) echo -e "${RED}无效选择！${NC}"; sleep 1 ;;
        esac
    done
}

# 水壶量水问题
water_jug_problem() {
    echo -e "${YELLOW}\n问题：有两个水壶，一个5升，一个3升，如何得到4升水？${NC}"
    read -p "查看解答？(y/n) > " ans
    if [[ "$ans" =~ ^[Yy] ]]; then
        echo -e "${GREEN}解法："
        echo "1. 装满5升壶"
        echo "2. 将5升壶的水倒入3升壶，剩下2升"
        echo "3. 倒空3升壶"
        echo "4. 将5升壶中剩余的2升倒入3升壶"
        echo "5. 再次装满5升壶"
        echo "6. 将5升壶的水倒入已有2升的3升壶，剩下4升"
        echo -e "${NC}"
        record_history "数学谜题" "水壶问题解答"
    fi
    sleep 2
}

# 鸡兔同笼问题
chicken_rabbit_problem() {
    echo -e "${YELLOW}\n问题：笼中有鸡兔共35只，脚共94只，求鸡兔各多少？${NC}"
    read -p "查看解答？(y/n) > " ans
    if [[ "$ans" =~ ^[Yy] ]]; then
        echo -e "${GREEN}解法："
        echo "设鸡x只，兔y只"
        echo "x + y = 35"
        echo "2x + 4y = 94"
        echo "解得："
        echo "y = (94 - 2*35)/2 = 12"
        echo "x = 35 - 12 = 23"
        echo "答：鸡23只，兔12只"
        echo -e "${NC}"
        record_history "数学谜题" "鸡兔同笼解答"
    fi
    sleep 2
}

# 三人过桥问题
bridge_crossing_problem() {
    echo -e "${YELLOW}\n问题：四人夜间过桥，每次最多两人，只有一个手电筒"
    echo "过桥时间分别为1、2、5、10分钟，如何17分钟内全部过桥？${NC}"
    read -p "查看解答？(y/n) > " ans
    if [[ "$ans" =~ ^[Yy] ]]; then
        echo -e "${GREEN}解法："
        echo "1. 1和2分钟先过 (2分钟)"
        echo "2. 1分钟返回 (累计3分钟)"
        echo "3. 5和10分钟过桥 (累计13分钟)"
        echo "4. 2分钟返回 (累计15分钟)"
        echo "5. 1和2分钟再过桥 (累计17分钟)"
        echo -e "${NC}"
        record_history "数学谜题" "过桥问题解答"
    fi
    sleep 2
}

# 主界面
main_menu() {
    clear
    echo -e "${BLUE}=== 多功能计算器 v$VERSION ===${NC}"
    echo "1) 基本计算     5) 使用帮助"
    echo "2) 科学计算     6) 方程求解"
    echo "3) 单位转换     7) 金融计算"
    echo "4) 查看历史     8) 复数计算"
    echo "9) 中文大写转换 10) 数学盒子"
    echo "11) 更新日志     12) 退出程序"
}

# 初始化
init_history

# 主循环
while true; do
    main_menu
    read -p "请选择操作 [1-12] > " choice
    
    case $choice in
        1) basic_calculation ;;
        2) scientific_calculation ;;
        3) unit_conversion ;;
        4) show_history ;;
        5) show_help ;;
        6) equation_solver ;;
        7) financial_calculation ;;
        8) complex_calculation ;;
        9) chinese_number_converter ;;
        10) math_box ;;
        11) show_changelog ;; 
        12) echo -e "${GREEN}感谢使用，再见！${NC}"; exit 0 ;;
        *) echo -e "${RED}无效选择，请重新输入！${NC}" ;;
    esac
    
    read -p "按回车键继续..."
done


        case $choice in
            1) play_guessing_game ;;
            2) dice_roller ;;
            3) coin_flipper ;;
            4) prime_checker ;;
            5) fibonacci_generator ;;
            6) math_puzzles ;;
            7) break ;;
            *) echo -e "${RED}无效输入！${NC}"; sleep 1 ;;
        esac
    done
}