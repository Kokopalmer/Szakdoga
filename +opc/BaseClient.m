classdef BaseClient < handle
    properties
        Client
        Nodes
        Connected = false
    end

    methods
        function obj = BaseClient(endpoint)
            try
                obj.Client = opcua(endpoint);
                connect(obj.Client);
                obj.Connected = strcmp(obj.Client.Status, "Connected");
                disp("Sikeres kapcsolodas")
            catch ME
                warning("Nem sikerült kapcsolódni: %s", [ME.message]);
                obj.Connected = false;
            end
        end

        function delete(obj)
            if ~isempty(obj.Client) && strcmp(obj.Client.Status, "Connected")
                disconnect(obj.Client);
            end
        end
    end
end