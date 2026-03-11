#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

# Modify default theme
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
#sed -i 's/OpenWrt/P3TERX-Router/g' package/base-files/files/bin/config_generate
# 修改默认 IP 为 192.168.50.250
# 自动查找 config_generate 文件并修改默认 IP
find package/base-files/ -name config_generate -exec sed -i 's/192.168.1.1/192.168.50.252/g' {} +
#!/bin/bash
echo ">>>>>> 开始天钡 N150 终极重构 (包含 Turbo ACC + FW4) <<<<<<"

# 1. 物理粉碎旧防火墙源码 (手术切除)
rm -rf package/network/config/firewall
rm -rf package/network/utils/iptables
rm -rf package/network/utils/ipset

# 2. 强行修改当前 .config 中的默认勾选项 (清理你的旧 Config 残留)
sed -i 's/CONFIG_DEFAULT_firewall=y/# CONFIG_DEFAULT_firewall is not set/' .config
sed -i 's/CONFIG_DEFAULT_iptables=y/# CONFIG_DEFAULT_iptables is not set/' .config
sed -i 's/CONFIG_DEFAULT_ip6tables=y/# CONFIG_DEFAULT_ip6tables is not set/' .config
sed -i 's/CONFIG_DEFAULT_ipset=y/# CONFIG_DEFAULT_ipset is not set/' .config

# 3. 基因手术：全目录扫描，切断 Passwall 和 Turbo ACC 对 iptables 的所有念想
find package/ -name Makefile -exec sed -i 's/iptables-mod-tproxy//g' {} +
find package/ -name Makefile -exec sed -i 's/iptables-mod-socket//g' {} +
find package/ -name Makefile -exec sed -i 's/iptables-mod-iprange//g' {} +
find package/ -name Makefile -exec sed -i 's/kmod-ipt-offload//g' {} +
find package/ -name Makefile -exec sed -i 's/ipset//g' {} +

# 4. 注入核心：FW4 + 2.5G 网卡驱动 + 现代加速
cat >> .config <<EOF
# 防火墙 4 核心
CONFIG_PACKAGE_fw4=y
CONFIG_PACKAGE_nftables=y
CONFIG_PACKAGE_kmod-nft-tproxy=y
CONFIG_PACKAGE_kmod-nft-socket=y
CONFIG_PACKAGE_kmod-nft-fullcone=y
CONFIG_PACKAGE_kmod-nft-offload=y

# Passwall 核心 (Nftables 模式)
CONFIG_PACKAGE_luci-app-passwall=y
CONFIG_PACKAGE_luci-app-passwall_Nftables_Transparent_Proxy=y
CONFIG_PACKAGE_dnsmasq_full_nftset=y

# Turbo ACC 核心 (Nftables 原生流加速)
# 注意：关闭 SFE 和 BBR，因为在 N100 + FW4 环境下，原生 Flow Offloading 最稳
CONFIG_PACKAGE_luci-app-turboacc=y
CONFIG_PACKAGE_luci-app-turboacc_Nftables_Network_Acceleration=y
# CONFIG_PACKAGE_luci-app-turboacc_Shortcut_FE is not set
# CONFIG_PACKAGE_luci-app-turboacc_BBR_CCA is not set

# N150 (Intel N100) 硬件必备
CONFIG_PACKAGE_kmod-igc=y
CONFIG_PACKAGE_kmod-nvme=y
CONFIG_PACKAGE_intel-microcode=y
EOF

# 5. 最后通牒：重新扫描依赖树
make defconfig

echo ">>>>>> 天钡 N150 重构脚本执行完毕，架构已锁定为 FW4 + TurboACC <<<<<<"
