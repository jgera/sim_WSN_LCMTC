function sim_sch_interface(...
    capacitor_max_lvl,...% massimo livello di carica del condensatore (valore nominale)
    capacitor_init_lvl,...[%] livello di carica iniziale del condensatore, in percentuale
    single_step_en,...% è legato a pd, ossia è l'energia massima di elaborazione dei task nell'unità di tempo
    ...% deve essere sempre maggiore dell'energia raccolta dall'harvester nell'unità di tempo
    tasks_arrival_time,...          
    tasks_energy_demand,...
    tasks_relative_deadline,...
    energy_harvest...   % l'energia raccolta dall'energy harvester
    )

    %%% imposto alcuni paraemteri della simulazione
    max_time_steps = lenght(energy_harvest);  % la durata della simulazione in timesteps
    sim_step_nr = 50; % numero di ripetizioni della simulazione

    % simula utilizzando i due algoritmi di scheduling:
    % - LSA
    % - EA-LSA
    for USE_EA_LSA = 0:1
        first_deadline_violation_time = zeros(1,capacitor_max_lvl);
        violated_deadline_nr = zeros(1,capacitor_max_lvl);
        for cap = linspace( 0.001, capacitor_max_lvl, sim_step_nr )
            % scalo le dimensioni della capacità iniziale e della capacità 
            % minima in funzione della capacità massima (cap) che varia in
            % funzione dello step del ciclo for da 1 a capacitor_max_lvl
            capacitor_min_lvl = 0;    % [%] minimo livello di carica del condensatore = 0%
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

end% end function
