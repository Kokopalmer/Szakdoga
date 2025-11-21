import struct
import snap7

PLC_IP = "192.168.0.12"
RACK = 0
SLOT = 1

DB_NUMBER = 14

# Offsets (byte addresses) of the REAL values in DB14
PARAM_OFFSETS = [6, 18, 30, 44, 54]


def connect_to_plc(ip: str, rack: int = RACK, slot: int = SLOT) -> snap7.client.Client:
    plc = snap7.client.Client()
    print(f"Connecting to PLC at {ip} (rack={rack}, slot={slot})...")
    plc.connect(ip, rack, slot)
    if not plc.get_connected():
        raise RuntimeError("Failed to connect to PLC")
    print("Connected.")
    return plc


def write_real(plc: snap7.client.Client, db_number: int, offset: int, value: float) -> None:
    """
    Write a single REAL (4-byte float) into DB at given offset.
    Siemens REAL = big-endian IEEE754.
    """
    data = struct.pack(">f", value)
    plc.db_write(db_number, offset, data)


def read_real(plc: snap7.client.Client, db_number: int, offset: int) -> float:
    data = plc.db_read(db_number, offset, 4)
    return struct.unpack(">f", data)[0]


def set_db14_parameters(plc: snap7.client.Client, values):
    """
    values: iterable with 5 float values, in order of PARAM_OFFSETS.
    """
    if len(values) != len(PARAM_OFFSETS):
        raise ValueError(f"Expected {len(PARAM_OFFSETS)} values, got {len(values)}")

    print("\nWriting parameters to DB14...")
    for offset, value in zip(PARAM_OFFSETS, values):
        v = float(value)
        print(f"  DB{DB_NUMBER}, offset {offset}: {v}")
        write_real(plc, DB_NUMBER, offset, v)

    print("\nReading back for verification:")
    for offset in PARAM_OFFSETS:
        v = read_real(plc, DB_NUMBER, offset)
        print(f"  DB{DB_NUMBER}, offset {offset}: {v}")


def main():
    # 1) Get values interactively (you can comment this block
    #    and hard-code values if you prefer)
    print("Enter 5 REAL values for DB14 at offsets:")
    print(f"  {PARAM_OFFSETS}")
    user_values = []
    for i, offset in enumerate(PARAM_OFFSETS, start=1):
        while True:
            try:
                raw = input(f"Value #{i} (offset {offset}): ")
                user_values.append(float(raw))
                break
            except ValueError:
                print("  Please enter a valid number.")

    # If you prefer hard-coded test values instead, comment the loop above
    # and uncomment the next line:
    # user_values = [45.0, 50.0, 55.0, 60.0, 65.0]

    plc = None
    try:
        plc = connect_to_plc(PLC_IP)
        set_db14_parameters(plc, user_values)
    except Exception as e:
        print("Error:", e)
    finally:
        if plc is not None and plc.get_connected():
            plc.disconnect()
            print("Disconnected from PLC.")


if __name__ == "__main__":
    main()