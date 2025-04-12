entware_fixed() {
    sed -i -e '/Package: xray/,/Installed-Time:/d' "$status_file"

    if [ -f "$register_dir/xray_s.control" ] || [ -f "$register_dir/xray_s.list" ]; then
        rm -f "$register_dir/xray_s.control" "$register_dir/xray_s.list"
    fi
	
	if [ -f "$initd_dir/S24xray" ]; then
        rm "$initd_dir/S24xray"
    fi
	
	if [ -f "$install_dir/xray" ]; then
        rm "$install_dir/xray"
    fi
	
	if [ -f "$install_conf_dir/config.json.example" ]; then
		rm "$install_conf_dir/config.json.example"
    fi	
}