classdef Szarito < opc.BaseClient
    methods
        function obj = Szarito(endpoint)
            obj@opc.BaseClient(endpoint);
            if obj.Connected
                obj.Nodes = [
                    opcuanode(4, 25);  % AutomataMod
                    opcuanode(4, 27);  % KeziElszivas
                    opcuanode(4, 26);  % ElszívásAktiv
                    opcuanode(4, 28);  % KeziFutes
                    opcuanode(4, 29);  % KeziLegaram
                    opcuanode(4, 30);  % KeziLepuffanas
                    opcuanode(4, 31);  % Zona1HoMert
                    opcuanode(4, 32);  % Zona1HoAlapjel
                    opcuanode(4, 33);  % Zona1Legaram
                    opcuanode(4, 34);  % Zona2HoMert
                    opcuanode(4, 35);  % Zona2HoAlapjel
                    opcuanode(4, 36);  % Zona2Legaram
                    opcuanode(4, 37);  % Zona3HoMert
                    opcuanode(4, 38);  % Zona3HoAlapjel
                    opcuanode(4, 40);  % Zona4HoMert
                    opcuanode(4, 39);  % Zona3Legaram
                    opcuanode(4, 41);  % Zona4Legaram
                    opcuanode(4, 42);  % VibromotorFrekvencia
                    opcuanode(4, 43);  % BefuvasiIdo
                    opcuanode(4, 44);  % KeziVibromotor
                    opcuanode(4, 45);  % Lampa
                    opcuanode(4, 46);  % Zona4HoAlapjel
                    opcuanode(4, 49);  % PreslevegoParaMert
                    opcuanode(4, 48);  % KilepoTermekMert
                    opcuanode(4, 47);  % KilepoLevegoMert
                ];
            end
        end

        function x = read(obj)
    if obj.Connected
        try
            vals = readValue(obj.Client, obj.Nodes);

            if any(cellfun(@isempty, vals))
                warning("Szárító: üres érték érkezett valamelyik node-ra.");
            end

            x = nan(numel(obj.Nodes), 1);
            for i = 1:numel(vals)
                try
                    x(i) = vals{i};
                catch
                    warning("Szárító: node %d értéke hibás.", i);
                    x(i) = NaN;
                end
            end
        catch ME
            warning("Szárító olvasási hiba: %s", [ME.message]);
            x = nan(numel(obj.Nodes), 1);
        end
    else
        x = nan(numel(obj.Nodes), 1);
    end
end
        end
end