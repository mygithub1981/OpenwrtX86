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

# 1. 强制从旧版防火墙 (fw3/iptables) 切换到新版防火墙 (fw4/nftables)
# 这一步解决了 has_fw4:0 的核心问题
sed -i 's/CONFIG_PACKAGE_firewall=y/CONFIG_PACKAGE_fw4=y/g' .config
sed -i 's/CONFIG_DEFAULT_firewall=y/CONFIG_DEFAULT_fw4=y/g' .config
echo "CONFIG_PACKAGE_nftables=y" >> .config
echo "CONFIG_PACKAGE_kmod-nft-tproxy=y" >> .config

# 2. 修正 Dnsmasq-full 的 nftset 支持
# Passwall 在 fw4 环境下更新规则必须依赖 nftset，而非旧的 ipset
sed -i 's/CONFIG_PACKAGE_dnsmasq_full_ipset=y/# CONFIG_PACKAGE_dnsmasq_full_ipset is not set/g' .config
if grep -q "CONFIG_PACKAGE_dnsmasq-full=y" .config; then
    echo "CONFIG_PACKAGE_dnsmasq_full_nftset=y" >> .config
fi

# 3. 强制 Passwall 开启 nftables 代理支持组件
# 这是解决日志中规则更新提示的关键组件
echo "CONFIG_PACKAGE_luci-app-passwall_Nftables_Transparent_Proxy=y" >> .config

# 4. 移除多余的旧版规则管理包（可选，保持固件纯净）
sed -i 's/CONFIG_PACKAGE_iptables=y/# CONFIG_PACKAGE_iptables is not set/g' .config
sed -i 's/CONFIG_PACKAGE_ipset=y/# CONFIG_PACKAGE_ipset is not set/g' .config

# 5. 确保依赖库能够正确链接
echo "CONFIG_PACKAGE_libnftnl=y" >> .config
echo "CONFIG_PACKAGE_libexttextcat=y" >> .config
