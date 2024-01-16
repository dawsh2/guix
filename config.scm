;; This is an operating system configuration template
;; for a "bare bones" setup, with no X11 display server.

(use-modules (gnu)
             (nongnu packages linux)
             (nongnu system linux-initrd))

(use-service-modules desktop networking ssh xorg linux)
(use-package-modules screen ssh)

(operating-system
  (host-name "desktop")
  (timezone "America/Dawson")
  (locale "en_US.utf8")
  (keyboard-layout (keyboard-layout "us"))

  ;; nonguix stuff 
  (kernel linux)
  (initrd microcode-initrd)
  (firmware (list linux-firmware))
  ;; /nonguix 

  
  ;; Boot in "legacy" BIOS mode, assuming /dev/sdX is the
  ;; target hard disk, and "my-root" is the label of the target
  ;; root file system.
  (bootloader (bootloader-configuration
                (bootloader grub-bootloader)
                (targets '("/dev/sda"))))
  ;; It's fitting to support the equally bare bones ‘-nographic’
  ;; QEMU option, which also nicely sidesteps forcing QWERTY.
  (kernel-arguments (list "console=ttyS0,115200"))
  (file-systems (cons (file-system
                        (device (file-system-label "my-root"))
                        (mount-point "/")
                        (type "ext4"))
                      %base-file-systems))

  ;; This is where user accounts are specified.  The "root"
  ;; account is implicit, and is initially created with the
  ;; empty password.
  (users (cons* (user-account
                (name "daws")
                (comment "Dawson")
                (group "users")
		(home-directory "/home/daws")
		
                ;; Adding the account to the "wheel" group
                ;; makes it a sudoer.  Adding it to "audio"
                ;; and "video" allows the user to play sound
                ;; and access the webcam.
                (supplementary-groups '("wheel" "audio" "netdev" "video")))
               %base-user-accounts))

  ;; Globally-installed packages.
  (packages (append (list (specification->package "emacs")
                          (specification->package "emacs-exwm")
                          (specification->package "emacs-desktop-environment")
                          (specification->package "nss-certs"))
                     %base-packages))

  ;; Add services to the baseline: a DHCP client and
  ;; an SSH server.
  (services (cons* ; (service dhcp-client-service-type)
		     ;; uncommenting the above causes networking to be provided more than once.. ?
		     (service zram-device-service-type
			      (zram-device-configuration
			       (size "1G")
			       (compression-algorithm 'lzo')
			       (memory-limit 0)
			       (priority #f))
			      )
			      
                     (service openssh-service-type
                              (openssh-configuration
                               (openssh openssh-sans-x)
                               (port-number 2222)))
		     (set-xorg-configuration
		      (xorg-configuration (keyboard-layout keyboard-layout)))
		    (modify-services %desktop-services
				     (guix-service-type config => (guix-configuration
								   (inherit config)
								   (substitute-urls
								    (append (list "https://substitutes.nonguix.org")
									    %default-substitute-urls))
								   (authorized-keys
								    (append (list (local-file "./signing-key.pub"))

					;(plain-file "non-guix.pub"
					;	   (public-key (ecc (curve Ed25519)
					;			    (q #C1FD53E5D4CE971933EC50C9F307AE2171A2D3B52C804642A7A35F84F3A4EA98#)))))
									    %default-authorized-guix-keys)))))
		    )))

		    
		    ;;                    %desktop-services)))   ;; dbus conflict if left alone 
		    
 ;; sudo guix system reconfigure --allow-downgrades /etc/config.scm --substitute-urls='https://ci.guix.gnu.org https://bordeaux.guix.org https://substitutes.nonguix.org'
