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
echo ">>>>>> DIY-PART2 脚本开始执行 <<<<<<"
# 1. 全局架构转换：把所有默认的旧版防火墙、iptables、ipset 统统踢出去
# 使用 sed 的 d 命令直接删除这些行，防止它们通过依赖关系死灰复燃
sed -i '/CONFIG_DEFAULT_firewall/d' .config
sed -i '/CONFIG_DEFAULT_iptables/d' .config
sed -i '/CONFIG_DEFAULT_ipset/d' .config
sed -i '/CONFIG_DEFAULT_ip6tables/d' .config
sed -i '/CONFIG_PACKAGE_firewall/d' .config
sed -i '/CONFIG_PACKAGE_iptables/d' .config
sed -i '/CONFIG_PACKAGE_ipset/d' .config

# 2. 强制指定系统使用 fw4 (nftables) 核心
cat >> .config <<EOF
CONFIG_PACKAGE_fw4=y
CONFIG_PACKAGE_nftables=y
CONFIG_PACKAGE_kmod-nft-tproxy=y
CONFIG_PACKAGE_kmod-nft-socket=y
CONFIG_PACKAGE_kmod-nft-fullcone=y
CONFIG_PACKAGE_kmod-nft-nat=y
CONFIG_PACKAGE_kmod-nft-offload=y
CONFIG_PACKAGE_dnsmasq_full_nftset=y
EOF

# 3. 针对 Passwall 的一键修正 (移除 iptables 依赖项，强制开启 nft 模式)
sed -i '/CONFIG_PACKAGE_luci-app-passwall/d' .config
cat >> .config <<EOF
CONFIG_PACKAGE_luci-app-passwall=y
CONFIG_PACKAGE_luci-app-passwall_Nftables_Transparent_Proxy=y
# CONFIG_PACKAGE_luci-app-passwall_Iptables_Transparent_Proxy is not set
EOF

# 4. 针对 Turbo ACC 的一键修正 (核心：改用 Flow Offloading，禁用 SFE)
sed -i '/CONFIG_PACKAGE_luci-app-turboacc/d' .config
cat >> .config <<EOF
CONFIG_PACKAGE_luci-app-turboacc=y
CONFIG_PACKAGE_luci-app-turboacc_Nftables_Network_Acceleration=y
# CONFIG_PACKAGE_luci-app-turboacc_Iptables_Network_Acceleration is not set
# CONFIG_PACKAGE_luci-app-turboacc_Shortcut_FE is not set
EOF

# 5. 处理 SSR Plus+ 冲突 (如果你不需要它，建议直接删除；如果需要，强制它不引用 iptables)
# 注意：在很多 LEDE 分支中，SSR Plus+ 无法完美脱离 iptables，建议与 Passwall 二选一
sed -i 's/CONFIG_DEFAULT_luci-app-ssr-plus=y/# CONFIG_DEFAULT_luci-app-ssr-plus is not set/g' .config
sed -i 's/CONFIG_PACKAGE_luci-app-ssr-plus=y/# CONFIG_PACKAGE_luci-app-ssr-plus is not set/g' .config

# 6. 最后的保险：确保 dnsmasq-full 编译正确
sed -i '/CONFIG_PACKAGE_dnsmasq_full_ipset/d' .config
echo "CONFIG_PACKAGE_dnsmasq_full_nftset=y" >> .config

echo ">>>>>> DIY-PART2 修正完成，当前配置预览： <<<<<<"
grep "CONFIG_PACKAGE_fw4" .config || echo "未找到 FW4 配置"
grep "CONFIG_PACKAGE_firewall" .config || echo "未找到旧防火墙配置"
grep "luci-app-passwall" .config | grep "Nftables" || echo "Passwall NFT 组件未勾选"
echo ">>>>>> DIY-PART2 输出结束 <<<<<<"
