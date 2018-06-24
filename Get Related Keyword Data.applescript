
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

property dv : 0.25
property browserTimeoutValue : 60

property repeatCount2 : -1

property firstKeyword : ""

property safari : "Safari"

property currentKeyword : ""

property badKeywordCount : 0
property lowEngagementCount : 0
property lowSearchesCount : 0
property highCompetitionCount : 0

property byId : "getElementById"
property byClassName : "getElementsByClassName"
property byTagName : "getElementsByTagName"
property byName : "getElementsByName"
property innerHTML : "innerHTML"
property innerText : "innerText"
property value : "value"
property stripCommas : "replace(',','')"
property stripK : "replace('k','000')"
property splitDashes : "split(' - ',1)"

property threshold : ""
property searchesMin : 0
property engagementMin : 0
property competitionMax : 0

property rowHeaders : "Keyword,Searches,Engagement,Competition,Shops Competing,Average Renewal,Bargain Price,Midrange Price,Premium Price"

property newLine : "
"



##
## USER INPUTS
##

-- User prompt
on userPrompt(theText, buttonText1, buttonText2, type)
	if type = 1 then
		display dialog theText
	else
		display dialog theText buttons {buttonText1, buttonText2}
	end if
end userPrompt

on userPrompt3(theText, buttonText1, buttonText2, buttonText3)
	display dialog theText buttons {buttonText1, buttonText2, buttonText3}
end userPrompt3


-- Ask the user for threshold setting
on getThreshold()
	activate
	set choice1 to "low"
	set choice2 to "medium"
	set choice3 to "high"
	
	set threshold to button returned of userPrompt3("Choose your keyword threshold", choice1, choice2, choice3) as text
	
	return
end getThreshold


-- Prompt for keyword
on userKeyword()
	set theKeyword to display dialog "Enter a keyword" default answer ""
	set keyword to text returned of theKeyword as text
	set firstKeyword to keyword
	return keyword as text
end userKeyword


-- Find the Marmalead search bar in the DOM and insert the search term
on setSearchInput(theId, keyword)
	tell application "Safari"
		do JavaScript "document.getElementById('" & theId & "').value ='" & keyword & "'; doSearch();" in document 1
		delay dv
	end tell
end setSearchInput



##
## FILE READING AND WRITING
##

-- Reading and Writing Params
on writeTextToFile(theText, theFile, overwriteExistingContent)
	try
		set theFile to theFile as string
		set theOpenedFile to open for access file theFile with write permission
		
		if overwriteExistingContent is true then set eof of theOpenedFile to 0
		write theText to theOpenedFile starting at eof
		close access theOpenedFile
		
		return true
	on error
		try
			close access file theFile
		end try
		
		return false
	end try
end writeTextToFile

-- Write to file
on writeFile(theContent, writable)
	set keyword to firstKeyword
	set this_Story to theContent
	set theFile to (((path to desktop folder) as string) & keyword & ".csv")
	writeTextToFile(this_Story, theFile, writable)
end writeFile


##
## GETTING DATA FROM THE DOM
##

-- Get the tag/keyword from the DOM
on getTagName()
	tell application "Safari"
		set input to do JavaScript "document." & byName & "('q')[0]." & value & ";" in document 1
		return input
	end tell
end getTagName

-- Get the stats from the DOM
on getStat(firstMethod, selector, secondMethod, doSplit)
	tell application "Safari"
		if doSplit = 0 then
			set input to do JavaScript "document." & firstMethod & "('" & selector & "')." & secondMethod & "." & stripCommas & ";" in document 1
			return input
		else if doSplit = 1 then
			set input to do JavaScript "document." & firstMethod & "('" & selector & "')." & secondMethod & "." & stripCommas & "." & stripK & "." & splitDashes & ";" in document 1
		end if
		return input
	end tell
end getStat


-- Get Etsy Stats from the DOM
on getEtsyData()
	set tagName to getTagName()
	
	if threshold is "high" then
		set searchesMin to 300
		set engagementMin to 500
		#set competitionMax to 25000
	else if threshold is "medium" then
		set searchesMin to 100
		set engagementMin to 300
		#set competitionMax to 50000
	else if threshold is "low" then
		set searchesMin to 0
		set engagementMin to 0
		#set competitionMax to 50000
	end if
	
	set searches to getStat(byId, "sumSearch", innerText, 1) as number
	
	if searches is less than searchesMin then
		set dataList to "" as text
		set badKeywordCount to badKeywordCount + 1
		set lowSearchesCount to lowSearchesCount + 1
		return dataList
	end if
	
	set engagement to getStat(byId, "sumEngagement", innerText, 1) as number
	
	if engagement is less than engagementMin then
		set dataList to "" as text
		set badKeywordCount to badKeywordCount + 1
		set lowEngagementCount to lowEngagementCount + 1
		return dataList
	end if
	
	
	set Competition to getStat(byId, "sumCompetition", innerText, 1)
	(*	
	if Competition is greater than competitionMax then
		set dataList to "" as text
		set badKeywordCount to badKeywordCount + 1
		set highCompetitionCount to highCompetitionCount + 1
		return dataList
	end if
	*)
	set Competing to getStat(byId, "totShops", innerText, 0)
	set AvgRenewal to getStat(byId, "avgRenewal", innerText, 0)
	set BargainPrice to getStat(byId, "minPrice", innerText, 0)
	set MidrangePrice to getStat(byId, "avgPrice", innerText, 0)
	set maxPrice to getStat(byId, "maxPrice", innerText, 0)
	set dataList to {tagName, searches, engagement, Competition, Competing, AvgRenewal, BargainPrice, MidrangePrice, maxPrice} as text
	
	return dataList
end getEtsyData



##
## CHECKS
##

-- Check if the browser is loaded
on checkIfLoaded()
	set browserTimeoutValue to 60
	
	tell application "Safari"
		repeat with i from 1 to the browserTimeoutValue
			tell application "Safari"
				delay dv
				set checkLoading to (do JavaScript "document.getElementById('loading').style.display;" in document 1)
				set loggedOut to (do JavaScript "document.getElementById('loError').style.display;" in document 1)
				delay dv
				
				if checkLoading is "none" then
					return true
				else if i is the browserTimeoutValue then
					return false
				else
					log "Loading..."
				end if
			end tell
		end repeat
	end tell
end checkIfLoaded

-- Check if the keyword is found
on checkKeyword()
	tell application "Safari"
		delay dv
		
		set noResultsCheck to (do JavaScript "document.getElementById('noresults').style.display;" in document 1)
		
		if noResultsCheck is "none" then
			return true
		else
			return false
		end if
		
	end tell
end checkKeyword

-- Check User Keyword Results
on checkResultsOfUserKeyword()
	repeat
		set theKeyword to userKeyword() as text
		
		setSearchInput("q", theKeyword)
		
		checkIfLoaded()
		
		if checkKeyword() is false then
			writeFile(rowHeaders & newLine & theKeyword & "," & "No Results Found.", false)
		else
			set row0 to writeFile(rowHeaders & newLine & getEtsyData(), false)
			return row0
		end if
	end repeat
end checkResultsOfUserKeyword



##
## RELATED KEYWORD AND WORD CLOUD EVENTS
##


-- Get Word Cloud DOM element
on getWordCloud(theInstance)
	tell application "Safari"
		try
			set doJS to "document." & byId & "('word_cloud')." & byTagName & "('span')[" & theInstance & "]." & innerText & ""
			set wordCloud to (do JavaScript doJS in document 1)
			
		on error
			return false
		end try
		
		return wordCloud
	end tell
end getWordCloud


-- Get every word cloud DOM element
on getWordCloudFromDOM()
	set theList to {}
	
	repeat
		try
			set updatedCount to (repeatCount2 + 1)
			set theKeyword to getWordCloud(updatedCount)
			
			if theKeyword is false then
				set repeatCount2 to -1
				return false
			end if
			
			set repeatCount2 to repeatCount2 + 1
			
			copy theKeyword to the end of the theList
			
		on error
			set repeatCount2 to -1
			exit repeat
		end try
	end repeat
	
	return theList as list
end getWordCloudFromDOM


-- Process all the Related Keywords
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



##
## MAIN ACTIONS AND CALLS
##

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


-- Routines
primaryRoutine()
#getEtsyData()
#checkResultsOfUserKeyword()



