-- Setup diagram syntax C#/B#/V#x# C=composite B=Bool V=Video Input #=channel number #x# pixel measured from bottem left up then right, d=distance a=azimuth e=elivation

-- Inputs
-- Scanning radar (set to rotation clockwise or counterclockwise with max y value min x value) C1=d1,C2=a1,C3=e1,  C4=d2,C5=a2,C6=e2,  C7=d3,C8=a3,C9=e3,  C10=d4,C11=a4,C12=e4,  C13=d5,C14=a5,C15=e5
-- Locking radar (set to static with small to medium x and y value that are roughly equal) C16=d1,C17=a1,C18=e1,  C19=d2,C20=a2,C21=e2,  C22=d3,C23=a3,C24=e3,  C25=d4,C26=a4,C27=e4,  C28=d5,C29=a5,C30=e5
-- physics sensor (point forward arrow toward bow and up arrow up) C31= Absolute Angular velocity (output 14 on physics sensor composite, output is in rotations per second)

-- Outputs



--Settings
	Tick = 1--									Initializes Internal Clock
	BoolIn = {}
	NumIn = {}
	BoolOut = {}
	NumOut = {}
	DetectedEle = {}
	DetectedAzi = {}
	DetectedDist = {}
	MaxInputTargets = 5
	MaxOuputTargets = 5
	MergeTolleranceMeters = 6
	DataOutputs = 3
	MaxNoContactTicks = 300--							5 seconds or about 2 revolutions of phalanx radar
	MinRange = 1
	MaxRange = 2000
	pi = 3.14159265
	Telemetry = {}
	AdjMergeTolleranceMeters = {}
	LocalAbsRotationalVelocity = 0--			sets value to 0 at program start to zero to prevent crash with a nil starting value
	

--Functions
function Check(A1,A2,A3,B1,B2,B3,T)--	Input DistanceA,ElevationA,AzimuthA,DistB,ElvB,AziB,Merge Tollerence Output if target unique based on merge parameters
	if A1~=nil and A2~=nil and A3~=nil and B1~=nil and B2~=nil and B3~=nil and T~=nil
	then
		dA=(((A1-B1)^2)+(((A2-B2)*A1)^2)+(((A3-B3)*A1)^2))^0.5
		dAC=(dA<=T)
	else
		dAC=false
	end
	return (dAC)
end

function MergeCorrection(Dist,LocalAbsRotationalVelocity,MergeTolleranceMeters)--									takes change in heading and adds change in roll from axis that has greatest angle of attack adds them takes the absolute value of each to prevent interference patters causing bugs uses that adjusted angle in arclength formula with distance as the radius to find max error for targeting causes by maneuvers then adds that to set merge tollerences to output new adjusted merge tollerence
	AdjMergeTolleranceMeters = Dist*(((LocalAbsRotationalVelocity/60)^2)^0.5)+MergeTolleranceMeters-- 	does math stated above using the identity that the square root of a square is the definition of absolute value
	return(AdjMergeTolleranceMeters)--																					returns the adjusted merge tollerence
end


function onTick()--            	Tick function that will be executed every logic tick
-- Data Input
	LocalAbsRotationalVelocity = input.getNumber(31)--   					 takes rotational velocity from physics sensor on input composite channel 31 in revolutions per second
	for i=1, 5
	do
		if (input.getNumber((3*(i-1))+1) >= MinRange and input.getNumber((3*(i-1))+1) ~= nil)
		then
			BoolIn[i] = input.getBool(i)
			DetectedDist[i] = input.getNumber((3*(i-1))+1)
			DetectedAzi[i] = input.getNumber((3*(i-1))+2)
			DetectedEle[i] = input.getNumber((3*(i-1))+3)
		end
	end
--Actual Program Starts
	if Tick--									Lua is silly and the non I/O portion has to be in an if loop or everything dies and I don't know why so frankly this is just my tribute to the magic smoke gods to apease them so the magic smoke will run the program
	then

		if Tick == 1--							Initialize Lists and Variables
		then
			TargetElevation = {}
			TargetAzimuth = {}
			TargetDistance = {}
			Targets = 0
			Target = {}
		elseif Tick >= 108010--					Prevents Interger Overflow on Tick breaking things (Tick Reset arbitrarily set to every 30 minutes or 1.5 default ingame days)
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
						if TargetDistance[j]~=nil and Check(DetectedDist[i],DetectedEle[i],DetectedAzi[i],TargetDistance[j],TargetElevation[j],TargetAzimuth[j],MergeCorrection(TargetDistance[j],LocalAbsRotationalVelocity,MergeTolleranceMeters))
						then
							NewTarget = false
							TargetDistance[j] = DetectedDist[i]
							TargetElevation[j] = DetectedEle[i]
							TargetAzimuth[j] = DetectedAzi[i]
							Target[j] = Tick
						end
					end
				end
				if NewTarget == true--								checks if detected object is marked as unrecorded
				then

					TargetDistance[Targets+1] = DetectedDist[i]--		if found to be unrecorded creates new target at index highest previous index+1 then records distance
					TargetElevation[Targets+1] = DetectedEle[i]--		elevation
					TargetAzimuth[Targets+1] = DetectedAzi[i]--			azimuth
					Target[Targets+1] = Tick--							and time last detected
				end
			end
			for i=1, Targets--									loop targets to check age
			do
				if (Tick-Target[i]) > MaxNoContactTicks--		checks if the last siting of the object is withing the threashold set and if so it marks the data as old and to be deleted from memory
				then
					TargetElevation[i]=nil--			intentionally corrupts the elevation data so the data integrety sub program deletes the data that is outdated
				end
			end
			for i=1, Targets--							loops through all target data
			do
				for j=(i+1), Targets--					repeats loop in a second dimension creating a factorial like table to prevent duplicate checks on same data as comparing index 2 with index 3 is the same as doing index 3 with 2 and this removes nearly half the computation time for this step making the script far more efficient
				do
					if (TargetElevation[i]==TargetElevation[j] and TargetAzimuth[i]==TargetAzimuth[j] and TargetDistance[i]==TargetDistance[j])
					then--								checks if values duplicated if so deletes memory entry to remove duplicate target data
						if(i~=j)
						then
							TargetDistance[i] = nil
							TargetElevation[i] = nil
							TargetAzimuth[i] = nil
						end
					elseif(TargetElevation[i]==nil or TargetElevation[i]==nil or TargetAzimuth[i]==nil)--		checks if data is corrupted and if it is it deletes the corrupt data to prevent errors
					then
						TargetDistance[i] = nil
						TargetElevation[i] = nil
						TargetAzimuth[i] = nil
					elseif(TargetDistance[i]==0 and TargetElevation[i]==0 and TargetAzimuth[i]==0)--		checks if data is corrupted (as zero not nil) and if it is it deletes the corrupt data to prevent errors
					then
						TargetDistance[i] = nil
						TargetElevation[i] = nil
						TargetAzimuth[i] = nil
					end
					if (i~=j and TargetElevation[i]==nil and TargetElevation[i]==nil and TargetAzimuth[i]==nil)--		checks if an output is empty
					then--																								if empty sets output to next output's data
						TargetDistance[i] = TargetDistance[j]
						TargetElevation[i] = TargetElevation[j]
						TargetAzimuth[i] = TargetAzimuth[j]
						if (TargetDistance[i] == TargetDistance[j] and TargetElevation[i] == TargetElevation[j] and TargetAzimuth[i] == TargetAzimuth[j])--	checks to see if copy successful
						then--																																if successful deletes source of copy data
						TargetDistance[j] = nil
						TargetElevation[j] = nil
						TargetAzimuth[j] = nil
						end
					end	
				end
			end
		end
		Tick = Tick + 1--							Iterates clock by one at end of each tick
	end
--Actual Program Ends
-- Data Output
	for i=1, MaxOuputTargets--					Starts Loop For Outputting Target Data
	do
			output.setNumber(((3*i)+(1-3)), TargetDistance[i])--	Outputs Target Distance
			output.setNumber(((3*i)+(2-3)), TargetAzimuth[i])--		Target Azimuth
			output.setNumber(((3*i)+(3-3)), TargetElevation[i])--	Target Elevation
	end--
		output.setNumber(29,Error)--				chennel 29 outputs optional internal readings for use in programming and error detection
		output.setNumber(30,Tick)--					channel 30 outputs current clock tick for time keeping
		output.setNumber(31,Detections)--			channel 31 outputs current number of objects in view of radar beam
		output.setNumber(32,Targets)--				chanel 32 outputs current targets in memory
end