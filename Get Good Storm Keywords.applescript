set AppleScript's text item delimiters to ","
property repeatCount : 0
property s : 0.5
property comma : ","
property fileName : "Marmalead-storms.csv"
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

-- Read line from file
on makeKeywordList()
	set theList to {}
	set theKeywords to paragraphs of (read POSIX file "/Users/nicokillips/Desktop/keyword-list.txt")
	repeat with nextLine in theKeywords
		if length of nextLine is greater than 0 then
			copy nextLine to the end of theList
		end if
	end repeat
	return theList
end makeKeywordList

on getDataScore_storm(instance)
	try
		tell application "Safari"
			set theData to do JavaScript "document.querySelector('#fs_suggestions > li:nth-child(1) > div > div > div:nth-child(1) > div:nth-child(" & instance & ") > div').className." & stripChars & "" in document 1
		end tell
		return theData
	on error
		return false
	end try
end getDataScore_storm

on getDataUserTerm()
	tell application "Safari"
		set theData to do JavaScript "document.getElementById('fs_name').innerText." & stripChars2 & "" in document 1
	end tell
	return theData
end getDataUserTerm

on removeButton_storm()
	tell application "Safari"
		delay s
		set btn to do JavaScript "document.querySelector('#fs_suggestions > li:nth-child(1) > div > div > div:nth-child(3) > button.btn.btn-danger').click()" in document 1
		delay s
	end tell
end removeButton_storm

on addToStorm()
	tell application "Safari"
		set btn to do JavaScript "document.getElementById('fs_suggestions').getElementsByTagName('button')[1].click()" in document 1
		delay s
	end tell
end addToStorm

##

on storm()
	repeat
		delay s
		
		repeat
			if getDataScore_storm is false then
				exit repeat
				return
			end if
			
			set searchesResult to getDataScore_storm(1)
			
			if searchesResult contains "bad" then
				removeButton_storm()
				exit repeat
				(*else if searchesResult contains "moderate" then
				removeButton_storm()
				exit repeat*)
			end if
			
			set engagementResult to getDataScore_storm(2)
			
			if engagementResult contains "bad" then
				removeButton_storm()
				exit repeat
				(*else if engagementResult contains "moderate" then
				removeButton_storm()
				exit repeat*)
			end if
			
			set competitionResult to getDataScore_storm(3)
			
			(*if competitionResult contains "bad" then
				delay s
				removeButton_storm()
				delay s
				exit repeat
			else if competitionResult contains "moderate" then
				delay s
				removeButton_storm()
				delay s
				exit repeat
			end if*)
			
			addToStorm()
		end repeat
	end repeat
end storm

storm()

