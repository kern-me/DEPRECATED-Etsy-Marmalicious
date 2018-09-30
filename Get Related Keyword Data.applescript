###################
# LOAD SCRIPT
###################
on load_script(_scriptName)
	tell application "Finder"
		set _myPath to container of (path to me) as string
		set _loadPath to (_myPath & _scriptName) as string
		load script (alias _loadPath)
	end tell
end load_script

set AppleScript's text item delimiters to ","

property keyword : "q"
property scoreEtsySearches : "sumSearch"
property scoreEtsyEngagement : "sumEngagement"
property scoreCompetition : "sumCompetition"
property scoreCompeting : "totShops"
property scoreAvgRenewal : "avgRenewal"
property scoreBargainPrice : "minPrice"
property scoreMidrangePrice : "avgPrice"
property scorePremiumPrice : "maxPrice"

property browserTimeoutValue : 60

property threshold : ""

property rowHeaders : "Keyword,Searches,Engagement,Competition,Shops Competing,Average Renewal,Bargain Price,Midrange Price,Premium Price"

property newLine : "
"

#################################
# Boolean Checks
on _check(_parent, _child)
	set _script to load_script("_check.scpt")
	tell _script to set a to _check(_parent, _child)
	return a
end _check

#################################
# Data Handlers
on _getData(_scriptName)
	set _script to load_script(_scriptName)
	set a to run _script
	return a
end _getData


#################################
on checkFlags()
	# Check if long tail
	set flag_a to _check("#kwType > div", "span")
	
	# Check if searches is at least 'good'
	set flag_b to _check("#mm-search-bars", "div")
	
	# Check if engagement is at least 'good'
	set flag_c to _check("#mm-eng-bars", "div")
	
	# Check if competition is at least 'goog'
	set flag_d to _check("#mm-comp-bars", "div")
	
	set flags to {flag_a, flag_b, flag_c, flag_d}
	
	if flags contains false then
		return false
	else
		return true
	end if
end checkFlags

#################################

on getDomData()
	set tagName to _getData("getTagName.scpt")
	set longTail to _check("#kwType > div", "span")
	set searches to _getData("getSearches.scpt")
	set engagement to _getData("getEngagement.scpt")
	set competition to _getData("getCompetition.scpt")
	set shops to _getData("getTotalShops.scpt")
	set minPrice to _getData("getMinPrice.scpt")
	set avgPrice to _getData("getAvgPrice.scpt")
	set maxPrice to _getData("getMaxPrice.scpt")
	
	set theList to {tagName, longTail, searches, engagement, competition, shops, minPrice, avgPrice, maxPrice}
	
	return theList
end getDomData

-- Get Etsy Stats from the DOM
on getEtsyData()
	#Prompt User for threshold setting
	set threshold to _getData("ui_getThreshold.scpt")
	
	if threshold is "high" then
		set thresholdFlag to checkFlags()
		
		if thresholdFlag is true then
			set theData to getDomData()
		else
			return
		end if
	end if
	
	return theData
end getEtsyData

getEtsyData()


-- Process all the words from the existing text file
on processTextFile()
	set fileName to "/Users/nicokillips/dev/Etsy Products/Marmalead/base-keywords.txt"
	set theList to paragraphs of (read POSIX file fileName)
	
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
end processTextFile


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
