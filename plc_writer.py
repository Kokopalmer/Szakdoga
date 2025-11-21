import struct
import snap7

PLC_IP = "192.168.0.12"
RACK = 0
SLOT = 1
DB_NUMBER = 14

# The 5 REAL offsets we want to write to DB14
PARAM_OFFSETS = [6, 18, 30, 54]


class PLCWriter:
    def __init__(self, ip: str = PLC_IP, rack: int = RACK, slot: int = SLOT):
        self.plc = snap7.client.Client()
        print(f"Connecting to PLC at {ip} (rack={rack}, slot={slot})...")
        self.plc.connect(ip, rack, slot)

        if not self.plc.get_connected():
            raise RuntimeError("Could not connect to PLC")

        print("PLC connected.")

    def write_real(self, offset: int, value: float):
        """Write a REAL (4 bytes) to DB14 at offset."""
        data = struct.pack(">f", float(value))
        self.plc.db_write(DB_NUMBER, int(offset), data)

    def write_params(self, values):
        """
        Write 5 REAL values to DB14 at offsets [6, 18, 30, 54]
        """
        if len(values) != len(PARAM_OFFSETS):
            raise ValueError(f"Expected 4 values, got {len(values)}")

        print("\nWriting PLC parameters...")

        for off, val in zip(PARAM_OFFSETS, values):
            v = float(val)
            print(f"  DB{DB_NUMBER}, offset {off}: {v}")
            self.write_real(off, v)

        print("Write completed.\n")

    def disconnect(self):
        """Disconnect cleanly."""
        if self.plc.get_connected():
            self.plc.disconnect()
            print("PLC disconnected.")