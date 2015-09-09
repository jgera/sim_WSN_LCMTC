%   incoming_power = computePVIncomingPower( filename, startMonth, startDay, length, run_time, PV_efficiency, PV_surface )
%
%   Compute the incoming power harvested from a PV module with a surface of
%   PV_surface [m^2] and an efficiency of PV_efficiency [W/W].
%   Return a vector of length equal to run_time with the mean of power
%   harvested by PV module over each timestep. 
%   E.g. If the observation time (length) is 1 day and run_time is 24, each
%   row of incoming_power contain the mean of the power harvested by the PV
%   module over 1 hour (the timestep) of that day. 
%   
%   This file need extractSIR.m file placed into the same directory.
%   See extractSIR.m for more information about solar irradiation data
%   import, the file type, etc.
%
%   INPUTS:
%   -filename: a string containing the full pathname of the .csv file 
%              downloaded from soda-is website.
%   -startMonth: is the number of the month of interest.
%   -startDay: it's the number of the day of interest.
%   -length: it's the length (in days) of the observation period. It is also
%            proportional to the length of SIR_data vector. In-fact, 
%            m = 96 x lentgh = the row's number of the SIR_data vector.
%   -run_time: it's the time vector of the simulation. It is also the length
%              of incoming_power vector.
%   -PV_efficiency: is the efficiency of the PV module, measured under  
%                   standard test conditions [1000W/m^2 @ 25°C]. 
%                   Typically it's in the range [9%-17%] that is [0.09-0.17]
%   -PV_surface: it's the surface of the PV module, in square meters.
%
%   OUTPUTS:
%   -PV_incoming_power: it's a vector of length equal to run_time containing the 
%   mean of power harvested by PV module over each timestep. 
%
%   EXAMPLE:
%
function PV_incoming_power = computePVIncomingPower( filename, startMonth, startDay, length, run_time, PV_efficiency, PV_surface )
    SIR_data=extractSIR(filename, startMonth, startDay, length);        %include extractSIR.m into the same directory of actual file
    PV_incoming_power=SIR_data.*(PV_surface*PV_efficiency);             %Compute the power in watt, harvested by a PV module with certain size and efficiency
    PV_incoming_power=resample(PV_incoming_power,run_time,numel(PV_incoming_power)); %adapt the signal length to the lentgh of the simulation (run_time)
    PV_incoming_power=PV_incoming_power';
end

