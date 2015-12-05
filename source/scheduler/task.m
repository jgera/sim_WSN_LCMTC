classdef task < handle
    %TASK Summary of this class goes here
    %   Detailed explanation goes here
    
    properties ( SetAccess = protected )
        arrival_time = 0;
        rel_dline    = 0;
        abs_dline    = 0;
        total_en     = 0;
        resid_en     = 0;
        start_star   = 0;
        start        = 0;
    end
    properties ( SetAccess = protected )
        Prev = [];
        Next = [];
    end
 % ho inserito un flag per segnalare che la deadline del task è già stata
 % violata e per evitare di contarla più volte.
    properties ( SetAccess = public )
        deadline_violation_flag = 0;
    end
    
    % METODI DI MANIPOLAZIONE DELLA CODA DEI TASK
    
    methods
        % costruttore della classe task . Instanzia un task, dati alcuni
        % parametri in ingresso.
        
        % Se non vi sono parametri in ingresso dati,
        % imposta a 0 le varie proprietà dell'oggetto.
        function lhs = task(arrival_time, rel_dline, total_en, cpu_time )
            if (~nargin)
                lhs.arrival_time = 0;
                lhs.rel_dline    = 0;
                lhs.abs_dline    = 0;
                lhs.total_en     = 0;
                lhs.resid_en     = 0;
                lhs.start_star   = 0;
                lhs.start        = 0;
                lhs.Prev     = lhs;
                lhs.Next     = lhs;
            elseif ((nargin == 1)&& isa(arrival_time,'task'))  % se c'è solo un argomento e questo è l'oggetto di classe task...
                rhs = arrival_time;
                namelist = properties(rhs);
                for i = 1:length(namelist)
                    lhs.(namelist{i})= rhs.(namelist{i});   % copia le proprietà dell'oggetto rhs nell'oggetto lhs
                end
            else       % altrimenti, se gli argomenti in ingresso sono > 1, inizializza le proprietà dell'oggetto
                lhs.arrival_time = arrival_time;
                lhs.rel_dline    = rel_dline;
                lhs.abs_dline    = arrival_time+rel_dline;
                lhs.total_en     = total_en;
                lhs.resid_en     = total_en;
                lhs.start_star   = lhs.abs_dline - cpu_time;
                lhs.start        = lhs.start_star;  % inizialmente è uguale a start_star, se la C è piena, calcolo a runtime start_first
                lhs.Prev     = lhs;
                lhs.Next     = lhs;
            end
        end
    end
    
    % METODI DI MANIPOLAZIONE DEI PARAMETRI RELATIVI AI TASK
    
    methods
        function update_energy(rhs, value)
            rhs.resid_en = value;
        end
        function update_start(rhs, value)
            rhs.start = value;
        end
        function insert_task(rhs, task )
            rhs.insert_fw(task, rhs);
        end
        function lhs = step_fw(rhs)
            if( rhs ~= rhs.Next)
                rhs = rhs.Next;
                rhs.Prev.rimuovi_task();
                lhs = rhs;
            else
                %rhs.rimuovi_task();
                rhs.delete();
                lhs = task();
            end
            
        end
    end
    
    % METODI DI SERVIZIO: ESEGUONO L'INSERIMENTO E LA RIMOZIONE DEI TASK
    % NON SERVE CHE SIANO DIRETTAMENTE ACCESSIBILI.
    
    methods (Access = protected)
        function insert_fw( rhs, new_task, root )
            if ((nargin == 2) && ( rhs.Next.abs_dline < new_task.abs_dline ) && (rhs.Next~=rhs))
                rhs.Next.insert_fw( new_task, rhs );
            elseif ((nargin == 3) && ( rhs.Next.abs_dline < new_task.abs_dline ) && (rhs.Next~=root))
                rhs.Next.insert_fw( new_task, root );
            else
                rhs.accoda_task( new_task );
            end
        end
        function accoda_task(rhs, new_task )
            
            %NOTA: SE INSERISCO TUTTI I NUOVI TASK DAL PRIMO ELEMENTO DELLA CODA, LA CODA OTTENUTA RISULTERÀ RIBALTATA.
            
            % apro la catena sulla direzione next, inserisco un nuovo task tra il task attuale ( rhs ) e quello successivo (rhs.next)
            % rhs.Next punta al nuovo task. il nuovo task ( rhs.Next.Next ) punta al task successivo.
            tempNext = rhs.Next;
            rhs.Next = task( new_task );
            rhs.Next.Next = tempNext;
            clear tempNext ;
            % a questo punto posso aggiustare i collegamenti anche lungo la direzione previous.
            rhs.Next.Prev = rhs;
            rhs.Next.Next.Prev = rhs.Next;
        end
        function rimuovi_task(rhs)
            if ( rhs.Next ~= rhs )
                rhs.disconnetti_task();
                rhs.delete();
            end
        end
        function disconnetti_task(rhs)
            if (~isscalar(rhs))
                error('i task sono rappresentati da cifre')
            end
            precedente = rhs.Prev;
            successivo = rhs.Next;
            
            if ~isempty(precedente)
                precedente.Next = successivo;
            end
            if ~isempty(successivo)
                successivo.Prev = precedente;
            end
            
            rhs.Prev = rhs;
            rhs.Next = rhs;
        end
    end
end