app.daq      = opc.DataAcq('opc.tcp://192.168.0.34:4840');
                LampColor(app, app.DaqLamp, app.daq)
                app.ExtLamp.Color = 'yellow';
                drawnow
                app.extruder = opc.Extruder('opc.tcp://192.168.0.5:4840');
                LampColor(app, app.ExtLamp, app.extruder)
                app.SzaLamp.Color = 'yellow';
                drawnow
                app.szarito  = opc.Szarito('opc.tcp://192.168.0.12:4840');