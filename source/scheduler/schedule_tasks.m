
function    [first_deadline_violation_time, violated_deadline_nr]=...
    schedule_tasks(...
    USE_EA_LSA, single_step_en,...
    capacitor_max_lvl, capacitor_min_lvl, capacitor_init_lvl,...
    max_time_steps,...
    tasks_arrival_time, tasks_relative_deadline, tasks_energy_demand,...
    energy_harvest...
    )

%%% Parametri del simulatore: definiscono il sistema ed il processo di
%%% simulazione.
en_surplus    = 0;      % energia in più rispetto all'energia massima immagazzinabile C
task_queue = task();    % inizializzo la coda dei task col task vuoto

capacitor_level = zeros(1, max_time_steps); % livello di energia residua in ciascun time step (E_C(t))
capacitor_level(1) = capacitor_init_lvl;

%%% Dati del problema: le informazioni sulla base delle quali eseguire il processo di
%%% simulazione.
task_num=length(tasks_arrival_time);

%%% Routine di valutazione dello scheduling.
% Parametri Ausiliari
task_scheduling_allowed = 0;    % utilizzata per scartare i task non completabili (utile per EA-LSA)
collected_en = 0;               % energia disponibile
time_idx = 1;
task_idx = 1;

%%%% Vettori utilizzati per loggare le deadline violate ed i task rimossi
%%%% dall'algoritmo EA-LSA.
LSA_violated_deadline_nr = 0;
LSA_first_deadline_violation_time = Inf;
EALSA_removed_tasks_nr = 0;
EALSA_first_deadline_violation_time = Inf;


for time_idx = 1: max_time_steps
    
    %disp(['Now executing cicle num ' num2str(time_idx) ] )
    %conteggio dell'energia disponibile all'istante t
    collected_en = capacitor_level(time_idx)+energy_harvest(time_idx);  % è l'energia disponibile per l'istante t(quella di C e l'energia che raccolgo nell'unità di tempo)
    
    %%% A questo punto verifichiamo se sono disponibili nuovi task per
    %%% l'accodamento (accodo solo i task con tempo di arrivo pari a time_idx)
    while( (task_idx <= task_num ) && (tasks_arrival_time(task_idx) <= time_idx)) % ciclo fra tutti i task presenti nel vettore ai e considero quelli il cui arrival time coincide con l'istante attuale
        %disp(['Task Queueing'] )
        
        % viene riscontrato l'assegnamento di un nuovo task
        task_abs_dline = tasks_arrival_time(task_idx)+ tasks_relative_deadline(task_idx);
        
        % computo dell'energia disponibile al raggiungimento della deadline
        % del task
        avail_en = collected_en;
        for ii = (time_idx+1):1:task_abs_dline % ciclo dall'istante corrente fino alla deadline del task preso in esame
            avail_en = avail_en+energy_harvest(ii);
        end
        
        %%% Verifica della schedulabilità del task
        %%% tale verifica distingue EA-LSA da LSA: in LSA
        %%% il check sull'energia disponibile non va eseguito.
        task_scheduling_allowed = 1;
        if((avail_en < tasks_energy_demand(task_idx)) && (USE_EA_LSA == 1))
            % il task non è schedulabile
            task_scheduling_allowed = 0;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % CHECKME: Di seguito il contatore per  i task rimossi
            % dall'EA-LSA e la variabile per monitorare il tempo della
            % prima deadline violation.
            % I tasks che non rispettano la deadline vengono
            % infatti tutti rimossi in anticipo!
            EALSA_removed_tasks_nr = EALSA_removed_tasks_nr + 1;
            if (time_idx < EALSA_first_deadline_violation_time)
                EALSA_first_deadline_violation_time = time_idx;
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end
        %%% Il check si conclude qui.
        
        if( task_scheduling_allowed == 1)
            
            % il task va inserito in una coda ordinata
            % secondo l'ordine crescente delle deadline assolute
            % All'inserimento si introducono tutti i parametri di interesse relativi al
            % task
            task_queue.insert_task(task(...
                tasks_arrival_time(task_idx), ...       % inserisco un nuovo oggetto task nella coda dei task
                tasks_relative_deadline(task_idx), ...
                tasks_energy_demand(task_idx), ...
                avail_en/single_step_en ...             % CPU time == tempo di processamento del task che si sta inserendo in coda
                ));
        end
        
        task_idx = task_idx+1; %% incrementiamo il task index per passare al task successivo.
    end %while(..tasks_arrival_time(task_idx) == time_idx)
    %%% Tutti i task arrivati all'istante time_idx sono stati processati.
    
    %%%-----------------------------------------INIZIO SCHEDULING------------------------------
    
    %disp(['Task Scheduling'] )
    %%% A questo punto inizia lo scheduling vero e proprio.
    %%% Scartiamo tutti gli slot vuoti (just in case)
    while((task_queue.abs_dline == 0) && (task_queue.Next ~=task_queue))   % se il task in esame ha la deadline nulla ed il prossimo task è diverso da quello attuale,
        task_queue = task_queue.step_fw();                                  % ossia se la coda dei task non è composta da solo un task, avanza al task successivo.
    end                                                                    % in altre parole si scarta il task che ha deadline nulla perchè è un dummy!
    
    %disp(['Task parsing'] )
    if(task_queue.abs_dline > 0)
        % ho rimosso già i task vuoti in eccesso. Se il primo task ha
        % deadline nulla significa che non ho task accodati.
        
        %%% Si fa riferimento al primo task della coda
        %%% (quello con deadline più piccola).
        
        if((USE_EA_LSA == 1) && (time_idx <= task_queue.abs_dline))
            %disp(['Task Early check'] )
            % Se uso EALSA calcolo l'energia disponibile per vedere se è sufficiente a completare il task.
            % Se non ho energia so che avrò una violazione della deadline e
            % posso rimuovere il task immediatamente.
            
            % computo dell'energia disponibile al raggiungimento della deadline
            % del task
            avail_en = collected_en;
            for ii = (time_idx+1):1:task_queue.abs_dline % ciclo dall'istante corrente fino alla deadline del task preso in esame
                avail_en = avail_en+energy_harvest(ii);
            end
            if ( task_queue.resid_en > avail_en)
                %l'energia disponibile da qui alla deadline non basta.
                % Posso scartare il task immediatamente.
                EALSA_removed_tasks_nr =  EALSA_removed_tasks_nr + 1;
                if ( time_idx < EALSA_first_deadline_violation_time )
                    EALSA_first_deadline_violation_time = time_idx;
                end
                task_queue = task_queue.step_fw();
                
            else
                break;
            end
            
        end
        
        if (task_queue.start > task_queue.abs_dline)    % altro controllo di sicurezza. Se il tempo di start è maggiore della deadline assoluta, si tratta di un dummy task
            task_queue = task_queue.step_fw();          %% rimuoviamo il task
            
        elseif (time_idx > task_queue.abs_dline)
            % Se il tempo corrente è maggiore della deadline assoluta, ho una violazione della deadline
            
            task_queue = task_queue.step_fw();
            
            if(USE_EA_LSA == 0)
                LSA_violated_deadline_nr =  LSA_violated_deadline_nr + 1;
                if ( time_idx < LSA_first_deadline_violation_time )
                    LSA_first_deadline_violation_time = time_idx;
                end
            else
                EALSA_removed_tasks_nr =  EALSA_removed_tasks_nr + 1;
                if ( time_idx < EALSA_first_deadline_violation_time )
                    EALSA_first_deadline_violation_time = time_idx;
                end
            end
            
        elseif ((time_idx >= task_queue.start) && (collected_en >= (single_step_en+capacitor_min_lvl)))
            % se ho superato lo start time e l'energia è disponibile
            % mi permette di eseguire uno step del task e mantenere il dispositivo ON
            % lo start time è stato superato, si avvia l'esecuzione.
            
            % si riduce il valore dell'energia residua del task e si aggiorna quella dello storage.
            if( task_queue.resid_en > single_step_en)   % posso dedicarmi all'esecuzione del task
                collected_en = collected_en - single_step_en;        % riduco il valore dell'energia accumulata in C allo step successivo
                task_queue.update_energy( task_queue.resid_en - single_step_en);    % aggiorno l'energia residua del task
            elseif ( task_queue.resid_en == single_step_en)
                collected_en = collected_en - single_step_en;    % aggiorno l'energia accumulata in C allo step successivo
                task_queue = task_queue.step_fw(); %% rimuoviamo il task perchè l'ho completato
            else  % ho più energia disponibile (in uno step) di quella che mi serve per completare il task
                collected_en = collected_en - (single_step_en-task_queue.resid_en);  % aggiorno l'energia accumulata in C allo step successivo
                task_queue = task_queue.step_fw(); %% rimuoviamo il task perchè l'ho completato
            end
            
        elseif(collected_en > capacitor_max_lvl)
            %lo start time non è stato superato, ma la batteria è piena.
            % si avvia l'esecuzione, si riduce il valore dell'energia residua della quantità pari al surplus
            % e si posticipa lo start time della quantità
            en_surplus = collected_en - capacitor_max_lvl;
            collected_en = capacitor_max_lvl;
            if ( en_surplus > single_step_en)
                disp (['WARNING: Energy surplus exceeded single step energy at time_idx ' num2str(time_idx)])
            end
            
            while((en_surplus > 0) && (task_queue.Next ~= task_queue))
                %l'esecuzione del task viene condotta in un loop, perchè
                %qualora il task venga completato senza esaurire il surplus occorre passare
                %all'esecuzione del task successivo
                %disp(['Task Early start'] )
                
                if( task_queue.resid_en > en_surplus)
                    %l'energia richiesta dal task eccede il surplus: esaurisco il
                    %surplus ma non termino il task.
                    task_queue.update_energy( task_queue.resid_en - en_surplus);
                    task_queue.update_start ( task_queue.start + en_surplus/single_step_en);
                    en_surplus = 0;
                    else    %% task completato con questo step
                    %l'energia richiesta dal task è minore del surplus: esaurisco il
                    % il task ma non il surplus.
                    en_surplus = en_surplus - task_queue.resid_en;  % aggiorno lo stato del surplus energetico
                    task_queue = task_queue.step_fw(); %% rimuoviamo il task quello attuale l'ho completato (passo al successivo)
                end
            end
        end
    end % if(task_queue.abs_dline > 0)
    % Si aggiorna il livello di energia nello storage.
    
    %     if ( collected_en > capacitor_max_lvl)
    %         disp (['NOTICE: collected energy exceeded the cap limits at time_idx ' num2str(time_idx)])
    %     end
    capacitor_level(time_idx+1) = min(collected_en, capacitor_max_lvl); % mi assicuro che capacitor level non ecceda il valore max
    
end % for time_idx = 1: max_time_steps

if ( USE_EA_LSA == 1 )
    first_deadline_violation_time = EALSA_first_deadline_violation_time;
    violated_deadline_nr = EALSA_removed_tasks_nr;
else
    first_deadline_violation_time = LSA_first_deadline_violation_time;
    violated_deadline_nr = LSA_violated_deadline_nr;
end

% figure()
% plot(capacitor_level)
end
