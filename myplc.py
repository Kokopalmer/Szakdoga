# file: myplc.py
import struct
import snap7


# PLC settings
PLC_IP = "192.168.0.12"
RACK = 0
SLOT = 1
DB_NUMBER = 14


# Mapping (MATLAB OPCUA node-ok → DB14 offsetek)
READ_MAP = {
    "AutomataMod": 0,              # Bool
    "KeziElszivas": 2,             # Bool
    "ElszivasAktiv": 1,            # Bool
    "KeziFutes": 3,                # Bool
    "KeziLegaram": 4,              # Bool
    "KeziLepuffanas": 5,           # Bool

    "Zona1HoMert": 6,              # REAL
    "Zona1HoAlapjel": 10,          # REAL
    "Zona1Legaram": 14,            # DWORD

    "Zona2HoMert": 18,             # REAL
    "Zona2HoAlapjel": 22,          # REAL
    "Zona2Legaram": 26,            # DWORD

    "Zona3HoMert": 30,             # REAL
    "Zona3HoAlapjel": 34,          # REAL
    "Zona3Legaram": 36,            # REAL

    "Zona4HoMert": 38,             # REAL
    "Zona4Legaram": 42,            # WORD
    "Zona4HoAlapjel": 54,          # REAL

    "VibromotorFrekvencia": 44,    # TIME (DWORD)
    "BefuvasiIdo": 48,             # TIME (DWORD)

    "KeziVibromotor": 52,          # Bool
    "Lampa": 53,                   # Bool

    "KilepoLevegoMert": 58,        # REAL
    "KilepoTermekMert": 62,        # REAL
    "PreslevegoParaMert": 66       # REAL
}


# -----------------------------
# PLC CONNECT
# -----------------------------
def connect_to_plc(ip: str = PLC_IP, rack: int = RACK, slot: int = SLOT):
    plc = snap7.client.Client()
    plc.connect(ip, rack, slot)
    if not plc.get_connected():
        raise RuntimeError("Failed to connect to PLC")
    return plc


# -----------------------------
# WRITE FUNCTIONS (optional)
# -----------------------------
def write_real(plc, db_number: int, offset: int, value: float):
    data = struct.pack(">f", float(value))
    plc.db_write(db_number, offset, data)


def set_db14_parameters(plc, values):
    if len(values) != 4:
        raise ValueError("Need 5 REAL values for DB14 parameter write!")
    OFFSETS = [6, 18, 30, 54]
    for offset, val in zip(OFFSETS, values):
        write_real(plc, DB_NUMBER, offset, float(val))


# -----------------------------
# READ ALL DRYER VALUES
# -----------------------------
def read_all(plc):
    """
    Dryer DB14 full readout as a dictionary.
    Keys match 1:1 the old MATLAB OPCUA node names.
    BefuvasiIdo is replaced with constant 0 as requested.
    """

    def read_bool(offset):
        raw = plc.db_read(DB_NUMBER, offset, 1)
        return 1.0 if raw[0] != 0 else 0.0

    def read_real(offset):
        raw = plc.db_read(DB_NUMBER, offset, 4)
        return float(struct.unpack(">f", raw)[0])

    def read_word(offset):
        raw = plc.db_read(DB_NUMBER, offset, 2)
        return float(int.from_bytes(raw, "big"))

    def read_dword(offset):
        raw = plc.db_read(DB_NUMBER, offset, 4)
        return float(int.from_bytes(raw, "big"))

    return {
        # ---- BOOL values ----
        "AutomataMod": read_bool(0),
        "KeziElszivas": read_bool(2),
        "ElszivasAktiv": read_bool(1),
        "KeziFutes": read_bool(3),
        "KeziLegaram": read_bool(4),
        "KeziLepuffanas": read_bool(5),

        # ---- REAL / DWORD Zóna 1 ----
        "Zona1HoMert": read_real(6),
        "Zona1HoAlapjel": read_real(10),
        "Zona1Legaram": read_dword(14),

        # ---- Zóna 2 ----
        "Zona2HoMert": read_real(18),
        "Zona2HoAlapjel": read_real(22),
        "Zona2Legaram": read_dword(26),

        # ---- Zóna 3 ----
        "Zona3HoMert": read_real(30),
        "Zona3HoAlapjel": read_real(34),
        "Zona3Legaram": read_real(36),

        # ---- Zóna 4 ----
        "Zona4HoMert": read_real(38),
        "Zona4Legaram": read_word(42),
        "Zona4HoAlapjel": read_real(54),

        # ---- Time / DWORD values ----
        "VibromotorFrekvencia": read_dword(44),

        # ---- Fixed values / missing ----
        "BefuvasiIdo": 0.0,   # FIXED constant, by request

        # ---- Boolean ----
        "KeziVibromotor": read_bool(52),
        "Lampa": read_bool(53),

        # ---- Outputs ----
        "KilepoLevegoMert": read_real(58),
        "KilepoTermekMert": read_real(62),
        "PreslevegoParaMert": read_real(66),
    }