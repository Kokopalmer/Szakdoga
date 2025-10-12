classdef Extruder < opc.BaseClient
    methods
        function obj = Extruder(endpoint)
            obj@opc.BaseClient(endpoint);
            if obj.Connected
                obj.Nodes = [
                    opcuanode(4, 4);   % MotorSebessegAlapjelSkalazott
                    opcuanode(4, 3);   % MotorSebessegMertSkalazott
                    opcuanode(4, 6);   % Futes1Mert
                    opcuanode(4, 5);   % Futes1Alapjel
                    opcuanode(4, 7);   % Futes2Alapjel
                    opcuanode(4, 8);   % Futes2Mert
                    opcuanode(4, 9);   % Futes3Alapjel
                    opcuanode(4, 11);  % Futes4Alapjel
                    opcuanode(4, 10);  % Futes3Mert
                    opcuanode(4, 18);  % SzerszamNyomasMert
                    opcuanode(4, 17);  % Csiga2NyomatekMert
                    opcuanode(4, 16);  % Csiga1NyomatekMert
                    opcuanode(4, 15);  % EchoTerwinHomerseklet
                    opcuanode(4, 14);  % Futes5Mert
                    opcuanode(4, 13);  % Futes5Alapjel
                    opcuanode(4, 12);  % Futes4Mert
                ];
            end
        end

        function x = read(obj)
            if obj.Connected
                try
                    vals = readValue(obj.Client, obj.Nodes);
                    x = cellfun(@(v) v, vals);  % cell → numeric
                catch
                    warning("Extruder olvasási hiba");
                    x = nan(numel(obj.Nodes), 1);
                end
            else
                x = nan(numel(obj.Nodes), 1);
            end
        end
    end
end