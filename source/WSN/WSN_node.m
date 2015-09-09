classdef WSN_node < node
    %WSN_node class: this class is used to build WSN_nodes of WSN WM-BUS    
    %network.
        
    properties
        %% Properties related to the Free Space Loss attenuation formula & retransmission of not-received packets
        WSN_frequency=169e6;    % the working WSN frequency
        distance;               % the distance between the node and the concentrator; it's useful to compute the attenuation introduced by the channel.
        n=2.97;                 % the path loss factor: typically it's in the range [1.5-5] (see ROUTING PROTOCOLS FOR LOSSY WIRELESS NETWORKS here:
                                % https://www.vutbr.cz/www_base/zav_prace_soubor_verejne.php?file_id=59199, paragraph 3.3.3)
        mu=0;                   % the mean of the random variable X, used in PathLoss formula
        sigma=3;                % the std deviation of the random variable X used in PathLoss formula
        detection_threshold=-110% [dBm] the minimum received power that results in a successful packet reception.
        att_retx_sequence       % the sequence of retransmitted packets due to attenuation
        retx_delay=5            % [s] the time elapsed from transmission and the retransmission of the not-received packet
        att_norx_sequence       % the sequence of packets not received by LC-MTC due to attenuation

    end
    
    methods
        %% The constructor of the WSN_node
        function obj = WSN_node(type,daily_tx,resolution,simulation_length,distance,WSN_TXpower)
            obj.sim_vector_length=86400*simulation_length/resolution;   %the length of the vectors that describe the simulation details (TXevents, Power, etc) 
            obj.set_id();           % automatically set the unambiguous id of the node                                        
            obj.type=type;
            obj.daily_tx=daily_tx;  
            obj.resolution=resolution;
            obj.simulation_length=simulation_length;
            obj.tx_sequence = computeTXSequence(obj);

            obj.distance = distance;
            obj.WSN_TXpower = WSN_TXpower;
            obj.retx_delay=obj.retx_delay/obj.resolution;   %fix the retx_delay according to resolution
        end
        
        %% the method used to build the transmitting sequence
        %it build a uniformly distributed pseudorandom sequence in the range
        %of the simulation and return the vector. Elements set to ones 
        %represets transmission events. Zeros elements represents no transmission.
        function tx_sequence = computeTXSequence(obj)
            rng(obj.id);    %the "id" that clearly identify a node it's also the seed of RNG algorithm: now "rand()" can create a repeatable sequence
            tx_sequence = zeros(1,obj.sim_vector_length);
            obj.att_retx_sequence = tx_sequence;
            obj.att_norx_sequence = tx_sequence;
            for i = 1:round(obj.daily_tx*obj.simulation_length)
                tx_sequence(randi(obj.sim_vector_length)) = 1;
            end
            % take into account for not-received packets due to
            % high attenuation: transmit again new packets
            for i = 1 : length(tx_sequence)
                if (obj.WSN_packetTX_result()==0)                       % if a packet is not received for high attenuation of the channel...
                    obj.att_norx_sequence(i) = 1;                    % save the time of the packet into a sequence
                    rnd_time = randi(obj.sim_vector_length);
                    tx_sequence(rnd_time) = 1;                      % add a new packet to TX sequence: retransmit the packet
                    obj.att_retx_sequence(rnd_time) = 1;            % also add a the packet into the list of retransmitted packets due to attenuation
                end
            end
        end
        %% compute the sequence of the power drained by the node according to the power consumption 
        function computePowerSequence(obj)     % compute the power sequence with a with resolution of a timestep
            
        %Definition of all power consumption of the node
            P_sleep = 9e-6; %Power drained during sleep mode, in [W] ((2.7e-6 + 0.3e-6[A])*3[V]) using TI MSP430+CC1120 as shown in table 1 in:
                            %Wireless M-Bus Sensor Nodes in Smart Water Grids: the Energy Issue by Stefano Squartini, 
                            %Leonardo Gabrielli, Matteo Mencarelli, Mirco Pizzichini, Susanna Spinsante, Francesco Piazza
            switch obj.type
                case 'generic'
                    P_run = 1.1109e-3;  %Power drained during running mode, in [W] (370e-6+0.3e-6[A]*3[V]) using TI MSP430+CC1120 (MCU running & CC1120 sleeping) 
                                        %as shown in table 1 in:
                                        %Wireless M-Bus Sensor Nodes in Smart Water Grids: the Energy Issue by Stefano Squartini, 
                                        %Leonardo Gabrielli, Matteo Mencarelli, Mirco Pizzichini, Susanna Spinsante, Francesco Piazza
                    T_run = 70e-3;      %Typical running time is 70ms  see: Current Characterisation for Ultra Low Power
                                        %Wireless Body Area Networks) by Fabio Di Franco, Christos Tachtatzis, Ben Graham, Marek Bykowski
                                        %David C. Tracey, Nick F. Timmons and Jim Morrison
                    P_tx = 166.47e-3;   %Power drained, in [W], during the transmission (no ACK reception) of a WM-Bus message over the N2g 38.4 kbps mode
                                        %using TI MSP430+CC1120 (MCU running & CC1120 Tx @ 169MHz) as shown in equation (1), in:
                                        %Wireless M-Bus Sensor Nodes in Smart Water Grids: the Energy Issue by Stefano Squartini, 
                                        %Leonardo Gabrielli, Matteo Mencarelli, Mirco Pizzichini, Susanna Spinsante, Francesco Piazza   
                    T_tx = 20e-3;       %Typical tx time is 20ms
                    
                    P_rx = 67.47e-3;    %Power drained, in [W], during the  ACK reception of a WM-Bus message over the N2g 38.4 kbps mode
                                        %using TI MSP430+CC1120 (MCU running & CC1120 rx) as shown in equation (1)
                    T_rx = 90e-3;       %Typical tx time is 90ms
                    
                case 'water'
                    %define here proper P_run, T_run, P_tx, T_tx, P_rx, T_rx for this type of node
                    error('Define P_run, P_tx and P_rx, etc. in water_WSN_node, in WSN_node.m file')
                case 'gas'
                    %define here proper P_run, T_run, P_tx, T_tx, P_rx, T_rx for this type of node
                    error('Define P_run, P_tx and P_rx, etc. in gas_WSN_node, in WSN_node.m file')
                case 'electricity'
                    %define here proper P_run, T_run, P_tx, T_tx, P_rx, T_rx for this type of node
                    error('Define P_run, P_tx and P_rx, etc. in electricity_WSN_node, in WSN_node.m file')
                otherwise
                    warning('Chose a type between the following: generic, water, gas, electricity')
            end
            
            TXevent_PowerProfile = computeTXeventPowerProfile(P_run,P_tx,P_rx,T_run,T_tx,T_rx) %build the PowerProfile vector (resolution of TXevent_PowerProfile=1 ms)
            TXevent_EnergyDrained = computeTXeventEnergyDrained(TXevent_PowerProfile, obj.resolution, P_sleep)
            
            %build PowerSequence from tx_sequence and the mean power of a
            %transmission event. When no-tx events are executed, some
            %little power P_sleep is drained.
            TXEvent_meanPower=TXevent_EnergyDrained/obj.resolution;
            
            %compute the PowerSequence
            local_power_sequence=ones(1,obj.sim_vector_length).*P_sleep;
            for i=1:(obj.sim_vector_length)
                if obj.tx_sequence(i)
                    local_power_sequence(i)=TXEvent_meanPower;
                end
            end
            obj.power_sequence=local_power_sequence;

            %{
            %Plot the Power sequence
            figure('Name','Power sequence','NumberTitle','off');
            stairs(local_power_sequence*1e+3); %stairs it's a better representation than plot for "PowerSequence": the power consumption remains constant for a time-step!
            xlabel(strcat('time [',num2str(obj.resolution,'%d'),' s]'));
            ylabel('power [mW]');
            title({strcat('Power Sequence of a ',obj.type,' WSN node');strcat(num2str(obj.daily_tx),' transmission each day, ',num2str(obj.simulation_length), ' day(s) simulated')});
            %}
        end
        
        %% compute the Path loss attenuation between the concentrator and this node.
        function PathLoss = computePathLoss(obj)
            %the refernce distance is d_0 = 1 m.
            PathLoss =  10*log(4*pi*obj.WSN_frequency/3e8) +...                     %PL(d_0), the path loss @ distance d_0
                        obj.n*10*log(obj.distance/1) +...                           %n 10 log(d/d_0), the path loss related to the environment
                        lognrnd(obj.mu,obj.sigma);                                  %X_sigma, the random variable to represent shadowing locale phenomena
        end
        
        %% compute if the WSN packet is received or not (return 1=received 0=not received)
        function WSNPacketReceived = WSN_packetTX_result(obj)
            RXPower=obj.WSN_TXpower-obj.computePathLoss;
            if RXPower < obj.detection_threshold                %WSN transmission failure: the packet is lost!
                WSNPacketReceived=0;
            else
                WSNPacketReceived=1;                            %WSN transmission OK: the packet is received!
            end
        end
        
    end
end

%% compute the power profile of a transmission event
%it include elaborating period, transmitting period and receiving of an ack
%period
function TXevent_PowerProfile = computeTXeventPowerProfile(P_run,P_tx,P_rx,T_run,T_tx,T_rx)
    T_run_ms=T_run*1e+3;
    T_tx_ms=T_tx*1e+3;
    T_rx_ms=T_rx*1e3;
    %build the PowerProfile vector
    TXevent_PowerProfile=zeros(1,T_run_ms+T_tx_ms+T_rx_ms); %pre-allocate vector: speed up the simulation
    for i=1:T_run_ms                                        %running period
        TXevent_PowerProfile(i)=P_run;
    end
    for i=(T_run_ms+1):(T_run_ms+T_tx_ms)                   %transmitting period
        TXevent_PowerProfile(i)=P_tx;
    end
    for i=(T_run_ms+T_tx_ms+1):(T_run_ms+T_tx_ms+T_rx_ms)   %receiving ACK period
        TXevent_PowerProfile(i)=P_rx;
    end
    
%     figure('Name','TXevent_PowerProfile','NumberTitle','off');
%     plot(TXevent_PowerProfile.*1e+3);
%     xlabel('time [ms]');
%     ylabel('power [mW]');
%     title('Power profile of a WM-BUS transmission event (elaboration + TX + RX of ACK)');
    
end

%% compute the total energy drained during a transmitting event
%it includes elaborating period, transmitting period and receiving of an ack
%period furthermore it must include the sleeping period.
%In-fact, a typical elaborating-transmitting-receiving period is smaller
%than a timestep (typical 1 s or more). Thus, the energy drained during the
%sleeping period, that always exist, must be taken into account.
function TXevent_EnergyDrained = computeTXeventEnergyDrained(TXevent_PowerProfile, resolution, P_sleep)
    TXevent_EnergyDrained=0;
    for i=1:numel(TXevent_PowerProfile)                     %energy = the integral of the power over the time (TXevent_PowerProfile is in ms -> 
                                                            %-> TXevent_EnergyDrained result in [mJ])
        TXevent_EnergyDrained = TXevent_EnergyDrained + TXevent_PowerProfile(i);
    end                                                     %TXevent_EnergyDrained is expressed in [mJ]=[W*ms]

    if resolution > (numel(TXevent_PowerProfile)*1e-3)      %if the resolution is too big, then the details about TX profile are unnecessary. 
                                                            %Treat TXprofile as a rect. step whith an amplitude equal to the mean power of TXevent.
        TXevent_EnergyDrained = TXevent_EnergyDrained + (((resolution*1e+3)-numel(TXevent_PowerProfile))*P_sleep);%include also the sleep energy in [mJ]
    end

    TXevent_EnergyDrained = TXevent_EnergyDrained * 1e-3;   %reestablish the scale: energy expressed in [J]=[W*s].
end
