#!/usr/bin/python

r"""
Contains xpaths and related string constants applicable for new Vue based OpenBMC GUI.
"""


class gui_variables():

    # Login page
    xpath_textbox_hostname = "//input[@id='host']"
    xpath_textbox_username = "//*[@data-test-id='login-input-username']"
    xpath_textbox_password = "//*[@data-test-id='login-input-password']"
    xpath_login_button = "//*[@data-test-id='login-button-submit']"
    xpath_logout_button = "//*[@data-test-id='appHeader-link-logout']"

    # Overview menu
    xpath_overview_menu = "//*[@data-test-id='nav-item-overview']"

    # GUI header
    xpath_root_button_menu = "//*[@data-test-id='appHeader-container-user']"
    xpath_profile_settings = "//*[@data-test-id='appHeader-link-profile']"
    xpath_server_health_header = "//*[@data-test-id='appHeader-container-health']"
    xpath_server_power_header = "//*[@data-test-id='appHeader-container-power']"
    xpath_refresh_button = "//*[@data-test-id='appHeader-button-refresh']"

    # Logs menu
    #xpath_health_menu = "//*[@data-test-id='nav-button-health']"
    xpath_logs_menu = "//*[@data-test-id='nav-button-logs']"
    xpath_dumps_sub_menu = "//*[@data-test-id='nav-item-dumps']"
    xpath_event_logs_sub_menu = "//*[@data-test-id='nav-item-event-logs']"
    xpath_event_header = "//h1[text()='Event logs']"

    # Hardware status menu
    # New xpath_hardware_status_menu = "//*[@data-test-id='nav-button-hardware-status']"
    xpath_hardware_status_sub_menu = "//*[@data-test-id='nav-item-inventory']"
    xpath_sensor_sub_menu = "//*[@data-test-id='nav-item-sensors']"

    # Operations menu
    # New xpath_operations_menu = "//*[@data-test-id='nav-button-operations']"
    xpath_factory_reset_sub_menu = "//*[@data-test-id='nav-item-factory-reset']"
    xpath_firmware_update_sub_menu = "//*[@data-test-id='nav-item-firmware']"
    xpath_reboot_bmc_sub_menu = "//*[@data-test-id='nav-item-reboot-bmc']"
    xpath_sol_sub_menu = "//*[@data-test-id='nav-item-serial-over-lan']"
    xpath_server_power_operations_sub_menu = "//*[@data-test-id='nav-item-server-power-operations']"
    xpath_sol_console_heading = "//h1[text()='Serial over LAN (SOL) console']"

    # Settings menu
    # New xpath_settings_menu = "//*[@data-test-id='nav-button-settings']"
    xpath_network_page_header = "//h1[contains(text(), 'Network')]"
    xpath_date_time_settings_sub_menu = "//*[@data-test-id='nav-item-date-time']"
    xpath_select_network_settings = "//*[@data-test-id='nav-item-network']"
    xpath_power_restore_policy_sub_menu = "//*[@data-test-id='nav-item-power-restore-policy']"

    # Security and access menu
    # New xpath_secuity_and_accesss_menu = "//*[@data-test-id='nav-button-security-and-access']"
    #xpath_client_sessions_sub_menu = "//*[@data-test-id='nav-item-client-sessions']"
    xpath_client_sessions_sub_menu = "//*[@data-test-id='nav-item-sessions']"
    xpath_ldap_sub_menu = "//*[@data-test-id='nav-item-ldap']"
    #xpath_local_user_management_sub_menu = "//*[@data-test-id='nav-item-local-user-management']"
    xpath_local_user_management_sub_menu = "//*[@data-test-id='nav-item-user-management']"
    #xpath_security_settings_sub_menu = "//*[@data-test-id='nav-item-security-settings']"
    xpath_policies_sub_menu = "//*[@data-test-id='nav-item-policies']"
    #xpath_ssl_certificates_sub_menu = "//*[@data-test-id='nav-item-ssl-certificates']"
    xpath_ssl_certificates_sub_menu = "//*[@data-test-id='nav-item-certificates']"

    # Resource management menu
    # New xpath_resource-management_menu = "//*[@data-test-id='nav-button-resource-management']"
    #xpath_manage_power_usage_sub_menu = "//*[@data-test-id='nav-item-manage-power-usage']"
    xpath_manage_power_usage_sub_menu = "//*[@data-test-id='nav-item-power']"

    # Profile settings
    xpath_default_UTC = "//*[@data-test-id='profileSettings-radio-defaultUTC']"
    xpath_profile_save_button = "//*[@data-test-id='profileSettings-button-saveSettings']"
    xpath_input_password = "//*[@data-test-id='profileSettings-input-newPassword']"
    xpath_input_confirm_password = "//*[@data-test-id='profileSettings-input-confirmPassword']"

    # Common variables
    xpath_save_settings_button = "//button[contains(text(),'Save settings')]"
