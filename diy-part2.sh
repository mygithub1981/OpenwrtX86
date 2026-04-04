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
# 1. 修改源码层面的依赖，把默认的 ksmbd 替换为 samba4
sed -i 's/luci-app-ksmbd/luci-app-samba4/g' feeds/luci/collections/luci/Makefile
sed -i 's/luci-app-ksmbd/luci-app-samba4/g' feeds/luci/collections/luci-nginx/Makefile
sed -i 's/luci-app-ksmbd/luci-app-samba4/g' feeds/luci/collections/luci-ssl-nginx/Makefile

# 2. 强行删除 .config 文件中所有与 ksmbd 相关的残留配置
sed -i '/CONFIG_PACKAGE_luci-app-ksmbd=y/d' .config
sed -i '/CONFIG_PACKAGE_ksmbd-server=y/d' .config
sed -i '/CONFIG_PACKAGE_kmod-fs-ksmbd=y/d' .config

# 3. 确保 .config 文件中写入了 samba4 及其依赖（可选，作为双保险）
echo "CONFIG_PACKAGE_luci-app-samba4=y" >> .config
echo "CONFIG_PACKAGE_autosamba=y" >> .config
