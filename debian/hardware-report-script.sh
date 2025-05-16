#!/bin/bash

# ====================================
# DEBIAN DONANİM RAPORU GELİŞMİŞ SÜRÜM
# ====================================

# Renk tanımlamaları
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
RESET='\033[0m'
BOLD='\033[1m'

# Terminal genişliğini al
TERM_WIDTH=$(tput cols)
if [ -z "$TERM_WIDTH" ] || [ "$TERM_WIDTH" -lt 80 ]; then
    TERM_WIDTH=80
fi

# Çıktı dosyası seçenekleri
OUTPUT_FILE=""
HTML_OUTPUT=""
INTERACTIVE=false
SELECTED_SECTIONS=""

# Dönen ilerleme göstergesi animasyonu
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    local start_time=$(date +%s)

    echo -ne "${YELLOW}Yükleniyor "

    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))

        local temp=${spinstr#?}
        printf "${YELLOW}[%c] (%ds)${RESET}" "${spinstr}" "$elapsed"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\r"
        echo -ne "${YELLOW}Yükleniyor "
    done

    printf "\r${GREEN}Tamamlandı!    ${RESET}\n"
}

# Eksik araçları otomatik yükleme (sessiz mod)
auto_install_tools() {
    local missing="$1"
    local optional="$2"
    local distro_type=""
    local install_success=true

    # Dağıtım türünü tespit et
    if [ -f /etc/debian_version ]; then
        distro_type="debian"
    elif [ -f /etc/redhat-release ]; then
        distro_type="redhat"
    elif [ -f /etc/arch-release ]; then
        distro_type="arch"
    else
        distro_type="unknown"
    fi

    # Paket isimlerini düzelt
    local packages_to_install=""
    local all_tools="$missing $optional"

    for tool in $all_tools; do
        case $tool in
            "nvidia-smi")
                if [ "$distro_type" = "debian" ]; then
                    if ! dpkg -l | grep -q nvidia-driver; then
                        echo -e "${YELLOW}nvidia-smi için nvidia-driver yüklenecek${RESET}"
                        packages_to_install="$packages_to_install nvidia-driver-525"
                    fi
                fi
                ;;
            "rocm-smi")
                echo -e "${YELLOW}rocm-smi otomatik yüklenemiyor, AMD GPU kullanıyorsanız ROCm'u manuel yüklemelisiniz${RESET}"
                ;;
            "sensors")
                packages_to_install="$packages_to_install lm-sensors"
                ;;
            "hddtemp")
                if [ "$distro_type" = "debian" ]; then
                    sudo add-apt-repository universe -y &>/dev/null
                    packages_to_install="$packages_to_install hddtemp"
                fi
                ;;
            *)
                packages_to_install="$packages_to_install $tool"
                ;;
        esac
    done

    # Boşlukları temizle
    packages_to_install=$(echo "$packages_to_install" | tr -s ' ' | sed 's/^ *//' | sed 's/ *$//')

    if [ -z "$packages_to_install" ]; then
        echo -e "${GREEN}Yüklenecek paket kalmadı.${RESET}"
        return 0
    fi

    echo -e "${CYAN}Paket listesi güncelleniyor...${RESET}"

    case $distro_type in
        debian)
            # Paket listesini güncelle (arka planda)
            sudo apt-get update -qq &>/dev/null &
            update_pid=$!
            show_spinner $update_pid
            wait $update_pid

            # Her paketi ayrı ayrı yükle ve ilerlemeyi göster
            local total_pkgs=$(echo "$packages_to_install" | wc -w)
            local current_pkg=1

            for pkg in $packages_to_install; do
                echo -e "${CYAN}[$current_pkg/$total_pkgs] Yükleniyor: $pkg${RESET}"

                # Paketi arka planda yükle
                sudo apt-get install -y -qq $pkg &>/dev/null &
                install_pid=$!
                show_spinner $install_pid

                # Yükleme işlemi tamamlandı mı kontrol et
                if wait $install_pid; then
                    echo -e "${GREEN}✓ Başarıyla yüklendi: $pkg${RESET}"
                else
                    echo -e "${RED}✗ Yükleme başarısız: $pkg${RESET}"
                    install_success=false
                fi

                ((current_pkg++))
            done
            ;;
        redhat)
            # Benzer şekilde RedHat için yükleme
            for pkg in $packages_to_install; do
                echo -e "${CYAN}Yükleniyor: $pkg${RESET}"
                sudo yum install -y -q $pkg &>/dev/null &
                install_pid=$!
                show_spinner $install_pid

                if wait $install_pid; then
                    echo -e "${GREEN}✓ Başarıyla yüklendi: $pkg${RESET}"
                else
                    echo -e "${RED}✗ Yükleme başarısız: $pkg${RESET}"
                    install_success=false
                fi
            done
            ;;
        arch)
            # Benzer şekilde Arch için yükleme
            for pkg in $packages_to_install; do
                echo -e "${CYAN}Yükleniyor: $pkg${RESET}"
                sudo pacman -S --noconfirm --quiet $pkg &>/dev/null &
                install_pid=$!
                show_spinner $install_pid

                if wait $install_pid; then
                    echo -e "${GREEN}✓ Başarıyla yüklendi: $pkg${RESET}"
                else
                    echo -e "${RED}✗ Yükleme başarısız: $pkg${RESET}"
                    install_success=false
                fi
            done
            ;;
        *)
            echo -e "${RED}Sisteminiz için otomatik yükleme desteklenmiyor.${RESET}"
            return 1
            ;;
    esac

    if [ "$install_success" = true ]; then
        echo -e "${GREEN}Tüm paketler başarıyla yüklendi.${RESET}"
        return 0
    else
        echo -e "${YELLOW}Bazı paketler yüklenemedi, ancak script çalışmaya devam edecek.${RESET}"
        return 1
    fi
}


# Gerekli araçları kontrol et ve eksikleri yükle
check_requirements() {
    echo -e "${YELLOW}Gerekli araçlar kontrol ediliyor...${RESET}"

    MISSING_TOOLS=""

    # Temel araçlar
    for cmd in lscpu free lsblk dmidecode lspci; do
        if ! command -v $cmd &> /dev/null; then
            MISSING_TOOLS="$MISSING_TOOLS $cmd"
        fi
    done

    # Opsiyonel araçlar
    OPTIONAL_TOOLS=""
    for cmd in smartctl xrandr nvidia-smi rocm-smi inxi sensors lm-sensors hddtemp nmap qrencode bc; do
        if ! command -v $cmd &> /dev/null; then
            OPTIONAL_TOOLS="$OPTIONAL_TOOLS $cmd"
        fi
    done

    if [ ! -z "$MISSING_TOOLS" ]; then
        echo -e "${RED}Bazı gerekli araçlar eksik:${RESET} ${MISSING_TOOLS}"
        echo -e "${YELLOW}Bu araçlar olmadan script düzgün çalışmayabilir.${RESET}"
    fi

    if [ ! -z "$OPTIONAL_TOOLS" ]; then
        echo -e "${YELLOW}Bazı opsiyonel araçlar eksik:${RESET} ${OPTIONAL_TOOLS}"
        echo -e "${GRAY}Bu araçları yüklerseniz daha detaylı bilgi alabilirsiniz.${RESET}"
    fi

    if [ ! -z "$MISSING_TOOLS" ] || [ ! -z "$OPTIONAL_TOOLS" ]; then
        echo -e "${YELLOW}Eksik araçları otomatik olarak yüklemek ister misiniz? (e/h)${RESET}"
        read -n 1 -r
        echo
        if [[ $REPLY =~ ^[Ee]$ ]]; then
            auto_install_tools "$MISSING_TOOLS" "$OPTIONAL_TOOLS"
            # Yükleme başarılı ise değişkenleri temizle
            if [ $? -eq 0 ]; then
                MISSING_TOOLS=""
                OPTIONAL_TOOLS=""
            fi
        fi
    fi

    # Gerekli araçlar hala eksikse, devam edip etmeyeceğini sor
    if [ ! -z "$MISSING_TOOLS" ]; then
        echo -e "${YELLOW}Bazı gerekli araçlar hala eksik. Devam etmek istiyor musunuz? (e/h)${RESET}"
        read -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ee]$ ]]; then
            exit 1
        fi
    fi
}

# Başlık çizgisi oluştur
header_line() {
    printf "%${TERM_WIDTH}s\n" | tr ' ' '='
}

# Alt çizgi oluştur
sub_line() {
    printf "%${TERM_WIDTH}s\n" | tr ' ' '-'
}

# Merkezi başlık oluştur
center_text() {
    local text="$1"
    local width=$2
    local text_len=${#text}
    local pad_len=$(( (width - text_len) / 2 ))

    printf "%${pad_len}s%s%${pad_len}s\n" "" "$text" ""
}

# Bölüm başlığı göster
section_title() {
    local title="$1"
    echo ""
    echo -e "${YELLOW}$(header_line)${RESET}"
    echo -e "${WHITE}${BOLD}$(center_text "▶ $title ◀" $TERM_WIDTH)${RESET}"
    echo -e "${YELLOW}$(header_line)${RESET}"
}

# Alt başlık göster
sub_title() {
    local title="$1"
    echo ""
    echo -e "${CYAN}${BOLD} ⦿ $title ${RESET}"
    echo -e "${CYAN}$(sub_line)${RESET}"
}

# İlerleme göstergesi
show_progress() {
    echo -ne "${YELLOW}Veri toplanıyor...${RESET}"
    for i in {1..5}; do
        sleep 0.1
        echo -ne "${YELLOW}.${RESET}"
    done
    echo ""
}

# Html başlangıcı
start_html() {
    if [ ! -z "$HTML_OUTPUT" ]; then
        cat > "$HTML_OUTPUT" << EOF
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Debian Donanım Raporu - $(date)</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            color: #333;
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding: 20px;
            background-color: #2b2b2b;
            color: white;
            border-radius: 5px;
        }
        .section {
            margin-bottom: 30px;
            border: 1px solid #ddd;
            border-radius: 5px;
            overflow: hidden;
        }
        .section-title {
            padding: Spx 15px;
            background-color: #4CAF50;
            color: white;
            font-size: 18px;
            margin: 0;
        }
        .section-content {
            padding: 15px;
        }
        .subsection {
            margin-top: 20px;
            margin-bottom: 15px;
            border-bottom: 1px solid #eee;
        }
        .subsection h3 {
            color: #2196F3;
            margin-bottom: 10px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 15px;
        }
        table, th, td {
            border: 1px solid #ddd;
        }
        th, td {
            padding: 12px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        .highlight {
            font-weight: bold;
            color: #E91E63;
        }
        .progress-container {
            margin-top: 20px;
            width: 100%;
            background-color: #f1f1f1;
            border-radius: 5px;
        }
        .progress-bar {
            height: 20px;
            border-radius: 5px;
        }
        .green { background-color: #4CAF50; }
        .yellow { background-color: #FFEB3B; }
        .red { background-color: #F44336; }
        .item {
            display: flex;
            margin-bottom: 10px;
        }
        .item-label {
            font-weight: bold;
            width: 200px;
        }
        .item-value {
            flex: 1;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding: 10px;
            background-color: #f8f9fa;
            border-radius: 5px;
        }
        .warning {
            color: #FF5722;
        }
        pre {
            background-color: #f8f9fa;
            padding: 10px;
            border-radius: 5px;
            overflow-x: auto;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>Debian Donanım Raporu</h1>
        <p>Oluşturulma Tarihi: $(date)</p>
    </div>
EOF
    fi
}

# Html bölüm başla
html_section_start() {
    local title="$1"
    if [ ! -z "$HTML_OUTPUT" ]; then
        cat >> "$HTML_OUTPUT" << EOF
    <div class="section">
        <h2 class="section-title">$title</h2>
        <div class="section-content">
EOF
    fi
}

# Html alt bölüm başla
html_subsection_start() {
    local title="$1"
    if [ ! -z "$HTML_OUTPUT" ]; then
        cat >> "$HTML_OUTPUT" << EOF
            <div class="subsection">
                <h3>$title</h3>
EOF
    fi
}

# Html alt bölüm bitir
html_subsection_end() {
    if [ ! -z "$HTML_OUTPUT" ]; then
        cat >> "$HTML_OUTPUT" << EOF
            </div>
EOF
    fi
}

# Html bölüm bitir
html_section_end() {
    if [ ! -z "$HTML_OUTPUT" ]; then
        cat >> "$HTML_OUTPUT" << EOF
        </div>
    </div>
EOF
    fi
}

# Html anahtar değer ekle
html_add_keyvalue() {
    local key="$1"
    local value="$2"
    if [ ! -z "$HTML_OUTPUT" ]; then
        cat >> "$HTML_OUTPUT" << EOF
                <div class="item">
                    <div class="item-label">$key</div>
                    <div class="item-value">$value</div>
                </div>
EOF
    fi
}

# Html tablo başla
html_table_start() {
    local headers="$1"
    if [ ! -z "$HTML_OUTPUT" ]; then
        cat >> "$HTML_OUTPUT" << EOF
                <table>
                    <thead>
                        <tr>
EOF
        # Başlıkları ekle
        for header in $headers; do
            echo "                            <th>$header</th>" >> "$HTML_OUTPUT"
        done

        cat >> "$HTML_OUTPUT" << EOF
                        </tr>
                    </thead>
                    <tbody>
EOF
    fi
}

# Html tablo satırı ekle
html_table_row() {
    local cells="$@"
    if [ ! -z "$HTML_OUTPUT" ]; then
        echo "                        <tr>" >> "$HTML_OUTPUT"
        for cell in "$@"; do
            echo "                            <td>$cell</td>" >> "$HTML_OUTPUT"
        done
        echo "                        </tr>" >> "$HTML_OUTPUT"
    fi
}

# Html tablo bitir
html_table_end() {
    if [ ! -z "$HTML_OUTPUT" ]; then
        cat >> "$HTML_OUTPUT" << EOF
                    </tbody>
                </table>
EOF
    fi
}

# Html pre bloğu ekle
html_pre_start() {
    if [ ! -z "$HTML_OUTPUT" ]; then
        cat >> "$HTML_OUTPUT" << EOF
                <pre>
EOF
    fi
}

# Html pre bloğu bitir
html_pre_end() {
    if [ ! -z "$HTML_OUTPUT" ]; then
        cat >> "$HTML_OUTPUT" << EOF
                </pre>
EOF
    fi
}

# Html içeriğe metin ekle
html_add_text() {
    local text="$1"
    if [ ! -z "$HTML_OUTPUT" ]; then
        echo "$text" >> "$HTML_OUTPUT"
    fi
}

# Html ilerleme çubuğu ekle
html_add_progress() {
    local value="$1"
    local max="$2"
    local text="$3"

    # bc ile ondalık hesaplama yap
    if command -v bc &> /dev/null; then
        percentage=$(echo "scale=0; $value * 100 / $max" | bc)
    else
        # bc yoksa, ondalık noktalarını kaldır
        value=$(echo "$value" | sed 's/\..*//')
        max=$(echo "$max" | sed 's/\..*//')
        percentage=$(( value * 100 / max ))
    fi

    # Değerleri kontrol et
    if [ -z "$percentage" ] || [ "$percentage" -lt 0 ] || [ "$percentage" -gt 100 ]; then
        percentage=50  # Varsayılan değer
    fi

    local color="green"

    if [ $percentage -gt 80 ]; then
        color="red"
    elif [ $percentage -gt 60 ]; then
        color="yellow"
    fi

    if [ ! -z "$HTML_OUTPUT" ]; then
        cat >> "$HTML_OUTPUT" << EOF
                <div class="progress-container">
                    <div class="progress-bar $color" style="width:${percentage}%"></div>
                </div>
                <p>$text: $percentage%</p>
EOF
    fi
}

# Html bitir
end_html() {
    if [ ! -z "$HTML_OUTPUT" ]; then
        cat >> "$HTML_OUTPUT" << EOF
    <div class="footer">
        <p>Debian Donanım Raporu &copy; $(date +%Y)</p>
    </div>
</body>
</html>
EOF
    fi
}

# CPU Bilgisi toplama
get_cpu_info() {
    if [[ $INTERACTIVE == false ]] || [[ $SELECTED_SECTIONS == *"cpu"* ]]; then
        section_title "CPU BİLGİSİ"
        show_progress

        html_section_start "CPU BİLGİSİ"

        sub_title "CPU Genel Bilgisi"
        html_subsection_start "CPU Genel Bilgisi"

        cpu_model=$(lscpu | grep 'Model name' | sed 's/Model name:[[:space:]]*//')
        cpu_arch=$(lscpu | grep 'Architecture' | awk '{print $2}')
        cpu_cores=$(nproc)
        cpu_freq=$(lscpu | grep 'CPU MHz' | awk '{print $3}')

        echo -e "${BOLD}CPU Modeli:${RESET} ${GREEN}$cpu_model${RESET}"
        html_add_keyvalue "CPU Modeli" "$cpu_model"

        echo -e "${BOLD}CPU Mimarisi:${RESET} ${GREEN}$cpu_arch${RESET}"
        html_add_keyvalue "CPU Mimarisi" "$cpu_arch"

        echo -e "${BOLD}Toplam Çekirdek Sayısı:${RESET} ${GREEN}$cpu_cores${RESET}"
        html_add_keyvalue "Toplam Çekirdek Sayısı" "$cpu_cores"

        echo -e "${BOLD}CPU Frekansı:${RESET} ${GREEN}$cpu_freq MHz${RESET}"
        html_add_keyvalue "CPU Frekansı" "$cpu_freq MHz"

        html_subsection_end

        sub_title "Detaylı CPU Bilgisi"
        html_subsection_start "Detaylı CPU Bilgisi"

        lscpu_output=$(lscpu | grep -E 'Thread|Core|Socket|NUMA|Vendor|Stepping|BogoMIPS|L[1-3]')

        html_table_start "Özellik Değer"

        while IFS= read -r line; do
            key=$(echo "$line" | awk -F: '{print $1}')
            value=$(echo "$line" | awk -F: '{print $2}' | sed 's/^[ \t]*//')
            echo -e "${BOLD}$key:${RESET} ${GREEN}$value${RESET}"
            html_table_row "$key" "$value"
        done <<< "$lscpu_output"

        html_table_end
        html_subsection_end

        # CPU Sıcaklık Bilgisi
        if command -v sensors &> /dev/null; then
            sub_title "CPU Sıcaklık Bilgisi"
            html_subsection_start "CPU Sıcaklık Bilgisi"

            sensors_output=$(sensors | grep -A4 -i "core\|package" | grep -v "power\|adapter")

            if [ ! -z "$sensors_output" ]; then
                html_pre_start
                echo -e "${GREEN}$sensors_output${RESET}"
                html_add_text "$sensors_output"
                html_pre_end

                # Kritik sıcaklıkları kontrol et
                high_temp=$(sensors | grep -i "high" | grep -o "[0-9]\+\.[0-9]\+" | sort -nr | head -1)
                crit_temp=$(sensors | grep -i "crit" | grep -o "[0-9]\+\.[0-9]\+" | sort -nr | head -1)
                curr_temp=$(sensors | grep -i "core\|package" | grep -o "+[0-9]\+\.[0-9]\+°C" | sed 's/+\|°C//g' | sort -nr | head -1)

                if (( $(echo "$curr_temp > $crit_temp*0.9" | bc -l) )); then
                    echo -e "${RED}UYARI: CPU sıcaklığı kritik seviyeye yakın!${RESET}"
                    html_add_text "<p class='warning'>UYARI: CPU sıcaklığı kritik seviyeye yakın!</p>"
                elif (( $(echo "$curr_temp > $high_temp*0.9" | bc -l) )); then
                    echo -e "${YELLOW}UYARI: CPU sıcaklığı yüksek seviyeye yakın!${RESET}"
                    html_add_text "<p class='warning'>UYARI: CPU sıcaklığı yüksek seviyeye yakın!</p>"
                fi

                html_add_progress "$curr_temp" "$crit_temp" "CPU Sıcaklık Seviyesi"
            else
                echo -e "${YELLOW}CPU sıcaklık bilgisi bulunamadı.${RESET}"
                html_add_text "CPU sıcaklık bilgisi bulunamadı."
            fi

            html_subsection_end
        fi
        html_section_end
    fi
}

# RAM Bilgisi toplama
get_ram_info() {
    if [[ $INTERACTIVE == false ]] || [[ $SELECTED_SECTIONS == *"ram"* ]]; then
        section_title "RAM BİLGİSİ"
        show_progress

        html_section_start "RAM BİLGİSİ"

        sub_title "RAM Genel Bilgisi"
        html_subsection_start "RAM Genel Bilgisi"

        total_ram=$(free -h | grep 'Mem' | awk '{print $2}')
        used_ram=$(free -h | grep 'Mem' | awk '{print $3}')
        free_ram=$(free -h | grep 'Mem' | awk '{print $4}')

        # Kullanım yüzdesi hesapla
        total_ram_bytes=$(free | grep 'Mem' | awk '{print $2}')
        used_ram_bytes=$(free | grep 'Mem' | awk '{print $3}')
        ram_percent=$((used_ram_bytes * 100 / total_ram_bytes))

        echo -e "${BOLD}Toplam RAM:${RESET} ${GREEN}$total_ram${RESET}"
        echo -e "${BOLD}Kullanılan RAM:${RESET} ${YELLOW}$used_ram${RESET}"
        echo -e "${BOLD}Boş RAM:${RESET} ${GREEN}$free_ram${RESET}"

        # Görsel RAM kullanım çubuğu
        ram_bar_len=$(( TERM_WIDTH - 20 ))
        ram_used_len=$(( ram_bar_len * used_ram_bytes / total_ram_bytes ))
        ram_free_len=$(( ram_bar_len - ram_used_len ))

        echo -ne "${BOLD}RAM Kullanımı [${RESET}"
        for ((i=0; i<ram_used_len; i++)); do
            if (( ram_percent > 80 )); then
                echo -ne "${RED}#${RESET}"
            elif (( ram_percent > 60 )); then
                echo -ne "${YELLOW}#${RESET}"
            else
                echo -ne "${GREEN}#${RESET}"
            fi
        done

        for ((i=0; i<ram_free_len; i++)); do
            echo -ne "${GRAY}.${RESET}"
        done
        echo -e "${BOLD}] $ram_percent%${RESET}"

        html_add_keyvalue "Toplam RAM" "$total_ram"
        html_add_keyvalue "Kullanılan RAM" "$used_ram"
        html_add_keyvalue "Boş RAM" "$free_ram"
        html_add_progress "$used_ram_bytes" "$total_ram_bytes" "RAM Kullanımı"

        html_subsection_end

        sub_title "RAM Modül Bilgileri"
        html_subsection_start "RAM Modül Bilgileri"

        ram_info=$(sudo dmidecode -t memory | grep -E 'Size|Type|Speed|Manufacturer|Serial Number|Part Number' | grep -v "^#")

        html_table_start "Özellik Değer"

        current_module=""
        while IFS= read -r line; do
            if [[ $line == *"Size"* ]]; then
                if [ ! -z "$current_module" ]; then
                    echo ""
                fi
                current_module=$(echo "$line" | sed 's/^\s*//')
                echo -e "\n${PURPLE}● $current_module${RESET}"
            else
                formatted_line=$(echo "$line" | sed 's/^\s*//')
                key=$(echo "$formatted_line" | awk -F: '{print $1}')
                value=$(echo "$formatted_line" | awk -F: '{print $2}' | sed 's/^[ \t]*//')
                echo -e "  ${BOLD}$key:${RESET} ${CYAN}$value${RESET}"
                html_table_row "$current_module: $key" "$value"
            fi
        done <<< "$ram_info"

        html_table_end

        # RAM Performans Testi
        if command -v mbw &> /dev/null; then
            sub_title "RAM Hız Testi"
            html_subsection_start "RAM Hız Testi"

            echo -e "${YELLOW}RAM hız testi çalıştırılıyor...${RESET}"
            mbw_output=$(mbw -q -n 5 100)

            html_pre_start
            echo -e "${GREEN}$mbw_output${RESET}"
            html_add_text "$mbw_output"
            html_pre_end

            html_subsection_end
        else
            # Basit RAM Hız Testi
            sub_title "Basit RAM Hız Testi"
            html_subsection_start "Basit RAM Hız Testi"

            echo -e "${YELLOW}Basit RAM testi çalıştırılıyor...${RESET}"

            # 1GB veri oluştur ve zamanını ölç
            start_time=$(date +%s.%N)
            dd if=/dev/zero of=/tmp/ram_test bs=1M count=1024 status=none
            end_time=$(date +%s.%N)
            write_time=$(echo "$end_time - $start_time" | bc)
            write_speed=$(echo "scale=2; 1024 / $write_time" | bc)

            # Veriyi oku ve zamanını ölç
            start_time=$(date +%s.%N)
            dd if=/tmp/ram_test of=/dev/null bs=1M status=none
            end_time=$(date +%s.%N)
            read_time=$(echo "$end_time - $start_time" | bc)
            read_speed=$(echo "scale=2; 1024 / $read_time" | bc)

            # Temizlik
            rm /tmp/ram_test

            echo -e "${BOLD}Yazma Hızı:${RESET} ${GREEN}$write_speed MB/s${RESET}"
            echo -e "${BOLD}Okuma Hızı:${RESET} ${GREEN}$read_speed MB/s${RESET}"

            html_add_keyvalue "Yazma Hızı" "$write_speed MB/s"
            html_add_keyvalue "Okuma Hızı" "$read_speed MB/s"

            html_subsection_end
        fi

        html_section_end
    fi
}

# GPU Bilgisi toplama
get_gpu_info() {
    if [[ $INTERACTIVE == false ]] || [[ $SELECTED_SECTIONS == *"gpu"* ]]; then
        section_title "GPU BİLGİSİ"
        show_progress

        html_section_start "GPU BİLGİSİ"

        if command -v lspci &> /dev/null; then
            sub_title "GPU Modeli"
            html_subsection_start "GPU Modeli"

            gpu_info=$(lspci | grep -E 'VGA|3D|Display' | sed 's/.*: //')

            html_pre_start
            echo -e "${GREEN}$gpu_info${RESET}"
            html_add_text "$gpu_info"
            html_pre_end

            html_subsection_end

            # NVIDIA GPU için ekstra bilgi
            if lspci | grep -i nvidia &> /dev/null && command -v nvidia-smi &> /dev/null; then
                sub_title "NVIDIA GPU Detayları"
                html_subsection_start "NVIDIA GPU Detayları"

                nvidia_info=$(nvidia-smi --query-gpu=name,driver_version,memory.total,utilization.gpu,temperature.gpu --format=csv,noheader)

                name=$(echo "$nvidia_info" | awk -F, '{print $1}')
                driver=$(echo "$nvidia_info" | awk -F, '{print $2}')
                memory=$(echo "$nvidia_info" | awk -F, '{print $3}')
                util=$(echo "$nvidia_info" | awk -F, '{print $4}')
                temp=$(echo "$nvidia_info" | awk -F, '{print $5}')

                echo -e "${BOLD}GPU Adı:${RESET} ${GREEN}$name${RESET}"
                echo -e "${BOLD}Sürücü Versiyonu:${RESET} ${GREEN}$driver${RESET}"
                echo -e "${BOLD}Toplam Bellek:${RESET} ${GREEN}$memory${RESET}"
                echo -e "${BOLD}Kullanım:${RESET} ${GREEN}$util${RESET}"
                echo -e "${BOLD}Sıcaklık:${RESET} ${GREEN}$temp°C${RESET}"

                html_add_keyvalue "GPU Adı" "$name"
                html_add_keyvalue "Sürücü Versiyonu" "$driver"
                html_add_keyvalue "Toplam Bellek" "$memory"
                html_add_keyvalue "Kullanım" "$util"
                html_add_keyvalue "Sıcaklık" "$temp°C"

                # GPU detaylı bilgi
                echo -e "\n${YELLOW}Detaylı GPU bilgisi alınıyor...${RESET}"
                nvidia_detailed=$(nvidia-smi -q)

                # Performance state
                perf_state=$(echo "$nvidia_detailed" | grep "Performance State" | head -1 | awk '{print $3}')
                echo -e "${BOLD}Performans Durumu:${RESET} ${GREEN}$perf_state${RESET}"
                html_add_keyvalue "Performans Durumu" "$perf_state"

                # Power draw
                power_draw=$(echo "$nvidia_detailed" | grep "Power Draw" | head -1 | awk '{print $3 $4}')
                if [ ! -z "$power_draw" ]; then
                    echo -e "${BOLD}Güç Tüketimi:${RESET} ${GREEN}$power_draw${RESET}"
                    html_add_keyvalue "Güç Tüketimi" "$power_draw"
                fi

                # Fan Speed
                fan_speed=$(echo "$nvidia_detailed" | grep "Fan Speed" | head -1 | awk '{print $3 $4}')
                if [ ! -z "$fan_speed" ]; then
                    echo -e "${BOLD}Fan Hızı:${RESET} ${GREEN}$fan_speed${RESET}"
                    html_add_keyvalue "Fan Hızı" "$fan_speed"
                fi

                # Bellek kullanımı
                mem_used=$(echo "$nvidia_detailed" | grep "Used" | head -1 | awk '{print $3 $4}')
                if [ ! -z "$mem_used" ]; then
                    echo -e "${BOLD}Kullanılan Bellek:${RESET} ${GREEN}$mem_used${RESET}"
                    html_add_keyvalue "Kullanılan Bellek" "$mem_used"
                fi

                html_subsection_end
            fi

            # AMD GPU için ekstra bilgi
            if lspci | grep -i amd &> /dev/null && command -v rocm-smi &> /dev/null; then
                sub_title "AMD GPU Detayları"
                html_subsection_start "AMD GPU Detayları"

                html_pre_start
                rocm_smi=$(rocm-smi --showproductname --showmeminfo vram --showuse --showclocks --showtemp)
                echo -e "${GREEN}$rocm_smi${RESET}"
                html_add_text "$rocm_smi"
                html_pre_end

                html_subsection_end
            fi

            # Entegre ve diğer GPU'lar için bilgi
            if lspci | grep -i intel &> /dev/null && ! (lspci | grep -i nvidia &> /dev/null) && ! (lspci | grep -i amd &> /dev/null); then
                sub_title "Entegre GPU Detayları"
                html_subsection_start "Entegre GPU Detayları"

                intel_info=$(lspci | grep -i "vga\|3d\|display" | grep -i intel)
                if [ ! -z "$intel_info" ]; then
                    echo -e "${BOLD}Entegre GPU:${RESET} ${GREEN}$intel_info${RESET}"
                    html_add_keyvalue "Entegre GPU" "$intel_info"

                    # Intel GPU sürücü bilgisi
                    intel_driver=$(glxinfo | grep "OpenGL renderer" | sed 's/OpenGL renderer string: //')
                    if [ ! -z "$intel_driver" ]; then
                        echo -e "${BOLD}OpenGL Renderer:${RESET} ${GREEN}$intel_driver${RESET}"
                        html_add_keyvalue "OpenGL Renderer" "$intel_driver"
                    fi

                    # Intel GPU sıcaklığı (sensörler ile)
                    if command -v sensors &> /dev/null; then
                        intel_temp=$(sensors | grep -i "temp1\|CPU\|core" | head -1)
                        if [ ! -z "$intel_temp" ]; then
                            echo -e "${BOLD}GPU Sıcaklığı (tahmini):${RESET} ${GREEN}$intel_temp${RESET}"
                            html_add_keyvalue "GPU Sıcaklığı (tahmini)" "$intel_temp"
                        fi
                    fi
                fi

                html_subsection_end
            fi
        else
            echo -e "${RED}GPU bilgisi alınamadı. 'lspci' komutu bulunamadı.${RESET}"
            html_add_text "<p class='warning'>GPU bilgisi alınamadı. 'lspci' komutu bulunamadı.</p>"
        fi

        html_section_end
    fi
}

# Disk Bilgisi toplama
get_disk_info() {
    if [[ $INTERACTIVE == false ]] || [[ $SELECTED_SECTIONS == *"disk"* ]]; then
        section_title "DİSK BİLGİSİ"
        show_progress

        html_section_start "DİSK BİLGİSİ"

        sub_title "Disk Kullanımı"
        html_subsection_start "Disk Kullanımı"

        disk_usage=$(df -h | grep -E '^/dev')

        echo -e "${BOLD}Dosya Sistemi      Boyut  Kull  Boş  Kull%  Monte Noktası${RESET}"
        echo -e "${YELLOW}$(sub_line)${RESET}"

        html_table_start "Dosya Sistemi Boyut Kullanılan Boş Kullanım% Monte Noktası"

        while IFS= read -r line; do
            fs=$(echo "$line" | awk '{print $1}')
            size=$(echo "$line" | awk '{print $2}')
            used=$(echo "$line" | awk '{print $3}')
            avail=$(echo "$line" | awk '{print $4}')
            usep=$(echo "$line" | awk '{print $5}')
            mount=$(echo "$line" | awk '{print $6}')

            # Doluluk oranına göre renk belirle
            used_color=$GREEN
            if [[ $usep == *9?%* ]] || [[ $usep == *8?%* ]]; then
                used_color=$YELLOW
            elif [[ $usep == *100%* ]] || [[ $usep == *9[5-9]%* ]]; then
                used_color=$RED
            fi

            echo -e "$fs  $size  $used  $avail  ${used_color}$usep${RESET}  $mount"
            html_table_row "$fs" "$size" "$used" "$avail" "$usep" "$mount"
        done <<< "$disk_usage"

        html_table_end
        html_subsection_end

        sub_title "Disklerin Marka ve Modeli"
        html_subsection_start "Disklerin Marka ve Modeli"

        lsblk_output=$(lsblk -o NAME,SIZE,MODEL,SERIAL,VENDOR,TYPE | grep -v loop)

        html_pre_start
        echo -e "$lsblk_output" | sed 's/^/  /'
        html_add_text "$lsblk_output"
        html_pre_end

        html_subsection_end

        # SMART Bilgisi (eğer kuruluysa)
        if command -v smartctl &> /dev/null; then
            sub_title "Disk Sağlık Bilgisi"
            html_subsection_start "Disk Sağlık Bilgisi"

            for disk in $(lsblk -d -o NAME | grep -v loop | grep -v NAME); do
                echo -e "\n${PURPLE}● Disk /dev/$disk ${RESET}"
                smart_info=$(sudo smartctl -i /dev/$disk | grep -E 'Model|Serial|Firmware|User|SMART')

                html_add_text "<h4>Disk /dev/$disk</h4>"
                html_table_start "Özellik Değer"

                while IFS= read -r line; do
                    key=$(echo "$line" | awk -F: '{print $1}')
                    value=$(echo "$line" | awk -F: '{print $2}' | sed 's/^[ \t]*//')
                    echo -e "  ${BOLD}$key:${RESET} ${CYAN}$value${RESET}"
                    html_table_row "$key" "$value"
                done <<< "$smart_info"

                html_table_end

                # Disk sağlık durumu
                echo -e "\n  ${BOLD}Disk Sağlık Kontrolü:${RESET}"
                smart_health=$(sudo smartctl -H /dev/$disk | grep -i "health")

                if [[ $smart_health == *"PASSED"* ]]; then
                    echo -e "  ${GREEN}$smart_health${RESET}"
                    html_add_text "<p style='color: green;'>$smart_health</p>"
                else
                    echo -e "  ${RED}$smart_health${RESET}"
                    html_add_text "<p style='color: red;'>$smart_health</p>"
                fi

                # Disk sıcaklığı
                smart_temp=$(sudo smartctl -A /dev/$disk | grep -i "temperature" | head -1)
                if [ ! -z "$smart_temp" ]; then
                    echo -e "  ${BOLD}Disk Sıcaklığı:${RESET} ${CYAN}$smart_temp${RESET}"
                    html_add_text "<p>Disk Sıcaklığı: $smart_temp</p>"
                fi

                # Önemli SMART özellikleri
                echo -e "\n  ${BOLD}Önemli SMART Değerleri:${RESET}"
                html_add_text "<h5>Önemli SMART Değerleri:</h5>"
                html_table_start "Özellik Değer Eşik Durum"

                smart_attrs=$(sudo smartctl -A /dev/$disk | grep -E "Reallocated|Spin|Current_Pending|Offline_Uncorrectable|UDMA_CRC|Seek_Error|Error")
                while IFS= read -r line; do
                    if [ ! -z "$line" ]; then
                        id=$(echo "$line" | awk '{print $1}')
                        attr=$(echo "$line" | awk '{print $2}')
                        value=$(echo "$line" | awk '{print $4}')
                        threshold=$(echo "$line" | awk '{print $6}')

                        # Durum kontrolü
                        status="✅ İyi"
                        status_color=$GREEN
                        if [[ "$attr" == "Reallocated_Sector_Ct" ]] && [[ "$value" -gt 0 ]]; then
                            status="⚠️ Dikkat"
                            status_color=$YELLOW
                        elif [[ "$attr" == "Current_Pending_Sector" ]] && [[ "$value" -gt 0 ]]; then
                            status="⚠️ Dikkat"
                            status_color=$YELLOW
                        elif [[ "$attr" == "Offline_Uncorrectable" ]] && [[ "$value" -gt 0 ]]; then
                            status="❌ Kritik"
                            status_color=$RED
                        elif [[ "$attr" == *"Error"* ]] && [[ "$value" -gt 0 ]]; then
                            status="⚠️ Dikkat"
                            status_color=$YELLOW
                        fi

                        echo -e "  ${BOLD}$id $attr:${RESET} Değer: $value, Eşik: $threshold | ${status_color}$status${RESET}"
                        html_table_row "$id $attr" "$value" "$threshold" "$status"
                    fi
                done <<< "$smart_attrs"

                html_table_end

                # Disk performans testi
                echo -e "\n  ${BOLD}Disk Performansı:${RESET}"
                html_add_text "<h5>Disk Performansı:</h5>"

                echo -e "  ${YELLOW}Kısa disk okuma/yazma testi yapılıyor...${RESET}"

                # Yazma testi
                echo -e "  ${BOLD}Yazma Hızı:${RESET} "
                write_speed=$(dd if=/dev/zero of=/tmp/disk_test bs=64k count=1024 conv=fdatasync status=none 2>&1 | grep -o "[0-9.]* [MG]B/s" || echo "Test başarısız oldu")
                echo -e "  ${GREEN}$write_speed${RESET}"
                html_add_keyvalue "Yazma Hızı" "$write_speed"

                # Okuma testi
                echo -e "  ${BOLD}Okuma Hızı:${RESET} "
                read_speed=$(dd if=/tmp/disk_test of=/dev/null bs=64k status=none 2>&1 | grep -o "[0-9.]* [MG]B/s" || echo "Test başarısız oldu")
                rm -f /tmp/disk_test
                echo -e "  ${GREEN}$read_speed${RESET}"
                html_add_keyvalue "Okuma Hızı" "$read_speed"
            done

            html_subsection_end
        fi

        # İlave disk I/O istatistikleri
        sub_title "Disk I/O İstatistikleri"
        html_subsection_start "Disk I/O İstatistikleri"

        iostat_output=""
        if command -v iostat &> /dev/null; then
            iostat_output=$(iostat -d -x | grep -v loop)
        else
            iostat_output="Disk I/O istatistikleri için 'iostat' komutu bulunamadı."
        fi

        html_pre_start
        echo -e "${GREEN}$iostat_output${RESET}"
        html_add_text "$iostat_output"
        html_pre_end

        html_subsection_end

        html_section_end
    fi
}

# Monitor Bilgisi toplama
get_monitor_info() {
    if [[ $INTERACTIVE == false ]] || [[ $SELECTED_SECTIONS == *"monitor"* ]]; then
        section_title "MONİTÖR BİLGİSİ"
        show_progress

        html_section_start "MONİTÖR BİLGİSİ"

        if command -v xrandr &> /dev/null; then
            sub_title "Bağlı Monitörler"
            html_subsection_start "Bağlı Monitörler"

            monitors=$(xrandr --query | grep " connected" | awk '{print $1}')

            html_table_start "Bağlı Monitörler"
            while read -r monitor; do
                echo -e "${PURPLE}● $monitor${RESET}"
                html_table_row "$monitor"
            done <<< "$monitors"
            html_table_end

            html_subsection_end

            sub_title "Monitör Çözünürlükleri ve Yenileme Hızları"
            html_subsection_start "Monitör Çözünürlükleri ve Yenileme Hızları"

            monitors_info=$(xrandr | grep " connected" -A1 | grep -v disconnected)

            html_pre_start
            while IFS= read -r line; do
                if [[ $line == *"connected"* ]]; then
                    echo -e "\n${PURPLE}● $(echo $line | awk '{print $1}')${RESET}"
                    monitor_info=$(echo "$line" | sed "s/^[^ ]* //")
                    echo -e "  ${GREEN}$monitor_info${RESET}"
                else
                    resolution=$(echo "$line" | tr -s ' ' | sed 's/^ */    /')
                    echo -e "  ${CYAN}$resolution${RESET}"
                fi
            done <<< "$monitors_info"
            html_add_text "$monitors_info"
            html_pre_end

            html_subsection_end

            sub_title "Monitör Marka ve Model Bilgileri"
            html_subsection_start "Monitör Marka ve Model Bilgileri"

            html_table_start "Monitör Özellik Değer"

            for monitor in $(xrandr --query | grep " connected" | awk '{print $1}'); do
                echo -e "\n${PURPLE}● Monitör: $monitor${RESET}"
                html_add_text "<h4>Monitör: $monitor</h4>"

                # EDID verilerini al
                edid_hex=$(xrandr --prop | grep -A10 "^$monitor" | grep -i "EDID" | sed 's/.*EDID: //')

                if [ ! -z "$edid_hex" ]; then
                    # Üretici kodunu çıkar (EDID byte 8-9)
                    manufacturer_hex=$(echo $edid_hex | cut -d' ' -f9-10 | tr -d ' ')

                    # ASCII değerlerini hesapla (ham yöntemle yaklaşık)
                    man_id=$(printf "%d %d %d\n" 0x${manufacturer_hex:0:2} 0x${manufacturer_hex:2:2} 0x${manufacturer_hex:4:2} 2>/dev/null)
                    echo -e "  ${BOLD}Üretici Kodu:${RESET} ${GREEN}$(echo $man_id | tr -cd '[:print:]')${RESET}"
                    html_table_row "$monitor" "Üretici Kodu" "$(echo $man_id | tr -cd '[:print:]')"

                    # Model adı varsa ekrana yazdır (genellikle EDID'nin sonlarında)
                    model_desc=$(echo $edid_hex | tr -d ' ' | grep -o -E '00fc00[0-9a-f]{26}' | sed 's/00fc00//')
                    if [ ! -z "$model_desc" ]; then
                        model=$(echo $model_desc | xxd -r -p 2>/dev/null | tr -cd '[:print:]')
                        echo -e "  ${BOLD}Model:${RESET} ${GREEN}$model${RESET}"
                        html_table_row "$monitor" "Model" "$model"
                    fi
                fi

                # Xorg loglarından monitör bilgilerini çıkar (alternatif yöntem)
                if [ -f "/var/log/Xorg.0.log" ]; then
                    xorg_info=$(grep -i "$monitor" -A5 /var/log/Xorg.0.log | grep -E "EDID|Manufacturer|Model|Serial" | head -5)
                    if [ ! -z "$xorg_info" ]; then
                        echo -e "  ${BOLD}Xorg Loglarından:${RESET}"
                        echo "$xorg_info" | sed 's/^/    /'

                        while IFS= read -r xline; do
                            key=$(echo "$xline" | sed -r 's/.*\((.*)\).*/\1/')
                            value=$(echo "$xline" | sed -r 's/.*: (.*)/\1/')
                            if [ ! -z "$key" ] && [ ! -z "$value" ]; then
                                html_table_row "$monitor" "$key" "$value"
                            fi
                        done <<< "$xorg_info"
                    fi
                fi

                # /sys dosya sisteminden EDID okuma (daha güvenilir)
                for card in /sys/class/drm/card*-*/; do
                    if [ -f "$card/edid" ] && basename $card | grep -q "$monitor" 2>/dev/null; then
                        echo -e "  ${BOLD}/sys'den EDID:${RESET}"
                        # Monitor adını al
                        sys_info=$(cat $card/edid 2>/dev/null | dd bs=1 skip=54 count=72 2>/dev/null | strings | grep -v "^$")
                        if [ ! -z "$sys_info" ]; then
                            echo "$sys_info" | sed 's/^/    /'
                            html_table_row "$monitor" "EDID Bilgisi" "$sys_info"
                        fi
                        # Üretici bilgisini al
                        sys_vendor=$(cat $card/edid 2>/dev/null | dd bs=1 count=20 2>/dev/null | strings | grep -v "^$")
                        if [ ! -z "$sys_vendor" ]; then
                            echo "$sys_vendor" | sed 's/^/    /'
                            html_table_row "$monitor" "Üretici" "$sys_vendor"
                        fi
                    fi
                done
            done

            html_table_end

            html_subsection_end
        else
            echo -e "${RED}xrandr bulunamadı, monitor bilgileri alınamıyor.${RESET}"
            html_add_text "<p class='warning'>xrandr bulunamadı, monitor bilgileri alınamıyor.</p>"
        fi

        # İlave X11 monitör bilgileri
        if command -v xdpyinfo &> /dev/null; then
            sub_title "Ekran Boyutları ve DPI Bilgisi"
            html_subsection_start "Ekran Boyutları ve DPI Bilgisi"

            xdpyinfo_output=$(xdpyinfo | grep -E 'dimensions|resolution')

            while IFS= read -r line; do
                key=$(echo "$line" | awk '{print $1}')
                value=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^[ \t]*//')
                echo -e "${BOLD}$key:${RESET} ${GREEN}$value${RESET}"
                html_add_keyvalue "$key" "$value"
            done <<< "$xdpyinfo_output"

            html_subsection_end
        fi

        # inxi ile grafik ve ekran bilgileri (eğer kuruluysa)
        if command -v inxi &> /dev/null; then
            sub_title "inxi ile Monitör Bilgileri"
            html_subsection_start "inxi ile Monitör Bilgileri"

            inxi_output=$(inxi -G)

            html_pre_start
            echo -e "$inxi_output" | sed 's/^/  /'
            html_add_text "$inxi_output"
            html_pre_end

            html_subsection_end
        fi

        # Alternatif olarak DMI'dan monitör arama (bazen sadece entegre ekranlarda çalışır)
        if sudo dmidecode | grep -A5 "Monitor" > /dev/null; then
            sub_title "DMI'dan Monitör Bilgileri"
            html_subsection_start "DMI'dan Monitör Bilgileri"

            dmi_info=$(sudo dmidecode | grep -A10 "Monitor" | grep -E "Manufacturer|Product|Serial")

            html_table_start "Özellik Değer"

            while IFS= read -r line; do
                key=$(echo "$line" | awk -F: '{print $1}' | sed 's/^\s*//')
                value=$(echo "$line" | awk -F: '{print $2}' | sed 's/^[ \t]*//')
                echo -e "  ${BOLD}$key:${RESET} ${CYAN}$value${RESET}"
                html_table_row "$key" "$value"
            done <<< "$dmi_info"

            html_table_end

            html_subsection_end
        fi

        html_section_end
    fi
}

# Ağ Donanımı Bilgisi toplama
get_network_info() {
    if [[ $INTERACTIVE == false ]] || [[ $SELECTED_SECTIONS == *"network"* ]]; then
        section_title "AĞ DONANIMI BİLGİSİ"
        show_progress

        html_section_start "AĞ DONANIMI BİLGİSİ"

        sub_title "Ağ Arayüzleri"
        html_subsection_start "Ağ Arayüzleri"

        if command -v ip &> /dev/null; then
            ip_output=$(ip -c addr)
            interfaces=$(ip -o -4 addr show | awk '{print $2}' | sort | uniq)

            html_table_start "Arayüz IP Adresi MAC Adresi Durum"

            while read -r interface; do
                echo -e "\n${PURPLE}● Arayüz: $interface${RESET}"

                ip_addr=$(ip -o -4 addr show $interface | awk '{print $4}')
                mac_addr=$(ip link show $interface | grep -o "link/ether [0-9a-f:]\+" | sed 's/link\/ether //')
                link_state=$(ip link show $interface | grep -o "state [A-Z]\+" | sed 's/state //')

                if [ -z "$mac_addr" ]; then
                    mac_addr="Bulunamadı"
                fi

                if [[ $link_state == "UP" ]]; then
                    link_color=$GREEN
                    link_text="$link_state (Aktif)"
                else
                    link_color=$RED
                    link_text="$link_state (Kapalı)"
                fi

                echo -e "  ${BOLD}IP Adresi:${RESET} ${GREEN}$ip_addr${RESET}"
                echo -e "  ${BOLD}MAC Adresi:${RESET} ${GREEN}$mac_addr${RESET}"
                echo -e "  ${BOLD}Durum:${RESET} ${link_color}$link_text${RESET}"

                html_table_row "$interface" "$ip_addr" "$mac_addr" "$link_text"

                # Bağlantı hızı
                if [[ $link_state == "UP" ]] && [ -d "/sys/class/net/$interface" ]; then
                    if [ -f "/sys/class/net/$interface/speed" ]; then
                        speed=$(cat /sys/class/net/$interface/speed 2>/dev/null)
                        if [ ! -z "$speed" ]; then
                            echo -e "  ${BOLD}Bağlantı Hızı:${RESET} ${GREEN}$speed Mbps${RESET}"
                            html_add_keyvalue "Bağlantı Hızı ($interface)" "$speed Mbps"
                        fi
                    fi
                fi

                # Aktarım istatistikleri
                if [ -d "/sys/class/net/$interface/statistics" ]; then
                    rx_bytes=$(cat /sys/class/net/$interface/statistics/rx_bytes 2>/dev/null)
                    tx_bytes=$(cat /sys/class/net/$interface/statistics/tx_bytes 2>/dev/null)

                    if [ ! -z "$rx_bytes" ] && [ ! -z "$tx_bytes" ]; then
                        # MB cinsinden dönüştür
                        rx_mb=$(echo "scale=2; $rx_bytes/1048576" | bc)
                        tx_mb=$(echo "scale=2; $tx_bytes/1048576" | bc)

                        echo -e "  ${BOLD}Alınan Veri:${RESET} ${GREEN}$rx_mb MB${RESET}"
                        echo -e "  ${BOLD}Gönderilen Veri:${RESET} ${GREEN}$tx_mb MB${RESET}"

                        html_add_keyvalue "Alınan Veri ($interface)" "$rx_mb MB"
                        html_add_keyvalue "Gönderilen Veri ($interface)" "$tx_mb MB"
                    fi
                fi
            done <<< "$interfaces"

            html_table_end
        else
            echo -e "${RED}Ağ bilgisi alınamadı. 'ip' komutu bulunamadı.${RESET}"
            html_add_text "<p class='warning'>Ağ bilgisi alınamadı. 'ip' komutu bulunamadı.</p>"
        fi

        html_subsection_end

        # Wi-Fi bilgisi
        sub_title "Kablosuz Ağ Bilgisi"
        html_subsection_start "Kablosuz Ağ Bilgisi"

        wifi_interfaces=$(ls /sys/class/net | grep -E "wlan|wl")

        if [ ! -z "$wifi_interfaces" ] && command -v iwconfig &> /dev/null; then
            html_table_start "Arayüz SSID Sinyal Gücü Frekans"

            for wifi in $wifi_interfaces; do
                echo -e "\n${PURPLE}● Wi-Fi Arayüzü: $wifi${RESET}"

                iwconfig_output=$(iwconfig $wifi 2>/dev/null)
                ssid=$(echo "$iwconfig_output" | grep -o "ESSID:\"[^\"]*\"" | sed 's/ESSID:"//' | sed 's/"//')
                freq=$(echo "$iwconfig_output" | grep -o "Frequency:[0-9.]* GHz" | sed 's/Frequency://')
                quality=$(echo "$iwconfig_output" | grep -o "Quality=[0-9]*/[0-9]*" | sed 's/Quality=//')
                signal=$(echo "$iwconfig_output" | grep -o "Signal level=[0-9-]* dBm" | sed 's/Signal level=//')

                if [ -z "$ssid" ]; then
                    ssid="Bağlı değil"
                fi

                echo -e "  ${BOLD}SSID:${RESET} ${GREEN}$ssid${RESET}"
                echo -e "  ${BOLD}Frekans:${RESET} ${GREEN}$freq${RESET}"
                echo -e "  ${BOLD}Sinyal Kalitesi:${RESET} ${GREEN}$quality${RESET}"
                echo -e "  ${BOLD}Sinyal Seviyesi:${RESET} ${GREEN}$signal${RESET}"

                html_table_row "$wifi" "$ssid" "$signal" "$freq"
            done

            html_table_end

            # Mevcut Wi-Fi ağlarını tara
            if command -v nmcli &> /dev/null; then
                echo -e "\n${BOLD}Mevcut Wi-Fi Ağları:${RESET}"
                nmcli_output=$(nmcli -t -f SSID,SIGNAL,RATE,SECURITY dev wifi list)

                if [ ! -z "$nmcli_output" ]; then
                    html_add_text "<h4>Mevcut Wi-Fi Ağları</h4>"
                    html_table_start "SSID Sinyal Hız Güvenlik"

                    # Başlık satırı
                    echo -e "  ${BOLD}SSID               Sinyal  Hız        Güvenlik${RESET}"
                    echo -e "  ${YELLOW}--------------------------------------------------${RESET}"

                    while IFS=':' read -r ssid signal rate security; do
                        # Sinyal gücüne göre renk
                        if [ ! -z "$signal" ]; then
                            if [ $signal -gt 70 ]; then
                                signal_color=$GREEN
                            elif [ $signal -gt 40 ]; then
                                signal_color=$YELLOW
                            else
                                signal_color=$RED
                            fi

                            # Boşlukları düzenle
                            printf "  %-20s ${signal_color}%-8s${RESET} %-10s %s\n" "$ssid" "$signal%" "$rate" "$security"
                            html_table_row "$ssid" "$signal%" "$rate" "$security"
                        fi
                    done <<< "$nmcli_output"

                    html_table_end
                else
                    echo -e "  ${YELLOW}Wi-Fi ağları taranamadı.${RESET}"
                    html_add_text "<p>Wi-Fi ağları taranamadı.</p>"
                fi
            fi
        else
            echo -e "${YELLOW}Kablosuz ağ arayüzü bulunamadı.${RESET}"
            html_add_text "<p>Kablosuz ağ arayüzü bulunamadı.</p>"
        fi

        html_subsection_end

        # Ağ Performans Testi
        sub_title "Ağ Performans Testi"
        html_subsection_start "Ağ Performans Testi"

        # Ping testi
        echo -e "${BOLD}Ping Testi:${RESET}"
        html_add_text "<h4>Ping Testi</h4>"

        google_ping=$(ping -c 4 8.8.8.8 2>&1)
        if [[ $google_ping == *"bytes from"* ]]; then
            ping_stats=$(echo "$google_ping" | grep -E "min/avg/max|statistics")
            echo -e "${GREEN}$ping_stats${RESET}"
            html_add_text "<pre>$ping_stats</pre>"

            # Ortalama ping süresini çıkar
            avg_ping=$(echo "$ping_stats" | grep -o "avg [0-9.]*" | sed 's/avg //')

            # Ping kalitesini değerlendir
            if [ ! -z "$avg_ping" ]; then
                if (( $(echo "$avg_ping < 50" | bc -l) )); then
                    echo -e "${GREEN}Ping Kalitesi: Mükemmel (< 50ms)${RESET}"
                    html_add_text "<p style='color: green;'>Ping Kalitesi: Mükemmel (< 50ms)</p>"
                elif (( $(echo "$avg_ping < 100" | bc -l) )); then
                    echo -e "${YELLOW}Ping Kalitesi: İyi (< 100ms)${RESET}"
                    html_add_text "<p style='color: #FFEB3B;'>Ping Kalitesi: İyi (< 100ms)</p>"
                else
                    echo -e "${RED}Ping Kalitesi: Zayıf (> 100ms)${RESET}"
                    html_add_text "<p style='color: red;'>Ping Kalitesi: Zayıf (> 100ms)</p>"
                fi
            fi
        else
            echo -e "${RED}Ping testi başarısız: İnternet bağlantısı yok gibi görünüyor.${RESET}"
            html_add_text "<p class='warning'>Ping testi başarısız: İnternet bağlantısı yok gibi görünüyor.</p>"
        fi

        # DNS testi
        echo -e "\n${BOLD}DNS Çözümleme Testi:${RESET}"
        html_add_text "<h4>DNS Çözümleme Testi</h4>"

        dns_lookup=$(dig +short google.com 2>&1)
        if [ ! -z "$dns_lookup" ]; then
            echo -e "${GREEN}DNS çözümleme başarılı: $dns_lookup${RESET}"
            html_add_text "<p>DNS çözümleme başarılı: $dns_lookup</p>"
        else
            echo -e "${RED}DNS çözümleme başarısız.${RESET}"
            html_add_text "<p class='warning'>DNS çözümleme başarısız.</p>"
        fi

        # Hız testi (curl ile)
        if command -v curl &> /dev/null; then
            echo -e "\n${BOLD}Basit İndirme Hız Testi:${RESET}"
            html_add_text "<h4>Basit İndirme Hız Testi</h4>"

            echo -e "${YELLOW}Test dosyası indiriliyor...${RESET}"

            download_speed=$(curl -s -w "%{speed_download}\n" -o /dev/null http://speedtest.wdc01.softlayer.com/downloads/test10.zip)

            if [ ! -z "$download_speed" ]; then
                # Bytes/s -> MB/s
                download_mbps=$(echo "scale=2; $download_speed / 131072" | bc)
                echo -e "${GREEN}İndirme Hızı: $download_mbps Mbps${RESET}"
                html_add_keyvalue "İndirme Hızı" "$download_mbps Mbps"

                # Hız kalitesini değerlendir
                if (( $(echo "$download_mbps > 50" | bc -l) )); then
                    echo -e "${GREEN}Bağlantı Kalitesi: Mükemmel (> 50 Mbps)${RESET}"
                    html_add_text "<p style='color: green;'>Bağlantı Kalitesi: Mükemmel (> 50 Mbps)</p>"
                elif (( $(echo "$download_mbps > 20" | bc -l) )); then
                    echo -e "${YELLOW}Bağlantı Kalitesi: İyi (> 20 Mbps)${RESET}"
                    html_add_text "<p style='color: #FFEB3B;'>Bağlantı Kalitesi: İyi (> 20 Mbps)</p>"
                else
                    echo -e "${RED}Bağlantı Kalitesi: Temel kullanım için yeterli (< 20 Mbps)${RESET}"
                    html_add_text "<p style='color: orange;'>Bağlantı Kalitesi: Temel kullanım için yeterli (< 20 Mbps)</p>"
                fi
            else
                echo -e "${RED}Hız testi başarısız.${RESET}"
                html_add_text "<p class='warning'>Hız testi başarısız.</p>"
            fi
        fi

        # Temel güvenlik taraması - açık portlar
        if command -v ss &> /dev/null || command -v netstat &> /dev/null; then
            echo -e "\n${BOLD}Açık Portlar ve Servisleri:${RESET}"
            html_add_text "<h4>Açık Portlar ve Servisleri</h4>"

            if command -v ss &> /dev/null; then
                open_ports=$(ss -tuln | grep -v "127.0.0.1" | grep LISTEN)
            else
                open_ports=$(netstat -tuln | grep -v "127.0.0.1" | grep LISTEN)
            fi

            if [ ! -z "$open_ports" ]; then
                html_pre_start
                echo -e "${GREEN}$open_ports${RESET}"
                html_add_text "$open_ports"
                html_pre_end

                # Potansiyel güvenlik riskleri kontrolü
                risky_ports="20 21 23 137 138 139 445"
                for port in $risky_ports; do
                    if echo "$open_ports" | grep -q ":$port "; then
                        echo -e "${RED}UYARI: Port $port açık! Bu bir güvenlik riski olabilir.${RESET}"
                        html_add_text "<p class='warning'>UYARI: Port $port açık! Bu bir güvenlik riski olabilir.</p>"
                    fi
                done
            else
                echo -e "${GREEN}Harici sistemlere açık port bulunamadı.${RESET}"
                html_add_text "<p>Harici sistemlere açık port bulunamadı.</p>"
            fi
        fi

        html_subsection_end

        # Ağ adaptör detayları
        sub_title "Ağ Adaptör Detayları"
        html_subsection_start "Ağ Adaptör Detayları"

        # lspci ile NIC bilgisi
        if command -v lspci &> /dev/null; then
            nic_info=$(lspci | grep -i "network\|ethernet")

            if [ ! -z "$nic_info" ]; then
                html_pre_start
                echo -e "${GREEN}$nic_info${RESET}"
                html_add_text "$nic_info"
                html_pre_end
            fi
        fi

        # ethtool ile detaylı NIC bilgisi
        if command -v ethtool &> /dev/null; then
            for interface in $(ls /sys/class/net | grep -v "lo\|docker\|vbox\|veth"); do
                echo -e "\n${PURPLE}● Arayüz: $interface${RESET}"
                html_add_text "<h4>Arayüz: $interface</h4>"

                ethtool_info=$(ethtool $interface 2>/dev/null)

                if [ ! -z "$ethtool_info" ]; then
                    # Ethtool çıktısını daha okunabilir hale getir
                    speed=$(echo "$ethtool_info" | grep -i "Speed:" | sed 's/.*: //')
                    duplex=$(echo "$ethtool_info" | grep -i "Duplex:" | sed 's/.*: //')
                    auto_neg=$(echo "$ethtool_info" | grep -i "Auto-negotiation:" | sed 's/.*: //')
                    link=$(echo "$ethtool_info" | grep -i "Link detected:" | sed 's/.*: //')

                    echo -e "  ${BOLD}Hız:${RESET} ${GREEN}$speed${RESET}"
                    echo -e "  ${BOLD}Duplex:${RESET} ${GREEN}$duplex${RESET}"
                    echo -e "  ${BOLD}Otomatik Yapılandırma:${RESET} ${GREEN}$auto_neg${RESET}"
                    echo -e "  ${BOLD}Bağlantı Durumu:${RESET} ${GREEN}$link${RESET}"

                    html_table_start "Özellik Değer"
                    html_table_row "Hız" "$speed"
                    html_table_row "Duplex" "$duplex"
                    html_table_row "Otomatik Yapılandırma" "$auto_neg"
                    html_table_row "Bağlantı Durumu" "$link"
                    html_table_end

                    # Sürücü detayları
                    driver=$(ethtool -i $interface 2>/dev/null | grep -E "driver|version|firmware")

                    if [ ! -z "$driver" ]; then
                        echo -e "\n  ${BOLD}Sürücü Bilgisi:${RESET}"
                        echo -e "${GREEN}$driver${RESET}" | sed 's/^/  /'

                        html_add_text "<h5>Sürücü Bilgisi</h5>"
                        html_pre_start
                        html_add_text "$driver"
                        html_pre_end
                    fi
                else
                    echo -e "  ${YELLOW}ethtool ile bilgi alınamadı.${RESET}"
                    html_add_text "<p>ethtool ile bilgi alınamadı.</p>"
                fi
            done
        fi

        html_subsection_end

        html_section_end
    fi
}

# Ses Donanımı Bilgisi toplama
get_audio_info() {
    if [[ $INTERACTIVE == false ]] || [[ $SELECTED_SECTIONS == *"audio"* ]]; then
        section_title "SES DONANIMI BİLGİSİ"
        show_progress

        html_section_start "SES DONANIMI BİLGİSİ"

        sub_title "Ses Kartları"
        html_subsection_start "Ses Kartları"

        # Ses kartı bilgisi (aplay veya lspci ile)
        if command -v aplay &> /dev/null; then
            aplay_output=$(aplay -l 2>/dev/null)

            if [ ! -z "$aplay_output" ]; then
                html_pre_start
                echo -e "${GREEN}$aplay_output${RESET}"
                html_add_text "$aplay_output"
                html_pre_end
            else
                echo -e "${YELLOW}Ses kartı bulunamadı (aplay).${RESET}"
                html_add_text "<p>Ses kartı bulunamadı (aplay).</p>"
            fi
        else
            # aplay yoksa lspci kullan
            if command -v lspci &> /dev/null; then
                audio_cards=$(lspci | grep -i audio)

                if [ ! -z "$audio_cards" ]; then
                    html_pre_start
                    echo -e "${GREEN}$audio_cards${RESET}"
                    html_add_text "$audio_cards"
                    html_pre_end
                else
                    echo -e "${YELLOW}Ses kartı bulunamadı (lspci).${RESET}"
                    html_add_text "<p>Ses kartı bulunamadı (lspci).</p>"
                fi
            else
                echo -e "${RED}Ses kartı bilgisi alınamadı. 'aplay' veya 'lspci' bulunamadı.${RESET}"
                html_add_text "<p class='warning'>Ses kartı bilgisi alınamadı. 'aplay' veya 'lspci' bulunamadı.</p>"
            fi
        fi

        html_subsection_end

        # PulseAudio veya ALSA bilgisi
        sub_title "Ses Sistemi Bilgisi"
        html_subsection_start "Ses Sistemi Bilgisi"

        # PulseAudio kontrolü
        if command -v pactl &> /dev/null; then
            echo -e "${BOLD}PulseAudio Bilgisi:${RESET}"
            html_add_text "<h4>PulseAudio Bilgisi</h4>"

            pulse_info=$(pactl info 2>/dev/null)

            if [ ! -z "$pulse_info" ]; then
                pulse_version=$(echo "$pulse_info" | grep "Server Version" | sed 's/.*: //')
                pulse_default_sink=$(echo "$pulse_info" | grep "Default Sink" | sed 's/.*: //')
                pulse_default_source=$(echo "$pulse_info" | grep "Default Source" | sed 's/.*: //')

                echo -e "  ${BOLD}PulseAudio Sürümü:${RESET} ${GREEN}$pulse_version${RESET}"
                echo -e "  ${BOLD}Varsayılan Hoparlör:${RESET} ${GREEN}$pulse_default_sink${RESET}"
                echo -e "  ${BOLD}Varsayılan Mikrofon:${RESET} ${GREEN}$pulse_default_source${RESET}"

                html_table_start "Özellik Değer"
                html_table_row "PulseAudio Sürümü" "$pulse_version"
                html_table_row "Varsayılan Hoparlör" "$pulse_default_sink"
                html_table_row "Varsayılan Mikrofon" "$pulse_default_source"
                html_table_end

                # Bağlı ses cihazları
                echo -e "\n  ${BOLD}Bağlı Ses Cihazları:${RESET}"
                html_add_text "<h4>Bağlı Ses Cihazları</h4>"

                sinks=$(pactl list sinks short 2>/dev/null)
                sources=$(pactl list sources short 2>/dev/null)

                if [ ! -z "$sinks" ]; then
                    echo -e "  ${BOLD}Çıkış Cihazları:${RESET}"
                    html_add_text "<h5>Çıkış Cihazları</h5>"
                    html_pre_start
                    echo -e "${GREEN}$sinks${RESET}" | sed 's/^/    /'
                    html_add_text "$sinks"
                    html_pre_end
                fi

                if [ ! -z "$sources" ]; then
                    echo -e "\n  ${BOLD}Giriş Cihazları:${RESET}"
                    html_add_text "<h5>Giriş Cihazları</h5>"
                    html_pre_start
                    echo -e "${GREEN}$sources${RESET}" | sed 's/^/    /'
                    html_add_text "$sources"
                    html_pre_end
                fi
            fi
        # ALSA kontrolü
        elif command -v amixer &> /dev/null; then
            echo -e "${BOLD}ALSA Bilgisi:${RESET}"
            html_add_text "<h4>ALSA Bilgisi</h4>"

            alsa_info=$(amixer info 2>/dev/null)

            if [ ! -z "$alsa_info" ]; then
                html_pre_start
                echo -e "${GREEN}$alsa_info${RESET}"
                html_add_text "$alsa_info"
                html_pre_end

                # ALSA mikserleri
                echo -e "\n  ${BOLD}ALSA Mikserleri:${RESET}"
                html_add_text "<h5>ALSA Mikserleri</h5>"

                controls=$(amixer scontrols 2>/dev/null)
                if [ ! -z "$controls" ]; then
                    html_pre_start
                    echo -e "${GREEN}$controls${RESET}" | sed 's/^/    /'
                    html_add_text "$controls"
                    html_pre_end
                fi
            else
                echo -e "${YELLOW}ALSA bilgisi alınamadı.${RESET}"
                html_add_text "<p>ALSA bilgisi alınamadı.</p>"
            fi
        else
            echo -e "${YELLOW}PulseAudio veya ALSA bilgisi alınamadı.${RESET}"
            html_add_text "<p>PulseAudio veya ALSA bilgisi alınamadı.</p>"
        fi

        html_subsection_end

        # JACK kontrolü
        if command -v jack_control &> /dev/null; then
            sub_title "JACK Ses Sistemi"
            html_subsection_start "JACK Ses Sistemi"

            jack_status=$(jack_control status 2>/dev/null)
            if [ ! -z "$jack_status" ]; then
                echo -e "${BOLD}JACK Durumu:${RESET} ${GREEN}$jack_status${RESET}"
                html_add_keyvalue "JACK Durumu" "$jack_status"

                # JACK yapılandırması
                jack_config=$(jack_control dp 2>/dev/null)
                if [ ! -z "$jack_config" ]; then
                    echo -e "\n${BOLD}JACK Yapılandırması:${RESET}"
                    html_add_text "<h4>JACK Yapılandırması</h4>"
                    html_pre_start
                    echo -e "${GREEN}$jack_config${RESET}"
                    html_add_text "$jack_config"
                    html_pre_end
                fi
            else
                echo -e "${YELLOW}JACK çalışmıyor veya bilgi alınamadı.${RESET}"
                html_add_text "<p>JACK çalışmıyor veya bilgi alınamadı.</p>"
            fi

            html_subsection_end
        fi

        # Bluetooth ses cihazları
        if command -v bluetoothctl &> /dev/null; then
            sub_title "Bluetooth Ses Cihazları"
            html_subsection_start "Bluetooth Ses Cihazları"

            bt_devices=$(bluetoothctl devices 2>/dev/null | grep -v "No default controller available")
            if [ ! -z "$bt_devices" ]; then
                echo -e "${BOLD}Eşleştirilmiş Bluetooth Cihazları:${RESET}"
                html_add_text "<h4>Eşleştirilmiş Bluetooth Cihazları</h4>"
                html_table_start "MAC Adresi Cihaz Adı"

                while read -r device; do
                    device_mac=$(echo "$device" | awk '{print $2}')
                    device_name=$(echo "$device" | cut -d ' ' -f 3-)
                    echo -e "  ${GREEN}$device_mac${RESET}: ${CYAN}$device_name${RESET}"
                    html_table_row "$device_mac" "$device_name"
                done <<< "$bt_devices"

                html_table_end

                # Bağlı cihazları kontrol et
                for mac in $(echo "$bt_devices" | awk '{print $2}'); do
                    bt_info=$(bluetoothctl info $mac 2>/dev/null)
                    if [[ $bt_info == *"Connected: yes"* ]]; then
                        name=$(echo "$bt_info" | grep "Name" | sed 's/.*: //')
                        echo -e "\n  ${BOLD}Bağlı Cihaz:${RESET} ${GREEN}$name${RESET}"

                        if [[ $bt_info == *"Audio Sink"* ]]; then
                            echo -e "  ${BOLD}Tür:${RESET} ${GREEN}Ses Çıkış Cihazı${RESET}"
                        fi

                        if [[ $bt_info == *"Audio Source"* ]]; then
                            echo -e "  ${BOLD}Tür:${RESET} ${GREEN}Ses Giriş Cihazı${RESET}"
                        fi

                        html_add_text "<p><strong>Bağlı Cihaz:</strong> $name</p>"
                    fi
                done
            else
                echo -e "${YELLOW}Bluetooth cihazı bulunamadı.${RESET}"
                html_add_text "<p>Bluetooth cihazı bulunamadı.</p>"
            fi

            html_subsection_end
        fi

        html_section_end
    fi
}

# USB Cihazları Bilgisi toplama
get_usb_info() {
    if [[ $INTERACTIVE == false ]] || [[ $SELECTED_SECTIONS == *"usb"* ]]; then
        section_title "USB CİHAZLARI BİLGİSİ"
        show_progress

        html_section_start "USB CİHAZLARI BİLGİSİ"

        sub_title "Bağlı USB Cihazları"
        html_subsection_start "Bağlı USB Cihazları"

        if command -v lsusb &> /dev/null; then
            usb_devices=$(lsusb)

            if [ ! -z "$usb_devices" ]; then
                html_table_start "Bus:Device ID Cihaz"

                while read -r device; do
                    bus_dev=$(echo "$device" | grep -o "Bus [0-9]* Device [0-9]*" | sed 's/Bus //' | sed 's/Device //' | sed 's/ /:/')
                    id=$(echo "$device" | grep -o "ID [0-9a-f]*:[0-9a-f]*" | sed 's/ID //')
                    desc=$(echo "$device" | sed 's/.*ID [0-9a-f]*:[0-9a-f]* //')

                    echo -e "${BOLD}$bus_dev${RESET} ($id): ${GREEN}$desc${RESET}"
                    html_table_row "$bus_dev" "$id" "$desc"
                done <<< "$usb_devices"

                html_table_end
            else
                echo -e "${YELLOW}USB cihazı bulunamadı.${RESET}"
                html_add_text "<p>USB cihazı bulunamadı.</p>"
            fi

            # Detaylı USB cihaz bilgisi
            echo -e "\n${BOLD}Detaylı USB Bilgisi:${RESET}"
            html_add_text "<h4>Detaylı USB Bilgisi</h4>"

            usb_detailed=$(lsusb -v 2>/dev/null | grep -E "idVendor|idProduct|iManufacturer|iProduct|bcdUSB|bInterfaceClass|wMaxPacketSize" | grep -v "Couldn" | head -40)

            if [ ! -z "$usb_detailed" ]; then
                html_pre_start
                echo -e "${GREEN}$usb_detailed${RESET}" | sed 's/^/  /'
                html_add_text "$usb_detailed"
                html_pre_end
            fi
        else
            echo -e "${RED}USB bilgisi alınamadı. 'lsusb' komutu bulunamadı.${RESET}"
            html_add_text "<p class='warning'>USB bilgisi alınamadı. 'lsusb' komutu bulunamadı.</p>"
        fi

        html_subsection_end

        # USB denetleyici bilgisi
        sub_title "USB Denetleyici Bilgisi"
        html_subsection_start "USB Denetleyici Bilgisi"

        if command -v lspci &> /dev/null; then
            usb_controllers=$(lspci | grep -i usb)

            if [ ! -z "$usb_controllers" ]; then
                html_pre_start
                echo -e "${GREEN}$usb_controllers${RESET}"
                html_add_text "$usb_controllers"
                html_pre_end

                # USB sürümlerini tespit et
                usb_versions=""

                if echo "$usb_controllers" | grep -q "USB 3"; then
                    usb_versions="$usb_versions USB 3.x"
                fi

                if echo "$usb_controllers" | grep -q "USB 2"; then
                    usb_versions="$usb_versions USB 2.0"
                fi

                if echo "$usb_controllers" | grep -q "USB 1"; then
                    usb_versions="$usb_versions USB 1.x"
                fi

                if echo "$usb_controllers" | grep -qi "xhci"; then
                    usb_versions="$usb_versions (xHCI denetleyici mevcut)"
                fi

                if [ ! -z "$usb_versions" ]; then
                    echo -e "\n${BOLD}Desteklenen USB Sürümleri:${RESET} ${GREEN}$usb_versions${RESET}"
                    html_add_keyvalue "Desteklenen USB Sürümleri" "$usb_versions"
                fi
            else
                echo -e "${YELLOW}USB denetleyici bilgisi bulunamadı.${RESET}"
                html_add_text "<p>USB denetleyici bilgisi bulunamadı.</p>"
            fi
        else
            echo -e "${YELLOW}USB denetleyici bilgisi alınamadı. 'lspci' komutu bulunamadı.${RESET}"
            html_add_text "<p>USB denetleyici bilgisi alınamadı. 'lspci' komutu bulunamadı.</p>"
        fi

        html_subsection_end

        # USB port durumu
        sub_title "USB Port Durumu"
        html_subsection_start "USB Port Durumu"

        if [ -d "/sys/bus/usb/devices" ]; then
            echo -e "${BOLD}USB Port İstatistikleri:${RESET}"
            html_add_text "<h4>USB Port İstatistikleri</h4>"

            usb_ports=$(find /sys/bus/usb/devices/usb* -maxdepth 0 -type l | wc -l)
            usb_devices=$(find /sys/bus/usb/devices/usb*/*/uevent -type f | wc -l)

            echo -e "  ${BOLD}Toplam USB Port Sayısı:${RESET} ${GREEN}$usb_ports${RESET}"
            echo -e "  ${BOLD}Toplam USB Cihaz Sayısı:${RESET} ${GREEN}$usb_devices${RESET}"

            html_add_keyvalue "Toplam USB Port Sayısı" "$usb_ports"
html_add_keyvalue "Toplam USB Cihaz Sayısı" "$usb_devices"

            # USB3 portları
            usb3_ports=$(find /sys/bus/usb/devices/usb* -name version | xargs cat 2>/dev/null | grep -c "3\.")
            if [ ! -z "$usb3_ports" ]; then
                echo -e "  ${BOLD}USB 3.x Port Sayısı:${RESET} ${GREEN}$usb3_ports${RESET}"
                html_add_keyvalue "USB 3.x Port Sayısı" "$usb3_ports"
            fi

            # USB2 portları
            usb2_ports=$(find /sys/bus/usb/devices/usb* -name version | xargs cat 2>/dev/null | grep -c "2\.")
            if [ ! -z "$usb2_ports" ]; then
                echo -e "  ${BOLD}USB 2.0 Port Sayısı:${RESET} ${GREEN}$usb2_ports${RESET}"
                html_add_keyvalue "USB 2.0 Port Sayısı" "$usb2_ports"
            fi
        else
            echo -e "${YELLOW}USB port bilgisi alınamadı.${RESET}"
            html_add_text "<p>USB port bilgisi alınamadı.</p>"
        fi

        html_subsection_end
        html_section_end
    fi
}

# Sıcaklık ve Fan Bilgisi toplama
get_temp_info() {
    if [[ $INTERACTIVE == false ]] || [[ $SELECTED_SECTIONS == *"temp"* ]]; then
        section_title "SICAKLIK VE FAN BİLGİSİ"
        show_progress

        html_section_start "SICAKLIK VE FAN BİLGİSİ"

        # Sensör kurulu değilse yüklemesini öner
        if ! command -v sensors &> /dev/null; then
            echo -e "${YELLOW}Sıcaklık bilgisi için 'lm-sensors' paketi kurulmamış.${RESET}"
            echo -e "${YELLOW}Yüklemek için:${RESET} sudo apt-get install lm-sensors"
            echo -e "${YELLOW}Kurulumdan sonra:${RESET} sudo sensors-detect"

            html_add_text "<p class='warning'>Sıcaklık bilgisi için 'lm-sensors' paketi kurulmamış.</p>"
            html_add_text "<p>Yüklemek için: <code>sudo apt-get install lm-sensors</code><br>Kurulumdan sonra: <code>sudo sensors-detect</code></p>"
        fi

        # Sıcaklık Bilgisi
        sub_title "Sistem Sıcaklıkları"
        html_subsection_start "Sistem Sıcaklıkları"

        if command -v sensors &> /dev/null; then
            sensors_output=$(sensors)

            if [ ! -z "$sensors_output" ]; then
                html_pre_start
                echo -e "${GREEN}$sensors_output${RESET}"
                html_add_text "$sensors_output"
                html_pre_end

                # Kritik sıcaklıkları tespit et
                cpu_temp=$(sensors | grep -E "Core|CPU" | grep -o "+[0-9.]*°C" | sed 's/+//' | sed 's/°C//' | sort -nr | head -1)
                cpu_high=$(sensors | grep -E "Core|CPU" | grep -o "high = +[0-9.]*°C" | sed 's/high = +//' | sed 's/°C//' | sort -nr | head -1)
                cpu_crit=$(sensors | grep -E "Core|CPU" | grep -o "crit = +[0-9.]*°C" | sed 's/crit = +//' | sed 's/°C//' | sort -nr | head -1)

                if [ ! -z "$cpu_temp" ] && [ ! -z "$cpu_crit" ]; then
                    temp_percent=$(echo "scale=2; 100 * $cpu_temp / $cpu_crit" | bc)
                    temp_color=$GREEN

                    if (( $(echo "$temp_percent > 80" | bc -l) )); then
                        temp_color=$RED
                        echo -e "\n${RED}UYARI: CPU sıcaklığı kritik seviyeye yakın!${RESET}"
                        html_add_text "<p class='warning'>UYARI: CPU sıcaklığı kritik seviyeye yakın!</p>"
                    elif (( $(echo "$temp_percent > 60" | bc -l) )); then
                        temp_color=$YELLOW
                        echo -e "\n${YELLOW}UYARI: CPU sıcaklığı yüksek seviyede!${RESET}"
                        html_add_text "<p class='warning'>UYARI: CPU sıcaklığı yüksek seviyede!</p>"
                    fi

                    # Sıcaklık çubuğu çiz
                    temp_bar_len=$(( TERM_WIDTH - 30 ))
                    temp_used_len=$(( temp_bar_len * cpu_temp / cpu_crit ))
                    temp_free_len=$(( temp_bar_len - temp_used_len ))

                    echo -ne "${BOLD}CPU Sıcaklığı [${RESET}"
                    for ((i=0; i<temp_used_len; i++)); do
                        echo -ne "${temp_color}#${RESET}"
                    done

                    for ((i=0; i<temp_free_len; i++)); do
                        echo -ne "${GRAY}.${RESET}"
                    done
                    echo -e "${BOLD}] ${cpu_temp}°C / ${cpu_crit}°C (${temp_percent}%)${RESET}"

                    html_add_progress "${cpu_temp}" "${cpu_crit}" "CPU Sıcaklığı"
                fi
            else
                echo -e "${YELLOW}Sensör bilgisi alınamadı veya sensör yok.${RESET}"
                html_add_text "<p>Sensör bilgisi alınamadı veya sensör yok.</p>"
            fi
        fi

        # hddtemp ile disklerin sıcaklığını al
        if command -v hddtemp &> /dev/null; then
            echo -e "\n${BOLD}Disk Sıcaklıkları:${RESET}"
            html_add_text "<h4>Disk Sıcaklıkları</h4>"

            disks=$(lsblk -d -o NAME | grep -v loop | grep -v NAME)

            html_table_start "Disk Sıcaklık"

            for disk in $disks; do
                disk_temp=$(sudo hddtemp /dev/$disk 2>/dev/null)

                if [ $? -eq 0 ] && [ ! -z "$disk_temp" ]; then
                    echo -e "  ${BOLD}/dev/$disk:${RESET} ${GREEN}$disk_temp${RESET}"

                    # Sıcaklık değerini çıkar
                    temp_value=$(echo "$disk_temp" | grep -o "[0-9]*°C" | sed 's/°C//')

                    # Disk modeli
                    disk_model=$(echo "$disk_temp" | sed "s|/dev/$disk: ||" | sed "s|: [0-9]*°C||")

                    html_table_row "/dev/$disk ($disk_model)" "$temp_value°C"

                    # Sıcaklık uyarısı
                    if [ ! -z "$temp_value" ] && [ $temp_value -gt 50 ]; then
                        echo -e "    ${YELLOW}UYARI: Disk sıcaklığı yüksek!${RESET}"
                    fi
                fi
            done

            html_table_end
        fi

        html_subsection_end

        # Fan bilgisi
        sub_title "Fan Bilgisi"
        html_subsection_start "Fan Bilgisi"

        # pwmconfig veya fancontrol kullanarak fan durumunu kontrol et
        if command -v sensors &> /dev/null; then
            fan_info=$(sensors | grep -i "fan" | grep -v "N/A")

            if [ ! -z "$fan_info" ]; then
                html_table_start "Fan Hızı"

                while read -r line; do
                    fan_name=$(echo "$line" | awk -F: '{print $1}')
                    fan_speed=$(echo "$line" | awk '{print $2" "$3}')

                    echo -e "${BOLD}$fan_name:${RESET} ${GREEN}$fan_speed${RESET}"
                    html_table_row "$fan_name" "$fan_speed"
                done <<< "$fan_info"

                html_table_end
            else
                echo -e "${YELLOW}Fan bilgisi bulunamadı.${RESET}"
                html_add_text "<p>Fan bilgisi bulunamadı.</p>"
            fi
        fi

        # İşlemci fan kontrolü
        if [ -d "/sys/devices/platform/coretemp.0" ] || [ -d "/sys/class/hwmon" ]; then
            echo -e "\n${BOLD}Termal Bölgeler:${RESET}"
            html_add_text "<h4>Termal Bölgeler</h4>"

            if [ -d "/sys/class/thermal" ]; then
                thermal_zones=$(ls /sys/class/thermal | grep thermal_zone)

                html_table_start "Termal Bölge Sıcaklık"

                for zone in $thermal_zones; do
                    if [ -f "/sys/class/thermal/$zone/temp" ]; then
                        temp=$(cat /sys/class/thermal/$zone/temp 2>/dev/null)

                        # Değer milicelcius ise dönüştür
                        if [ $temp -gt 1000 ]; then
                            temp=$(echo "scale=1; $temp / 1000" | bc)
                        fi

                        type=$(cat /sys/class/thermal/$zone/type 2>/dev/null)

                        if [ ! -z "$type" ]; then
                            echo -e "  ${BOLD}$type:${RESET} ${GREEN}${temp}°C${RESET}"
                            html_table_row "$type" "${temp}°C"
                        else
                            echo -e "  ${BOLD}$zone:${RESET} ${GREEN}${temp}°C${RESET}"
                            html_table_row "$zone" "${temp}°C"
                        fi
                    fi
                done

                html_table_end
            fi
        fi

        html_subsection_end

        # Güç tüketimi bilgisi
        if [ -d "/sys/class/power_supply" ] || [ -f "/sys/class/powercap/intel-rapl" ]; then
            sub_title "Güç Tüketimi"
            html_subsection_start "Güç Tüketimi"

            # RAPL ile güç tüketimi
            if [ -d "/sys/class/powercap/intel-rapl" ]; then
                echo -e "${BOLD}İşlemci Güç Tüketimi:${RESET}"
                html_add_text "<h4>İşlemci Güç Tüketimi</h4>"

                rapl_dirs=$(find /sys/class/powercap/intel-rapl -name energy_uj -type f)

                for rapl_file in $rapl_dirs; do
                    rapl_dir=$(dirname $rapl_file)
                    name=$(cat $rapl_dir/name 2>/dev/null)

                    if [ ! -z "$name" ]; then
                        echo -e "  ${BOLD}$name:${RESET} Mevcut (RAPL destekli)"
                        html_add_keyvalue "$name" "Mevcut (RAPL destekli)"
                    fi
                done
            fi

            html_subsection_end
        fi

        html_section_end
    fi
}

# Pil Bilgisi toplama
get_battery_info() {
    if [[ $INTERACTIVE == false ]] || [[ $SELECTED_SECTIONS == *"battery"* ]]; then
        # Sadece pil mevcut ise göster
        if [ -d "/sys/class/power_supply" ] && ls /sys/class/power_supply/BAT* 1> /dev/null 2>&1; then
            section_title "PİL BİLGİSİ"
            show_progress

            html_section_start "PİL BİLGİSİ"

            sub_title "Pil Durumu"
            html_subsection_start "Pil Durumu"

            batteries=$(ls /sys/class/power_supply/ | grep BAT)

            for bat in $batteries; do
                echo -e "${PURPLE}● Pil: $bat${RESET}"
                html_add_text "<h4>Pil: $bat</h4>"

                if [ -f "/sys/class/power_supply/$bat/uevent" ]; then
                    bat_info=$(cat /sys/class/power_supply/$bat/uevent)

                    # Pil modeli
                    model=$(echo "$bat_info" | grep "MODEL_NAME" | cut -d= -f2)
                    if [ ! -z "$model" ]; then
                        echo -e "  ${BOLD}Model:${RESET} ${GREEN}$model${RESET}"
                        html_add_keyvalue "Model" "$model"
                    fi

                    # Üretici
                    manufacturer=$(echo "$bat_info" | grep "MANUFACTURER" | cut -d= -f2)
                    if [ ! -z "$manufacturer" ]; then
                        echo -e "  ${BOLD}Üretici:${RESET} ${GREEN}$manufacturer${RESET}"
                        html_add_keyvalue "Üretici" "$manufacturer"
                    fi

                    # Seri numarası
                    serial=$(echo "$bat_info" | grep "SERIAL_NUMBER" | cut -d= -f2)
                    if [ ! -z "$serial" ]; then
                        echo -e "  ${BOLD}Seri Numarası:${RESET} ${GREEN}$serial${RESET}"
                        html_add_keyvalue "Seri Numarası" "$serial"
                    fi

                    # Teknoloji
                    technology=$(echo "$bat_info" | grep "TECHNOLOGY" | cut -d= -f2)
                    if [ ! -z "$technology" ]; then
                        echo -e "  ${BOLD}Teknoloji:${RESET} ${GREEN}$technology${RESET}"
                        html_add_keyvalue "Teknoloji" "$technology"
                    fi

                    # Sağlık
                    if [ -f "/sys/class/power_supply/$bat/capacity" ]; then
                        capacity=$(cat /sys/class/power_supply/$bat/capacity)

                        # Renk belirle
                        if [ $capacity -gt 80 ]; then
                            cap_color=$GREEN
                        elif [ $capacity -gt 20 ]; then
                            cap_color=$YELLOW
                        else
                            cap_color=$RED
                        fi

                        echo -e "  ${BOLD}Şarj Durumu:${RESET} ${cap_color}$capacity%${RESET}"
                        html_add_keyvalue "Şarj Durumu" "$capacity%"
                        html_add_progress "$capacity" "100" "Pil Şarj Durumu"
                    fi

                    # Durum
                    if [ -f "/sys/class/power_supply/$bat/status" ]; then
                        status=$(cat /sys/class/power_supply/$bat/status)

                        # Duruma göre renk belirle
                        if [ "$status" == "Charging" ]; then
                            status_color=$GREEN
                            status_tr="Şarj Oluyor"
                        elif [ "$status" == "Discharging" ]; then
                            status_color=$YELLOW
                            status_tr="Deşarj Oluyor"
                        elif [ "$status" == "Full" ]; then
                            status_color=$GREEN
                            status_tr="Tam Dolu"
                        else
                            status_color=$RED
                            status_tr="$status"
                        fi

                        echo -e "  ${BOLD}Pil Durumu:${RESET} ${status_color}$status_tr${RESET}"
                        html_add_keyvalue "Pil Durumu" "$status_tr"
                    fi

                    # Voltaj
                    if [ -f "/sys/class/power_supply/$bat/voltage_now" ]; then
                        voltage=$(cat /sys/class/power_supply/$bat/voltage_now)
                        voltage_v=$(echo "scale=2; $voltage / 1000000" | bc)

                        echo -e "  ${BOLD}Voltaj:${RESET} ${GREEN}${voltage_v}V${RESET}"
                        html_add_keyvalue "Voltaj" "${voltage_v}V"
                    fi

                    # Tasarım kapasitesi
                    if [ -f "/sys/class/power_supply/$bat/energy_full_design" ]; then
                        design=$(cat /sys/class/power_supply/$bat/energy_full_design)
                        design_wh=$(echo "scale=2; $design / 1000000" | bc)

                        echo -e "  ${BOLD}Tasarım Kapasitesi:${RESET} ${GREEN}${design_wh}Wh${RESET}"
                        html_add_keyvalue "Tasarım Kapasitesi" "${design_wh}Wh"
                    fi

                    # Gerçek kapasite
                    if [ -f "/sys/class/power_supply/$bat/energy_full" ]; then
                        full=$(cat /sys/class/power_supply/$bat/energy_full)
                        full_wh=$(echo "scale=2; $full / 1000000" | bc)

                        echo -e "  ${BOLD}Gerçek Kapasite:${RESET} ${GREEN}${full_wh}Wh${RESET}"
                        html_add_keyvalue "Gerçek Kapasite" "${full_wh}Wh"

                        # Pil sağlığı hesapla
                        if [ -f "/sys/class/power_supply/$bat/energy_full_design" ]; then
                            design=$(cat /sys/class/power_supply/$bat/energy_full_design)
                            health=$(echo "scale=2; 100 * $full / $design" | bc)

                            # Sağlık rengi belirle
                            if (( $(echo "$health > 80" | bc -l) )); then
                                health_color=$GREEN
                                health_text="İyi"
                            elif (( $(echo "$health > 50" | bc -l) )); then
                                health_color=$YELLOW
                                health_text="Orta"
                            else
                                health_color=$RED
                                health_text="Zayıf"
                            fi

                            echo -e "  ${BOLD}Pil Sağlığı:${RESET} ${health_color}${health}% ($health_text)${RESET}"
                            html_add_keyvalue "Pil Sağlığı" "${health}% ($health_text)"
                            html_add_progress "${health}" "100" "Pil Sağlığı"
                        fi
                    fi

                    # Mevcut enerji
                    if [ -f "/sys/class/power_supply/$bat/energy_now" ]; then
                        energy_now=$(cat /sys/class/power_supply/$bat/energy_now)
                        energy_now_wh=$(echo "scale=2; $energy_now / 1000000" | bc)

                        echo -e "  ${BOLD}Mevcut Enerji:${RESET} ${GREEN}${energy_now_wh}Wh${RESET}"
                        html_add_keyvalue "Mevcut Enerji" "${energy_now_wh}Wh"
                    fi

                    # Güç tüketimi
                    if [ -f "/sys/class/power_supply/$bat/power_now" ]; then
                        power_now=$(cat /sys/class/power_supply/$bat/power_now)
                        power_now_w=$(echo "scale=2; $power_now / 1000000" | bc)

                        echo -e "  ${BOLD}Anlık Güç:${RESET} ${GREEN}${power_now_w}W${RESET}"
                        html_add_keyvalue "Anlık Güç" "${power_now_w}W"
                    fi

                    # Kalan süre hesapla
                    if [ -f "/sys/class/power_supply/$bat/energy_now" ] && [ -f "/sys/class/power_supply/$bat/power_now" ] && [ -f "/sys/class/power_supply/$bat/status" ]; then
                        energy_now=$(cat /sys/class/power_supply/$bat/energy_now)
                        power_now=$(cat /sys/class/power_supply/$bat/power_now)
                        status=$(cat /sys/class/power_supply/$bat/status)

                        # Sadece deşarj durumunda ve güç tüketimi varsa hesapla
                        if [ "$status" == "Discharging" ] && [ $power_now -gt 0 ]; then
                            # Saat:dakika hesapla
                            remaining_h=$(echo "scale=2; $energy_now / $power_now" | bc)
                            hours=$(echo "$remaining_h" | cut -d. -f1)
                            minutes=$(echo "scale=0; ($remaining_h - $hours) * 60" | bc)

                            echo -e "  ${BOLD}Tahmini Kalan Süre:${RESET} ${GREEN}${hours} saat ${minutes} dakika${RESET}"
                            html_add_keyvalue "Tahmini Kalan Süre" "${hours} saat ${minutes} dakika"
                        elif [ "$status" == "Charging" ] && [ $power_now -gt 0 ]; then
                            # Tam şarj için kalan süre
                            if [ -f "/sys/class/power_supply/$bat/energy_full" ]; then
                                energy_full=$(cat /sys/class/power_supply/$bat/energy_full)
                                energy_to_full=$(( energy_full - energy_now ))

                                # Saat:dakika hesapla
                                remaining_h=$(echo "scale=2; $energy_to_full / $power_now" | bc)
                                hours=$(echo "$remaining_h" | cut -d. -f1)
                                minutes=$(echo "scale=0; ($remaining_h - $hours) * 60" | bc)

                                echo -e "  ${BOLD}Tahmini Tam Şarj Süresi:${RESET} ${GREEN}${hours} saat ${minutes} dakika${RESET}"
                                html_add_keyvalue "Tahmini Tam Şarj Süresi" "${hours} saat ${minutes} dakika"
                            fi
                        fi
                    fi

                    # Döngü sayısı
                    if [ -f "/sys/class/power_supply/$bat/cycle_count" ]; then
                        cycles=$(cat /sys/class/power_supply/$bat/cycle_count)

                        echo -e "  ${BOLD}Şarj Döngüsü:${RESET} ${GREEN}$cycles${RESET}"
                        html_add_keyvalue "Şarj Döngüsü" "$cycles"

                        # Döngü sayısı uyarısı
                        if [ $cycles -gt 500 ]; then
                            echo -e "  ${YELLOW}NOT: Pil 500'den fazla şarj döngüsüne sahip, değiştirilmesi tavsiye edilir.${RESET}"
                            html_add_text "<p class='warning'>NOT: Pil 500'den fazla şarj döngüsüne sahip, değiştirilmesi tavsiye edilir.</p>"
                        fi
                    fi
                fi
            done

            html_subsection_end

            # AC adaptör bilgisi
            if [ -d "/sys/class/power_supply/AC" ] || [ -d "/sys/class/power_supply/ACAD" ]; then
                sub_title "AC Adaptör Bilgisi"
                html_subsection_start "AC Adaptör Bilgisi"

                ac_adapter=""
                if [ -d "/sys/class/power_supply/AC" ]; then
                    ac_adapter="AC"
                elif [ -d "/sys/class/power_supply/ACAD" ]; then
                    ac_adapter="ACAD"
                fi

                if [ ! -z "$ac_adapter" ]; then
                    # AC adaptör durumu
                    if [ -f "/sys/class/power_supply/$ac_adapter/online" ]; then
                        online=$(cat /sys/class/power_supply/$ac_adapter/online)

                        if [ $online -eq 1 ]; then
                            echo -e "${BOLD}AC Adaptör:${RESET} ${GREEN}Bağlı${RESET}"
                            html_add_keyvalue "AC Adaptör" "Bağlı"
                        else
                            echo -e "${BOLD}AC Adaptör:${RESET} ${RED}Bağlı Değil${RESET}"
                            html_add_keyvalue "AC Adaptör" "Bağlı Değil"
                        fi
                    fi
                fi

                # Güç yönetimi bilgisi
                if command -v tlp-stat &> /dev/null; then
                    echo -e "\n${BOLD}TLP Güç Yönetimi:${RESET} ${GREEN}Kurulu${RESET}"
                    html_add_keyvalue "TLP Güç Yönetimi" "Kurulu"

                    tlp_status=$(tlp-stat -s 2>/dev/null | grep "TLP status" | sed 's/TLP status: //')
                    if [ ! -z "$tlp_status" ]; then
                        echo -e "${BOLD}TLP Durumu:${RESET} ${GREEN}$tlp_status${RESET}"
                        html_add_keyvalue "TLP Durumu" "$tlp_status"
                    fi
                fi

                html_subsection_end
            fi

            html_section_end
        fi
    fi
}

# Sistem Özeti toplama
get_system_info() {
    if [[ $INTERACTIVE == false ]] || [[ $SELECTED_SECTIONS == *"system"* ]]; then
        section_title "SİSTEM ÖZETİ"
        show_progress

        html_section_start "SİSTEM ÖZETİ"

        sub_title "Sistem Bilgisi"
        html_subsection_start "Sistem Bilgisi"

        os_info=$(lsb_release -ds 2>/dev/null)
        kernel_ver=$(uname -r)
        pc_model=$(sudo dmidecode -s system-product-name 2>/dev/null)
        manufacturer=$(sudo dmidecode -s system-manufacturer 2>/dev/null)
        bios_ver=$(sudo dmidecode -s bios-version 2>/dev/null)
        bios_date=$(sudo dmidecode -s bios-release-date 2>/dev/null)

        if [ -z "$os_info" ]; then
            os_info=$(cat /etc/os-release | grep "PRETTY_NAME" | sed 's/PRETTY_NAME=//' | sed 's/"//g')
        fi

        echo -e "${BOLD}İşletim Sistemi:${RESET} ${GREEN}$os_info${RESET}"
        echo -e "${BOLD}Kernel Sürümü:${RESET} ${GREEN}$kernel_ver${RESET}"
        echo -e "${BOLD}Bilgisayar Modeli:${RESET} ${GREEN}$pc_model${RESET}"
        echo -e "${BOLD}Üretici:${RESET} ${GREEN}$manufacturer${RESET}"
        echo -e "${BOLD}BIOS Sürümü:${RESET} ${GREEN}$bios_ver${RESET}"
        echo -e "${BOLD}BIOS Tarihi:${RESET} ${GREEN}$bios_date${RESET}"

        html_add_keyvalue "İşletim Sistemi" "$os_info"
        html_add_keyvalue "Kernel Sürümü" "$kernel_ver"
        html_add_keyvalue "Bilgisayar Modeli" "$pc_model"
        html_add_keyvalue "Üretici" "$manufacturer"
        html_add_keyvalue "BIOS Sürümü" "$bios_ver"
        html_add_keyvalue "BIOS Tarihi" "$bios_date"

        # Kullanıcı ve hostname bilgisi
        username=$(whoami)
        hostname=$(hostname)
        uptime=$(uptime -p)

        echo -e "${BOLD}Kullanıcı:${RESET} ${GREEN}$username${RESET}"
        echo -e "${BOLD}Hostname:${RESET} ${GREEN}$hostname${RESET}"
        echo -e "${BOLD}Çalışma Süresi:${RESET} ${GREEN}$uptime${RESET}"

        html_add_keyvalue "Kullanıcı" "$username"
        html_add_keyvalue "Hostname" "$hostname"
        html_add_keyvalue "Çalışma Süresi" "$uptime"

        html_subsection_end

        # Güvenlik Bilgisi
        sub_title "Güvenlik Bilgisi"
        html_subsection_start "Güvenlik Bilgisi"

        # Firewall durumu
        echo -e "${BOLD}Firewall Durumu:${RESET}"
        html_add_text "<h4>Firewall Durumu</h4>"

        if command -v ufw &> /dev/null; then
            ufw_status=$(sudo ufw status | grep -i "Status" | awk '{print $2}')

            if [[ $ufw_status == "active" ]]; then
                echo -e "  ${BOLD}UFW:${RESET} ${GREEN}Aktif${RESET}"
                html_add_keyvalue "UFW" "Aktif"
            else
                echo -e "  ${BOLD}UFW:${RESET} ${RED}Kapalı${RESET}"
                html_add_keyvalue "UFW" "Kapalı"
            fi
        elif command -v firewalld &> /dev/null; then
            firewalld_status=$(sudo firewall-cmd --state 2>/dev/null)

            if [[ $firewalld_status == "running" ]]; then
                echo -e "  ${BOLD}FirewallD:${RESET} ${GREEN}Aktif${RESET}"
                html_add_keyvalue "FirewallD" "Aktif"
            else
                echo -e "  ${BOLD}FirewallD:${RESET} ${RED}Kapalı${RESET}"
                html_add_keyvalue "FirewallD" "Kapalı"
            fi
        else
            echo -e "  ${YELLOW}Herhangi bir firewall tespit edilemedi.${RESET}"
            html_add_text "<p>Herhangi bir firewall tespit edilemedi.</p>"
        fi

        # SSH kontrolü
        if command -v ssh &> /dev/null; then
            ssh_status=$(systemctl is-active ssh 2>/dev/null || systemctl is-active sshd 2>/dev/null)

            if [[ $ssh_status == "active" ]]; then
                echo -e "  ${BOLD}SSH Servisi:${RESET} ${GREEN}Aktif${RESET}"
                html_add_keyvalue "SSH Servisi" "Aktif"
            else
                echo -e "  ${BOLD}SSH Servisi:${RESET} ${YELLOW}Kapalı${RESET}"
                html_add_keyvalue "SSH Servisi" "Kapalı"
            fi
        fi

        html_subsection_end

        # Dağıtım bilgisi
        sub_title "Dağıtım Bilgisi"
        html_subsection_start "Dağıtım Bilgisi"

        # Dağıtım detayları
        if [ -f "/etc/os-release" ]; then
            os_name=$(cat /etc/os-release | grep "NAME=" | head -1 | sed 's/NAME=//' | sed 's/"//g')
            os_version=$(cat /etc/os-release | grep "VERSION=" | head -1 | sed 's/VERSION=//' | sed 's/"//g')
            os_id=$(cat /etc/os-release | grep "ID=" | head -1 | sed 's/ID=//' | sed 's/"//g')

            echo -e "${BOLD}Dağıtım:${RESET} ${GREEN}$os_name${RESET}"
            echo -e "${BOLD}Sürüm:${RESET} ${GREEN}$os_version${RESET}"
            echo -e "${BOLD}ID:${RESET} ${GREEN}$os_id${RESET}"

            html_add_keyvalue "Dağıtım" "$os_name"
            html_add_keyvalue "Sürüm" "$os_version"
            html_add_keyvalue "ID" "$os_id"
        fi

        # Paket yöneticisi ve paket sayıları
        if command -v apt &> /dev/null; then
            echo -e "${BOLD}Paket Yöneticisi:${RESET} ${GREEN}APT${RESET}"
            html_add_keyvalue "Paket Yöneticisi" "APT"

            apt_packages=$(dpkg-query -l | grep -c "^ii")
            echo -e "${BOLD}Yüklü Paket Sayısı:${RESET} ${GREEN}$apt_packages${RESET}"
            html_add_keyvalue "Yüklü Paket Sayısı" "$apt_packages"

            # Güncelleme kontrolü
            echo -e "${BOLD}Güncelleme Durumu:${RESET}"
            update_count=$(apt list --upgradable 2>/dev/null | grep -c "upgradable")

            if [ $update_count -gt 0 ]; then
                echo -e "  ${YELLOW}$update_count paket güncellenebilir${RESET}"
                html_add_keyvalue "Güncellenebilir Paket" "$update_count"
            else
                echo -e "  ${GREEN}Tüm paketler güncel${RESET}"
                html_add_keyvalue "Güncellenebilir Paket" "0 (Tüm paketler güncel)"
            fi
        elif command -v yum &> /dev/null || command -v dnf &> /dev/null; then
            if command -v dnf &> /dev/null; then
                pkg_mgr="DNF"
                rpm_packages=$(rpm -qa | wc -l)
            else
                pkg_mgr="YUM"
                rpm_packages=$(rpm -qa | wc -l)
            fi

            echo -e "${BOLD}Paket Yöneticisi:${RESET} ${GREEN}$pkg_mgr${RESET}"
            echo -e "${BOLD}Yüklü Paket Sayısı:${RESET} ${GREEN}$rpm_packages${RESET}"

            html_add_keyvalue "Paket Yöneticisi" "$pkg_mgr"
            html_add_keyvalue "Yüklü Paket Sayısı" "$rpm_packages"
        fi

        html_subsection_end

        # Donanım Özeti
        sub_title "Donanım Özeti"
        html_subsection_start "Donanım Özeti"

        # CPU
        cpu_model=$(lscpu | grep 'Model name' | sed 's/Model name:[[:space:]]*//')
        cpu_cores=$(nproc)

        echo -e "${BOLD}CPU:${RESET} ${GREEN}$cpu_model${RESET}"
        echo -e "${BOLD}CPU Çekirdekleri:${RESET} ${GREEN}$cpu_cores${RESET}"

        html_add_keyvalue "CPU" "$cpu_model"
        html_add_keyvalue "CPU Çekirdekleri" "$cpu_cores"

        # RAM
        total_ram=$(free -h | grep 'Mem' | awk '{print $2}')

        echo -e "${BOLD}RAM:${RESET} ${GREEN}$total_ram${RESET}"
        html_add_keyvalue "RAM" "$total_ram"

        # Disk Toplam
        total_disk=$(df -h --total | grep total | awk '{print $2}')

        echo -e "${BOLD}Toplam Disk:${RESET} ${GREEN}$total_disk${RESET}"
        html_add_keyvalue "Toplam Disk" "$total_disk"

        # GPU
        if command -v lspci &> /dev/null; then
            gpu_info=$(lspci | grep -E 'VGA|3D|Display' | sed 's/.*: //')

            echo -e "${BOLD}GPU:${RESET} ${GREEN}$gpu_info${RESET}"
            html_add_keyvalue "GPU" "$gpu_info"
        fi

        html_subsection_end

        html_section_end
    fi
}

# QR Kod Oluşturma
generate_qr_code() {
    if [[ $INTERACTIVE == false ]] || [[ $SELECTED_SECTIONS == *"qr"* ]]; then
        if command -v qrencode &> /dev/null; then
            section_title "QR KOD"

            html_section_start "QR KOD"

            echo -e "${BOLD}Rapor Özeti QR Kodu:${RESET}"

            # Özet bilgileri oluştur
            system_info=$(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep "PRETTY_NAME" | sed 's/PRETTY_NAME=//' | sed 's/"//g')
            cpu_info=$(lscpu | grep 'Model name' | sed 's/Model name:[[:space:]]*//')
            ram_info=$(free -h | grep 'Mem' | awk '{print "RAM: "$2}')
            disk_info=$(df -h --total | grep total | awk '{print "Disk: "$2}')
            hostname_info=$(hostname)
            date_info=$(date)

            qr_text="Sistem: $system_info\nCPU: $cpu_info\n$ram_info\n$disk_info\nHostname: $hostname_info\nTarih: $date_info"

            # QR kodunu oluştur
            echo -e "$qr_text" | qrencode -t UTF8

            # HTML için QR kodu
            echo -e "$qr_text" | qrencode -o /tmp/hwreport_qr.png

            if [ $? -eq 0 ] && [ -f "/tmp/hwreport_qr.png" ]; then
                # Base64'e dönüştür
                qr_base64=$(base64 -w 0 /tmp/hwreport_qr.png)

                html_add_text "<h3>Rapor Özeti QR Kodu</h3>"
                html_add_text "<p>Bu QR kodu, temel donanım bilgilerinizi içerir. Mobil cihazınızla tarayabilirsiniz.</p>"
                html_add_text "<img src='data:image/png;base64,$qr_base64' alt='QR Kod' style='max-width: 300px;'>"

                # Geçici dosyayı sil
                rm -f /tmp/hwreport_qr.png
            else
                html_add_text "<p>QR kodu oluşturulamadı.</p>"
            fi

            html_section_end
        fi
    fi
}

# Benchmark için ilerleme göstergesi
show_benchmark_progress() {
    local message="$1"
    local duration=${2:-5}  # Varsayılan süre 5 saniye
    local chars="▏▎▍▌▋▊▉█"
    local interval=0.1
    local max_steps=$(echo "$duration / $interval" | bc)
    local current_step=0

    echo -ne "${YELLOW}$message [${RESET}"

    # Boş çubuğu göster
    for ((i=0; i<20; i++)); do
        echo -ne "${GRAY}·${RESET}"
    done
    echo -ne "${YELLOW}]${RESET}"

    # İmleci başa getir
    echo -ne "\r${YELLOW}$message [${RESET}"

    # İşlem süresince dolan çubuk göster
    while [ "$current_step" -lt "$max_steps" ]; do
        local progress=$(( current_step * 20 / max_steps ))

        # İlerleme çubuğunu güncelle
        for ((i=0; i<20; i++)); do
            if [ "$i" -lt "$progress" ]; then
                echo -ne "${GREEN}█${RESET}"
            else
                echo -ne "${GRAY}·${RESET}"
            fi
        done

        # Yüzdeyi göster
        local percent=$(( current_step * 100 / max_steps ))
        echo -ne "${YELLOW}] ${percent}%${RESET}"

        # İmleci başa getir
        echo -ne "\r${YELLOW}$message [${RESET}"

        sleep $interval
        ((current_step++))
    done

    # Tamamlandı göster
    for ((i=0; i<20; i++)); do
        echo -ne "${GREEN}█${RESET}"
    done
    echo -ne "${YELLOW}] 100%${RESET}"
    echo -e "\r\n"
}

# Benchmark
run_benchmarks() {
    if [[ $INTERACTIVE == false ]] || [[ $SELECTED_SECTIONS == *"benchmark"* ]]; then
        section_title "BENCHMARK TESTLERİ"
        show_progress

        html_section_start "BENCHMARK TESTLERİ"

        sub_title "CPU Benchmark"
        html_subsection_start "CPU Benchmark"

        echo -e "${YELLOW}CPU benchmark çalıştırılıyor...${RESET}"

        # CPU test 1: Pi hesaplama
        echo -e "\n${BOLD}PI Hesaplama Testi:${RESET}"
        html_add_text "<h4>PI Hesaplama Testi</h4>"

        # Pi hesaplama işlemi
        start_time=$(date +%s.%N)

        # İlerleme göstergesini başlat (arka planda)
        show_benchmark_progress "PI hesaplanıyor" 3 &
        progress_pid=$!

        # Gerçek işlemi yap
        bc -l <<< "scale=3000; a(1)*4" > /dev/null

        # İlerleme göstergesini sonlandır
        if kill -0 $progress_pid 2>/dev/null; then
            wait $progress_pid
        fi

        end_time=$(date +%s.%N)
        pi_time=$(echo "$end_time - $start_time" | bc)

        echo -e "${GREEN}Süre: ${pi_time} saniye${RESET}"
        html_add_keyvalue "PI Hesaplama Süresi" "${pi_time} saniye"


        # CPU test 2: Sıkıştırma
        echo -e "\n${BOLD}Sıkıştırma Testi:${RESET}"
        html_add_text "<h4>Sıkıştırma Testi</h4>"

        start_time=$(date +%s.%N)
        dd if=/dev/zero bs=1M count=500 2>/dev/null | gzip > /dev/null
        end_time=$(date +%s.%N)
        compression_time=$(echo "$end_time - $start_time" | bc)

        echo -e "${GREEN}500MB Veri Sıkıştırma Süresi: ${compression_time} saniye${RESET}"
        html_add_keyvalue "500MB Veri Sıkıştırma Süresi" "${compression_time} saniye"

        # CPU test 3: Matris çarpımı
        echo -e "\n${BOLD}Matris Çarpımı Testi:${RESET}"
        html_add_text "<h4>Matris Çarpımı Testi</h4>"

        start_time=$(date +%s.%N)

        # Geçici Python scripti oluştur
        cat > /tmp/matrix_mult.py << 'EOF'
import numpy as np
import time

n = 1000
a = np.random.rand(n, n)
b = np.random.rand(n, n)
c = np.dot(a, b)
EOF

        # Python kurulu ise çalıştır
        if command -v python3 &> /dev/null; then
            if python3 -c "import numpy" 2>/dev/null; then
                python3 /tmp/matrix_mult.py
                end_time=$(date +%s.%N)
                matrix_time=$(echo "$end_time - $start_time" | bc)

                echo -e "${GREEN}1000x1000 Matris Çarpımı Süresi: ${matrix_time} saniye${RESET}"
                html_add_keyvalue "1000x1000 Matris Çarpımı Süresi" "${matrix_time} saniye"
            else
                echo -e "${YELLOW}NumPy kütüphanesi kurulu değil, test atlanıyor.${RESET}"
                html_add_text "<p>NumPy kütüphanesi kurulu değil, test atlanıyor.</p>"
            fi
        else
            echo -e "${YELLOW}Python3 kurulu değil, test atlanıyor.${RESET}"
            html_add_text "<p>Python3 kurulu değil, test atlanıyor.</p>"
        fi

        # Geçici dosyayı sil
        rm -f /tmp/matrix_mult.py

        html_subsection_end

        # RAM benchmark
        sub_title "RAM Benchmark"
        html_subsection_start "RAM Benchmark"

        echo -e "${YELLOW}RAM benchmark çalıştırılıyor...${RESET}"

        # RAM test 1: Büyük dosya oluşturma ve okuma
        echo -e "\n${BOLD}RAM Yazma/Okuma Testi:${RESET}"
        html_add_text "<h4>RAM Yazma/Okuma Testi</h4>"

        # Yazma testi
        echo -e "${GREEN}Yazma Testi:${RESET}"
        start_time=$(date +%s.%N)
        dd if=/dev/zero of=/tmp/ram_test bs=1M count=1024 status=none
        end_time=$(date +%s.%N)
        write_time=$(echo "$end_time - $start_time" | bc)
        write_speed=$(echo "scale=2; 1024 / $write_time" | bc)

        echo -e "${GREEN}1GB Yazma Hızı: ${write_speed} MB/s${RESET}"
        html_add_keyvalue "1GB Yazma Hızı" "${write_speed} MB/s"

        # Okuma testi
        echo -e "${GREEN}Okuma Testi:${RESET}"
        sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
        start_time=$(date +%s.%N)
        dd if=/tmp/ram_test of=/dev/null bs=1M status=none
        end_time=$(date +%s.%N)
        read_time=$(echo "$end_time - $start_time" | bc)
        read_speed=$(echo "scale=2; 1024 / $read_time" | bc)

        echo -e "${GREEN}1GB Okuma Hızı: ${read_speed} MB/s${RESET}"
        html_add_keyvalue "1GB Okuma Hızı" "${read_speed} MB/s"

        # Geçici dosyayı sil
        rm -f /tmp/ram_test

        html_subsection_end

        # Disk benchmark
        sub_title "Disk Benchmark"
        html_subsection_start "Disk Benchmark"

        echo -e "${YELLOW}Disk benchmark çalıştırılıyor...${RESET}"

        # Root dizinine test yapma
        test_dir="/tmp"

        # Yazma testi
        echo -e "\n${BOLD}Disk Yazma Testi:${RESET}"
        html_add_text "<h4>Disk Yazma Testi</h4>"

        start_time=$(date +%s.%N)
        dd if=/dev/zero of=$test_dir/disk_test bs=4k count=10000 conv=fsync status=none
        end_time=$(date +%s.%N)
        write_time=$(echo "$end_time - $start_time" | bc)
        write_speed=$(echo "scale=2; 40 / $write_time" | bc)

        echo -e "${GREEN}4K Blok, 40MB Yazma Hızı: ${write_speed} MB/s${RESET}"
        html_add_keyvalue "4K Blok, 40MB Yazma Hızı" "${write_speed} MB/s"

        # Okuma testi
        echo -e "\n${BOLD}Disk Okuma Testi:${RESET}"
        html_add_text "<h4>Disk Okuma Testi</h4>"

        # Önbelleği temizle
        sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true

        start_time=$(date +%s.%N)
        dd if=$test_dir/disk_test of=/dev/null bs=4k status=none
        end_time=$(date +%s.%N)
        read_time=$(echo "$end_time - $start_time" | bc)
        read_speed=$(echo "scale=2; 40 / $read_time" | bc)

        echo -e "${GREEN}4K Blok, 40MB Okuma Hızı: ${read_speed} MB/s${RESET}"
        html_add_keyvalue "4K Blok, 40MB Okuma Hızı" "${read_speed} MB/s"

        # Geçici dosyayı sil
        rm -f $test_dir/disk_test

        # IOPS testi
        echo -e "\n${BOLD}Disk IOPS Testi:${RESET}"
        html_add_text "<h4>Disk IOPS Testi</h4>"

        # Rastgele yazma
        echo -e "${GREEN}Rastgele Yazma Testi:${RESET}"
        start_time=$(date +%s.%N)
        dd if=/dev/urandom of=$test_dir/iops_test bs=4k count=1000 oflag=direct 2>/dev/null
        end_time=$(date +%s.%N)
        rand_write_time=$(echo "$end_time - $start_time" | bc)
        rand_write_iops=$(echo "scale=0; 1000 / $rand_write_time" | bc)

        echo -e "${GREEN}4K Rastgele Yazma IOPS: ${rand_write_iops} IOPS${RESET}"
        html_add_keyvalue "4K Rastgele Yazma IOPS" "${rand_write_iops} IOPS"

        # Rastgele okuma
        echo -e "${GREEN}Rastgele Okuma Testi:${RESET}"
        sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
        start_time=$(date +%s.%N)
        dd if=$test_dir/iops_test of=/dev/null bs=4k count=1000 iflag=direct 2>/dev/null
        end_time=$(date +%s.%N)
        rand_read_time=$(echo "$end_time - $start_time" | bc)
        rand_read_iops=$(echo "scale=0; 1000 / $rand_read_time" | bc)

        echo -e "${GREEN}4K Rastgele Okuma IOPS: ${rand_read_iops} IOPS${RESET}"
        html_add_keyvalue "4K Rastgele Okuma IOPS" "${rand_read_iops} IOPS"

        # Geçici dosyayı sil
        rm -f $test_dir/iops_test

        html_subsection_end

        html_section_end
    fi
}

# İnteraktif mod seçimleri
interactive_mode() {
    clear
    echo -e "${GREEN}$(header_line)${RESET}"
    echo -e "${WHITE}${BOLD}$(center_text "DEBIAN DONANİM RAPORU - İNTERAKTİF MOD" $TERM_WIDTH)${RESET}"
    echo -e "${GREEN}$(header_line)${RESET}"
    echo ""
    echo -e "${BOLD}Hangi donanım bilgilerini görmek istiyorsunuz?${RESET}"
    echo ""
    echo -e "${CYAN}1)${RESET} CPU Bilgisi"
    echo -e "${CYAN}2)${RESET} RAM Bilgisi"
    echo -e "${CYAN}3)${RESET} GPU Bilgisi"
    echo -e "${CYAN}4)${RESET} Disk Bilgisi"
    echo -e "${CYAN}5)${RESET} Monitör Bilgisi"
    echo -e "${CYAN}6)${RESET} Ağ Donanımı Bilgisi"
    echo -e "${CYAN}7)${RESET} Ses Donanımı Bilgisi"
    echo -e "${CYAN}8)${RESET} USB Cihazları Bilgisi"
    echo -e "${CYAN}9)${RESET} Sıcaklık ve Fan Bilgisi"
    echo -e "${CYAN}10)${RESET} Pil Bilgisi (varsa)"
    echo -e "${CYAN}11)${RESET} Sistem Özeti"
    echo -e "${CYAN}12)${RESET} Benchmark Testleri"
    echo -e "${CYAN}13)${RESET} QR Kod Oluştur"
    echo -e "${CYAN}0)${RESET} Tüm Bilgileri Göster"
    echo ""
    echo -e "${YELLOW}Seçiminizi yapın (ör: 1 2 5 veya 0 için tümü):${RESET} "
    read -e selections

    if [[ $selections == *"0"* ]]; then
        INTERACTIVE=false
    else
        SELECTED_SECTIONS=""
        for selection in $selections; do
            case $selection in
                1) SELECTED_SECTIONS="$SELECTED_SECTIONS cpu";;
                2) SELECTED_SECTIONS="$SELECTED_SECTIONS ram";;
                3) SELECTED_SECTIONS="$SELECTED_SECTIONS gpu";;
                4) SELECTED_SECTIONS="$SELECTED_SECTIONS disk";;
                5) SELECTED_SECTIONS="$SELECTED_SECTIONS monitor";;
                6) SELECTED_SECTIONS="$SELECTED_SECTIONS network";;
                7) SELECTED_SECTIONS="$SELECTED_SECTIONS audio";;
                8) SELECTED_SECTIONS="$SELECTED_SECTIONS usb";;
                9) SELECTED_SECTIONS="$SELECTED_SECTIONS temp";;
                10) SELECTED_SECTIONS="$SELECTED_SECTIONS battery";;
                11) SELECTED_SECTIONS="$SELECTED_SECTIONS system";;
                12) SELECTED_SECTIONS="$SELECTED_SECTIONS benchmark";;
                13) SELECTED_SECTIONS="$SELECTED_SECTIONS qr";;
            esac
        done
    fi
}

BENCHMARK_ENABLED=false  # Varsayılan olarak kapalı

# Kullanım mesajını güncelleyelim
usage() {
    echo "Kullanım: $0 [SEÇENEKLER]"
    echo ""
    echo "Seçenekler:"
    echo "  -h, --help             Bu yardım mesajını gösterir"
    echo "  -i, --interactive      İnteraktif mod - hangi bilgilerin gösterileceğini seçin"
    echo "  -o, --output DOSYA     Çıktıyı belirtilen dosyaya kaydet"
    echo "  -H, --html DOSYA       HTML çıktısını belirtilen dosyaya kaydet"
    echo "  --no-color             Renkli çıktıyı devre dışı bırak"
    echo "  -b, --benchmark        Performans benchmark testlerini çalıştır (daha uzun sürer)"
    echo ""
    echo "Örnek: $0 --html rapor.html --output rapor.txt"
    exit 0
}

# Ana fonksiyon
main() {
    # Parametreleri kontrol et
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -h|--help) usage;;
            -i|--interactive) INTERACTIVE=true;;
            -o|--output) OUTPUT_FILE="$2"; shift;;
            -H|--html) HTML_OUTPUT="$2"; shift;;
            -b|--benchmark) BENCHMARK_ENABLED=false;;
            --no-color)
                # Renkleri devre dışı bırak
                BLUE=""
                GREEN=""
                YELLOW=""
                RED=""
                PURPLE=""
                CYAN=""
                WHITE=""
                GRAY=""
                RESET=""
                BOLD=""
                ;;
            *) echo "Bilinmeyen parametre: $1"; usage;;
        esac
        shift
    done

    # Konsol çıktısı dosyaya yönlendirilecekse
    if [ ! -z "$OUTPUT_FILE" ]; then
        exec > >(tee "$OUTPUT_FILE")
    fi

    # HTML çıktısı varsa başlat
    if [ ! -z "$HTML_OUTPUT" ]; then
        start_html
    fi

    # İnteraktif mod etkinse
    if [ "$INTERACTIVE" = true ]; then
        interactive_mode
    fi

    # Başlık
    clear
    echo -e "${GREEN}$(header_line)${RESET}"
    echo -e "${WHITE}${BOLD}$(center_text "📊 DEBIAN DONANİM RAPORU 📊" $TERM_WIDTH)${RESET}"
    echo -e "${WHITE}${BOLD}$(center_text "$(date)" $TERM_WIDTH)${RESET}"
    echo -e "${GREEN}$(header_line)${RESET}"

    # Gerekli araçları kontrol et
    check_requirements

    # Donanım bilgilerini topla - benchmark'ı koşullu olarak çalıştır
    get_cpu_info
    get_ram_info
    get_gpu_info
    get_disk_info
    get_monitor_info
    get_network_info
    get_audio_info
    get_usb_info
    get_temp_info
    get_battery_info

    # Sonuç
    echo -e "\n${GREEN}$(header_line)${RESET}"
    echo -e "${WHITE}${BOLD}$(center_text "✅ Rapor tamamlandı. Donanım bilgileriniz yukarıda verilmiştir. ✅" $TERM_WIDTH)${RESET}"
    echo -e "${GREEN}$(header_line)${RESET}"

    # HTML çıktısı varsa bitir
    if [ ! -z "$HTML_OUTPUT" ]; then
        end_html
        echo -e "\n${PURPLE}HTML raporu '$HTML_OUTPUT' dosyasına kaydedildi.${RESET}"
    fi

    # Çıktı dosyası varsa bildir
    if [ ! -z "$OUTPUT_FILE" ]; then
        echo -e "\n${PURPLE}Rapor '$OUTPUT_FILE' dosyasına kaydedildi.${RESET}"
    fi
}

# Programı başlat
main "$@"