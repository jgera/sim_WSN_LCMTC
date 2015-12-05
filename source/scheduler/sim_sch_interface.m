
close all;
clear classes;
% clear all;

%%% I Parametri della simulazione forniti allo scheduler
%USE_EA_LSA = 1;         % se =1, utilizza EA-LSA. Se =0, usa LSA
single_step_en = 10;     % è legato a pd, ossia è l'energia massima di elaborazione dei task nell'unità di tempo
% deve essere sempre maggiore dell'energia raccolta
% dalll'harvester nell'unità di tempo

capacitor_max_lvl = 100; % massimo livello di carica del condensatore (valore nominale)
capacitor_min_lvl = 0;   % minimo livello di carica del condensatore
capacitor_init_lvl = 0.5 * capacitor_max_lvl; % iniziale livello di carica del condensatore

%%% Inserito un non random set per motivi di test.
max_time_steps  = 2000;
task_num = 8;
tasks_arrival_time      = [ 10, 15, 30, 55, 80,105,115,125];
tasks_energy_demand     = 20* [ 10, 10,  2,  2,  2,  3,  3,  3];
tasks_relative_deadline   = [120,135, 20, 20, 20, 20, 20, 20];

energy_harvest = max(0,randn(1,max_time_steps)); % quantità di energia raccolta in ciascun time step (E_S(t))

% numero di violazioni della deadline in funzione di C (da 1 fino a
% "cap_max_value")
cap_max_value=60;

first_deadline_violation_time = zeros(1,cap_max_value);
violated_deadline_nr = zeros(1,cap_max_value);

% simula utilizzando i due algoritmi di scheduling:
% - LSA
% - EA-LSA
for USE_EA_LSA = 0:1
    first_deadline_violation_time = zeros(1,cap_max_value);
    violated_deadline_nr = zeros(1,cap_max_value);
    for cap=1:cap_max_value
        
        [ first_deadline_violation_time(1,cap), violated_deadline_nr(1,cap) ]=...
            schedule_tasks(...
            USE_EA_LSA, single_step_en,...
            capacitor_max_lvl*cap, capacitor_min_lvl*cap, capacitor_init_lvl*cap,...
            max_time_steps,...
            tasks_arrival_time, tasks_relative_deadline, tasks_energy_demand,...
            energy_harvest...
            );
    end
    % salva i risultati su dei vettori
    if ( USE_EA_LSA == 1)
        EALSA_first_deadline_violation_time =  first_deadline_violation_time;
        EALSA_removed_tasks_nr = violated_deadline_nr;
    else
        LSA_first_deadline_violation_time = first_deadline_violation_time;
        LSA_violated_deadline_nr = violated_deadline_nr;
    end
end


% Risulatati della simulazione
figure()
hold on
plot(LSA_first_deadline_violation_time,'-+');
plot(EALSA_first_deadline_violation_time,'-x');
title(['Power = ', num2str(single_step_en),';  First deadline violation time'])
xlabel('C')
ylabel('time of first deadline violation')
legend('LSA first dline violation t', 'EA-LSA first dline violation t')
legend('boxoff')
hold off

figure()
hold on
plot(LSA_violated_deadline_nr,'-+');
plot(EALSA_removed_tasks_nr,'-x');
title(['Power = ', num2str(single_step_en),';  Deadline violation number'])
xlabel('C')
ylabel('number of violation')
legend('LSA dline violation num', 'EA-LSA dline violation num')
legend('boxoff')
hold off
