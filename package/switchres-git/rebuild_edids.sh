#!/bin/bash
source /opt/gatools/include/includes.sh

#Build various EDIDs
build_and_install_edids() {
	mkdir -p /tmp/sredid
	cd /tmp/sredid
	for m in generic_15 arcade_15 arcade_15ex k7000 k7131 h9110 polo ; do
		switchres 640 480 60 --edid --monitor "$m"
	done

	# 25kHz
	for m in arcade_25 arcade_15_25 ; do
		switchres 512 384 60 --edid --monitor "$m"
	done

	# 31kHz
	for m in arcade_31 arcade_15_31 arcade_15_25_31 m2929 d9200 d9400 d9800 m3129 pstar ms2930 ms929 r666b pc_31_120 vesa_480 ; do
		switchres 640 480 60 --edid --monitor "$m"
	done

	# onliners, or special cases
	switchres 768 576 50 --edid --monitor pal
	switchres 720 480 60 --edid --monitor ntsc
	switchres 800 600 60 --edid --monitor vesa_600
	switchres 1024 768 60 --edid --monitor pc_70_120
	switchres 1024 768 60 --edid --monitor vesa_768
	switchres 1280 1024 60 --edid --monitor vesa_1024

	# Now generate a super res 15kHz edid wihth crt_range from generic_15
	mkdir superres
	cd superres
	cp /etc/switchres.ini .
	set_mame_config_value ./switchres.ini dotclock_min "25.0"
	switchres 640 480 60 --edid --monitor generic_15
	mv generic_15.bin generic_15_super_resi.bin
	echo "interlace 0" >> ./switchres.ini
	switchres 640 240 60 --edid --monitor generic_15
	mv generic_15.bin generic_15_super_resp.bin
	cp generic_15_super_res{i,p}.bin ../
	cd ..

	# Also recompute the custom mode EDID if it has been used
	custom_w=$(grep "^custom.width=" /home/arcade/shared/configs/ga.conf | cut -d ' ' -f 2-)
	custom_h=$(grep "^custom.height=" /home/arcade/shared/configs/ga.conf | cut -d ' ' -f 2-)
	custom_rr=$(grep "^custom.refresh_rate=" /home/arcade/shared/configs/ga.conf | cut -d ' ' -f 2-)
	edid_file=/usr/lib/firmware/edid/custom_resolution.bin
	if [[ -e $edid_file ]] && [[ -n $custom_w ]] && [[ -n $custom_h ]]  && [[ -n $custom_rr ]] ; then
		switchres $w $h $rr -e
		mv custom.bin $(basename "$edid_file")
	fi

	install -d /usr/lib/firmware/edid
	install -m 644 *.bin "$pkgdir"/usr/lib/firmware/edid

	cd ..
	rm -rf  /tmp/sredid
}

# Launch between () so changing dirs don't mess the current shell
(build_and_install_edids)