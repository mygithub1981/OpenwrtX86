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
echo ">>>>>> 执行终极物理粉碎绝招：强制转向纯 FW4 架构 <<<<<<"

# --- 第一步：物理粉碎旧防火墙源码 (手术切除) ---
# 在编译扫描前，直接把这些旧东西的文件夹删掉，让系统找不到它们
rm -rf package/network/config/firewall      # 删除 fw3
rm -rf package/network/utils/iptables       # 删除 iptables 工具
rm -rf package/network/utils/ipset          # 删除 ipset 工具
rm -rf package/libs/libnftnl                # 强制重新索引 nftables 相关库 (可选)

# --- 第二步：手术级修改所有插件的 Makefile ---
# 这一步是为了防止 Passwall、Turbo ACC 等插件在编译时去寻找已经不存在的 iptables
find package/ -name Makefile -exec sed -i 's/iptables-mod-tproxy//g' {} +
find package/ -name Makefile -exec sed -i 's/iptables-mod-socket//g' {} +
find package/ -name Makefile -exec sed -i 's/iptables-mod-iprange//g' {} +
find package/ -name Makefile -exec sed -i 's/iptables-mod-conntrack-extra//g' {} +
find package/ -name Makefile -exec sed -i 's/iptables-mod-nat-extra//g' {} +
find package/ -name Makefile -exec sed -i 's/ipset//g' {} +

# --- 第三步：注入纯净的 FW4 核心配置 ---
# 既然物理删除了旧包，必须手动确保新包被选中
cat >> .config <<EOF
CONFIG_PACKAGE_fw4=y
CONFIG_PACKAGE_nftables=y
CONFIG_PACKAGE_kmod-nft-tproxy=y
CONFIG_PACKAGE_kmod-nft-socket=y
CONFIG_PACKAGE_kmod-nft-fullcone=y
CONFIG_PACKAGE_kmod-nft-offload=y
CONFIG_PACKAGE_dnsmasq_full_nftset=y
EOF

# --- 第四步：强制 Passwall 走 Nftables 路径 ---
sed -i '/CONFIG_PACKAGE_luci-app-passwall/d' .config
cat >> .config <<EOF
CONFIG_PACKAGE_luci-app-passwall=y
CONFIG_PACKAGE_luci-app-passwall_Nftables_Transparent_Proxy=y
# CONFIG_PACKAGE_luci-app-passwall_Iptables_Transparent_Proxy is not set
EOF

# --- 修正版：针对纯 FW4 环境的 Turbo ACC 处理 ---
# 1. 物理粉碎 Turbo ACC 内部可能存在的 iptables 依赖声明
find package/ -name "luci-app-turboacc" -exec sed -i 's/iptables-mod-tproxy//g' {} +
find package/ -name "luci-app-turboacc" -exec sed -i 's/kmod-ipt-offload//g' {} +

# 2. 强制指定使用 Nftables 版本的加速，并禁用所有旧版 SFE/Flow 加速
sed -i '/CONFIG_PACKAGE_luci-app-turboacc/d' .config
cat >> .config <<EOF
CONFIG_PACKAGE_luci-app-turboacc=y
CONFIG_PACKAGE_luci-app-turboacc_Nftables_Network_Acceleration=y
# CONFIG_PACKAGE_luci-app-turboacc_Iptables_Network_Acceleration is not set
# CONFIG_PACKAGE_luci-app-turboacc_Shortcut_FE is not set
# CONFIG_PACKAGE_luci-app-turboacc_BBR_CCA is not set
EOF

# 3. 补齐 FW4 原生加速内核模块
echo "CONFIG_PACKAGE_kmod-nft-offload=y" >> .config

# --- 第六步：最后通牒 - 运行修复索引 ---
# 物理删除后必须运行一次修复，确保编译系统知道那些旧包已经消失了
make defconfig

echo ">>>>>> 物理粉碎完成！现在系统已经没有 iptables 的立足之地了 <<<<<<"
