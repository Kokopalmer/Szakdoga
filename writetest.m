% ===== OPC UA KLIENSEK CSATLAKOZTATÁSA =====
ua_szarito   = opcua('opc.tcp://192.168.0.12:4840');
ua_extruder  = opcua('opc.tcp://192.168.0.5:4840');
connect(ua_szarito);
connect(ua_extruder);
ua
disp(">> OPC UA kapcsolatok létrejöttek.")

% ===== SZÁRÍTÓ – HŐMÉRSÉKLET ZÓNÁK ÍRÁSA =====
try
    n1 = findNodeByName(ua_szarito.Namespace, 'Zona1HoAlapjel');
    n2 = findNodeByName(ua_szarito.Namespace, 'Zona2HoAlapjel');
    n3 = findNodeByName(ua_szarito.Namespace, 'Zona3HoAlapjel');
    n4 = findNodeByName(ua_szarito.Namespace, 'Zona4HoAlapjel');
    
    writeValue(ua_szarito, n1, 30.0);
    writeValue(ua_szarito, n2, 30.0);
    writeValue(ua_szarito, n3, 30.0);
    writeValue(ua_szarito, n4, 30.0);
    disp(">> Szárító hőmérséklet zónák írása OK")
catch
    warning("!! Hiba: Szárító hőmérséklet zónák nem írhatók")
end

% ===== SZÁRÍTÓ – LEVEGŐ ÁRAM ZÓNÁK =====
try
    v1 = findNodeByName(ua_szarito.Namespace, 'Zona1Legaram');
    v2 = findNodeByName(ua_szarito.Namespace, 'Zona2Legaram');
    v3 = findNodeByName(ua_szarito.Namespace, 'Zona3Legaram');
    v4 = findNodeByName(ua_szarito.Namespace, 'Zona4Legaram');

    writeValue(ua_szarito, v1, 60.0);
    writeValue(ua_szarito, v2, 60.0);
    writeValue(ua_szarito, v3, 60.0);
    writeValue(ua_szarito, v4, 60.0);
    disp(">> Szárító légáram zónák írása OK")
catch
    warning("!! Hiba: Szárító légáram zónák nem írhatók")
end

% ===== EXTRUDER – FORDULATSZÁM =====
try
    rpm = findNodeByName(ua_extruder.Namespace, 'MotorSebessegAlapjelSkalazott');
    writeValue(ua_extruder, rpm, 600.0);
    disp(">> Extruder fordulatszám írása OK")
catch
    warning("!! Hiba: Extruder fordulatszám nem írható")
end

% ===== EXTRUDER – HŐMÉRSÉKLET ZÓNÁK =====
try
    f1 = findNodeByName(ua_extruder.Namespace, 'Futes1Alapjel');
    f2 = findNodeByName(ua_extruder.Namespace, 'Futes2Alapjel');
    f3 = findNodeByName(ua_extruder.Namespace, 'Futes3Alapjel');
    f4 = findNodeByName(ua_extruder.Namespace, 'Futes4Alapjel');

    writeValue(ua_extruder, f1, 25.0);
    writeValue(ua_extruder, f2, 25.0);
    writeValue(ua_extruder, f3, 25.0);
    writeValue(ua_extruder, f4, 25.0);
    disp(">> Extruder hőmérséklet zónák írása OK")
catch
    warning("!! Hiba: Extruder hőmérséklet zónák nem írhatók")
end

disp("=== OPC UA WRITE TESZT BEFEJEZVE ===");alue(uaClientszar, myNode3, 42.0);   % numerikus érték


% ======== READBACK & VALIDÁCIÓ ========
disp("=== OPC UA READBACK & VALIDÁCIÓ ===");

measuredValues = zeros(size(expectedValues));

for i = 1:length(readNodes)
    try
        val = readValue(ua_szarito, readNodes{i}); % első próbálja szárítóról
        if isempty(val)
            val = readValue(ua_extruder, readNodes{i}); % ha nincs, próbál extruderről
        end
        measuredValues(i) = double(val);
    catch
        measuredValues(i) = NaN;
    end
end

measuredValues


expectedValues = [30, 30, 30, 30, ...            % Szárító hőmérséklet zónák
                  60, 60, 60, 60, ...            % Szárító légáram zónák
                  600, ...                       % Extruder sebesség
                  165, 170, 175, 180];           % Extruder zónák

readNodes = {
    n1, n2, n3, n4, ...
    v1, v2, v3, v4, ...
    rpm, ...
    f1, f2, f3, f4
};

measuredValues = zeros(size(expectedValues));

for i = 1:length(readNodes)
    try
        val = readValue(ua_szarito, readNodes{i}); % első próbálja szárítóról
        if isempty(val)
            val = readValue(ua_extruder, readNodes{i}); % ha nincs, próbál extruderről
        end
        measuredValues(i) = double(val);
    catch
        measuredValues(i) = NaN;
    end
end

% ======== KIÉRTÉKELÉS ========
disp("== KIÉRTÉKELÉS ==")
for i = 1:length(expectedValues)
    if abs(measuredValues(i) - expectedValues(i)) < 0.1
        fprintf(2, "OK ✅  | Elvárt: %.1f | PLC: %.1f\n", expectedValues(i), measuredValues(i));
    else
        fprintf(1, "HIBA ⚠ | Elvárt: %.1f | PLC: %.1f\n", expectedValues(i), measuredValues(i));
    end
end

% ======== Opcionális vizualizációs előkészítés (plot) ========
figure;
plot(expectedValues, 'o-', 'DisplayName', 'Elvárt');
hold on;
plot(measuredValues, 'x--', 'DisplayName', 'PLC-ből visszaolvasott');
xlabel('Paraméter index');
ylabel('Érték');
legend;
title('OPC UA WRITE TEST - Elvárt vs Mért értékek');
grid on;