classdef LCMTC_node < node
    %LC-MTC_node class: this class is used to build a LC-MTC_node, the
    %concentrator
    
    properties                   
        %LTE power consumption management
        Idle_PagingCycle_time;          %[s]    typical in the range [0.64 - 10.24]s
        Idle_Sleep_time;                %[s]    it is equal to PagingCycle_time-IDLE_ACTEVEAWAKEPO_TIME
        Connected_RRC_Inactivity_time;  %[s]
        Connected_TXRX_datarate;        %[Mbps] data rate selected to transmit data over LTE connection
        IAT_mean;                       %[s]    the mean of the Inter Arrival Time used to build the exponential distribuition to model IAT of LTE packets
        Data_qty;                       %[Mb]   the amount of data to transmit over LTE network
        
        %WSN parameters
        WSN_RXSequence;                 % the sequence representing the WSN rx events. It's an input from whole WSN.
        
        %Energy source (harvester) and energy storage
        PV_incoming_power;              %[W]    the power harvested by energy source of LC-MTC concentrator, a PV module
        EnergyStoragelevel;             %[J] or [W*s] the value of actual energy level contained into energy storage device
    end
    
    properties(Constant)  % uppercase to remember they're constants
        %MCU power consumption @ 200 MHz
%         MCU_SLEEP_POWER=               464e-3;     %[W]    typical Power consumption of a Spansion Cortex R5 @200MHz, frequently used in LTE: 
%         MCU_NORMALOPERATIONS_POWER=    892e-3;     %[W]    http://www.spansion.com/downloads/mb9d560-ds708-00001-e.pdf  pp.65-68

        %MCU power consumption @ 160 MHz
        MCU_SLEEP_POWER =               366e-3;     %[W]    typical Power consumption of a Spansion Cortex R5 @160MHz, frequently used in LTE: 
        MCU_RUNNING_POWER=              873e-3;     %[W]    http://www.spansion.com/downloads/mb9d560-ds708-00001-e.pdf  pp.65-68
        
        %WM-BUS transceiver power consumption               % Further details in:
                                                            % Wireless M-Bus Sensor Nodes in Smart Water Grids: the Energy Issue by Stefano Squartini, 
                                                            % Leonardo Gabrielli, Matteo Mencarelli, Mirco Pizzichini, Susanna Spinsante, Francesco Piazza
        WMBUS_TX_POWER=                 165e-3;     %[W]    typical Power consumption of TI CC1120 transceiver during WM-BUS packet transmission (tx ACK)
        WMBUS_RX_POWER=                 66e-3;      %[W]    typical Power consumption of TI CC1120 transceiver during WM-BUS packet reception (rx DATA)
        WMBUS_RXSNIFFINGMODE_POWER=     4.553e-3;   %[W]    typical Power consumption of TI CC1120 transceiver during RX Sniffing Mode. Current consumption 
                                                    %       in RXSniffing Mode is typical [0.369 - 1.518] mA, @ 3V. See
                                                    %       http://www.ti.com/lit/ml/slyy042/slyy042.pdf and http://www.ti.com/lit/an/swra428a/swra428a.pdf

        %LTE power consumption management
        IDLE_SLEEP_POWER=               11.4e-3;    %[W]    
        IDLE_ACTIVEAWAKEPO_POWER=       594.3e-3;   %[W]
        IDLE_ACTEVEAWAKEPO_TIME=        43e-3;      %[s]
        
        PACKETARRIVAL_TRANSITION_POWER= 1210.7e-3;  %[W]
        PACKETARRIVAL_TRANSITION_TIME=  260.1e-3;   %[s]
        
        CONNECTED_BASE_POWER=           1280.04e-3; %[W]   
        CONNECTED_TX_POWER_SURPLUS=     438.39e-3;  %[W/Mbps]   related to effective datarate (Connected_TXRX_datarate)!
        CONNECTED_RX_POWER_SURPLUS=     51.97e-3;   %[W/Mbps]   related to effective datarate (Connected_TXRX_datarate)!
        CONNECTED_NODATATXRX_POWER=     1060e-3;    %[W]
        
        %Energy storage detail
        ENERGYSTORAGEMAXENERGY=         37296;      %[J] or [W*s]   the max value of the energy contained into device
                                                    % typically, a 18650 li-ion battery has a capacity of 2800 mAh @ 3.7V equal to 37296[W*s] of energy
    end

    methods
        %% The constructor of the LCMTC_node
        function obj = LCMTC_node(type,daily_tx,resolution,simulation_length,WSN_rxSequence,batterylevel,WSN_TXpower,...         %mandatory parameters
                IAT_mean,Data_qty,Idle_PagingCycle_time,Connected_RRC_Inactivity_time,Connected_TXRX_datarate)                  %optional parameters
            obj.sim_vector_length=86400*simulation_length/resolution;   %the length of the vectors that describe the simulation details (TXevents, Power, etc)
            obj.set_id();           % automatically set the unambiguous id of the node (implemented in "node" superclass)
            obj.type=type;
            obj.daily_tx=daily_tx;
            obj.resolution=resolution;
            obj.simulation_length=simulation_length;
            %obj.tx_sequence = computeTXSequence(obj);
            if numel(WSN_rxSequence)==obj.sim_vector_length
                obj.WSN_RXSequence=WSN_rxSequence;
            else
                error('ATTENTION! The length of "WSN_RXSequence" input parameter does not match with LCMCT_node simulation parameters (simulation length and resolution).');
            end
            obj.EnergyStoragelevel=obj.ENERGYSTORAGEMAXENERGY * batterylevel;  % the initial battery level of the concentrator (battery level is in percentage [0-1])
            obj.WSN_TXpower=WSN_TXpower;
               
            % default parameters value: if the input parameter is not
            % specified, the default value will be adopted
            obj.IAT_mean=3600;                      % [s]       Inter Arrival Time
            obj.Data_qty=(1)*8e-3;                  % [Mb]      Set to 1kB. Typical values are 1 byte to 10kB(1 Kilobyte = 0.008 Megabits)
            obj.Idle_PagingCycle_time=10.24;        % [s]       typical in the range [0.64 - 10.24]s               
            obj.Connected_RRC_Inactivity_time=60;   % [s]       typical in the range [15 - 60]s        
            obj.Connected_TXRX_datarate=0.5;        % [Mb/s]    minimum 59.2 kbps = 0.0592 Mbps
            
            % if input parameters are present, overwrite default values
            mandatory_parameters=7;
            if nargin > mandatory_parameters
                obj.IAT_mean=IAT_mean;
            end
            if nargin > (mandatory_parameters + 1)
                obj.Data_qty=Data_qty;
            end
            if nargin > (mandatory_parameters + 2)
                obj.Idle_PagingCycle_time=Idle_PagingCycle_time;
            end
            if nargin > (mandatory_parameters + 3) 
                obj.Connected_RRC_Inactivity_time=Connected_RRC_Inactivity_time;
            end
            if nargin > (mandatory_parameters + 4)
                obj.Connected_TXRX_datarate=Connected_TXRX_datarate;
            end
            
            % compute idle_sleep_time
            obj.Idle_Sleep_time=obj.Idle_PagingCycle_time-obj.IDLE_ACTEVEAWAKEPO_TIME;  %[s]    it is equal to PagingCycle_time-IDLE_ACTEVEAWAKEPO_TIME
            
            %compute the harvested power by PV module (10% of efficiency and a surface of 0.04 m^2) from the day 07/07/2005
            % include the path containing the files computeIncompigPower.m
            % and extractSIR.m
            SIR_data_relativePathName='LCMTC\EnergySource\SolarRadiationData_SODA-IS\2005_Ancona_15min_obs\request_hc3v5lat43.630_lon13.500_2005-01-01_2005-12-31_990776387.csv';
            startMonth = 7;         %the number of the month of interest.
            startDay = 7;           %the number of the day of interest. 
            PV_efficiency = 0.1;    %the efficiency of the PV module
            PV_surface = 0.02;      %the surface of the PV module, in square meters. E.g. a PV module of 10cm * 20 cm
            obj.PV_incoming_power = computePVIncomingPower( SIR_data_relativePathName, startMonth, startDay,... % compute PV incomping power (see external files)
                obj.simulation_length, obj.sim_vector_length, PV_efficiency, PV_surface );
        end
        
        %% compute the three vectors of a schedulable LTE trasnsmission taskset a_i, d_i, e_i
        % that is: phases, deadlines and energies
        function [LTE_TX_phase, LTE_TX_deadline, LTE_TX_energy] = computeSchedulableTaskset(obj)
            
            LTE_TXSequence = computeTXSequence(obj);
            LTEoptionalTX = nnz(LTE_TXSequence);        % the number of optional LTE transmissions. It depends from IAT mean and simulation length
            
            % allocate memory space for the vectors (speed-up computation)
            LTE_TX_phase = zeros(1,LTEoptionalTX);
            LTE_TX_relative_deadline = zeros(1,LTEoptionalTX);
            LTE_TX_deadline = zeros(1,LTEoptionalTX);
            LTE_TX_energy = zeros(1,LTEoptionalTX);
            
            %----------- build phase vector from LTE TXSequence -----------
            j=0;
            for i=1:obj.sim_vector_length
                if LTE_TXSequence(i)==1;
                    j=j+1;
                    LTE_TX_phase(j)=i;
                end
            end
            
            %----------- build deadline vector related to bitrate and data quantity -----------
            LTE_TX_time = (obj.PACKETARRIVAL_TRANSITION_TIME +...           % the time occurred to TX an LTE packet
                        (obj.Data_qty / obj.Connected_TXRX_datarate)+...    % composed by the sum of transition time, TX time and inactivity time 
                        obj.Connected_RRC_Inactivity_time) / ...
                        obj.resolution;     
%             display(LTE_TX_time);
                    
            LTE_TX_time_mu = LTE_TX_time * 500;                             % the mean deadline to execute an LTE transmission is 500 times the minimum time    
                                                                            % needful to execute an LTE transmission

            LTE_TX_time_sigma = LTE_TX_time * 200;                          % the variance of the normal distribuition of the LTE TX time
            
            rng(obj.id);                                                    % make normal random sequence repetible (related to obj.id)
            for i=1:LTEoptionalTX
                LTE_TX_relative_deadline(i) = round(max(normrnd(LTE_TX_time_mu,LTE_TX_time_sigma),LTE_TX_time_mu));% extract a value from normal distribuition
            end
            LTE_TX_deadline = LTE_TX_phase + LTE_TX_relative_deadline;      % build absolute deadline from relative deadline

            %----------- build energy vector related to bitrate and data quantity -----------
            LTE_TX_energy_mu = ...                                          % the mean energy occurred to TX an LTE packet
                computeLTETXRXEventEnergy(obj,'TX') - (computeLTEIdleMeanPower(obj) * LTE_TX_time); % during LTE TX, the device is not in IDLE thus the idle power consuption
                                                                                                    % has been removed. At meantime, LTE TX power consumtption is added.
            LTE_TX_energy_sigma = LTE_TX_energy_mu * 0.02;                  % the variance of the normal distribuition of the LTE TX energy
            
            rng(obj.id+1);                                                  % make normal random sequence repetible (related to obj.id)
            for i=1:LTEoptionalTX
                LTE_TX_energy(i)= round(normrnd(LTE_TX_energy_mu,LTE_TX_energy_sigma)); % extract a value from normal distribuition
            end
            
            %--------------------------------------------------------------------------------
            while LTE_TX_deadline(end) > obj.sim_vector_length;             % if last LTE TX event deadline is out of bound, delete last event                     
                LTE_TX_deadline = LTE_TX_deadline(1,1:(end-1));             % from deadline, phase and energy vectors 
                LTE_TX_phase = LTE_TX_phase(1,1:(end-1));
                LTE_TX_energy = LTE_TX_energy(1,1:(end-1));
            end     
        end
        
        %% the method used to build the transmitting sequence towards LTE network
        %it build an exponential distributed sequence in the time-range of 
        %the simulation and return the vector. Elements set to one 
        %represets transmission events. Zero-elements represents no transmission.
        function LTE_TXSequence = computeTXSequence(obj)
            LTE_TXSequence = zeros(1,obj.sim_vector_length);    % allocate vector
            rng(obj.id);                                        % make exponential random sequence repetible (related to obj.id)
            LTE_TXEvent_index=0;
            while LTE_TXEvent_index <= obj.sim_vector_length    %build the exponential random sequence
                LTE_TXEvent_index = LTE_TXEvent_index + exprnd(obj.IAT_mean/obj.resolution);
                if LTE_TXEvent_index <= obj.sim_vector_length
                    LTE_TXSequence(round(LTE_TXEvent_index))=1; % ones means LTE-transmission; zeros means no-LTE-transmission
                end
            end
        end
               
        %% compute the sequence of the power drained by the node according to the whole fixed power consumption 
        function computePowerSequence(obj)
            
            LTEIdleMeanPower = computeLTEIdleMeanPower(obj);
            
            obj.power_sequence=(LTEIdleMeanPower + obj.MCU_SLEEP_POWER).*ones(1,obj.sim_vector_length);  % power consumption of MCU in sleep mode and LTE in idle mode
            obj.power_sequence=obj.power_sequence+computeWSNPowerSequence(obj); %add WSN power sequence to the total power sequence (include MCU running power absorption)
            
            % compute the LTE TX event length and mean power
            LTEdailyTXsequence=zeros(1,obj.sim_vector_length);
                % compute the LTE TX event length
            LTE_TXevent_length=obj.PACKETARRIVAL_TRANSITION_TIME+...
                (obj.Data_qty/obj.Connected_TXRX_datarate)+...
                obj.Connected_RRC_Inactivity_time;                                  %the length of a TX event over LTE network, in seconds
            LTE_TXevent_length=max(1,round(LTE_TXevent_length/obj.resolution));     %the length of a TX event over LTE network, in timesteps (min=1 timestep)
                % compute the mean power
            LTETXRXMeanPower=obj.computeLTETXRXEventEnergy('TX')/(LTE_TXevent_length*obj.resolution);   % the LTE TX event mean power in a period 
                                                                                                        % length of (LTE_TXevent_length*obj.resolution)
            
            %insert the LTE TX event at the end of each day
            LTETXRXInterval=obj.sim_vector_length/(obj.simulation_length*obj.daily_tx);    % it's the gap, in timesteps, among two LTE transmission
            for actual_day=1:(obj.simulation_length*obj.daily_tx)                          % cycle for each simulation day
                for i=1:LTE_TXevent_length                                      % append the LTE TX sequence at the end of each day; it has a length of "LTE_TXevent_length"
                LTEdailyTXsequence((actual_day*LTETXRXInterval)-i)=LTETXRXMeanPower-LTEIdleMeanPower;   % during LTE TX the device is not in IDLE thus the idle power consuption
                end                                                                                     % has been removed and LTE TX power consumtption are added.
            end
            
            obj.power_sequence=obj.power_sequence+LTEdailyTXsequence;       %add LTE TX power sequence to the total LC-MTC power sequence. 
                                                                            %This is the fixed power consumption of the device                                                                
        end
            
        %% compute the power sequence due to transceiver and MCU elaboration related to WSN packets
        % This profile is composed by:
        % - A constant power consumption due to transceiver and MCU (sleeping) 
        %   activity during listening for WM-BUS packets.
        % - A burst of consumption due to RX of a packet and TX of related
        %   ACK plus the power consumption of the MCU in running mode. 
        %   To compute this, is mandatory the knowledge of the TX
        %   sequences of all WSN nodes.
        function WSNPowerSequence = computeWSNPowerSequence(obj)
            
            MCU_RunningPowerSurplus = obj.MCU_RUNNING_POWER - obj.MCU_SLEEP_POWER;  % the power surplus during MCU running, 
                                                                                    % regards to MCU power consumption in sleep mode  
            
            % Comment/uncomment one of the following two lines to select 
            % the desired listening power
            WMBUS_listening_power=obj.WMBUS_RXSNIFFINGMODE_POWER;           % constant power consumption using RX Sniffing Mode
%             WMBUS_listening_power=obj.WMBUS_RX                            % constant power consumption using standard listening mode (RX)

            %fixed power consumption due to transceiver activity 
            WSNPowerSequence = WMBUS_listening_power*ones(1,obj.sim_vector_length);   % constant power consumption in listening mode

            %burst of consumption due to RX of a packet and TX of related ACK
            T_rx = 20e-3;       % Typical rx time is <20ms for WM-BUS packets, using N2g mode @ 38.4 kbps. See WSN_node T_tx variable before to set this variable
            T_tx_ack= 1e-3;     % Assimung 40 bit of ack over WM-BUS, N2g mode @ 38.4 kbps
            WSN_RXevent_Energy= (obj.WMBUS_RX_POWER * T_rx) + (obj.WMBUS_TX_POWER * T_tx_ack);  %energy of WM-BUS packet RX event drained by transceiver (related to one sole packet)
            MCU_RunningEnergySurplus = MCU_RunningPowerSurplus * (T_rx + T_tx_ack);     %energy of WM-BUS packet RX event drained by MCU (only surplus and related to one sole packet)
            % the power sequence composed by the fixed power consumption of
            % the transceiver during listening and by the burst power
            % consumption during RX and TX of ACK.
            % Also the power consumption of the MCU in running mode, during
            % WSN packets receiving, are taked into account.
            for i=1:obj.sim_vector_length
                if obj.WSN_RXSequence(i)
                    WSN_RXevent_meanPower=(((WSN_RXevent_Energy+MCU_RunningEnergySurplus)*obj.WSN_RXSequence(i))+...%the energy spent to receive one or more packets (WMBUS transceiver + MCU running surplus)
                        (WMBUS_listening_power* (obj.resolution-(obj.WSN_RXSequence(i)*(T_rx+T_tx_ack))))) /...      % the energy spent during listening mode
                                    obj.resolution;                 % mean power of WM-BUS packet RX event over a resolution period (related to one or more packets)
                    WSNPowerSequence(i)= WSN_RXevent_meanPower;     % if in a period are received more than one packet              
                end
            end
            
%             figure('Name','WSNPowerSequence','NumberTitle','off');
%             stairs(WSNPowerSequence.*1e+3);
%             xlabel(strcat('time [',num2str(obj.resolution,'%d'),' s]'));
%             ylabel('power [mW]');
%             title('Power drained during WM-BUS messages RX (data RX + TX of ACK + MCU-RUN surplus)');
        end     
        
          %%  compute the residual energy into energy storage device. This method override the supercalss method
        function computeEnergySequence(obj)
            if isempty(obj.power_sequence)
                warning('before to compute energy sequence, please compute power sequence!')
            else
                %compute NET POWER that is the difference between 
                %incoming power and drained power
                net_power= obj.PV_incoming_power - obj.power_sequence;
                figure('Name','LC-MTC powers & energy','NumberTitle','off');
                subplot(2,1,1);
                hold on
                stairs(obj.PV_incoming_power,'g');
                stairs(obj.power_sequence,'c');
                stairs(net_power,'r');
                xlabel('timestep');
                ylabel('power [W]');
                legend('incoming power [W]','power drained [W]','net power [W]')
                hold off
                subplot(2,1,2);
                
                %compute EnergySequence
                local_energy_sequence=zeros(1,obj.sim_vector_length);
                local_energy_sequence(1)=(net_power(1)*obj.resolution)+obj.EnergyStoragelevel;  % E(1) it's not a part of the for-cycle because it doesn't depends from E(0)!
                                                                                                % Added initial storaged energy
                for i=2:(obj.sim_vector_length)
                    local_energy_sequence(i)=max(0,min(obj.ENERGYSTORAGEMAXENERGY,...
                                                 local_energy_sequence(i-1)+net_power(i)*obj.resolution));  %E(n)=E(n-1)+P(n)*delta_n  (valid for i>1)
                end
%                 TotalNodeEnergy=local_energy_sequence(obj.sim_vector_length)          %the energy level at the end of the simulation
                obj.energy_sequence=local_energy_sequence;                              %the energy sequence accumulated into energy storage device
                
                hold on
                stairs(obj.energy_sequence, 'b');
                xlabel('timestep');
                ylabel('Energy [J] or [W s]');
                plot(obj.ENERGYSTORAGEMAXENERGY.*ones(1,obj.sim_vector_length),'r');
                legend('actual energy [J]','max storage energy [J]')
                hold off
            end
        end
    end

    methods(Access=private)
        %% compute the mean power during LTE idle phase, in Watt
        % Since minimum resolution is 1 s, it has no sense to 
        % represent details such as Paging Cycle, Idle active/awake PO and
        % idle sleep status. Thus the mean power consumption take into
        % account all power and time details but represent the whole 
        % idle state with the mean power consumption of its sub-states.
        function LTEIdleMeanPower = computeLTEIdleMeanPower(obj)
            LTEIdleMeanPower = ...
                ( obj.Idle_Sleep_time*obj.IDLE_SLEEP_POWER + ...                % energy drained during idle-sleep phase
                obj.IDLE_ACTEVEAWAKEPO_TIME*obj.IDLE_ACTIVEAWAKEPO_POWER ) /... % energy drained during idle-active/awake PO phase
                obj.Idle_PagingCycle_time;                                      % time of a paging cycle (Sleep time + ActiveAwakePO time)
        end
        %% compute the energy drained during LTE connected phase (TX or RX), in Watt
        % action is a string describing the event: 'TX' or 'RX' of a LTE packet
        % the connected event is understood as packet arrival transition
        % event + connected state (data TX, data RX or no-data TX/RX) + 
        % transition for no-data activity
        function LTETXRXEventEnergy = computeLTETXRXEventEnergy(obj,action)
            
            MCU_RunningPowerSurplus = obj.MCU_RUNNING_POWER - obj.MCU_SLEEP_POWER;  % the power surplus during MCU running, 
                                                                                    % regards to MCU power consumption in sleep mode  
            if nargin<2            % default value = 'TX'
                action='TX';
            end
            if strcmp(action,'TX')  % action = 'TX'
                LTETXRXEventEnergy = ...
                (obj.PACKETARRIVAL_TRANSITION_POWER*obj.PACKETARRIVAL_TRANSITION_TIME) + ...    % energy drained during transition due to packet arrival (UL or DL)
                (obj.CONNECTED_BASE_POWER+(obj.CONNECTED_TX_POWER_SURPLUS*obj.Connected_TXRX_datarate)) * ...
                    (obj.Data_qty / obj.Connected_TXRX_datarate) + ...                          % energy drained during LTE packet transmission
                (obj.CONNECTED_NODATATXRX_POWER * obj.Connected_RRC_Inactivity_time);           % energy drained during transition for no-data activity     
            elseif strcmp(action,'RX')  % action = 'RX'
                LTETXRXEventEnergy = ...
                (obj.PACKETARRIVAL_TRANSITION_POWER*obj.PACKETARRIVAL_TRANSITION_TIME) + ...    % energy drained during transition due to packet arrival (UL or DL)    
                (obj.CONNECTED_BASE_POWER+(obj.CONNECTED_RX_POWER_SURPLUS*obj.Connected_TXRX_datarate)) * ...
                    (obj.Data_qty / obj.Connected_TXRX_datarate) + ...                          % energy drained during LTE packet transmission             
                (obj.CONNECTED_NODATATXRX_POWER * obj.Connected_RRC_Inactivity_time);           % energy drained during transition for no-data activity                
            else 
                error('please, specify correct action: RX or TX');                
            end
                % add energy drained by MCU in running mode (only surplus energy) to LTEConnectedEnergy
                LTETXRXEventEnergy = LTETXRXEventEnergy +...        
                    (MCU_RunningPowerSurplus *...
                    (obj.PACKETARRIVAL_TRANSITION_TIME +...             % MCU is running durning "packet arrival transition time"
                    (obj.Data_qty / obj.Connected_TXRX_datarate)...     % MCU is running durning "Connected TX/RX" time.
                     ));                                                % MCU is not running durning RRC Inactivity Time  
                 
%                 LTETXRXEventEnergy = LTETXRXEventEnergy +...            % uncomment these two lines if MCU IS RUNNING also durning RRC Inactivity Time  
%                     (MCU_RunningPowerSurplus * obj.Connected_RRC_Inactivity_time);
        end
    end
   
end
