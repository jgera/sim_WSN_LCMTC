% test computePVIncomingPower with the SIR file relative to year 2005 in Ancona
SIR_data_relativePathName='LCMTC\EnergySource\SolarRadiationData_SODA-IS\2005_Ancona_15min_obs\request_hc3v5lat43.630_lon13.500_2005-01-01_2005-12-31_990776387.csv'

startMonth = 7;         %the number of the month of interest.
startDay = 7;           %the number of the day of interest.
length = 2;             %the length (in days) of the observation period. 
run_time = 10000;       %the time vector of the simulation. It is also the length of incoming_power vector.
PV_efficiency = 0.1;    %the efficiency of the PV module
PV_surface = 0.04;      %the surface of the PV module, in square meters.

incoming_power=computePVIncomingPower(SIR_data_relativePathName,startMonth,startDay,length,run_time,PV_efficiency,PV_surface);

figure('Name','Energy Source profile','NumberTitle','off');
plot(incoming_power);
xlabel('timestep');
ylabel('harvested power [W]');