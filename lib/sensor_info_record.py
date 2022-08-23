#!/usr/bin/env python3

from robot.libraries.BuiltIn import BuiltIn
import gen_print as gp
import utils as ut


def validate_threshold_values(sensor_threshold_values, sensor_id):

    r"""
    As per IPMI spec, threshold value should not be equal and lower values should be lower within its key
    and upper value should be higher within its key.
    It should be like below,
        For lower -  lnr < lcr < lnc
        For upper -  unc < ucr < unr
    """

    sensor_threshold_keys = list(sensor_threshold_values.keys())

    for key in range(0, len(sensor_threshold_keys) - 1):
        threshold_value_1 = sensor_threshold_values.get(sensor_threshold_keys[key])
        threshold_value_2 = sensor_threshold_values.get(sensor_threshold_keys[key + 1])
        if not float(threshold_value_1) < float(threshold_value_2):
            error_message = sensor_id + " " + "sensor threshold value :\n" + \
                            str(sensor_threshold_keys[key]) + " " + "-" + str(threshold_value_1) + "\n" + \
                            str(sensor_threshold_keys[key+1]) + " " + "-" + str(threshold_value_2)
            BuiltIn().fail(gp.sprint_error(error_message))


def check_reading_value_length(sensor_reading, sensor_id, sensor_unit):

    r"""
    Reading value will have dot.
    Value before dot was taken as integer reading value and after dot was taken as fractional reading value.
    Integer reading value length will vary based on sensor type
        - For fan sensor   - Integer reading value length can be upto 6.
        - For other sensor - Integer reading value length should be within 4.
    Fractional reading value for all sensor type(including fan) length should be within 4.
    """

    integer_reading_value = sensor_reading.split(".")[0]
    fractional_reading_value = sensor_reading.split(".")[1]
    fan_sensor_status = sensor_unit == "RPM"
    if not len(integer_reading_value) < 6:
        error_message = sensor_id + " " + "sensor integer reading value length was more than 5.\n" + \
        "Integer Reading Value : " + " " + integer_reading_value
        BuiltIn().fail(gp.sprint_error(error_message))
    if fan_sensor_status:
        if not len(fractional_reading_value) < 4:
            error_message = sensor_id + " " + "sensor fractional reading value length was more than 3.\n" + \
            "Fractional Reading Value : " + " " + fractional_reading_value
            BuiltIn().fail(gp.sprint_error(error_message))
    else:
        if not len(fractional_reading_value) < 5:
            error_message = sensor_id + " " + "sensor fractional reading value length was more than 4.\n" + \
            "Fractional Reading Value : " + " " + fractional_reading_value
            BuiltIn().fail(gp.sprint_error(error_message))


def convert_sensor_name_as_per_ipmi_spec(sensor_name):

    r"""
    As per IPMI spec, sensor id in IPMI sensor command needs to be in 16 bytes.
    But in dbus sensor_id can be any length.
    This function will check whether sensor name got from ipmi/dbus was 16bytes
    If not then it will shorten to first 16bytes and return as decoded sensor name.
    If it was within 16bytes then without doing anything it will return as decoded sensor name.
    """

    tmp_lst = []
    tmp_lst_1 = []

    expected_byte = 16

    for letter in sensor_name:
        tmp_lst.append(hex(ord(letter)))

    if not expected_byte >= len(tmp_lst):
        bytes_to_be_reduced = len(tmp_lst) - expected_byte
        tmp_lst = tmp_lst[:-bytes_to_be_reduced]

    for value in tmp_lst:
        if value[:2] == '0x':
            value = value[2:]
            tmp_lst_1.append(bytes.fromhex(value).decode('utf-8'))

    return ut.convert_list_to_string(tmp_lst_1)


def create_sensor_list_not_having_single_threshold(ipmi_sensor_response, threshold_sensor_list):

    r"""
    If an threshold sensor does not have an single threshold value
    then that sensor id will be append to the list.
    """

    sensor_id_not_having_single_threshold = []

    for sensor_id in threshold_sensor_list:
        id = sensor_id.replace('_', ' ')
        for lines in ipmi_sensor_response.split("\n"):
            if id in lines:
                lnr = lines.split('|')[4].strip()
                lcr = lines.split('|')[5].strip()
                lnc = lines.split('|')[6].strip()
                unc = lines.split('|')[7].strip()
                ucr = lines.split('|')[8].strip()
                unr = lines.split('|')[9].strip()
        if lnr == "na" and lcr == "na" and lnc == "na" and unc == "na" and ucr == "na" and unr == "na":
            sensor_id_not_having_single_threshold.append(id)

    return sensor_id_not_having_single_threshold
