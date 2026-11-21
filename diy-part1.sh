#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Uncomment a feed source
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
# echo 'src-git istore https://github.com/linkease/istore;main' >>feeds.conf.default


# nlbwmon: persist a larger Netlink receive buffer.
# The nlbwmon UCI setting is applied on first boot, after package installation.
mkdir -p files/etc/uci-defaults
cat > files/etc/uci-defaults/99-nlbwmon-netlink-buffer <<'EOF'
#!/bin/sh

if [ -f /etc/config/nlbwmon ]; then
    uci set nlbwmon.@nlbwmon[0].netlink_buffer_size='2097152' || exit 1
    uci commit nlbwmon || exit 1
fi

exit 0
EOF
chmod 755 files/etc/uci-defaults/99-nlbwmon-netlink-buffer

