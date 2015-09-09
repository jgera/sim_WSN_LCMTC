classdef node < handle
    %node superclass: used to create WSN node objects and LC-MTC
    %concentrator objects
%% Properties of the node
    properties
        type                % the type of the node
        daily_tx            % the number of daily transmission (it's the numbers of ones into tx_sequence)
        resolution          % [s] it is the resolution, in seconds, of the simulation
        simulation_length   % the length of the simulation in days
        WSN_TXpower;        % [dBm] the TX power of the WSN transceiver
    end
    
    properties(GetAccess='public', SetAccess='protected')
        id                  % an integer that clearly identify a node. It's also the seed of RNG algorithm
        sim_vector_length   % the length of the vectors that describe the simulation details (TXevents, Power, etc)
        tx_sequence         % a sequence that describe the transmission events of the node itself (1 means tx 0 means no-tx)
        power_sequence      % a sequence that describe the power drained by the node itself
        energy_sequence     % a sequence that describe the energy drained by the node itself
    end
    
    properties(Constant)
        
    end
    
    methods(Access='protected')
        %%  set_id(obj): set the id of the node to an unambiguous value
        function set_id(obj)
            persistent used_ids; % in C language it's equal to: static used_id=0;
            if isempty(used_ids) % if is the first access to this function then initialize used_id to 0;
                used_ids=0;
            end
            used_ids=used_ids+1;  
            obj.id = used_ids;
        end  
    end
    
    methods 
        %%  compute the sequence of energy drained by a node
        function computeEnergySequence(obj)
            if isempty(obj.power_sequence)
                warning('before to compute energy sequence, please compute power sequence!')
            else
                %compute EnergySequence
                local_energy_sequence=zeros(1,obj.sim_vector_length);
                local_energy_sequence(1)=obj.power_sequence(1)*obj.resolution;  %E(1) it's not a part of the for-cycle because it doesn't depends from E(0)! [E(0) returns error!]
                for i=2:(obj.sim_vector_length)
                    local_energy_sequence(i)=local_energy_sequence(i-1)+obj.power_sequence(i)*obj.resolution;  %E(n)=E(n-1)+P(n)*delta_n  (valid for i>1)
                end
                TotalNodeEnergy=local_energy_sequence(obj.sim_vector_length)
                obj.energy_sequence=local_energy_sequence;
                %{
                %Plot Energy sequence
                figure('Name','Energy sequence','NumberTitle','off');
                plot(local_energy_sequence*1e+3);
                xlabel(strcat('time [',num2str(obj.resolution,'%d'),' s]'));
                ylabel('energy [mJ]');
                title({strcat('Energy drained by ',obj.type,' device');strcat(num2str(obj.daily_tx),' transmission each day, ',num2str(obj.simulation_length), ' day(s) simulated')});
                %}
            end
        end
    end
    
    %% Abstract methods to be implemented into subclasses
    methods(Abstract)
        computeTXSequence(obj);     % an abstract method to compute the sequence. Implement it into subclass: each node has its own statistic distribuition
        computePowerSequence(obj);  % an abstract method to compute the power sequence with a with resolution of a timestep
    end
    
end
