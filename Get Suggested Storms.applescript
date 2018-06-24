set AppleScript's text item delimiters to ","
property repeatCount : 0
property s : 0.5
property comma : ","
property fileName : "Marmalead Storm Scores.csv"
property doSaveButton : "document.getElementById('btn_fs_save').click()"
property headers : "keyword, searches, engagement, competition"
property stripChars : "replace('marmameter-dot','')"
property stripChars2 : "replace(/Your Bucket for /g,'')"

property newLine : "
"

set repeatCount to 0



###############################################
## LIST HANDLING
#
-- Insert item into a list
on insertItemInList(theItem, theList, thePosition)
	set theListCount to length of theList
	if thePosition is 0 then
		return false
	else if thePosition is less than 0 then
		if (thePosition * -1) is greater than theListCount + 1 then return false
	else
		if thePosition is greater than theListCount + 1 then return false
	end if
	if thePosition is less than 0 then
		if (thePosition * -1) is theListCount + 1 then
			set beginning of theList to theItem
		else
			set theList to reverse of theList
			set thePosition to (thePosition * -1)
			if thePosition is 1 then
				set beginning of theList to theItem
			else if thePosition is (theListCount + 1) then
				set end of theList to theItem
			else
				set theList to (items 1 thru (thePosition - 1) of theList) & theItem & (items thePosition thru -1 of theList)
			end if
			set theList to reverse of theList
		end if
	else
		if thePosition is 1 then
			set beginning of theList to theItem
		else if thePosition is (theListCount + 1) then
			set end of theList to theItem
		else
			set theList to (items 1 thru (thePosition - 1) of theList) & theItem & (items thePosition thru -1 of theList)
		end if
	end if
	return theList
end insertItemInList

###############################################
## FILE READING AND WRITING
#

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
	set this_Story to theContent
	set theFile to (((path to desktop folder) as string) & fileName)
	writeTextToFile(this_Story, theFile, writable)
end writeFile

-- Open a File
on openFile(theFile, theApp)
	tell application "Finder"
		open file ((path to desktop folder as text) & theFile) using ((path to applications folder as text) & theApp)
	end tell
end openFile

-- Write Headers
on writeHeaders()
	writeFile(headers & newLine, false)
end writeHeaders

######################################################
# Get data from the "Your Bucket" section of the DOM
######################################################

# get the keyword scores (searches, engagement, competition)
on getDataScore_bucket(updatedCounter, instance)
	tell application "Safari"
		set col to do JavaScript "document.querySelector('#fs_bucket > li:nth-child(" & updatedCounter & ") > div > div > div:nth-child(2) > div:nth-child(" & instance & ") > div').className." & stripChars & "" in document 1
	end tell
	return col
end getDataScore_bucket

# get the keyword for the bucket section
on getDataKeyword_bucket(updatedCounter)
	tell application "Safari"
		set keyword to do JavaScript "document.querySelector('#fs_bucket > li:nth-child(" & updatedCounter & ") > div > div > div:nth-child(3)').innerText" in document 1
	end tell
	return keyword as text
end getDataKeyword_bucket

######################################################
# Get data from the "Suggestions" section of the DOM
######################################################

# get the keyword scores (searches, engagement, competition)
on getSuggestionsScores(updatedCounter, instance)
	tell application "Safari"
		set theData to do JavaScript "document.querySelector('#fs_suggestions > li:nth-child(" & updatedCounter & ") > div > div > div:nth-child(1) > div:nth-child(" & instance & ") > div').className." & stripChars & "" in document 1
	end tell
	return theData
end getSuggestionsScores

on getSuggestionsKeyword(updatedCounter)
	tell application "Safari"
		set keyword to do JavaScript "document.querySelector('#fs_suggestions > li:nth-child(" & updatedCounter & ") > div > div > div:nth-child(2)').innerText" in document 1
	end tell
	return keyword as text
end getSuggestionsKeyword

# Get the term we searched for
on getDataUserTerm()
	tell application "Safari"
		set theData to do JavaScript "document.getElementById('fs_name').innerText." & stripChars2 & "" in document 1
	end tell
	return theData
end getDataUserTerm

##############################################
# Get Suggestions Data Routine
##############################################

on getSuggestions()
	set userTerm to getDataUserTerm()
	
	writeFile(userTerm & newLine & headers & newLine, false)
	
	set repeatCount to 0
	try
		repeat
			set updatedCounter to repeatCount + 1
			
			set keyword to getSuggestionsKeyword(updatedCounter)
			set col1 to getSuggestionsScores(updatedCounter, 1)
			set col2 to getSuggestionsScores(updatedCounter, 2)
			set col3 to getSuggestionsScores(updatedCounter, 3)
			
			writeFile(keyword & "," & col1 & "," & col2 & "," & col3 & newLine, false)
			
			set repeatCount to repeatCount + 1
		end repeat
	on error
		log "Finished!"
		return
	end try
end getSuggestions



#################################
# Routines
#################################

# get keywords and scores from storm bucket
on getBucket()
	set userTerm to getDataUserTerm()
	
	writeFile(userTerm & newLine & headers & newLine, false)
	
	set repeatCount to 0
	try
		repeat
			set updatedCounter to repeatCount + 1
			
			set keyword to getDataKeyword_bucket(updatedCounter)
			set col1 to getDataScore_bucket(updatedCounter, 1)
			set col2 to getDataScore_bucket(updatedCounter, 2)
			set col3 to getDataScore_bucket(updatedCounter, 3)
			
			writeFile(keyword & "," & col1 & "," & col2 & "," & col3 & newLine, false)
			
			set repeatCount to repeatCount + 1
		end repeat
	on error
		log "Finished!"
		return
	end try
end getBucket

#getBucket()
getSuggestions()
