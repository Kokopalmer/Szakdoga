classdef PlotManager < handle
    properties
        hLines
        Ax
        Colors
    end

    methods
        function obj = PlotManager(ax, nLines)
            obj.Ax = ax;
            hold(ax, 'on');
            obj.Colors = lines(nLines);
            obj.hLines = gobjects(nLines,1);

            for i = 1:nLines
                obj.hLines(i) = plot(ax, NaT, NaN, ...
                    'Color', obj.Colors(i,:),'LineWidth', 2);
            end
            grid(ax, 'on');
            xtickformat(ax, 'HH:mm:ss');
        end

        function update(obj, t, data)
            for i = 1:numel(obj.hLines)
                set(obj.hLines(i), 'XData', [get(obj.hLines(i),'XData'), t], ...
                                   'YData', [get(obj.hLines(i),'YData'), data(i)]);
            end
        end
    end
end
