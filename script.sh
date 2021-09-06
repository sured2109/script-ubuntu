echo "Konfigurasi IP secara temporer"
echo -n "IP Address (IPV4): "
read ipv4ku
echo -n "IP Address (IPV6): "
read ipv6ku
echo -n "Subnetmask: "
read smku
echo -n "Prefix IPV6: "
read prefix6
echo -n "Default Gateway (IPV4): "
read gw4ku
echo -n "Default Gateway (IPV6): "
read gw6ku
echo -n "Domain name: "
read domainku
ifconfig enp0s3 $ipv4ku netmask $smku
route add default gw $gw4ku
ifconfig enp0s3 inet6 add $ipv6ku$prefix6
route add -A inet6 default gw $gw6ku

cat > /etc/bind/named.conf.options << EOF
options {
	directory "/var/cache/bind";
	auth-nxdomain no; # conform to RFC1035
	listen-on-v6 { $ipv6ku; };
	listen-on { $ipv4ku; };
	allow-query { any; };
	recursion no;
};
EOF

cat >> /etc/bind/named.conf.local << EOF

zone "$domainku" IN {
	type master;
	file "/etc/bind/$domainku.zone";
	allow-update { none; };
};
EOF

cat > /etc/bind/$domainku.zone << EOF
\$TTL 1D
\$ORIGIN $domainku.
@	IN 	SOA 	ns1.$domainku. hostmaster (
			26092015; serial
			1D 	; refresh
			1H 	; retry
			1W 	; expire
			3H ) 	; minimum

@	IN 	NS 	ns1
@	IN 	MX 5 	mx1
@	IN 	A	$ipv4ku
@	IN 	AAAA 	$ipv6ku
ns1 	IN 	A	$ipv4ku
ns1 	IN 	AAAA 	$ipv6ku
mx1 	IN 	A	$ipv4ku
mx1 	IN 	AAAA 	$ipv6ku
mail 	IN 	A	$ipv4ku
mail 	IN 	AAAA 	$ipv6ku
www 	IN 	CNAME 	@

EOF

chgrp bind /etc/bind/$domainku.zone
systemctl restart bind9
echo "nameserver $ipv4ku" > /etc/resolv.conf
echo "nameserver $ipv6ku" >> /etc/resolv.conf
