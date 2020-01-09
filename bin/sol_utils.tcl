#!/bin/bash
#\
exec expect "$0" -- ${1+"$@"}

# This file contains utilities for working with Serial over Lan (SOL).

# Example use case:
# sol_utils.tcl --os_host=ip --os_password=password --os_username=username
# --openbmc_host=ip --openbmc_password=password --openbmc_username=username
# --proc_name=boot_to_petitboot --host_sol_port=port

source [exec bash -c "which source.tcl"]
my_source \
[list print.tcl opt.tcl valid.tcl call_stack.tcl tools.exp cmd.tcl host.tcl]

longoptions openbmc_host: openbmc_username:=root openbmc_password:=0penBmc host_sol_port:=2200\
  os_host: os_username:=root os_password: proc_name: ftp_username: \
  ftp_password: os_repo_url: autoboot_setting: test_mode:=0 quiet:=0 debug:=0
pos_parms

set valid_proc_name [list os_login boot_to_petitboot go_to_petitboot_shell \
  install_os time_settings software_selection root_password set_autoboot]

# Create help dictionary for call to gen_print_help.
set help_dict [dict create\
  ${program_name} [list "${program_name} is an SOL utilities program that\
    will run the user's choice of utilities.  See the \"proc_name\" parm below\
    for details."]\
  openbmc_host [list "The OpenBMC host name or IP address." "host"]\
  openbmc_username [list "The OpenBMC username." "username"]\
  openbmc_password [list "The OpenBMC password." "password"]\
  os_host [list "The OS host name or IP address." "host"]\
  os_username [list "The OS username." "username"]\
  os_password [list "The OS password." "password"]\
  host_sol_port [list "The HOST SOL port number." "port"]\
  proc_name [list "The proc_name you'd like to run.  Valid values are as\
    follows: [regsub -all {\s+} $valid_proc_name {, }]."]\
  autoboot_setting [list "The desired state of autoboot." "true/flase"]\
]


# Setup state dictionary.
set state [dict create\
  ssh_logged_in 0\
  os_login_prompt 0\
  os_logged_in 0\
  petitboot_screen 0\
  petitboot_shell_prompt 0\
]


proc help {} {

  gen_print_help

}


proc exit_proc { {ret_code 0} } {

  # Execute whenever the program ends normally or with the signals that we
  # catch (i.e. TERM, INT).

  dprintn ; dprint_executing
  dprint_var ret_code

  set cmd_buf os_logoff
  qprintn ; qprint_issuing
  eval ${cmd_buf}

  set cmd_buf sol_logoff
  qprintn ; qprint_issuing
  eval ${cmd_buf}

  qprint_pgm_footer

  exit $ret_code

}


proc validate_parms {} {

  trap { exit_proc } [list SIGTERM SIGINT]

  valid_value openbmc_host
  valid_value openbmc_username
  valid_value openbmc_password
  valid_value os_host
  valid_value os_username
  valid_password os_password
  valid_value host_sol_port
  global valid_proc_name
  global proc_name proc_names
  set proc_names [split $proc_name " "]
  if { [lsearch -exact $proc_names "install_os"] != -1 } {
    valid_value ftp_username
    valid_password ftp_password
    valid_value os_repo_url
  }
  if { [lsearch -exact $proc_names "set_autoboot"] != -1 } {
    valid_value autoboot_setting {} [list "true" "false"]
  }

}


proc sol_login {} {

  # Login to the SOL console.

  dprintn ; dprint_executing

  global spawn_id
  global expect_out
  global state
  global openbmc_host openbmc_username openbmc_password host_sol_port
  global cr_lf_regex
  global ssh_password_prompt

  set cmd_buf "spawn -nottycopy ssh -p $host_sol_port $openbmc_username@$openbmc_host"
  qprint_issuing
  eval $cmd_buf

  append bad_host_regex "ssh: Could not resolve hostname ${openbmc_host}:"
  append bad_host_regex " Name or service not known"
  set expect_result [expect_wrap\
    [list $bad_host_regex $ssh_password_prompt]\
    "an SOL password prompt" 5]

  if { $expect_result == 0 } {
    puts stderr ""
    print_error "Invalid openbmc_host value.\n"
    exit_proc 1
  }

  send_wrap "${openbmc_password}"

  append bad_user_pw_regex "Permission denied, please try again\."
  append bad_user_pw_regex "${cr_lf_regex}${ssh_password_prompt}"
  set expect_result [expect_wrap\
    [list $bad_user_pw_regex "sh: xauth: command not found"]\
    "an SOL prompt" 10]

  switch $expect_result {
    0 {
      puts stderr "" ; print_error "Invalid OpenBmc username or password.\n"
      exit_proc 1
    }
    1 {
      # Currently, this string always appears but that is not necessarily
      # guaranteed.
      dict set state ssh_logged_in 1
    }
  }

  if { [dict get $state ssh_logged_in] } {
    qprintn ; qprint_timen "Logged into SOL."
    dprintn ; dprint_dict state
    return
  }

  # If we didn't get a hit on the "sh: xauth: command not found", then we just
  # need to see a linefeed.
  set expect_result [expect_wrap [list ${cr_lf_regex}] "an SOL prompt" 5]

  dict set state ssh_logged_in 1
  qprintn ; qprint_timen "Logged into SOL."
  dprintn ; dprint_dict state

}


proc sol_logoff {} {

  # Logoff from the SOL console.

  dprintn ; dprint_executing

  global spawn_id
  global expect_out
  global state
  global openbmc_host

  if { ! [dict get $state ssh_logged_in] } {
    qprintn ; qprint_timen "No SOL logoff required."
    return
  }

  send_wrap "~."

  set expect_result [expect_wrap\
    [list "Connection to $openbmc_host closed"]\
    "a connection closed message" 5]

  dict set state ssh_logged_in 0
  qprintn ; qprint_timen "Logged off SOL."
  dprintn ; dprint_dict state

}


proc get_post_ssh_login_state {} {

  # Get the initial state following sol_login.

  # The following state global dictionary variable is set by this procedure.

  dprintn ; dprint_executing

  global spawn_id
  global expect_out
  global state
  global os_login_prompt_regex
  global os_prompt_regex
  global petitboot_screen_regex
  global petitboot_shell_prompt_regex
  global installer_screen_regex

  if { ! [dict get $state ssh_logged_in] } {
    puts stderr ""
    append message "Programmer error - [get_stack_proc_name] must only be"
    append message " called after sol_login has been called."
    print_error_report $message
    exit_proc 1
  }

  # The first thing one must do after signing into ssh -p 2200 is hit enter to
  # see where things stand.
  send_wrap ""
  set expect_result [expect_wrap\
  [list $os_login_prompt_regex $os_prompt_regex $petitboot_screen_regex \
  $petitboot_shell_prompt_regex $installer_screen_regex] \
  "any indication of status" 5 0]

  switch $expect_result {
    0 {
      dict set state os_login_prompt 1
    }
    1 {
      dict set state os_logged_in 1
    }
    2 {
      dict set state petitboot_screen 1
    }
    3 {
      dict set state petitboot_shell_prompt 1
    }
  }

  dprintn ; dprint_dict state

}


proc os_login {} {

  # Login to the OS.

  dprintn ; dprint_executing

  global spawn_id
  global expect_out
  global state
  global openbmc_host os_username os_password
  global os_password_prompt
  global os_prompt_regex

  if { [dict get $state os_logged_in] } {
    printn ; print_timen "We are already logged in to the OS."
    return
  }

  send_wrap "${os_username}"

  append bad_host_regex "ssh: Could not resolve hostname ${openbmc_host}:"
  append bad_host_regex " Name or service not known"
  set expect_result [expect_wrap\
    [list $os_password_prompt]\
    "an OS password prompt" 5]

  send_wrap "${os_password}"
  set expect_result [expect_wrap\
    [list "Login incorrect" "$os_prompt_regex"]\
    "an OS prompt" 10]
  switch $expect_result {
    0 {
      puts stderr "" ; print_error "Invalid OS username or password.\n"
      exit_proc 1
    }
  }

  dict set state os_logged_in 1
  dict set state os_login_prompt 0
  qprintn ; qprint_timen "Logged into OS."
  dprintn ; dprint_dict state

}


proc os_logoff {} {

  # Logoff from the SOL console.

  dprintn ; dprint_executing

  global spawn_id
  global expect_out
  global state
  global os_login_prompt_regex

  if { ! [dict get $state os_logged_in] } {
    qprintn ; qprint_timen "No OS logoff required."
    return
  }

  send_wrap "exit"
  set expect_result [expect_wrap\
    [list $os_login_prompt_regex]\
    "an OS prompt" 5]

  dict set state os_logged_in 0
  qprintn ; qprint_timen "Logged off OS."
  dprintn ; dprint_dict state

}


proc boot_to_petitboot {} {

  # Boot the machine until the petitboot screen is reached.

  dprintn ; dprint_executing

  global spawn_id
  global expect_out
  global state
  global os_prompt_regex
  global petitboot_screen_regex
  global autoboot_setting

  if { [dict get $state petitboot_screen] } {
    qprintn ; qprint_timen "Already at petiboot."
    return
  }

  if { [dict get $state petitboot_shell_prompt] } {
    qprintn ; qprint_timen "Now at the shell prompt. Going to petitboot."
    send_wrap "exit"
    set expect_result [expect_wrap [list $petitboot_screen_regex]\
    "the petitboot screen" 900]
    dict set state petitboot_shell_prompt 0
    dict set state petitboot_screen 1
    return
  }

  if { [dict get $state os_login_prompt] } {
    set cmd_buf os_login
    qprintn ; qprint_issuing
    eval ${cmd_buf}
  }

  # Turn off autoboot.
  set_autoboot "false"

  # Reboot and wait for petitboot.
  send_wrap "reboot"

  # Once we've started a reboot, we are no longer logged into OS.
  dict set state os_logged_in 0
  dict set state os_login_prompt 0

  set expect_result [expect_wrap\
    [list $petitboot_screen_regex]\
    "the petitboot screen" 900]
  set expect_result [expect_wrap\
    [list "Exit to shell"]\
    "the 'Exit to shell' screen" 10]
  dict set state petitboot_screen 1

  qprintn ; qprint_timen "Arrived at petitboot screen."
  dprintn ; dprint_dict state

}


proc go_to_petitboot_shell {} {

  # Go to petitboot shell.
  global spawn_id
  global state
  global expect_out
  global petitboot_shell_prompt_regex

  if { [dict get $state petitboot_shell_prompt] } {
    qprintn ; qprint_timen "Already at the shell prompt."
    return
  }

  eval boot_to_petitboot
  send_wrap "x"
  set expect_result [expect_wrap [list $petitboot_shell_prompt_regex]\
    "the shell prompt" 10]
  dict set state petitboot_screen 0
  dict set state petitboot_shell_prompt 1
  qprintn ; qprint_timen "Arrived at the shell prompt."
  qprintn ; qprint_timen state

}


proc set_autoboot { { autoboot_setting {}} } {

  # Set the state of autoboot.
  # Defaults to the value of the global autoboot_setting.

  # This will work regardless of whether the OS is logged in or at petitboot.

  # Description of argument(s):
  # autoboot_setting  The desired state of autoboot (true/flase).

  dprintn ; dprint_executing
  global spawn_id
  global expect_out
  global state
  global os_prompt_regex
  global petitboot_shell_prompt_regex

  set_var_default autoboot_setting [get_stack_var autoboot_setting 0 2]
  set prompt_regex $petitboot_shell_prompt_regex

  if { [dict get $state os_login_prompt] } {
    set cmd_buf os_login
    qprintn ; qprint_issuing
    eval ${cmd_buf}
    set prompt_regex $os_prompt_regex
  }

  if { [dict get $state petitboot_screen ] } {
    set cmd_buf go_to_petitboot_shell
    qprintn ; qprint_issuing
    eval ${cmd_buf}
  }

  if { [dict get $state os_logged_in ] } {
    set prompt_regex $os_prompt_regex
  }


  set cmd_result [shell_command\
    "nvram --update-config auto-boot?=$autoboot_setting" $prompt_regex]
  set cmd_result [shell_command "nvram --print-config" $prompt_regex]

}


proc installation_destination {} {

  # Set the software installation destination.

  # Expectation is that we are starting at the "Installation" options screen.

  dprintn ; dprint_executing

  global spawn_id
  global expect_out
  global state
  global installer_screen_regex

  qprintn ; qprint_timen "Presumed to be at \"Installation\" screen."

  qprintn ; qprint_timen "Setting Installation Destination."
  # Option 5). Installation Destination
  qprintn ; qprint_timen "Selecting \"Installation Destination\" option."
  send_wrap "5"
  expect_wrap [list "Installation Destination"] "installation destination\
  menu" 30

  qprintn ; qprint_timen "Selecting \"Select all\" option."
  send_wrap "3"
  expect_wrap [list "Select all"] "selected all disks" 10

  qprintn ; qprint_timen "Selecting \"continue\" option."
  send_wrap "c"
  expect_wrap [list "Autopartitioning"] "autopartitioning options" 10

  qprintn ; qprint_timen "\
  Selecting \"Replace Existing Linux system(s)\" option."
  send_wrap "1"
  expect_wrap [list "Replace"] "selected stanard partition" 10

  qprintn ; qprint_timen "Selecting \"continue\" option."
  send_wrap "c"
  expect_wrap [list "Partition Scheme"] "partition scheme options" 10

  qprintn ; qprint_timen "Selecting \"LVM\" option."
  send_wrap "3"
  expect_wrap [list "LVM"] "lvm option" 10

  qprintn ; qprint_timen "Selecting \"continue\" option."
  send_wrap "c"
  expect_wrap [list $installer_screen_regex] "installation options screen" 10

}


proc time_settings {} {

  # Set the time/zone via the petitboot shell prompt "Time settings" menu.

  # Expectation is that we are starting at the "Installation" options screen.

  dprintn ; dprint_executing

  global spawn_id
  global expect_out
  global state
  global installer_screen_regex

  # Option 2). Timezone.

  qprintn ; qprint_timen "Presumed to be at \"Installation\" screen."
  qprintn ; qprint_timen "Setting time."

  qprintn ; qprint_timen "Selecting \"Time settings\"."
  send_wrap "2"
  expect_wrap [list "Set timezone" "Time settings"] "Time settings menu" 30

  qprintn ; qprint_timen "Selecting \"Change timezone\"."
  send_wrap "1"
  expect_wrap [list "Available regions"] "available regions menu" 10

  qprintn ; qprint_timen "Selecting \"US\"."
  send_wrap "11"
  expect_wrap [list "region US"] "select region in US menu" 10

  qprintn ; qprint_timen "Selecting \"Central\"."
  send_wrap "3"
  expect_wrap [list $installer_screen_regex] "installation options screen" 10

}


proc software_selection {} {

  # Set the base environment via the petitboot shell prompt
  # "Software Selection" menu.

  # Expectation is that we are starting at the "Installation" options
  # screen.

  dprintn ; dprint_executing

  global spawn_id
  global expect_out
  global state
  global installer_screen_regex

  qprintn ; qprint_timen "Presumed to be at \"Installation\" screen."
  qprintn ; qprint_timen "Software selection."
  # Option 4). Software selection.
  set expect_result 0
  while { $expect_result != 1 } {
    qprintn ; qprint_timen "Selecting \"Software selection\"."
    send_wrap "4"
    set expect_result [expect_wrap\
      [list "Installation source needs to be set up first." \
      "Base environment"] "base environment menu" 10 0]

    switch $expect_result {
      0 {
        qprintn ; qprint_timen "Selecting \"continue\"."
        send_wrap "c"
        expect_wrap [list $installer_screen_regex] \
        "installation options screen" 15
      }
      1 {
        break
      }
    }
  }

  qprintn ; qprint_timen "Selecting \"Infrastructure Server\"."
  send_wrap "2"
  expect_wrap [list "Infrastructure"] "selected infrastructure" 15

  qprintn ; qprint_timen "Selecting \"continue\"."
  send_wrap "c"
  expect_wrap [list $installer_screen_regex] "installation options screen" 15

}


proc root_password {} {

  # Set the os root password via the petitboot shell prompt "Root password"
  # option.

  # Expectation is that we are starting at the "Installation" options screen.

  dprintn ; dprint_executing

  global spawn_id
  global expect_out
  global state
  global os_password
  global installer_screen_regex

  qprintn ; qprint_timen "Presumed to be at \"Installation\" screen."
  qprintn ; qprint_timen "Setting root password."

  # Option 8). Root password.
  qprintn ; qprint_timen "Selecting \"Root password\"."
  send_wrap "8"
  expect_wrap [list "Password:"] "root password prompt" 30

  qprintn ; qprint_timen "Entering root password."
  send_wrap "$os_password"
  expect_wrap [list "confirm"] "comfirm root password prompt" 15

  qprintn ; qprint_timen "Re-entering root password."
  send_wrap "$os_password"
  set expect_result [expect_wrap\
    [list $installer_screen_regex "The password you have provided is weak"] \
    "root password accepted" 10 0]
  switch $expect_result {
    0 {
      break
    }
    1 {
    qprintn ; qprint_timen "Confirming weak password."
      send_wrap "yes"
    }
  }
  expect_wrap [list $installer_screen_regex] "installation options screen" 10

}


proc install_os {} {

  # Install an os on the machine.
  global spawn_id
  global expect_out
  global petitboot_shell_prompt_regex
  global installer_screen_regex
  global ftp_username ftp_password os_repo_url
  global os_host os_username os_password

  lassign [get_host_name_ip $os_host 0] os_hostname short_host_name ip_address
  set netmask [get_host_netmask $os_host $os_username $os_password {} 0]
  set gateway [get_host_gateway $os_host $os_username $os_password 0]
  set mac_address \
    [get_host_mac_address $os_host $os_username $os_password {} 0]
  set name_servers [get_host_name_servers $os_host $os_username $os_password 0]
  set dns [lindex $name_servers 0]
  set domain [get_host_domain $os_host $os_username $os_password 0]

  # Go to shell and download files for installation
  eval go_to_petitboot_shell
  after 10000
  set vmlinuz_url \
    "ftp://$ftp_username:$ftp_password@$os_repo_url/ppc/ppc64/vmlinuz"
  set initrd_url \
    "ftp://$ftp_username:$ftp_password@$os_repo_url/ppc/ppc64/initrd.img"
  send_wrap "wget -c $vmlinuz_url"
  expect_wrap [list "vmlinuz *100%"] "wget vmlinuz file success" 30
  send_wrap "wget -c $initrd_url"
  expect_wrap [list "initrd.img *100%"] "wget initrd file success" 30

  # Setup parms and run kexec.
  set colon "::"
  set squashfs_url \
    "ftp://$ftp_username:$ftp_password@$os_repo_url/LiveOS/squashfs.img"
  set kexec_args "kexec -l vmlinuz --initrd initrd.img\
    --append='root=live:$squashfs_url \
    repo=ftp://$ftp_username:$ftp_password@$os_repo_url rd.dm=0 rd.md=0\
    nodmraid console=hvc0 ifname=net0:$mac_address\
    ip=$os_host$colon$gateway:$netmask:$os_hostname:net0:none nameserver=$dns\
    inst.text'"
  send_wrap "$kexec_args"
  dprintn ; dprint_vars expect_out
  set expect_result [expect_wrap [list $petitboot_shell_prompt_regex]\
    "the shell prompt" 10]

  # Turn on autoboot.
  set_autoboot "true"

  send_wrap "kexec -e"

  # Begin installation process, go to settings screen.
  set expect_result [expect_wrap [list "Starting installer"]\
    "starting installer log" 900]
  set expect_result [expect_wrap [list "Use text mode"]\
    "install mode selection prompt" 120]
  send_wrap "2"
  expect_wrap [list $installer_screen_regex] "installation options screen" 15

  installation_destination
  time_settings
  software_selection
  root_password

  # Now begin installation process.
  set expect_result [expect_wrap\
    [list $os_repo_url "Processing..."] \
    "installation source processing" 10 0]

  switch $expect_result {
    0 {
      break
    }
    1 {
      expect_wrap [list $os_repo_url] "source processing complete" 240
    }
  }
  send_wrap "b"
  set expect_result [expect_wrap \
    [list "Installation complete* Press return to quit"] \
    "os installation complete message" 2000]
  send_wrap ""; # Reboots to petitboot.
  return

}


# Main

  gen_get_options $argv

  validate_parms

  qprint_pgm_header

  # Global variables for current prompts of the SOL console.
  set ssh_password_prompt ".* password: "
  set os_login_prompt_regex "login: "
  set os_password_prompt "Password: "
  set petitboot_screen_regex "Petitboot"
  set cr_lf_regex "\[\n\r\]"
  set os_prompt_regex "(\\\[${os_username}@\[^ \]+ ~\\\]# )"
  set petitboot_shell_prompt_regex "/ #"
  set installer_screen_regex \
  {Installation[\r\n].*Please make your choice from above.* to refresh\]: }

  dprintn ; dprint_dict state

  set cmd_buf sol_login
  qprint_issuing
  eval ${cmd_buf}

  set cmd_buf get_post_ssh_login_state
  qprintn ; qprint_issuing
  eval ${cmd_buf}

  foreach proc_name $proc_names {
    set cmd_buf ${proc_name}
    qprintn ; qprint_issuing
    eval ${cmd_buf}
  }

  exit_proc
