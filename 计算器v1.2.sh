#!/bin/bash

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
unit_conversion() {
    echo -e "${CYAN}请选择转换类型："
    echo "1) 温度  2) 长度  3) 重量  4) 数据存储"
    read -p "输入选择 [1-4] > " choice
    
    case $choice in
        1)
            echo -e "温度转换：\n1) 摄氏转华氏  2) 华氏转摄氏"
            read -p "选择转换方向 [1-2] > " dir
            read -p "输入温度值: " temp
            if [ $dir -eq 1 ]; then
                result=$(echo "scale=2; ($temp * 9/5) + 32" | bc)
                echo -e "${GREEN}${temp}°C = ${result}°F${NC}"
                record_history "温度转换" "℃→℉ $result"
            else
                result=$(echo "scale=2; ($temp - 32) * 5/9" | bc)
                echo -e "${GREEN}${temp}°F = ${result}°C${NC}"
                record_history "温度转换" "℉→℃ $result"
            fi
            ;;
        2)
            echo -e "长度转换：\n1) 米→英尺  2) 英尺→米"
            read -p "选择转换方向 [1-2] > " dir
            read -p "输入长度值: " value
            if [ $dir -eq 1 ]; then
                result=$(echo "scale=2; $value * 3.28084" | bc)
                echo -e "${GREEN}${value}m = ${result}ft${NC}"
                record_history "长度转换" "米→英尺 $result"
            else
                result=$(echo "scale=2; $value / 3.28084" | bc)
                echo -e "${GREEN}${value}ft = ${result}m${NC}"
                record_history "长度转换" "英尺→米 $result"
            fi
            ;;
        3)
            echo -e "重量转换：\n1) 千克→磅  2) 磅→千克"
            read -p "选择转换方向 [1-2] > " dir
            read -p "输入重量值: " value
            if [ $dir -eq 1 ]; then
                result=$(echo "scale=2; $value * 2.20462" | bc)
                echo -e "${GREEN}${value}kg = ${result}lb${NC}"
                record_history "重量转换" "kg→lb $result"
            else
                result=$(echo "scale=2; $value / 2.20462" | bc)
                echo -e "${GREEN}${value}lb = ${result}kg${NC}"
                record_history "重量转换" "lb→kg $result"
            fi
            ;;
        4)
            echo -e "数据存储转换：\n1) GB→MB  2) TB→GB"
            read -p "选择转换方向 [1-2] > " dir
            read -p "输入数值: " value
            if [ $dir -eq 1 ]; then
                result=$(echo "$value * 1024" | bc)
                echo -e "${GREEN}${value}GB = ${result}MB${NC}"
                record_history "数据转换" "GB→MB $result"
            else
                result=$(echo "$value * 1024" | bc)
                echo -e "${GREEN}${value}TB = ${result}GB${NC}"
                record_history "数据转换" "TB→GB $result"
            fi
            ;;
        *) echo -e "${RED}无效选择！${NC}"; return ;;
    esac
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

# 主界面
main_menu() {
    clear
    echo -e "${BLUE}=== 多功能计算器 ===${NC}"
    echo "1) 基本计算"
    echo "2) 科学计算"
    echo "3) 单位转换"
    echo "4) 查看历史"
    echo "5) 使用帮助"
    echo "6) 方程求解"
    echo "7) 金融计算"  # 新增项
    echo "8) 退出程序"  # 原7改为8
}

# 初始化
init_history

# 主循环
while true; do
    main_menu
    read -p "请选择操作 [1-6] > " choice
    
    case $choice in
        1) basic_calculation ;;
        2) scientific_calculation ;;
        3) unit_conversion ;;
        4) show_history ;;
        5) show_help ;;
        6) equation_solver ;;
        7) financial_calculation ;;
        7) echo -e "${GREEN}感谢使用，再见！${NC}"; exit 0 ;;
        *) echo -e "${RED}无效选择，请重新输入！${NC}" ;;
    esac
    
    read -p "按回车键继续..."
done
