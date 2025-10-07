function [start_time,end_time] = get_time(mot_file)

import org.opensim.modeling.*;

T = TimeSeriesTable(mot_file);
S = osimTableToStruct(T);
t = S.time;

start_time = t(1);
end_time = t(end);

end