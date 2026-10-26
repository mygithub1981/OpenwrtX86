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
# 修改系统默认的 TCP 拥塞控制算法为 BBR

# 设置系统默认队列规则、TCP 拥塞控制和 nlbwmon 接收缓冲区
SYSCTL_CONF="package/base-files/files/etc/sysctl.conf"

# 删除已有配置，避免重复或冲突
sed -i '/^net\.ipv4\.tcp_congestion_control=/d' "$SYSCTL_CONF"
sed -i '/^net\.core\.default_qdisc=/d' "$SYSCTL_CONF"
sed -i '/^net\.core\.rmem_max=/d' "$SYSCTL_CONF"

# 写入经过当前固件验证的配置
echo "net.core.default_qdisc=fq_codel" >> "$SYSCTL_CONF"
echo "net.ipv4.tcp_congestion_control=bbr" >> "$SYSCTL_CONF"
echo "net.core.rmem_max=1048576" >> "$SYSCTL_CONF"
