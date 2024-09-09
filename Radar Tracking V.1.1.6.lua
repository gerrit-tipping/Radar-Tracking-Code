Tick = 1
	BoolIn = {}
	NumIn = {}
	BoolOut = {}
	NumOut = {}
	
function onTick()            -- Tick function that will be executed every logic tick	
-- Data Input
	DataOutputs = 3
	for i=1, 8
	do
		BoolIn[i] = input.getBool(i)
		NumIn[(4*(i-1))+1] = input.getNumber((4*(i-1))+1)
		NumIn[(4*(i-1))+2] = input.getNumber((4*(i-1))+2)
		NumIn[(4*(i-1))+3] = input.getNumber((4*(i-1))+3)
		NumIn[(4*i)] = input.getNumber((4*i))
	end
	MinRange = NumIn[4]						-- Numerical Channel 4 Sets Radar Minimum Range
	MinRange = NumIn[8]						-- Numerical Channel 8 Sets Radar Max Range

--Actual Program Starts
	if Tick									-- Lua is silly and the non I/O portion has to be in an if loop or everything dies and I don't know why
	then
	
		if Tick == 1							-- Initialize Lists and Variables
		then
			Elevation = {}								-- Elevation in Rotations
			Azimuth = {}								-- Azimuth in Rotations
			Distance = {}								-- Distance in Rotations
			Detections = 0								-- Count of Times Radar detected an object
			Targets = 0									-- Number of detected objects outside Target merging threashold
		elseif Tick >= 108010					--- Prevents Interger Overflow on Tick breaking things (Tick Reset arbitrarily set to every 30 minutes or 1.5 default ingame days)
		then
			Tick =10
		end
		
		for i=1, 8 
		do
			if NumIn[(4*(i-1))+1] >= MinRange
			then
				Distance[i] = NumIn[(4*(i-1))+1]
				Azimuth[i] = NumIn[(4*(i-1))+2]
				Elevation[i] = NumIn[(4*(i-1))+3]
			end
		end
		
		for i=1, 8 
		do
			NumOut[(DataOutputs*(i-1))+1] = Distance[i]
			NumOut[(DataOutputs*(i-1))+2] = Azimuth[i]
			NumOut[(DataOutputs*(i-1))+3] = Elevation[i]
		end
		
		NumOut[33] = Tick
		NumOut[34] = Detections
		NumOut[35] = Targets
		Tick = Tick + 1
	end
--Actual Program Ends

-- Data Output
		for i=0, 7 
		do
			output.setNumber(((DataOutputs*i)+1), NumOut[((DataOutputs*i)+1)])		--Output Distance to Target i
			output.setNumber(((DataOutputs*i)+2), NumOut[(DataOutputs*i)+2])		--Output Azimuth of Target i
			output.setNumber(((DataOutputs*i)+3), NumOut[(DataOutputs*i)+3])		--Output Elevation of Target i
		end
		output.setNumber(30,NumOut[33])		--Output number of Ticks
		output.setNumber(31,NumOut[34])		--Output number of Detections
		output.setNumber(32,NumOut[35])		--Output number of Targets
end