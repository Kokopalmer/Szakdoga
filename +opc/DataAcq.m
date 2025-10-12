classdef DataAcq < opc.BaseClient
    methods
        function obj = DataAcq(endpoint)
            obj@opc.BaseClient(endpoint);
            if obj.Connected
                obj.Nodes = [
                    opcuanode(4, 4);  % Balance
                    opcuanode(4, 5);  % PeristalticPump1RPM
                    opcuanode(4, 3);  % Counter
                ];
            else
                fprintf("Nem jo %s", [ME.message])
            end
        end

        function x = read(obj)
            if obj.Connected
                try
                    vals = readValue(obj.Client, obj.Nodes);
                    x = [vals{1}; vals{2}; vals{3}];
                catch
                    warning("DataAcq olvasási hiba");
                    x = nan(3,1);
                end
            else
                x = nan(3,1);
            end
        end
    end
end