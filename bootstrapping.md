
# Bootstrapping

Allow the unifreq kernel to read AML partition table: https://github.com/ophub/amlogic-s9xxx-armbian/issues/1109

## Repartitioning

- AML Partition Tables: https://7ji.github.io/embedded/2022/11/11/ept-with-ampart.html
- Decrypt AML dtb: https://7ji.github.io/crack/2023/01/08/decrypt-aml-dtb.html
- ampart Tool: https://github.com/7Ji/ampart/tree/master

### Backup

>[!WARNING]
>Remember to backup or else you may be unable to restore the system to factory.

[full reserved partition backup](https://github.com/err4o4/spotify-car-thing-reverse-engineering/issues/30#issuecomment-2161567419)
My backup `ampart` partitions output is in `ampart_partitions.txt`.

### Retrieve and Decrypt dtb

Please follow the [Decrypt AML dtb](https://7ji.github.io/crack/2023/01/08/decrypt-aml-dtb.html) to get the decrypted dtb from stock firmware. I uploaded one but it's recommended you do that using your own device. 

### Download initrd image and sample Nerves application

Download the following and save locally.

- [Kernel Image](https://github.com/ericr3r/notes-superbird/releases/download/v0.1.0/Image)
- [Device Tree](https://github.com/ericr3r/notes-superbird/releases/download/v0.1.0/meson-g12a-superbird.dtb)
- [Scenic Clock app](https://github.com/ericr3r/superbird_clock/releases/download/v0.1.0/clock-0.1.0.fw)

### Boot initrd image and backup bootloader

1. Start Spotify&trade; Car Thing in `burn mode`.

2. Use initrd to boot:

 `python ./amlogic_device.py -c ./uboot_envs/bootargs.txt ~/Downloads/Image ~/Downloads/meson-g12a-superbird.dtb`

3. Ssh into the system, `ssh superbird@172.16.42.2` with the password `superbird`. You will later transfer files using `scp` from the host to superbird.

4. Backup bootloader and encrypted dtb using 
    ```
    sudo dd if=/dev/mmcblk2 of=bootloader.img bs=1M count=4
    sudo dd if=/dev/mmcblk2 of=stock_dtb.img bs=256K skip=160 count=2
    ```
5. Copy the backups back to the host.

On the *host*, scp the backups and copy needed files to superbird:
```
    scp superbird@172.16.42.2:/home/superbird/bootloader.img bootloader.img
    scp superbird@172.16.42.2:/home/superbird/stock_dtb.img stock_dtb.img
    scp decrypted.dtb superbird@172.16.42.2:/home/superbird/stock_dtb.img
    scp ~/Downloads/clock-0.1.0.fw superbird@172.16.42.2:/home/superbird/clock.fw
```

4. Restore decrypted dtb using 
    ```
    sudo dd if=decrypted.dtb of=/dev/mmcblk2 bs=256K seek=160 conv=notrunc
    sudo dd if=decrypted.dtb of=/dev/mmcblk2 bs=256K seek=161 conv=notrunc
    sudo sync
    ```
5. Check your stock partitions.

```
sudo ./ampart-v1.4-aarch64-static /dev/mmcblk2 --mode esnapshot
```

6. Update partition table.
    ```
    sudo ./ampart-v1.4-aarch64-static /dev/mmcblk2 --mode eclone bootloader:0B:4M:0 reserved:36M:64M:0 cache:108M:0B:0 env:116M:8M:0 fip_a:132M:4M:0 fip_b:144M:4M:0 logo:156M:8M:0 data:176M:-1:4
    ```

7. Format partitions and upload the clock app using
    ```
    sudo fwup -i clock.fw -a -t complete -y
    ```

8. Restore bootloader using
    ```
    sudo dd if=bootloader.img of=/dev/mmcblk2 conv=fsync,notrunc bs=1 count=444
    sudo dd if=bootloader.img of=/dev/mmcblk2 conv=fsync,notrunc bs=512 skip=1 seek=1
    ```

10. reboot into `burn_mode`.

11. Update UBoot environment to boot Nerves image in Gadget mode.

Using [Superbird Tool](https://github.com/bishopdynamics/superbird-tool), flash `uboot_envs/nerves_usb_gadet.txt` or `uboot_envs/nerves_usb_host.txt` for `gadget` or `usb host support`.

```
python3 superbird_tool.py --send_full_env nerves_usb_gadet.txt
```


```
python3 superbird_tool.py --send_full_env nerves_usb_host.txt
```





