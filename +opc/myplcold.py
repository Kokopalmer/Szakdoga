def read_all(plc):
    result = {}

    for name, offset in READ_MAP.items():
        try:
            # BOOL
            if "Mod" in name or "Kezi" in name or name == "Lampa":
                raw = plc.db_read(14, offset, 1)
                result[name] = bool(raw[0])

            # WORD (Zona4Legaram)
            elif name == "Zona4Legaram":
                raw = plc.db_read(14, offset, 2)
                result[name] = int.from_bytes(raw, byteorder='big')

            # DWORD (Zona1Legaram, Zona2Legaram)
            elif "Legaram" in name and name != "Zona3Legaram":
                raw = plc.db_read(14, offset, 4)
                result[name] = int.from_bytes(raw, byteorder='big')

            # REAL
            else:
                raw = plc.db_read(14, offset, 4)
                result[name] = struct.unpack(">f", raw)[0]

        except Exception:
            result[name] = None

    return result