----------------------------------
-- PROPERTIES
----------------------------------
set AppleScript's text item delimiters to ","

property rowHeaders : "Keyword,Longtail,Searches,Engagement,Competition,Shops Competing,Free Shipping %,Bargain Price,Midrange Price,Premium Price"

property newLine : "\n"

----------------------------------
-- GLOBAL HANDLERS
----------------------------------

-- Load Script
on load_script(_scriptName)
	tell application "Finder"
		set _myPath to container of (path to me) as string
		set _loadPath to (_myPath & _scriptName) as string
		load script (alias _loadPath)
	end tell
end load_script

-- Boolean Checks
on _check(_parent, _child)
	set _script to load_script("_check.scpt")
	tell _script to set a to _check(_parent, _child)
	return a
end _check

-- Data Handlers
on _getData(_scriptName)
	set _script to load_script(_scriptName)
	set a to run _script
	return a
end _getData


-- Run Single Script
on _run(_scriptName)
	set _script to load_script(_scriptName)
	set a to run _script
	return
end _run

----------------------------------
-- ROUTINES
----------------------------------
-- Get Etsy Data from the DOM
on getData()
	set tagName to _getData("getTagName.scpt")
	set longTail to _check("#kwType > div", "span")
	set searches to _getData("getSearches.scpt")
	set engagement to _getData("getEngagement.scpt")
	set competition to _getData("getCompetition.scpt")
	set shops to _getData("getTotalShops.scpt")
	set freeShipping to _getData("getFreeShipping.scpt")
	set minPrice to _getData("getMinPrice.scpt")
	set avgPrice to _getData("getAvgPrice.scpt")
	set maxPrice to _getData("getMaxPrice.scpt")
	
	set theList to {tagName, longTail, searches, engagement, competition, shops, freeShipping, minPrice, avgPrice, maxPrice}
	
	return theList
end getData


-- Get Etsy Stats from the DOM
on checkThreshold(a)
	if a is true then
		set b to getData()
		return b
	end if
end checkThreshold

on saveFile(theContent, fileName)
	set a to load_script("file_writeFile.scpt")
	tell a to set theData to writeFile(theContent, false, fileName) as string
end saveFile

-- Process all the words from the existing text file
# "base-keywords.txt"
on processTextFile(theProcessFile, theNewFile, returnType)
	set b to load_script("file_path.scpt")
	set c to load_script("do_setInput.scpt")
	set d to load_script("file_writeFile.scpt")
	set e to load_script("list_insert_item.scpt")
	
	set processedList to {}
	set AppleScript's text item delimiters to ","
	
	tell b to set filePath to setFilePath(theProcessFile)
	
	set theList to paragraphs of (read POSIX file filePath)
	
	saveFile(rowHeaders & newLine, theNewFile) as string
	
	repeat with a from 1 to length of theList
		set theCurrentListItem to item a of theList
		
		# Set the input to the current word line of the file and initiate the search
		tell c to set theCurrentSearch to setSearchInput("q", theCurrentListItem)
		
		# Wait for the page to load
		_run("_check_loaded.scpt")
		
		if returnType is 1 then
			set theData to getData() as string
			saveFile(theData & newLine, theNewFile) as string
		else if returnType is 2 then
			set theData to getData()
			tell e to insertItemInList(theData, processedList, 1)
		end if
	end repeat
	
	if returnType is 1 then
		return
	else if returnType is 2 then
		return processedList as string
	end if
end processTextFile

--
processTextFile("base-keywords.txt", "results.csv", 1)

-- Process all the words from the Word Cloud (Related Keywords)
on processWordCloud()
	set theList to getWordCloudFromDOM()
	
	repeat with a from 1 to length of theList
		set theCurrentListItem to item a of theList
		set theCurrentSearch to setSearchInput("q", theCurrentListItem)
		
		checkIfLoaded()
		
		try
			set rowData to writeFile(newLine & getEtsyData(), false)
		on error
			exit repeat
		end try
		
	end repeat
	return
end processWordCloud

-- Main Actions
on primaryRoutine()
	set badKeywordCount to 0
	
	getThreshold()
	
	repeat
		checkResultsOfUserKeyword()
		processWordCloud()
		
		if badKeywordCount is greater than 1 then
			set userMessage to "All done! There were " & badKeywordCount & " keywords that we left out since they had low scores."
		else
			set userMessage to "All done!"
		end if
		
		userPrompt(userMessage, "", "", 1)
		
		exit repeat
	end repeat
end primaryRoutine
