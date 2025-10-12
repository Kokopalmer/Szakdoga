% 1. OPC UA kliens létrehozása és csatlakozás
uaClientdaq = opcua('opc.tcp://192.168.0.34:4840');
uaClientext = opcua('opc.tcp://192.168.0.5:4840');
uaClientszar = opcua('opc.tcp://192.168.0.12:4840');

connect(uaClientdaq);
connect(uaClientext)
connect(uaClientszar)

% 2. Node hivatkozása
myNode1 = findNodeByName(uaClientdaq.Namespace, 'Counter'); % vagy nodeId: opcuanode(4,27)
myNode2 = findNodeByName(uaClientext.Namespace, 'Counter'); % vagy nodeId: opcuanode(4,27)
myNode3 = findNodeByName(uaClientszar.Namespace, 'Counter'); % vagy nodeId: opcuanode(4,27)

% 3. Írás a node-ba
writeValue(uaClientdaq, myNode1, true);   % logikai érték
writeValue(uaClientdaq, myNode1, 42.0);   % numerikus érték

writeValue(uaClientext, myNode2, true);   % logikai érték
writeValue(uaClientext, myNode2, 42.0);   % numerikus érték

writeValue(uaClientszar, myNode3, true);   % logikai érték
writeValue(uaClientszar, myNode3, 42.0);   % numerikus érték