--Settings
	Tick = 1									--Initializes Internal Clock
	BoolIn = {}
	NumIn = {}
	BoolOut = {}
	NumOut = {}
	DetectedEle = {}		
	DetectedAzi = {}
	DetectedDist = {}
	MaxInputTargets = 8
	MaxOuputTargets = 1
	MergeTolleranceMeters = 1								
	DataOutputs = 3								
	MaxNoContactTicks = 120	
	MinRange = 1
	MaxRange = 2000
	pi = 3.14159265
	
	Error = 0
--Functions
function Check(A1,A2,A3,B1,B2,B3,T) -- Input DistanceA,ElevationA,AzimuthA,DistB,ElvB,AziB,Merge Tollerence Output if target unique based on merge parameters
	if A1~=nil and A2~=nil and A3~=nil and B1~=nil and B2~=nil and B3~=nil and T~=nil
	then 
		dA=(((A1-B1)^2)+(((A2-B2)*A1)^2)+(((A3-B3)*A1)^2))^0.5
		dAC=(dA<=T)
	else
		dAC=false
	end
	return (dAC)
end




function onTick()            -- Tick function that will be executed every logic tick	
-- Data Input

	for i=1, 8
	do
		if (input.getNumber((4*(i-1))+1) >= MinRange and input.getNumber((4*(i-1))+1) ~= nil)
		then
			BoolIn[i] = input.getBool(i)
			DetectedDist[i] = input.getNumber((4*(i-1))+1)
			DetectedAzi[i] = input.getNumber((4*(i-1))+2)
			DetectedEle[i] = input.getNumber((4*(i-1))+3)
		end
	end
--Actual Program Starts
	if Tick									-- Lua is silly and the non I/O portion has to be in an if loop or everything dies and I don't know why
	then

		if Tick == 1							-- Initialize Lists and Variables
		then
			TargetElevation = {}							
			TargetAzimuth = {}								
			TargetDistance = {}								
			Targets = 0 	
			Target = {}
		elseif Tick >= 108010					--- Prevents Interger Overflow on Tick breaking things (Tick Reset arbitrarily set to every 30 minutes or 1.5 default ingame days)
		then
			Tick =10
		end

		for i=1, MaxInputTargets
		do
			Targets = #TargetElevation	
			Detections = #DetectedEle	
			for i=1, Detections 
			do
				NewTarget = true
				if Targets ~=0
				then
					for j=1, Targets
					do

						if Check(DetectedDist[i],DetectedEle[i],DetectedAzi[i],TargetDistance[j],TargetElevation[j],TargetAzimuth[j],MergeTolleranceMeters)
						then
							NewTarget = false
							TargetDistance[j] = DetectedDist[i]
							TargetElevation[j] = DetectedEle[i]
							TargetAzimuth[j] = DetectedAzi[i]
							Target[j] = Tick
						end
					end

				end
				if NewTarget == true
				then
				
					TargetDistance[Targets+1] = DetectedDist[i]
					TargetElevation[Targets+1] = DetectedEle[i]
					TargetAzimuth[Targets+1] = DetectedAzi[i]
					Target[Targets+1] = Tick
				end
			
			end		


			for i=1, Targets
			do
				if (Tick-Target[i]) > MaxNoContactTicks
				then
					TargetElevation[i]=nil
				end
			end
			for i=1, Targets
			do
				for j=(i+1), Targets
				do
					if ((TargetElevation[i]==TargetElevation[j] and TargetAzimuth[i]==TargetAzimuth[j] and TargetDistance[i]==TargetDistance[j]) or TargetElevation[i]==nil or TargetAzimuth[i]==nil or TargetDistance[i]==nil)
					then
						if(i~=j)
						then
							TargetDistance[i] = nil
							TargetElevation[i] = nil
							TargetAzimuth[i] = nil
						elseif(TargetElevation[i]==nil)
						then
							TargetDistance[i] = nil
							TargetElevation[i] = nil
							TargetAzimuth[i] = nil
						end
					end
				end
			end
		
		end
		Tick = Tick + 1
	end
--Actual Program Ends
-- Data Output
	--	for i=1, MaxOuputTargets
	--	do
	i=1
			output.setNumber(((DataOutputs*i)+(1-DataOutputs)), TargetDistance[i])
			output.setNumber(((DataOutputs*i)+(2-DataOutputs)), TargetAzimuth[i])
			output.setNumber(((DataOutputs*i)+(3-DataOutputs)), TargetElevation[i])
	--	end
		output.setNumber(29,Error)
		output.setNumber(30,Tick)
		output.setNumber(31,Detections)
		output.setNumber(32,Targets)
end